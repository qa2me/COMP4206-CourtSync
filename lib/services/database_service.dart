import 'dart:async';
import 'package:firebase_dart/firebase_dart.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final FirebaseDatabase _db = FirebaseDatabase(
    app: Firebase.app(),
    databaseURL: 'https://part3-29031-default-rtdb.firebaseio.com',
  );

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => _auth.currentUser != null;
  String get currentUserEmail => _auth.currentUser?.email ?? 'Player';
  String get currentUserName =>
      _auth.currentUser?.displayName ??
      _auth.currentUser?.email?.split('@').first ??
      'Player';
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> signUp(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  Future<void> signOut() => _auth.signOut();

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  DatabaseReference get _matchesRef => _db.reference().child('matches');
  DatabaseReference get _tournamentsRef => _db.reference().child('tournaments');
  DatabaseReference get _courtsRef => _db.reference().child('courts');
  DatabaseReference get _usersRef => _db.reference().child('users');
  DatabaseReference get _friendsRef => _db.reference().child('friends');
  DatabaseReference get _userMatchesRef => _db.reference().child('userMatches');

  DatabaseReference _userProfileRef(String uid) =>
      _db.reference().child('users/$uid');

  Stream<Map<String, dynamic>?> userProfileStream(String uid) {
    final ctrl = StreamController<Map<String, dynamic>?>.broadcast();
    _userProfileRef(uid).onValue.listen((event) {
      if (event.snapshot.value != null && event.snapshot.value is Map) {
        ctrl.add((event.snapshot.value as Map).cast<String, dynamic>());
      } else {
        ctrl.add(null);
      }
    });
    return ctrl.stream;
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) =>
      _userProfileRef(uid).update(data);

  Stream<List<Map<String, dynamic>>> get matchesStream {
    final ctrl = StreamController<List<Map<String, dynamic>>>.broadcast();
    _matchesRef.onValue.listen((event) {
      final list = <Map<String, dynamic>>[];
      if (event.snapshot.value != null) {
        final map = event.snapshot.value as Map<dynamic, dynamic>;
        map.forEach((key, value) {
          if (value is Map) {
            list.add({...value.cast<String, dynamic>(), 'id': key.toString()});
          }
        });
      }
      ctrl.add(list);
    });
    return ctrl.stream;
  }

  Future<String> createMatch(Map<String, dynamic> data) async {
    final ref = _matchesRef.push();
    await ref.set(data);
    return ref.key!;
  }

  Future<void> updateMatch(String id, Map<String, dynamic> data) =>
      _matchesRef.child(id).update(data);

  Future<void> deleteMatch(String id) =>
      _matchesRef.child(id).remove();

  Stream<List<Map<String, dynamic>>> get tournamentsStream {
    final ctrl = StreamController<List<Map<String, dynamic>>>.broadcast();
    _tournamentsRef.onValue.listen((event) {
      final list = <Map<String, dynamic>>[];
      if (event.snapshot.value != null) {
        final map = event.snapshot.value as Map<dynamic, dynamic>;
        map.forEach((key, value) {
          if (value is Map) {
            list.add({...value.cast<String, dynamic>(), 'id': key.toString()});
          }
        });
      }
      ctrl.add(list);
    });
    return ctrl.stream;
  }

  Future<void> createTournament(Map<String, dynamic> data) =>
      _tournamentsRef.push().set(data);

  DatabaseReference _userTournamentRegsRef(String uid) =>
      _db.reference().child('tournamentRegistrations').child(uid);

  Future<void> joinTournament(String uid, String tournamentId) async {
    final exists = await _userTournamentRegsRef(uid).child(tournamentId).once();
    if (exists.value == true) return;
    await _userTournamentRegsRef(uid).child(tournamentId).set(true);
    final snap = await _tournamentsRef.child(tournamentId).child('spotsLeft').once();
    final current = snap.value as int? ?? 1;
    if (current > 0) {
      await _tournamentsRef.child(tournamentId).child('spotsLeft').set(current - 1);
    }
  }

  Future<void> leaveTournament(String uid, String tournamentId) async {
    await _userTournamentRegsRef(uid).child(tournamentId).remove();
    final snap = await _tournamentsRef.child(tournamentId).child('spotsLeft').once();
    final current = snap.value as int? ?? 0;
    await _tournamentsRef.child(tournamentId).child('spotsLeft').set(current + 1);
  }

  Stream<Set<String>> userTournamentRegistrationsStream(String uid) {
    final ctrl = StreamController<Set<String>>.broadcast();
    _userTournamentRegsRef(uid).onValue.listen((event) {
      final set = <String>{};
      if (event.snapshot.value != null) {
        final map = event.snapshot.value as Map<dynamic, dynamic>;
        map.forEach((key, _) => set.add(key.toString()));
      }
      ctrl.add(set);
    });
    return ctrl.stream;
  }

  Stream<List<Map<String, dynamic>>> get courtsStream {
    final ctrl = StreamController<List<Map<String, dynamic>>>.broadcast();
    _courtsRef.onValue.listen((event) {
      final list = <Map<String, dynamic>>[];
      if (event.snapshot.value != null) {
        final map = event.snapshot.value as Map<dynamic, dynamic>;
        map.forEach((key, value) {
          if (value is Map) {
            list.add({...value.cast<String, dynamic>(), 'id': key.toString()});
          }
        });
      }
      ctrl.add(list);
    });
    return ctrl.stream;
  }

  Stream<List<Map<String, dynamic>>> get usersStream {
    final ctrl = StreamController<List<Map<String, dynamic>>>.broadcast();
    _usersRef.onValue.listen((event) {
      final list = <Map<String, dynamic>>[];
      if (event.snapshot.value != null) {
        final map = event.snapshot.value as Map<dynamic, dynamic>;
        map.forEach((key, value) {
          if (value is Map) {
            list.add({...value.cast<String, dynamic>(), 'id': key.toString()});
          }
        });
      }
      ctrl.add(list);
    });
    return ctrl.stream;
  }

  Future<void> createUser(String uid, Map<String, dynamic> data) =>
      _usersRef.child(uid).set(data);

  Stream<List<Map<String, dynamic>>> friendsStream(String uid) {
    final ctrl = StreamController<List<Map<String, dynamic>>>.broadcast();
    _friendsRef.child(uid).onValue.listen((event) {
      final list = <Map<String, dynamic>>[];
      if (event.snapshot.value != null) {
        final root = event.snapshot.value as Map<dynamic, dynamic>;

        final sentMap = root['sentRequests'];
        if (sentMap is Map) {
          sentMap.forEach((key, _) {
            list.add({'id': key.toString(), 'type': 'sent'});
          });
        }

        final incomingMap = root['incomingRequests'];
        if (incomingMap is Map) {
          incomingMap.forEach((key, _) {
            list.add({'id': key.toString(), 'type': 'incoming'});
          });
        }

        final friendsMap = root['friends'];
        if (friendsMap is Map) {
          friendsMap.forEach((key, _) {
            list.add({'id': key.toString(), 'type': 'friend'});
          });
        }
      }
      ctrl.add(list);
    });
    return ctrl.stream;
  }

  Future<void> addFriend(String uid, String friendId, Map<String, dynamic> data) =>
      _friendsRef.child(uid).child('friends').child(friendId).set(data);

  Future<void> removeFriend(String uid, String friendId) =>
      _friendsRef.child(uid).child('friends').child(friendId).remove();

  Future<void> sendFriendRequest(String uid, String targetId) async {
    await _friendsRef.child(uid).child('sentRequests').child(targetId).set({
      'to': targetId,
      'status': 'pending',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    await _friendsRef.child(targetId).child('incomingRequests').child(uid).set({
      'from': uid,
      'status': 'pending',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> acceptFriendRequest(String uid, String requesterId) async {
    await _friendsRef.child(uid).child('incomingRequests').child(requesterId).remove();
    await _friendsRef.child(uid).child('friends').child(requesterId).set(true);
    await _friendsRef.child(requesterId).child('friends').child(uid).set(true);
    await _friendsRef.child(requesterId).child('sentRequests').child(uid).remove();
  }

  Future<void> declineFriendRequest(String uid, String requesterId) async {
    await _friendsRef.child(uid).child('incomingRequests').child(requesterId).remove();
    await _friendsRef.child(requesterId).child('sentRequests').child(uid).remove();
  }

  Future<void> removeFriendByBoth(String uid, String friendId) async {
    await _friendsRef.child(uid).child('friends').child(friendId).remove();
    await _friendsRef.child(friendId).child('friends').child(uid).remove();
  }

  Stream<List<Map<String, dynamic>>> userMatchesStream(String uid) {
    final ctrl = StreamController<List<Map<String, dynamic>>>.broadcast();
    _userMatchesRef.child(uid).onValue.listen((event) {
      final list = <Map<String, dynamic>>[];
      if (event.snapshot.value != null) {
        final map = event.snapshot.value as Map<dynamic, dynamic>;
        map.forEach((key, value) {
          if (value is Map) {
            list.add({...value.cast<String, dynamic>(), 'id': key.toString()});
          }
        });
      }
      ctrl.add(list);
    });
    return ctrl.stream;
  }

  Future<void> addUserMatch(String uid, String matchId, Map<String, dynamic> data) =>
      _userMatchesRef.child(uid).child(matchId).set(data);

  Future<void> removeUserMatch(String uid, String matchId) =>
      _userMatchesRef.child(uid).child(matchId).remove();
}
