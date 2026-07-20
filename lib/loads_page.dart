import 'package:flutter/material.dart';
import 'calendar_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'new_load_page.dart';
import 'home_page.dart';
import 'profile_page.dart';
import 'edit_load_page.dart';

class LoadsPage extends StatefulWidget {
  const LoadsPage({super.key});
  @override
  State<LoadsPage> createState() => _LoadsPageState();
}

class _LoadsPageState extends State<LoadsPage> {
  final _searchController = TextEditingController();
  String _searchText = '';
  String _statusFilter = 'All';

  static const Color background = Color(0xFF0B1628);
  static const Color surface = Color(0xFF122035);
  static const Color border = Color(0xFF1C2E45);
  static const Color orange = Color(0xFFF5921E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF5A7A9A);
  static const Color success = Color(0xFF4ADE80);
  static const Color info = Color(0xFF60A5FA);
  static const Color danger = Color(0xFFEF4444);

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF0D1E30), border: Border(top: BorderSide(color: border))),
      child: Row(
        children: [
          _buildNavItem(Icons.home, 'HOME', false, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage()))),
          _buildNavItem(Icons.local_shipping, 'LOADS', true, () {}),
          _buildNavItem(Icons.person, 'PROFILE', false, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage()))),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isActive ? orange : textMuted, size: 22),
              const SizedBox(height: 4),
              Text(label, style: GoogleFonts.barlowCondensed(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: isActive ? orange : textMuted)),
              if (isActive) Container(margin: const EdgeInsets.only(top: 4), width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFFF5921E), shape: BoxShape.circle)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage())),
                            child: Container(width: 36, height: 36, decoration: BoxDecoration(color: orange, shape: BoxShape.circle), child: const Center(child: Icon(Icons.chevron_left, color: Colors.white, size: 22))),
                          ),
                          const SizedBox(width: 12),
                          Text('Loads', style: GoogleFonts.barlowCondensed(fontSize: 32, fontWeight: FontWeight.w900, color: textPrimary, letterSpacing: -0.5)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      child: Text('What would you like to do?', style: GoogleFonts.barlow(fontSize: 13, color: textMuted)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewLoadPage())),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(color: orange, borderRadius: BorderRadius.circular(16)),
                                child: Column(
                                  children: [
                                    const Icon(Icons.add, size: 32, color: Color(0xFF0B1628)),
                                    const SizedBox(height: 10),
                                    Text('NEW LOAD', style: GoogleFonts.barlowCondensed(fontSize: 18, fontWeight: FontWeight.w900, color: background)),
                                    const SizedBox(height: 4),
                                    Text('Upload docs and generate invoice', style: GoogleFonts.barlow(fontSize: 11, color: Color(0x990B1628)), textAlign: TextAlign.center),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarPage())),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
                                child: Column(
                                  children: [
                                    const Icon(Icons.calendar_month, size: 32, color: Color(0xFFF5921E)),
                                  const SizedBox(height: 10),
                                  Text('PAST LOADS', style: GoogleFonts.barlowCondensed(fontSize: 18, fontWeight: FontWeight.w900, color: textPrimary)),
                                  const SizedBox(height: 4),
                                    Text('Browse your load history', style: GoogleFonts.barlow(fontSize: 11, color: textMuted), textAlign: TextAlign.center),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchText = val.toLowerCase()),
                        style: GoogleFonts.barlow(fontSize: 14, color: textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search load number, state, broker...',
                          hintStyle: GoogleFonts.barlow(fontSize: 13, color: textMuted),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF5A7A9A), size: 20),
                          suffixIcon: _searchText.isNotEmpty ? GestureDetector(onTap: () { _searchController.clear(); setState(() => _searchText = ''); }, child: const Icon(Icons.clear, color: Color(0xFF5A7A9A), size: 18)) : null,
                          filled: true,
                          fillColor: surface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1C2E45), width: 1.5)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF5921E), width: 1.5)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        children: ['All', 'Unpaid', 'Invoiced', 'Paid'].map((filter) {
                          final isActive = _statusFilter == filter;
                          return GestureDetector(
                            onTap: () => setState(() => _statusFilter = filter),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(color: isActive ? orange : surface, borderRadius: BorderRadius.circular(20), border: isActive ? null : Border.all(color: border)),
                              child: Text(filter, style: GoogleFonts.barlowCondensed(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1, color: isActive ? background : textMuted)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                      child: Text('RECENT LOADS', style: GoogleFonts.barlowCondensed(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2, color: textMuted)),
                    ),
                    if (user != null)
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('loads').where('userId', isEqualTo: user.uid).orderBy('createdAt', descending: true).snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: Color(0xFFF5921E))));
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(24),
                              child: Center(child: Column(children: [
                                const Icon(Icons.local_shipping_outlined, color: Color(0xFF5A7A9A), size: 48),
                                const SizedBox(height: 12),
                                Text('No loads yet. Go get some miles.', style: GoogleFonts.barlow(fontSize: 14, color: textMuted)),
                              ])),
                            );
                          }
                          final docs = snapshot.data!.docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final loadNum = (data['loadNumber'] ?? '').toString().toLowerCase();
                            final pickup = (data['pickupState'] ?? '').toString().toLowerCase();
                            final delivery = (data['deliveryState'] ?? '').toString().toLowerCase();
                            final broker = (data['brokerEmail'] ?? '').toString().toLowerCase();
                            final status = (data['status'] ?? '').toString().toLowerCase();
                            final matchesSearch = _searchText.isEmpty || loadNum.contains(_searchText) || pickup.contains(_searchText) || delivery.contains(_searchText) || broker.contains(_searchText);
                            final matchesStatus = _statusFilter == 'All' || status == _statusFilter.toLowerCase();
                            return matchesSearch && matchesStatus;
                          }).toList();
                          if (docs.isEmpty) {
                            return Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('No loads match your search.', style: GoogleFonts.barlow(fontSize: 14, color: textMuted))));
                          }
                          return Column(
                            children: docs.map<Widget>((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final loadNum = data['loadNumber'] ?? 'YU-0000';
                              final pickup = data['pickupState'] ?? '';
                              final delivery = data['deliveryState'] ?? '';
                              final route = pickup.isNotEmpty && delivery.isNotEmpty ? pickup + ' to ' + delivery : 'Route pending';
                              final rate = (data['rate'] ?? 0.0).toDouble();
                              final status = data['status'] ?? 'invoiced';
                              Color statusColor;
                              if (status == 'paid') statusColor = success;
                              else if (status == 'invoiced') statusColor = info;
                              else statusColor = orange;
                              return Dismissible(
                                key: Key(doc.id),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (_) async {
                                  return await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: surface,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: Text('Delete ' + loadNum + '?', style: GoogleFonts.barlowCondensed(fontSize: 22, fontWeight: FontWeight.w900, color: textPrimary)),
                                      content: Text('This cannot be undone.', style: GoogleFonts.barlow(fontSize: 14, color: textMuted)),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('NOPE', style: GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w900, color: textMuted, letterSpacing: 1))),
                                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('YUP DELETE', style: GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w900, color: danger, letterSpacing: 1))),
                                      ],
                                    ),
                                  ) ?? false;
                                },
                                onDismissed: (_) async {
                                  await FirebaseFirestore.instance.collection('loads').doc(doc.id).delete();
                                  final u = FirebaseAuth.instance.currentUser;
                                  if (u != null) await FirebaseFirestore.instance.collection('users').doc(u.uid).update({'totalLoads': FieldValue.increment(-1)});
                                },
                                background: Container(
                                  margin: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                                  decoration: BoxDecoration(color: danger, borderRadius: BorderRadius.circular(12)),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
                                ),
                                child: GestureDetector(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditLoadPage(loadId: doc.id, loadData: data))),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(loadNum.toString(), style: GoogleFonts.barlowCondensed(fontSize: 14, fontWeight: FontWeight.w800, color: orange, letterSpacing: 1)),
                                                const SizedBox(height: 2),
                                                Text(route, style: GoogleFonts.barlow(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                                                const SizedBox(height: 2),
                                                Text('Tap to edit - Swipe left to delete', style: GoogleFonts.barlow(fontSize: 10, color: textMuted)),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text('USD ' + rate.toStringAsFixed(0), style: GoogleFonts.barlowCondensed(fontSize: 18, fontWeight: FontWeight.w900, color: textPrimary)),
                                              const SizedBox(height: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                                                child: Text(status.toString().toUpperCase(), style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildBottomNav(context),
          ],
        ),
      ),
    );
  }
}
