import 'dart:async';
import 'package:flutter/material.dart';
import '../pages/match_confirmation_page.dart';
import '../services/database_service.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class MatchPlayer {
  String name;
  MatchPlayer({required this.name});
}

class Match {
  final MatchPlayer player1;
  final MatchPlayer player2;
  final String venue;
  final String type;
  final String dateTime;
  int playersJoined;
  final int playersTotal;
  final bool isManager;
  String? referee;
  final bool isPublic;
  final double? entryFee;
  final String? studioName;

  Match({
    required this.player1,
    required this.player2,
    required this.venue,
    required this.type,
    required this.dateTime,
    required this.playersJoined,
    required this.playersTotal,
    required this.isManager,
    this.referee,
    this.isPublic = false,
    this.entryFee,
    this.studioName,
  });
}

// ── Matches Page Body (no HeaderAndFooter wrapper) ────────────────────────────

class MatchesPageBody extends StatefulWidget {
  const MatchesPageBody({super.key});

  @override
  State<MatchesPageBody> createState() => _MatchesPageBodyState();
}

class _MatchesPageBodyState extends State<MatchesPageBody> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _currentUserName = '';
  List<Map<String, dynamic>> _allDocs = [];
  Set<String> _joinedMatchIds = {};
  StreamSubscription? _matchSub;
  StreamSubscription? _userMatchSub;

  @override
  void initState() {
    super.initState();
    _matchSub = DatabaseService.instance.matchesStream.listen((list) {
      if (mounted) setState(() => _allDocs = list);
    });
    final uid = DatabaseService.instance.currentUser?.uid;
    if (uid != null) {
      DatabaseService.instance.userProfileStream(uid).listen((profile) {
        if (profile != null) {
          _currentUserName = (profile['firstName'] ?? profile['name'] ?? '').toString();
        }
      });
      _userMatchSub = DatabaseService.instance.userMatchesStream(uid).listen((list) {
        _joinedMatchIds = list.map((m) => m['id']?.toString() ?? '').toSet();
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _matchSub?.cancel();
    _userMatchSub?.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    final available = _allDocs.where((d) {
      final pid = d['id']?.toString() ?? '';
      if (_joinedMatchIds.contains(pid)) return false;
      return true;
    }).toList();
    if (_searchQuery.isEmpty) return available;
    final q = _searchQuery.toLowerCase();
    return available.where((d) {
      final p1 = (d['player1Name'] ?? '').toString().toLowerCase();
      final p2 = (d['player2Name'] ?? '').toString().toLowerCase();
      final venue = (d['venue'] ?? '').toString().toLowerCase();
      final type = (d['type'] ?? '').toString().toLowerCase();
      return p1.contains(q) || p2.contains(q) || venue.contains(q) || type.contains(q);
    }).toList();
  }

  Match _docToMatch(Map<String, dynamic> d) {
    return Match(
      player1: MatchPlayer(name: d['player1Name'] ?? ''),
      player2: MatchPlayer(name: d['player2Name'] ?? ''),
      venue: d['venue'] ?? '',
      type: d['type'] ?? '',
      dateTime: d['dateTime'] ?? '',
      playersJoined: (d['playersJoined'] ?? 0) as int,
      playersTotal: (d['playersTotal'] ?? 0) as int,
      isManager: d['isManager'] ?? false,
      referee: d['referee'] as String?,
      isPublic: d['isPublic'] ?? false,
      entryFee: (d['entryFee'] as num?)?.toDouble(),
      studioName: d['studioName'] as String?,
    );
  }

  Future<void> _handleDelete(Map<String, dynamic> d) async {
    final match = _docToMatch(d);
    final confirmed = await _showConfirmDialog(
      title: 'Delete Match',
      message: 'Are you sure you want to delete the match at ${match.venue} on ${match.dateTime}?',
      confirmLabel: 'Delete',
      confirmColor: Colors.red,
    );
    if (!confirmed || !mounted) return;
    await DatabaseService.instance.deleteMatch(d['id'] as String);
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A2A4A), fontSize: 17)),
        content: Text(message, style: const TextStyle(color: Colors.black87, fontSize: 14)),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF1A2A4A)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF1A2A4A))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _handleJoin(Map<String, dynamic> d) async {
    final match = _docToMatch(d);
    final confirmed = await _showConfirmDialog(
      title: 'Join Match',
      message: 'You are about to join a match at ${match.venue} on ${match.dateTime}.\n\nType: ${match.type}\n\nDo you want to confirm?',
      confirmLabel: 'Join',
      confirmColor: const Color(0xFF4CAF50),
    );
    if (!confirmed || !mounted) return;

    final userName = _currentUserName.isNotEmpty
        ? _currentUserName
        : DatabaseService.instance.currentUserEmail.split('@').first;

    String p1Name = d['player1Name'] ?? '';
    String p2Name = d['player2Name'] ?? '';
    int joined = (d['playersJoined'] ?? 0) as int;

    if (p1Name.contains('Empty')) {
      p1Name = userName;
    } else if (p2Name.contains('Empty')) {
      p2Name = userName;
    }
    joined += 1;

    setState(() {
      d['player1Name'] = p1Name;
      d['player2Name'] = p2Name;
      d['playersJoined'] = joined;
    });

    await DatabaseService.instance.updateMatch(d['id'] as String, {
      'player1Name': p1Name,
      'player2Name': p2Name,
      'playersJoined': joined,
    });

    final uid = DatabaseService.instance.currentUser?.uid;
    if (uid != null) {
      await DatabaseService.instance.addUserMatch(uid, d['id'] as String, {
        'matchId': d['id'] as String,
        'role': 'Player',
        'joinedAt': DateTime.now().toIso8601String(),
        'matchData': {
          'player1Name': p1Name,
          'player2Name': p2Name,
          'venue': d['venue'],
          'type': d['type'],
          'dateTime': d['dateTime'],
          'playersJoined': joined,
          'playersTotal': d['playersTotal'],
          'isManager': d['isManager'] ?? false,
          'referee': d['referee'],
          'isPublic': d['isPublic'] ?? false,
          'entryFee': d['entryFee'],
          'studioName': d['studioName'],
        },
      });
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MatchConfirmationPage(
          match: match,
          role: 'Player',
          userName: userName,
        ),
      ),
    );
  }

  Future<void> _handleManage(Map<String, dynamic> d) async {
    final match = _docToMatch(d);
    final confirmed = await _showConfirmDialog(
      title: 'Become Referee',
      message: 'You are about to assign yourself as the referee for the match at ${match.venue} on ${match.dateTime}.\n\nType: ${match.type}\n\nDo you want to confirm?',
      confirmLabel: 'Confirm',
      confirmColor: const Color(0xFF1A2A4A),
    );
    if (!confirmed || !mounted) return;

    final userName = _currentUserName.isNotEmpty
        ? _currentUserName
        : DatabaseService.instance.currentUserEmail.split('@').first;

    setState(() => d['referee'] = userName);

    await DatabaseService.instance.updateMatch(d['id'] as String, {
      'referee': userName,
    });

    final uid = DatabaseService.instance.currentUser?.uid;
    if (uid != null) {
      await DatabaseService.instance.addUserMatch(uid, d['id'] as String, {
        'matchId': d['id'] as String,
        'role': 'Referee',
        'joinedAt': DateTime.now().toIso8601String(),
        'matchData': {
          'player1Name': d['player1Name'],
          'player2Name': d['player2Name'],
          'venue': d['venue'],
          'type': d['type'],
          'dateTime': d['dateTime'],
          'playersJoined': d['playersJoined'],
          'playersTotal': d['playersTotal'],
          'isManager': d['isManager'] ?? false,
          'referee': userName,
          'isPublic': d['isPublic'] ?? false,
          'entryFee': d['entryFee'],
          'studioName': d['studioName'],
        },
      });
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MatchConfirmationPage(
          match: match,
          role: 'Referee',
          userName: userName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSearchBar(),
        _buildTitle(),
        Expanded(
          child: _filtered.isEmpty
              ? const Center(
                  child: Text('No matches available',
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    if (i >= _filtered.length) return const SizedBox.shrink();
                    final d = _filtered[i];
                    final match = _docToMatch(d);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MatchCard(
                        match: match,
                        onJoinTap: () => _handleJoin(d),
                        onManageTap: () => _handleManage(d),
                        onDeleteTap: () => _handleDelete(d),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Search ...',
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Matches', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1A2A4A))),
          Divider(color: Color(0xFF1A2A4A), thickness: 1.5),
        ],
      ),
    );
  }
}

// ── Match Card ────────────────────────────────────────────────────────────────

class _MatchCard extends StatelessWidget {
  final Match match;
  final VoidCallback onJoinTap;
  final VoidCallback onManageTap;
  final VoidCallback onDeleteTap;

  const _MatchCard({
    required this.match,
    required this.onJoinTap,
    required this.onManageTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool refereeAssigned = match.referee != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Expanded(child: _PlayerChip(name: match.player1.name)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('VS',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1A2A4A))),
                ),
                Expanded(child: _PlayerChip(name: match.player2.name)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {},
                  child: Text(match.venue,
                      style: const TextStyle(
                          color: Color(0xFF2196F3),
                          fontSize: 11,
                          decoration: TextDecoration.underline)),
                ),
                const SizedBox(height: 3),
                Text(match.type,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 11)),
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.access_time,
                      size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(match.dateTime,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 11)),
                ]),
                const SizedBox(height: 5),
                Row(children: [
                  const Icon(Icons.sports,
                      size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  const Text('Referee: ',
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  Text(
                    match.referee ?? 'Not assigned',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: refereeAssigned
                          ? const Color(0xFF388E3C)
                          : Colors.grey,
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${match.playersJoined} / ${match.playersTotal}  Players Joined',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.white54, size: 18),
                  onPressed: onDeleteTap,
                  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                  padding: EdgeInsets.zero,
                  splashRadius: 16,
                ),
                SizedBox(
                  height: 28,
                  child: ElevatedButton(
                    onPressed: match.isManager
                        ? (refereeAssigned ? null : onManageTap)
                        : onJoinTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A2A4A),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF1A2A4A)
                          .withOpacity(0.45),
                      disabledForegroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18),
                      minimumSize: Size.zero,
                      tapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: Text(
                      match.isManager ? 'Manage' : 'Join',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
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

// ── Player Chip ───────────────────────────────────────────────────────────────

class _PlayerChip extends StatelessWidget {
  final String name;
  const _PlayerChip({required this.name});

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = name.contains('Empty');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor:
              isEmpty ? Colors.grey.shade300 : const Color(0xFF2196F3),
          child: Icon(Icons.person,
              color: isEmpty ? Colors.grey : Colors.white, size: 18),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isEmpty ? Colors.grey : const Color(0xFF1A2A4A),
            ),
          ),
        ),
      ],
    );
  }
}
