import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FleetPage extends StatelessWidget {
  const FleetPage({super.key});

  static const Color background = Color(0xFF0B1628);
  static const Color surface = Color(0xFF122035);
  static const Color border = Color(0xFF1C2E45);
  static const Color orange = Color(0xFFF5921E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF5A7A9A);
  static const Color success = Color(0xFF4ADE80);

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
            final fleetCode = userData['fleetCode'] ?? '';
            final mcDot = userData['mcDot'] ?? '';
            final firstName = userData['firstName'] ?? 'Fleet Owner';

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(width: 36, height: 36, decoration: BoxDecoration(color: orange, shape: BoxShape.circle), child: const Center(child: Icon(Icons.chevron_left, color: Colors.white, size: 22))),
                      ),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Fleet Dashboard', style: GoogleFonts.barlowCondensed(fontSize: 24, fontWeight: FontWeight.w900, color: textPrimary)),
                        Text('MC-' + mcDot, style: GoogleFonts.barlow(fontSize: 12, color: textMuted)),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // FLEET CODE CARD
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: orange.withValues(alpha: 0.3))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('YOUR FLEET CODE', style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2, color: textMuted)),
                      const SizedBox(height: 8),
                      Text(fleetCode, style: GoogleFonts.barlowCondensed(fontSize: 32, fontWeight: FontWeight.w900, color: orange, letterSpacing: 2)),
                      const SizedBox(height: 4),
                      Text('Share this code with your drivers when they register', style: GoogleFonts.barlow(fontSize: 12, color: textMuted)),
                    ]),
                  ),

                  const SizedBox(height: 20),

                  Text('YOUR DRIVERS', style: GoogleFonts.barlowCondensed(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2, color: textMuted)),
                  const SizedBox(height: 8),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').where('fleetId', isEqualTo: user?.uid).snapshots(),
                    builder: (context, driversSnapshot) {
                      final drivers = driversSnapshot.data?.docs ?? [];

                      if (drivers.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                          child: Center(child: Column(children: [
                            const Icon(Icons.person_add, color: Color(0xFF5A7A9A), size: 40),
                            const SizedBox(height: 12),
                            Text('No drivers yet', style: GoogleFonts.barlow(fontSize: 14, color: textMuted)),
                            const SizedBox(height: 4),
                            Text('Share your fleet code with your drivers', style: GoogleFonts.barlow(fontSize: 12, color: textMuted), textAlign: TextAlign.center),
                          ])),
                        );
                      }

                      return Column(
                        children: drivers.map<Widget>((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final driverName = (data['firstName'] ?? '') + ' ' + (data['lastName'] ?? '');
                          final totalLoads = (data['totalLoads'] ?? 0) as int;
                          final verifiedLoads = (data['verifiedLoads'] ?? 0) as int;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44, height: 44,
                                    decoration: BoxDecoration(color: orange.withValues(alpha: 0.12), shape: BoxShape.circle),
                                    child: Center(child: Text(driverName.isNotEmpty ? driverName[0].toUpperCase() : 'D', style: GoogleFonts.barlowCondensed(fontSize: 18, fontWeight: FontWeight.w900, color: orange))),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(driverName, style: GoogleFonts.barlow(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                                    Text(totalLoads.toString() + ' loads uploaded', style: GoogleFonts.barlow(fontSize: 12, color: textMuted)),
                                  ])),
                                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                    Text(verifiedLoads.toString(), style: GoogleFonts.barlowCondensed(fontSize: 20, fontWeight: FontWeight.w900, color: verifiedLoads >= 100 ? success : orange)),
                                    Text('confirmed', style: GoogleFonts.barlow(fontSize: 10, color: textMuted)),
                                  ]),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  Text('ALL FLEET LOADS', style: GoogleFonts.barlowCondensed(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2, color: textMuted)),
                  const SizedBox(height: 8),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('loads').where('fleetId', isEqualTo: user?.uid).orderBy('createdAt', descending: true).limit(20).snapshots(),
                    builder: (context, loadsSnapshot) {
                      final loads = loadsSnapshot.data?.docs ?? [];

                      if (loads.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                          child: Center(child: Text('No loads yet from your fleet', style: GoogleFonts.barlow(fontSize: 14, color: textMuted))),
                        );
                      }

                      return Column(
                        children: loads.map<Widget>((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final loadNum = data['loadNumber'] ?? 'YU-0000';
                          final pickup = data['pickupCity']?.isNotEmpty == true ? data['pickupCity'] + ' ' + (data['pickupState'] ?? '') : (data['pickupState'] ?? '');
                          final delivery = data['deliveryCity']?.isNotEmpty == true ? data['deliveryCity'] + ' ' + (data['deliveryState'] ?? '') : (data['deliveryState'] ?? '');
                          final rate = (data['rate'] ?? 0.0).toDouble();
                          final driverName = data['driverName'] ?? 'Driver';
                          final confirmed = data['brokerConfirmed'] ?? false;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                              child: Row(
                                children: [
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(loadNum, style: GoogleFonts.barlowCondensed(fontSize: 13, fontWeight: FontWeight.w800, color: orange, letterSpacing: 1)),
                                    Text(pickup + ' → ' + delivery, style: GoogleFonts.barlow(fontSize: 13, color: textPrimary)),
                                    Text(driverName, style: GoogleFonts.barlow(fontSize: 11, color: textMuted)),
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
                                ],
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
            );
          },
        ),
      ),
    );
  }
}
