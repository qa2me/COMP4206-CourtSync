import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/database_service.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String utr;
  final int rank;
  final int matchesPlayed;
  final int matchesWon;
  final int winStreak;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.utr,
    required this.rank,
    required this.matchesPlayed,
    required this.matchesWon,
    required this.winStreak,
  });

  double get winRate =>
      matchesPlayed == 0 ? 0 : matchesWon / matchesPlayed;
}

class FriendsStore extends ChangeNotifier {
  FriendsStore._();
  static final FriendsStore instance = FriendsStore._();

  List<AppUser> allUsers = [];
  StreamSubscription? _usersSub;
  StreamSubscription? _friendsSub;

  List<String> _friendIds  = [];
  List<String> _pendingIds = [];
  List<String> _sentIds    = [];

  String? get _uid => DatabaseService.instance.currentUser?.uid;

  void init() {
    _usersSub?.cancel();
    _friendsSub?.cancel();

    _usersSub = DatabaseService.instance.usersStream.listen((list) {
      allUsers = list.map((d) => AppUser(
        id:             d['id']             ?? '',
        name:           d['name']           ?? '',
        email:          d['email']          ?? '',
        utr:            d['utr']            ?? '0.0',
        rank:           (d['rank']          ?? 0) as int,
        matchesPlayed:  (d['matchesPlayed'] ?? 0) as int,
        matchesWon:     (d['matchesWon']    ?? 0) as int,
        winStreak:      (d['winStreak']     ?? 0) as int,
      )).toList();
      notifyListeners(); // ← rebuild all listening widgets
    });

    final uid = _uid;
    if (uid != null) {
      _friendsSub =
          DatabaseService.instance.friendsStream(uid).listen((list) {
        _friendIds = list
            .where((f) => f['type'] == 'friend')
            .map<String>((f) => f['id']?.toString() ?? '')
            .toList();
        _pendingIds = list
            .where((f) => f['type'] == 'incoming')
            .map<String>((f) => f['id']?.toString() ?? '')
            .toList();
        _sentIds = list
            .where((f) => f['type'] == 'sent')
            .map<String>((f) => f['id']?.toString() ?? '')
            .toList();
        notifyListeners(); // ← rebuild all listening widgets
      });
    }
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    _friendsSub?.cancel();
    super.dispose();
  }

  List<AppUser> get friends =>
      allUsers.where((u) => _friendIds.contains(u.id)).toList();

  List<AppUser> get pendingRequests =>
      allUsers.where((u) => _pendingIds.contains(u.id)).toList();

  List<AppUser> get sentRequests =>
      allUsers.where((u) => _sentIds.contains(u.id)).toList();

  List<AppUser> discover(String query) {
    final q          = query.toLowerCase();
    final currentUid = _uid;
    return allUsers.where((u) {
      if (currentUid != null && u.id == currentUid) return false;
      if (_friendIds.contains(u.id))  return false;
      if (_pendingIds.contains(u.id)) return false;
      if (q.isEmpty) return true;
      return u.name.toLowerCase().contains(q) ||
             u.email.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> sendRequest(String userId) async {
    final uid = _uid;
    if (uid == null) return;
    if (!_sentIds.contains(userId)) _sentIds.add(userId);
    notifyListeners();
    try {
      await DatabaseService.instance.sendFriendRequest(uid, userId);
    } catch (_) {
      _sentIds.remove(userId);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> acceptRequest(String userId) async {
    final uid = _uid;
    if (uid == null) return;
    _pendingIds.remove(userId);
    if (!_friendIds.contains(userId)) _friendIds.add(userId);
    notifyListeners();
    try {
      await DatabaseService.instance.acceptFriendRequest(uid, userId);
    } catch (_) {
      _friendIds.remove(userId);
      _pendingIds.add(userId);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> declineRequest(String userId) async {
    final uid = _uid;
    if (uid == null) return;
    _pendingIds.remove(userId);
    notifyListeners();
    try {
      await DatabaseService.instance.declineFriendRequest(uid, userId);
    } catch (_) {
      _pendingIds.add(userId);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> unfriend(String userId) async {
    final uid = _uid;
    if (uid == null) return;
    _friendIds.remove(userId);
    notifyListeners();
    try {
      await DatabaseService.instance.removeFriendByBoth(uid, userId);
    } catch (_) {
      _friendIds.add(userId);
      notifyListeners();
      rethrow;
    }
  }

  void simulateIncoming(String userId) {
    final uid = _uid;
    if (uid == null) return;
    if (!_pendingIds.contains(userId) && !_friendIds.contains(userId)) {
      _pendingIds.add(userId);
      _sentIds.remove(userId);
      notifyListeners();
    }
  }

  FriendStatus statusOf(String userId) {
    if (_friendIds.contains(userId))  return FriendStatus.friend;
    if (_pendingIds.contains(userId)) return FriendStatus.incoming;
    if (_sentIds.contains(userId))    return FriendStatus.sent;
    return FriendStatus.none;
  }
}

enum FriendStatus { none, sent, incoming, friend }