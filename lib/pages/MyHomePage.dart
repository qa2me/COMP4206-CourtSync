import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_template/pages/ViewTournamentPage.dart';
import 'package:flutter_template/pages/start_match_page.dart';
import '../models/tournament.dart';
import '../widgets/tournament_card.dart';
import '../widgets/hero_section.dart';
import '../services/database_service.dart';

// HomePageBody is used directly by HeaderAndFooter via IndexedStack
class HomePageBody extends StatefulWidget {
  const HomePageBody({super.key});

  @override
  State<HomePageBody> createState() => _HomePageBodyState();
}

class _HomePageBodyState extends State<HomePageBody> {
  List<Tournament> _tournaments = [];
  List<Map<String, dynamic>> _courts = [];
  Set<String> _joinedIds = {};
  StreamSubscription? _regsSub;

  @override
  void initState() {
    super.initState();
    DatabaseService.instance.tournamentsStream.listen((list) {
      if (mounted) {
        setState(() {
          _tournaments = list.map((d) => Tournament(
            id: d['id'] ?? '',
            name: d['name'] ?? '',
            description: d['description'] ?? '',
            venue: d['venue'] ?? '',
            location: d['location'] ?? '',
            startDate: d['startDate'] ?? '',
            endDate: d['endDate'] ?? '',
            startTime: d['startTime'] ?? '',
            status: _parseStatus(d['status']),
            matchType: _parseMatchType(d['matchType']),
            format: _parseFormat(d['format']),
            isFree: d['isFree'] ?? true,
            entryFee: (d['entryFee'] as num?)?.toDouble(),
            prize: d['prize'] as String?,
            spotsTotal: (d['spotsTotal'] ?? 0) as int,
            spotsLeft: (d['spotsLeft'] ?? 0) as int,
            imagePath: d['imagePath'] ?? 'assets/images/court1.png',
            isCreatedByMe: d['isCreatedByMe'] ?? false,
            isJoined: _joinedIds.contains(d['id'] ?? ''),
          )).toList();
        });
      }
    });
    DatabaseService.instance.courtsStream.listen((list) {
      if (mounted) setState(() => _courts = list);
    });
    final uid = DatabaseService.instance.currentUser?.uid;
    if (uid != null) {
      _regsSub = DatabaseService.instance.userTournamentRegistrationsStream(uid).listen((ids) {
        _joinedIds = ids;
        if (mounted) setState(() {
          for (final t in _tournaments) {
            t.isJoined = ids.contains(t.id);
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _regsSub?.cancel();
    super.dispose();
  }

  TournamentStatus _parseStatus(String? s) {
    switch (s) {
      case 'upcoming': return TournamentStatus.upcoming;
      case 'ongoing': return TournamentStatus.ongoing;
      case 'completed': return TournamentStatus.completed;
      default: return TournamentStatus.upcoming;
    }
  }

  TournamentMatchType _parseMatchType(String? s) {
    switch (s) {
      case 'singles': return TournamentMatchType.singles;
      case 'doubles': return TournamentMatchType.doubles;
      case 'both': return TournamentMatchType.both;
      default: return TournamentMatchType.singles;
    }
  }

  TournamentFormat _parseFormat(String? s) {
    switch (s) {
      case 'singleElimination': return TournamentFormat.singleElimination;
      case 'doubleElimination': return TournamentFormat.doubleElimination;
      case 'roundRobin': return TournamentFormat.roundRobin;
      case 'swiss': return TournamentFormat.swiss;
      default: return TournamentFormat.singleElimination;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildHeroSection(context),
          _buildUpcomingTournaments(),
          const SizedBox(height: 16),
          _buildBottomSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildUpcomingTournaments() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming Tournaments:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2A4A),
                ),
              ),
              Container(
                  
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ViewTournamentPage(),
                          ),
                        );
                      },
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          color: Color(0xFF2196F3),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF2196F3),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: _tournaments
                .where((tournament) => tournament.spotsLeft > 0)
                .map((tournament) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TournamentCard(tournament,context),
                  );
                })
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(14)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Nearby Courts',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF1A2A4A),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: const Row(
                            children: [
                              Text('View',
                                  style: TextStyle(
                                      color: Color(0xFF2196F3),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                              Icon(Icons.chevron_right,
                                  color: Color(0xFF2196F3), size: 15),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 130,
                    width: double.infinity,
                    child: Image.asset(
                      _courts.isNotEmpty
                          ? 'assets/images/alqurmCourt.png'
                          : 'assets/images/alqurmCourt.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 80,
                        color: const Color(0xFFE8F0F8),
                        child: const Icon(Icons.sports_tennis,
                            size: 36, color: Color(0xFF1A2A4A)),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 12, color: Color(0xFF2196F3)),
                            const SizedBox(width: 3),
                            Text(_courts.isNotEmpty
                                ? _courts.first['name'] ?? 'Court'
                                : 'Al-Qurm Court',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A2A4A))),
                          ],
                        ),
                        Text('Nearby',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(14)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick Match',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF1A2A4A))),
                  const SizedBox(height: 3),
                  const Text('Find Players to Challenge',
                      style:
                          TextStyle(color: Colors.grey, fontSize: 10)),
                  const SizedBox(height: 14),
                  Center(
                    child: Image.asset(
                      'assets/images/blackCourtLogo-Photoroom.png',
                      width: 44,
                      height: 44,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.sports_tennis,
                          size: 40,
                          color: Color(0xFF1A2A4A)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (_) => const StartMatchPage()));},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A2A4A),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      child: const Text('Start Match',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
