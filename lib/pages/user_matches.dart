import 'package:flutter/material.dart';
import 'matches.dart';
import 'user_matches_store.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
const Color _kNavy        = Color(0xFF1A2A4A);
const Color _kPlayerBlue  = Color(0xFF1565C0); // card accent — player
const Color _kPlayerLight = Color(0xFFE3F2FD); // card bg — player
const Color _kRefYellow   = Color(0xFFF9A825); // card accent — referee
const Color _kRefLight    = Color(0xFFFFFDE7); // card bg — referee
const Color _kGreen       = Color(0xFF4CAF50);

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────
class UserMatchesPage extends StatefulWidget {
  const UserMatchesPage({super.key});

  @override
  State<UserMatchesPage> createState() => _UserMatchesPageState();
}

class _UserMatchesPageState extends State<UserMatchesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final store = UserMatchesStore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    store.init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    store.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _playerEntries =>
      store.entries.where((e) => e['role'] == 'Player').toList();

  List<Map<String, dynamic>> get _refereeEntries =>
      store.entries.where((e) => e['role'] == 'Referee').toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: _kNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Matches',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.6),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_rounded, size: 16),
                  const SizedBox(width: 6),
                  Text('AS PLAYER (${_playerEntries.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sports_rounded, size: 16),
                  const SizedBox(width: 6),
                  Text('AS REFEREE (${_refereeEntries.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(_playerEntries, isReferee: false),
          _buildList(_refereeEntries, isReferee: true),
        ],
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> entries,
      {required bool isReferee}) {
    if (entries.isEmpty) {
      return _EmptyState(isReferee: isReferee);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final match = entries[i]['match'] as Match;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _UserMatchCard(match: match, isReferee: isReferee),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MATCH CARD
// ─────────────────────────────────────────────────────────────────────────────
class _UserMatchCard extends StatelessWidget {
  final Match match;
  final bool isReferee;

  const _UserMatchCard({required this.match, required this.isReferee});

  Color get _accent => isReferee ? _kRefYellow : _kPlayerBlue;
  Color get _bg     => isReferee ? _kRefLight  : _kPlayerLight;
  Color get _bar    => isReferee ? _kRefYellow  : _kPlayerBlue;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: _accent, width: 4)),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Top: role badge + players ────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                // Role badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isReferee
                            ? Icons.sports_rounded
                            : Icons.person_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isReferee ? 'Referee' : 'Player',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Players vs
                _PlayerPill(name: match.player1.name, accent: _accent),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'VS',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: _accent,
                    ),
                  ),
                ),
                _PlayerPill(name: match.player2.name, accent: _accent),
              ],
            ),
          ),

          // ── Middle: match details ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(
                  icon: Icons.location_on_rounded,
                  text: match.venue,
                  color: const Color(0xFF2196F3),
                ),
                const SizedBox(height: 5),
                _DetailRow(
                  icon: Icons.sports_tennis_rounded,
                  text: match.type,
                  color: Colors.grey,
                ),
                const SizedBox(height: 5),
                _DetailRow(
                  icon: Icons.access_time_rounded,
                  text: match.dateTime,
                  color: Colors.grey,
                ),
                if (match.referee != null) ...[
                  const SizedBox(height: 5),
                  _DetailRow(
                    icon: Icons.sports_rounded,
                    text: 'Referee: ${match.referee}',
                    color: _kGreen,
                    bold: true,
                  ),
                ],
                const SizedBox(height: 10),
              ],
            ),
          ),

          // ── Bottom bar: players count ────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: _bar,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: Row(
              children: [
                const Icon(Icons.group_rounded,
                    color: Colors.white, size: 15),
                const SizedBox(width: 6),
                Text(
                  '${match.playersJoined} / ${match.playersTotal}  Players Joined',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // Upcoming chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'UPCOMING',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────
class _PlayerPill extends StatelessWidget {
  final String name;
  final Color accent;
  const _PlayerPill({required this.name, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: accent.withOpacity(0.15),
          child: Icon(Icons.person_rounded, color: accent, size: 15),
        ),
        const SizedBox(width: 4),
        Text(
          name.replaceAll('\n', '/'),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: _kNavy,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool bold;

  const _DetailRow({
    required this.icon,
    required this.text,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: bold ? color : Colors.grey.shade700,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isReferee;
  const _EmptyState({required this.isReferee});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isReferee ? Icons.sports_rounded : Icons.person_rounded,
            size: 60,
            color: isReferee
                ? _kRefYellow.withOpacity(0.4)
                : _kPlayerBlue.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            isReferee
                ? 'No referee assignments yet'
                : 'You haven\'t joined any matches yet',
            style: const TextStyle(
              fontSize: 15,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isReferee
                ? 'Manage a match to see it here'
                : 'Join a match to see it here',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}