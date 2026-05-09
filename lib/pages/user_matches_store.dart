import 'dart:async';
import 'matches.dart';
import '../services/database_service.dart';

class UserMatchesStore {
  UserMatchesStore._();
  static final UserMatchesStore instance = UserMatchesStore._();

  StreamSubscription? _sub;
  final List<Map<String, dynamic>> _entries = [];

  List<Map<String, dynamic>> get entries => List.unmodifiable(_entries);

  String? get _uid => DatabaseService.instance.currentUser?.uid;

  void init() {
    _sub?.cancel();
    final uid = _uid;
    if (uid == null) return;
    _sub = DatabaseService.instance.userMatchesStream(uid).listen((list) {
      _entries.clear();
      for (final item in list) {
        final matchData = item['matchData'];
        if (matchData is Map) {
          final match = Match(
            player1: MatchPlayer(name: matchData['player1Name'] ?? ''),
            player2: MatchPlayer(name: matchData['player2Name'] ?? ''),
            venue: matchData['venue'] ?? '',
            type: matchData['type'] ?? '',
            dateTime: matchData['dateTime'] ?? '',
            playersJoined: (matchData['playersJoined'] ?? 0) as int,
            playersTotal: (matchData['playersTotal'] ?? 0) as int,
            isManager: matchData['isManager'] ?? false,
            referee: matchData['referee'] as String?,
            isPublic: matchData['isPublic'] ?? false,
            entryFee: (matchData['entryFee'] as num?)?.toDouble(),
            studioName: matchData['studioName'] as String?,
          );
          _entries.add({
            'match': match,
            'role': item['role'] ?? 'Player',
          });
        }
      }
    });
  }

  Future<bool> tryAdd(Match match, String role) async {
    final uid = _uid;
    if (uid == null) return false;
    if (_hasOverlap(match)) return false;

    await DatabaseService.instance.addUserMatch(uid, match.hashCode.toString(), {
      'role': role,
      'matchData': {
        'player1Name': match.player1.name,
        'player2Name': match.player2.name,
        'venue': match.venue,
        'type': match.type,
        'dateTime': match.dateTime,
        'playersJoined': match.playersJoined,
        'playersTotal': match.playersTotal,
        'isManager': match.isManager,
        'referee': match.referee,
        'isPublic': match.isPublic,
        'entryFee': match.entryFee,
        'studioName': match.studioName,
      },
    });
    _entries.add({'match': match, 'role': role});
    return true;
  }

  Future<void> remove(Match match) async {
    final uid = _uid;
    if (uid == null) return;
    await DatabaseService.instance.removeUserMatch(uid, match.hashCode.toString());
    _entries.removeWhere((e) => e['match'] == match);
  }

  void dispose() {
    _sub?.cancel();
  }

  static const int _matchDurationMinutes = 90;

  bool _hasOverlap(Match incoming) {
    final incomingTime = _parse(incoming.dateTime);
    if (incomingTime == null) return false;

    for (final entry in _entries) {
      final Match existing = entry['match'] as Match;
      final existingTime = _parse(existing.dateTime);
      if (existingTime == null) continue;

      final incomingEnd = incomingTime.add(
          const Duration(minutes: _matchDurationMinutes));
      final existingEnd = existingTime.add(
          const Duration(minutes: _matchDurationMinutes));

      if (incomingTime.isBefore(existingEnd) &&
          incomingEnd.isAfter(existingTime)) {
        return true;
      }
    }
    return false;
  }

  static DateTime? _parse(String raw) {
    try {
      final parts = raw.split(' - ');
      if (parts.length < 2) return null;

      final dateParts = parts[0].trim().split('/');
      if (dateParts.length < 3) return null;

      final day   = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final year  = int.parse(dateParts[2]);

      final timeRaw = parts[1].trim();
      final isPm    = timeRaw.toUpperCase().contains('PM');
      final timeParts = timeRaw
          .replaceAll(RegExp(r'[APMapm]'), '')
          .trim()
          .split(':');
      int hour   = int.parse(timeParts[0]);
      final min  = int.parse(timeParts[1]);

      if (isPm && hour != 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;

      return DateTime(year, month, day, hour, min);
    } catch (_) {
      return null;
    }
  }
}
