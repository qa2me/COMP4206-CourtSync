import 'package:flutter/material.dart';
import '../pages/matches.dart';

class MatchConfirmationPage extends StatelessWidget {
  final Match match;
  final String role; // 'Player' or 'Referee'
  final String userName;

  const MatchConfirmationPage({
    super.key,
    required this.match,
    required this.role,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2A4A),
        foregroundColor: Colors.white,
        title: const Text(
          'Match Confirmed',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),

            // ── Success icon ──────────────────────────────────────────────
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 52),
            ),
            const SizedBox(height: 20),

            Text(
              'You\'re in, $userName!',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2A4A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'You have joined as a $role',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 32),

            // ── Info card ─────────────────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow(Icons.sports_tennis, 'Match Type', match.type),
                  const Divider(height: 24),
                  _infoRow(Icons.location_on, 'Venue', match.venue),
                  const Divider(height: 24),
                  _infoRow(Icons.access_time, 'Date & Time', match.dateTime),
                  const Divider(height: 24),
                  _infoRow(
                    Icons.people,
                    'Players',
                    '${match.player1.name.replaceAll('\n', ' ')}  vs  ${match.player2.name.replaceAll('\n', ' ')}',
                  ),
                  const Divider(height: 24),
                  _infoRow(
                    Icons.sports,
                    'Referee',
                    match.referee ?? 'Not assigned',
                  ),
                  const Divider(height: 24),
                  _infoRow(
                    Icons.group,
                    'Players Joined',
                    '${match.playersJoined} / ${match.playersTotal}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Role badge ────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: role == 'Referee'
                    ? const Color(0xFF1A2A4A)
                    : const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Icon(
                    role == 'Referee' ? Icons.sports : Icons.person,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your Role: $role',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Back button ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Color(0xFF1A2A4A)),
                label: const Text(
                  'Back to Matches',
                  style: TextStyle(color: Color(0xFF1A2A4A)),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF1A2A4A)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF2196F3)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF1A2A4A),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}