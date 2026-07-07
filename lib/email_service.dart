import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
static const String _serviceId = 'service_lsbabw6';
static const String _templateId = 'template_uudk7dh';
static const String _publicKey = 'pi76fwr';

static Future<bool> sendInvoice({
required String brokerEmail,
required String loadNumber,
required String pickupState,
required String deliveryState,
required String rate,
required String driverName,
required String mcNumber,
}) async {
try {
final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

final response = await http.post(
url,
headers: {
'Content-Type': 'application/json',
'origin': 'http://localhost',
},
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
}) async {
try {
final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

final response = await http.post(
url,
headers: {
'Content-Type': 'application/json',
'origin': 'http://localhost',
},
body: json.encode({
'service_id': _serviceId,
'template_id': _templateId,
'user_id': _publicKey,
'template_params': {
'broker_email': dispatcherEmail,
'load_number': loadNumber,
'pickup_state': pickupState,
'delivery_state': deliveryState,
'rate': 'N/A',
'driver_name': driverName,
'mc_number': 'Dispatcher Copy',
},
}),
);

return response.statusCode == 200;
} catch (e) {
return false;
}
}
}

