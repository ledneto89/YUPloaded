import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  static const String _serviceId = 'service_lsbabw6';
  static const String _templateId = 'template_uudk7dh';
  static const String _publicKey = '9Q40PrgjQF6dCbg-y';
  static const String _confirmBaseUrl = 'https://us-central1-yuploaded-998bb.cloudfunctions.net/confirmLoad';

  static Future<bool> sendInvoice({
    required String brokerEmail,
    required String loadNumber,
    required String pickupState,
    required String deliveryState,
    required String rate,
    required String driverName,
    required String mcNumber,
    String? rateConUrl,
    String? bolUrl,
    List<String> freightUrls = const [],
    String? podUrl,
    String? pickupZip,
    String? deliveryZip,
    String? notes,
  }) async {
    try {
      final confirmUrl = _confirmBaseUrl + '?load=' + loadNumber + '&email=' + Uri.encodeComponent(brokerEmail);

      // Build document links section
      String docLinks = '';
      if (rateConUrl != null && rateConUrl.isNotEmpty) {
        docLinks += 'Rate Confirmation: ' + rateConUrl + '\n';
      }
      if (bolUrl != null && bolUrl.isNotEmpty) {
        docLinks += 'Bill of Lading: ' + bolUrl + '\n';
      }
      if (freightUrls.isNotEmpty) {
        for (int i = 0; i < freightUrls.length; i++) {
          docLinks += 'Freight Photo ' + (i + 1).toString() + ': ' + freightUrls[i] + '\n';
        }
      }
      if (podUrl != null && podUrl.isNotEmpty) {
        docLinks += 'Proof of Delivery: ' + podUrl + '\n';
      }

      // Build HTML doc links
      String docLinksHtml = '';
      if (rateConUrl != null && rateConUrl.isNotEmpty) {
        docLinksHtml += '<a href="' + rateConUrl + '" style="display:block;margin-bottom:8px;color:#F5921E;font-weight:bold;">📄 View Rate Confirmation</a>';
      }
      if (bolUrl != null && bolUrl.isNotEmpty) {
        docLinksHtml += '<a href="' + bolUrl + '" style="display:block;margin-bottom:8px;color:#F5921E;font-weight:bold;">📄 View Bill of Lading</a>';
      }
      if (freightUrls.isNotEmpty) {
        docLinksHtml += '<a href="' + freightUrls[0] + '" style="display:block;margin-bottom:8px;color:#F5921E;font-weight:bold;">📷 View Freight Photos (' + freightUrls.length.toString() + ')</a>';
      }
      if (podUrl != null && podUrl.isNotEmpty) {
        docLinksHtml += '<a href="' + podUrl + '" style="display:block;margin-bottom:8px;color:#4ADE80;font-weight:bold;">✅ View Proof of Delivery</a>';
      }

      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'origin': 'http://localhost'},
        body: json.encode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _publicKey,
          'template_params': {
            'broker_email': brokerEmail,
            'load_number': loadNumber,
            'pickup_state': pickupState,
            'delivery_state': deliveryState,
            'rate': rate,
            'driver_name': driverName,
            'mc_number': mcNumber,
            'confirm_url': confirmUrl,
            'doc_links': docLinks,
            'doc_links_html': docLinksHtml,
            'pickup_zip': pickupZip ?? '',
            'delivery_zip': deliveryZip ?? '',
            'notes': notes ?? '',
          },
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> sendDispatcherPacket({
    required String dispatcherEmail,
    required String loadNumber,
    required String pickupState,
    required String deliveryState,
    required String driverName,
    String? rateConUrl,
    String? bolUrl,
    List<String> freightUrls = const [],
    String? podUrl,
  }) async {
    try {
      String docLinksHtml = '';
      if (rateConUrl != null && rateConUrl.isNotEmpty) {
        docLinksHtml += '<a href="' + rateConUrl + '" style="display:block;margin-bottom:8px;color:#F5921E;font-weight:bold;">📄 View Rate Confirmation</a>';
      }
      if (bolUrl != null && bolUrl.isNotEmpty) {
        docLinksHtml += '<a href="' + bolUrl + '" style="display:block;margin-bottom:8px;color:#F5921E;font-weight:bold;">📄 View Bill of Lading</a>';
      }
      if (freightUrls.isNotEmpty) {
        docLinksHtml += '<a href="' + freightUrls[0] + '" style="display:block;margin-bottom:8px;color:#F5921E;font-weight:bold;">📷 View Freight Photos (' + freightUrls.length.toString() + ')</a>';
      }
      if (podUrl != null && podUrl.isNotEmpty) {
        docLinksHtml += '<a href="' + podUrl + '" style="display:block;margin-bottom:8px;color:#4ADE80;font-weight:bold;">✅ View Proof of Delivery</a>';
      }

      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'origin': 'http://localhost'},
        body: json.encode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _publicKey,
          'template_params': {
            'broker_email': dispatcherEmail,
            'load_number': loadNumber,
            'pickup_state': pickupState,
            'delivery_state': deliveryState,
            'rate': 'Dispatcher Copy',
            'driver_name': driverName,
            'mc_number': 'Dispatcher Copy',
            'confirm_url': '',
            'doc_links': '',
            'doc_links_html': docLinksHtml,
          },
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
