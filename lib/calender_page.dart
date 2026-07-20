import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_load_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;
  Map<String, List<Map<String, dynamic>>> _loadsByDate = {};
  bool _isLoading = true;

  static const Color background = Color(0xFF0B1628);
  static const Color surface = Color(0xFF122035);
  static const Color border = Color(0xFF1C2E45);
  static const Color orange = Color(0xFFF5921E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF5A7A9A);
  static const Color success = Color(0xFF4ADE80);

  @override
  void initState() {
    super.initState();
    _loadLoads();
  }

  Future<void> _loadLoads() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isLoading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('loads')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      final Map<String, List<Map<String, dynamic>>> byDate = {};
      for (final doc in snap.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        final createdAt = data['createdAt'];
        if (createdAt == null) continue;
        try {
          final date = (createdAt as dynamic).toDate() as DateTime;
          final key = date.year.toString() + '-' + date.month.toString().padLeft(2, '0') + '-' + date.day.toString().padLeft(2, '0');
          byDate[key] = [...(byDate[key] ?? []), data];
        } catch (e) {}
      }
      setState(() { _loadsByDate = byDate; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _dateKey(DateTime date) {
    return date.year.toString() + '-' + date.month.toString().padLeft(2, '0') + '-' + date.day.toString().padLeft(2, '0');
  }

  List<DateTime> _daysInMonth(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    final days = <DateTime>[];
    // Add padding days before first
    for (int i = 0; i < first.weekday % 7; i++) {
      days.add(DateTime(0));
    }
    for (int i = 1; i <= last.day; i++) {
      days.add(DateTime(month.year, month.month, i));
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final days = _daysInMonth(_focusedMonth);
    final selectedLoads = _selectedDay != null ? (_loadsByDate[_dateKey(_selectedDay!)] ?? []) : [];
    final monthName = ['January','February','March','April','May','June','July','August','September','October','November','December'][_focusedMonth.month - 1];

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(children: [
              GestureDetector(onTap: () => Navigator.pop(context), child: Container(width: 36, height: 36, decoration: BoxDecoration(color: orange, shape: BoxShape.circle), child: const Center(child: Icon(Icons.chevron_left, color: Colors.white, size: 22)))),
              const SizedBox(width: 12),
              Text('Load Calendar', style: GoogleFonts.barlowCondensed(fontSize: 24, fontWeight: FontWeight.w900, color: textPrimary)),
            ]),
          ),

          const SizedBox(height: 16),

          // MONTH NAVIGATION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              GestureDetector(
                onTap: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1)),
                child: Container(width: 36, height: 36, decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: border)), child: const Center(child: Icon(Icons.chevron_left, color: Colors.white, size: 20))),
              ),
              Text(monthName + ' ' + _focusedMonth.year.toString(), style: GoogleFonts.barlowCondensed(fontSize: 20, fontWeight: FontWeight.w900, color: textPrimary)),
              GestureDetector(
                onTap: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1)),
                child: Container(width: 36, height: 36, decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: border)), child: const Center(child: Icon(Icons.chevron_right, color: Colors.white, size: 20))),
              ),
            ]),
          ),

          const SizedBox(height: 12),

          // DAY LABELS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(children: ['S','M','T','W','T','F','S'].map((d) => Expanded(child: Center(child: Text(d, style: GoogleFonts.barlowCondensed(fontSize: 12, fontWeight: FontWeight.w700, color: textMuted))))).toList()),
          ),

          const SizedBox(height: 8),

          // CALENDAR GRID
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: Color(0xFFF5921E)))
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1),
                itemCount: days.length,
                itemBuilder: (context, index) {
                  final day = days[index];
                  if (day.year == 0) return const SizedBox();
                  final key = _dateKey(day);
                  final hasLoads = _loadsByDate.containsKey(key);
                  final isSelected = _selectedDay != null && _dateKey(_selectedDay!) == key;
                  final isToday = _dateKey(DateTime.now()) == key;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedDay = day),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isSelected ? orange : isToday ? orange.withValues(alpha: 0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isToday && !isSelected ? Border.all(color: orange, width: 1) : null,
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(day.day.toString(), style: GoogleFonts.barlowCondensed(fontSize: 14, fontWeight: FontWeight.w700, color: isSelected ? background : textPrimary)),
                        if (hasLoads) Container(width: 5, height: 5, decoration: BoxDecoration(color: isSelected ? background : orange, shape: BoxShape.circle)),
                      ]),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 16),

          // SELECTED DAY LOADS
          if (_selectedDay != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(children: [
                Text(
                  ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'][_selectedDay!.weekday % 7] + ', ' +
                  ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][_selectedDay!.month - 1] + ' ' +
                  _selectedDay!.day.toString(),
                  style: GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w800, color: orange),
                ),
                const SizedBox(width: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: orange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Text(selectedLoads.length.toString() + ' load${selectedLoads.length == 1 ? '' : 's'}', style: GoogleFonts.barlowCondensed(fontSize: 12, fontWeight: FontWeight.w800, color: orange))),
              ]),
            ),
            const SizedBox(height: 8),
            if (selectedLoads.isEmpty)
              Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Text('No loads on this day', style: GoogleFonts.barlow(fontSize: 14, color: textMuted)))
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: selectedLoads.length,
                  itemBuilder: (context, index) {
                    final data = selectedLoads[index];
                    final loadNum = data['loadNumber'] ?? 'YU-0000';
                    final pickup = data['pickupCity']?.isNotEmpty == true ? data['pickupCity'] + ' ' + (data['pickupState'] ?? '') : (data['pickupState'] ?? '');
                    final delivery = data['deliveryCity']?.isNotEmpty == true ? data['deliveryCity'] + ' ' + (data['deliveryState'] ?? '') : (data['deliveryState'] ?? '');
                    final rate = (data['rate'] ?? 0.0).toDouble();
                    final confirmed = data['brokerConfirmed'] ?? false;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditLoadPage(loadId: data['id'], data: data))),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                          child: Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(loadNum, style: GoogleFonts.barlowCondensed(fontSize: 14, fontWeight: FontWeight.w800, color: orange, letterSpacing: 1)),
                              Text(pickup + ' → ' + delivery, style: GoogleFonts.barlow(fontSize: 13, color: textPrimary)),
                            ])),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text('USD ' + rate.toStringAsFixed(0), style: GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w900, color: textPrimary)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: confirmed ? success.withValues(alpha: 0.12) : orange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                                child: Text(confirmed ? 'CONFIRMED' : 'PENDING', style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w700, color: confirmed ? success : orange)),
                              ),
                            ]),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ] else
            Padding(padding: const EdgeInsets.all(24), child: Text('Tap a date to see loads', style: GoogleFonts.barlow(fontSize: 14, color: textMuted))),
        ]),
      ),
    );
  }
}
