import 'dart:async';
import 'package:flutter/material.dart';
import '../services/database_service.dart';

const Color _kNavy  = Color(0xFF1A2A4A);
const Color _kGreen = Color(0xFF4CAF50);
const Color _kRed   = Color(0xFFE53935);
const Color _kGold  = Color(0xFFFFD700);

class _RecentMatch {
  final String title;
  final String subtitle;
  final String score;
  final String timeAgo;
  final bool won;

  const _RecentMatch({
    required this.title,
    required this.subtitle,
    required this.score,
    required this.timeAgo,
    required this.won,
  });
}

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  StreamSubscription? _profileSub;
  Map<String, dynamic>? _profile;
  List<_RecentMatch> _recentMatches = [];
  List<bool> _matchHistory = [];

  @override
  void initState() {
    super.initState();
    final uid = DatabaseService.instance.currentUser?.uid;
    if (uid != null) {
      _profileSub = DatabaseService.instance.userProfileStream(uid).listen((p) {
        if (mounted) {
          setState(() {
            _profile = p;
            _buildMatchData();
          });
        }
      });
    }
  }

  void _buildMatchData() {
    if (_profile == null) return;
    final won = _profile!['matchesWon'] ?? 0;
    final played = _profile!['matchesPlayed'] ?? 0;
    _matchHistory = List.generate(played > 11 ? played : 11, (i) {
      if (i < played) {
        return i < (won as int);
      }
      return true;
    });

    final name = DatabaseService.instance.currentUserName;
    if (played > 0) {
      _recentMatches = [
        _RecentMatch(
          title: '$name vs Player',
          subtitle: 'Recent Match',
          score: won > 0 ? 'Won' : 'Lost',
          timeAgo: 'Today',
          won: (won as int) > 0,
        ),
      ];
    }
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    super.dispose();
  }

  String get _name => _profile?['firstName'] ?? DatabaseService.instance.currentUserName;
  String get _email => DatabaseService.instance.currentUserEmail;
  int get _matchesPlayed => (_profile?['matchesPlayed'] ?? 0) as int;
  int get _matchesWon => (_profile?['matchesWon'] ?? 0) as int;
  int get _winStreak => (_profile?['winStreak'] ?? 0) as int;
  int get _minutesPlayed => (_profile?['minutesPlayed'] ?? 0) as int;

  double get _winRate =>
      _matchesPlayed == 0 ? 0 : _matchesWon / _matchesPlayed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: _kNavy,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_rounded,
                    color: Colors.white, size: 24),
                onPressed: () => debugPrint('Settings tapped'),
              ),
            ],
            title: const Text(
              'Statistics',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17),
            ),
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D1B2A), _kNavy],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: _kGreen, width: 2.5),
                        ),
                        child: const ClipOval(
                          child: Icon(Icons.person_rounded,
                              size: 44, color: _kNavy),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _email,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: '🏆',
                        value: '$_matchesPlayed',
                        label: 'MATCHES PLAYED',
                        footer: const Row(children: [
                          Icon(Icons.access_time,
                              size: 11, color: Colors.white70),
                          SizedBox(width: 4),
                          Text('All time',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 10)),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: '🏆',
                        value: '$_matchesWon',
                        label: 'MATCHES WON',
                        footer: Text(
                          '${(_winRate * 100).toStringAsFixed(0)}% Winning Rate',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: '🔥',
                        value: '$_winStreak',
                        label: 'WIN STREAK',
                        footer: Text(
                          '🔥 You win $_winStreak Matches in row',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: '⏱️',
                        value: '$_minutesPlayed',
                        label: 'MINUTES PLAYED',
                        footer: Row(children: [
                          const Icon(Icons.timer_outlined,
                              size: 11, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text('You Played $_minutesPlayed Minutes',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 10)),
                        ]),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                _sectionHeader('Match Played'),
                const SizedBox(height: 8),
                _MatchHistoryDots(history: _matchHistory),

                const SizedBox(height: 20),

                _sectionHeader('Recent Matches'),
                const SizedBox(height: 10),
                ..._recentMatches.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RecentMatchCard(match: m),
                    )),

                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: _kNavy,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _MatchHistoryDots extends StatelessWidget {
  final List<bool> history;
  const _MatchHistoryDots({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: const Center(
          child: Text('No matches played yet',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Oldest',
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 11)),
              Text('Recent',
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: history.map((won) {
              return Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: won ? _kGreen : _kRed,
                  shape: BoxShape.circle,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final Widget footer;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: _kNavy,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _kGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(icon, style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const Divider(color: Colors.white12, height: 14),
          footer,
        ],
      ),
    );
  }
}

class _RecentMatchCard extends StatelessWidget {
  final _RecentMatch match;
  const _RecentMatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: _kNavy,
                  ),
                ),
                const SizedBox(height: 3),
                Text(match.subtitle,
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 11)),
                const SizedBox(height: 5),
                Text(
                  match.score,
                  style: const TextStyle(
                    color: _kNavy,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: match.won ? _kGreen : _kRed,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  match.won ? 'WON' : 'LOST',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(match.timeAgo,
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
