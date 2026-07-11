import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'loads_page.dart';
import 'expenses_page.dart';
import 'taxes_page.dart';
import 'profile_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const Color background = Color(0xFF0B1628);
  static const Color surface = Color(0xFF122035);
  static const Color border = Color(0xFF1C2E45);
  static const Color orange = Color(0xFFF5921E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF5A7A9A);

  String _getRank(int totalLoads) {
    if (totalLoads >= 500) return 'YUPLOADED Elite';
    if (totalLoads >= 250) return 'Road Legend';
    if (totalLoads >= 100) return 'Veteran Hauler';
    if (totalLoads >= 50) return 'Highway Pro';
    if (totalLoads >= 10) return 'Road Warrior';
    return 'Rookie';
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: user != null ? FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots() : null,
          builder: (context, userSnapshot) {
            final userData = userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
            final firstName = userData['firstName'] ?? 'Driver';
            final totalLoads = (userData['totalLoads'] ?? 0) as int;
            final rank = _getRank(totalLoads);

            return StreamBuilder<QuerySnapshot>(
              stream: user != null ? FirebaseFirestore.instance.collection('loads').where('userId', isEqualTo: user.uid).snapshots() : null,
              builder: (context, loadsSnapshot) {
                final loads = loadsSnapshot.data?.docs ?? [];
                final now = DateTime.now();

                final thisMonthLoads = loads.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final createdAt = data['createdAt'];
                  if (createdAt == null) return false;
                  try { final date = (createdAt as dynamic).toDate() as DateTime; return date.month == now.month && date.year == now.year; } catch (e) { return false; }
                }).toList();

                final unpaidLoads = loads.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['status'] == 'unpaid';
                }).toList();

                final thisMonthRate = thisMonthLoads.fold<double>(0, (sum, doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return sum + ((data['rate'] ?? 0.0) as num).toDouble();
                });

                final unpaidRate = unpaidLoads.fold<double>(0, (sum, doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return sum + ((data['rate'] ?? 0.0) as num).toDouble();
                });

                final thisMonthMiles = thisMonthLoads.fold<int>(0, (sum, doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return sum + ((data['mileage'] ?? 0) as num).toInt();
                });

                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_getGreeting(), style: GoogleFonts.barlow(fontSize: 13, color: textMuted, fontWeight: FontWeight.w500)),
                                      Text(firstName + ' !!', style: GoogleFonts.barlowCondensed(fontSize: 28, fontWeight: FontWeight.w900, color: textPrimary, letterSpacing: -0.5)),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage())),
                                    child: Container(
                                      width: 44, height: 44,
                                      decoration: const BoxDecoration(color: orange, shape: BoxShape.circle),
                                      child: Center(child: Text(firstName.isNotEmpty ? firstName[0].toUpperCase() : 'D', style: GoogleFonts.barlowCondensed(fontSize: 18, fontWeight: FontWeight.w900, color: background))),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Container(
                                decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
                                child: Row(
                                  children: [
                                    _buildSummaryItem('USD ' + thisMonthRate.toStringAsFixed(0), 'THIS MONTH', orange),
                                    _buildDivider(),
                                    _buildSummaryItem('USD ' + unpaidRate.toStringAsFixed(0), 'OUTSTANDING', textPrimary),
                                    _buildDivider(),
                                    _buildSummaryItem(thisMonthLoads.length.toString(), 'LOADS', textPrimary),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('MONTHLY MILES', style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: textMuted)),
                                          const SizedBox(height: 4),
                                          Text(thisMonthMiles.toString() + ' mi', style: GoogleFonts.barlowCondensed(fontSize: 22, fontWeight: FontWeight.w900, color: textPrimary, letterSpacing: -0.5)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: orange.withValues(alpha: 0.3))),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('CURRENT RANK', style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: textMuted)),
                                          const SizedBox(height: 4),
                                          Text(rank, style: GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w900, color: orange, letterSpacing: -0.5)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                children: [
                                  _buildNavCard(context, icon: Icons.local_shipping, title: 'LOADS', subtitle: 'New load - Load history', isPrimary: true, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LoadsPage()))),
                                  const SizedBox(height: 12),
                                  _buildNavCard(context, icon: Icons.receipt_long, title: 'EXPENSES', subtitle: 'Log fuel, tolls, repairs', isPrimary: false, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExpensesPage()))),
                                  const SizedBox(height: 12),
                                  _buildNavCard(context, icon: Icons.bar_chart, title: 'TAXES', subtitle: 'P and L - Year-end export', isPrimary: false, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaxesPage()))),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    _buildBottomNav(context),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String value, String label, Color valueColor) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.barlowCondensed(fontSize: 18, fontWeight: FontWeight.w900, color: valueColor, letterSpacing: -0.5)),
            const SizedBox(height: 3),
            Text(label, style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1, color: textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() => Container(width: 1, height: 40, color: border);

  Widget _buildNavCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required bool isPrimary, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isPrimary ? orange : surface,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(icon, color: isPrimary ? background : orange, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.barlowCondensed(fontSize: 20, fontWeight: FontWeight.w900, color: isPrimary ? background : textPrimary, letterSpacing: 0.5)),
                  Text(subtitle, style: GoogleFonts.barlow(fontSize: 12, color: isPrimary ? background.withValues(alpha: 0.6) : textMuted, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: isPrimary ? background.withValues(alpha: 0.5) : textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF0D1E30), border: Border(top: BorderSide(color: border))),
      child: Row(
        children: [
          _buildNavItem(Icons.home, 'HOME', true, () {}),
          _buildNavItem(Icons.local_shipping, 'LOADS', false, () => Navigator.push(context, MaterialPageRoute(builder: (_) => LoadsPage()))),
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
}
