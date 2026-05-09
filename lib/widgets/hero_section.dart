import 'package:flutter/material.dart';
import '../pages/ViewTournamentPage.dart';
import '../pages/CreateTournamentPage.dart';
import '../widgets/hero_button.dart';

Widget buildHeroSection(BuildContext context) {
  return Container(
    width: double.infinity,
    color: const Color(0xFF1A2A4A),
    child: Stack(
      children: [

        SizedBox(
          height: 200,
          width: double.infinity,
          child: Image.asset(
            'assets/images/court1.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFF1A2A4A),
              child: const Icon(
                Icons.sports_tennis,
                color: Colors.white,
                size: 60,
              ),
            ),
          ),
        ),


        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Local Tournaments',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Discover upcoming Tournaments nearby and Compete',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: buildHeroButton(
                      icon: Icons.emoji_events,
                      label: 'View Tournament',
                      bgColor: const Color(0xFFFEE01E),
                      textColor: const Color(0xFF1A2A4A),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ViewTournamentPage(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: buildHeroButton(
                      icon: Icons.emoji_events_outlined,
                      label: 'Create Tournament',
                      bgColor: const Color(0xFF1A2A4A),
                      textColor: Colors.white,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateTournamentPage(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}