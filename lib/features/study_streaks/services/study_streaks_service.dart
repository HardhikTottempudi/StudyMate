import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/streak_models.dart';

class StudyStreaksService {
  StudyStreaksService(this._firestore, this._auth, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  String? get _uid => _auth.currentUser?.uid;
  String get _displayName =>
      _auth.currentUser?.displayName ?? _auth.currentUser?.email ?? 'Someone';

  CollectionReference<Map<String, dynamic>> get _streaksRef => _firestore
      .collection('users')
      .doc(_uid)
      .collection('studyStreaks');

  CollectionReference<Map<String, dynamic>> get _inboxRef =>
      _firestore.collection('users').doc(_uid).collection('inboxSnaps');

  CollectionReference<Map<String, dynamic>> get _friendsRef =>
      _firestore.collection('users').doc(_uid).collection('friends');

  // ── Friends ──────────────────────────────────────────────────────────────

  Stream<List<FriendContact>> watchFriends() {
    if (_uid == null) return Stream.value([]);
    return _friendsRef.orderBy('addedAt').snapshots().map(
          (snap) => snap.docs
              .map((d) => FriendContact(
                    id: d.data()['friendUid'] ?? d.id,
                    name: d.data()['friendName'] ?? 'Friend',
                    username: d.data()['friendUsername'] ?? '',
                  ))
              .toList(),
        );
  }

  /// Looks up a user by username, then adds them as a friend.
  /// Throws a descriptive [Exception] on failure.
  Future<void> addFriendByUsername(String username) async {
    if (_uid == null) throw Exception('Not signed in');
    final clean = username.toLowerCase().trim().replaceAll('@', '');
    if (clean.isEmpty) throw Exception('Username cannot be empty');

    final result = await _firestore
        .collection('users')
        .where('username', isEqualTo: clean)
        .limit(1)
        .get();

    if (result.docs.isEmpty) throw Exception('No user found with @$clean');

    final friendDoc = result.docs.first;
    final friendUid = friendDoc.id;

    if (friendUid == _uid) throw Exception("You can't add yourself");

    final existing = await _friendsRef.doc(friendUid).get();
    if (existing.exists) throw Exception('@$clean is already your friend');

    final friendData = friendDoc.data();
    await _friendsRef.doc(friendUid).set({
      'friendUid': friendUid,
      'friendName': friendData['displayName'] ?? clean,
      'friendUsername': clean,
      'addedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeFriend(String friendUid) async {
    if (_uid == null) return;
    await _friendsRef.doc(friendUid).delete();
  }

  // ── Streaks ───────────────────────────────────────────────────────────────

  Stream<List<FriendStreak>> watchStreaks() {
    if (_uid == null) return Stream.value([]);
    return _streaksRef
        .orderBy('streakCount', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => FriendStreak.fromMap(d.data()))
            .toList());
  }

  // ── Inbox ─────────────────────────────────────────────────────────────────

  Stream<List<StudySnap>> watchInbox() {
    if (_uid == null) return Stream.value([]);
    return _inboxRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => StudySnap.fromMap(d.data()))
            .where((s) => !s.isViewed)
            .toList());
  }

  Stream<List<StudySnap>> watchFriendHistory(String friendUid) {
    if (_uid == null) return Stream.value([]);
    return _streaksRef
        .doc(friendUid)
        .collection('snaps')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => StudySnap.fromMap(d.data())).toList());
  }

  // ── Send snap ─────────────────────────────────────────────────────────────

  Future<void> sendDailySnap({
    required FriendContact friend,
    required String localImagePath,
    String? caption,
    String? emoji,
  }) async {
    if (_uid == null) throw Exception('Not signed in');

    final now = DateTime.now();
    final todayKey = _dayKey(now);

    // Prevent duplicate snap to same friend on the same day.
    final existingToday = await _streaksRef
        .doc(friend.id)
        .collection('snaps')
        .where('dayKey', isEqualTo: todayKey)
        .limit(1)
        .get();
    if (existingToday.docs.isNotEmpty) {
      throw Exception(
          "You already sent today's study moment to ${friend.name}.");
    }

    // Upload image to Firebase Storage.
    final snapId = const Uuid().v4();
    final imageUrl = await _uploadSnapImage(localImagePath, snapId);

    // Compute new streak count.
    final streakDoc = _streaksRef.doc(friend.id);
    final streakSnapshot = await streakDoc.get();
    int streakCount = 1;
    if (streakSnapshot.exists) {
      final data = streakSnapshot.data()!;
      final lastDay = data['lastDayKey'] as String?;
      final lastCount = data['streakCount'] as int? ?? 0;
      if (lastDay != null && _isPreviousDay(lastDay, todayKey)) {
        streakCount = lastCount + 1;
      } else if (lastDay == todayKey) {
        streakCount = lastCount;
      }
    }

    final snap = StudySnap(
      id: snapId,
      senderUid: _uid!,
      senderName: _displayName,
      friendId: friend.id,
      friendName: friend.name,
      imageUrl: imageUrl,
      createdAtIso: now.toIso8601String(),
      dayKey: todayKey,
      caption: caption,
      emoji: emoji,
      viewedAtIso: null,
    );

    final batch = _firestore.batch();

    // Update sender's streak record.
    batch.set(streakDoc, {
      'friendId': friend.id,
      'friendName': friend.name,
      'friendUsername': friend.username,
      'streakCount': streakCount,
      'lastSentAt': now.toIso8601String(),
      'lastDayKey': todayKey,
      'pendingCount': (streakSnapshot.data()?['pendingCount'] ?? 0) + 1,
      'updatedAt': now.toIso8601String(),
    }, SetOptions(merge: true));

    // Save to sender's own snap history.
    batch.set(streakDoc.collection('snaps').doc(snapId), snap.toMap());

    // Deliver to RECIPIENT's inbox (cross-user write).
    final recipientInbox = _firestore
        .collection('users')
        .doc(friend.id)
        .collection('inboxSnaps')
        .doc(snapId);
    batch.set(recipientInbox, snap.toMap());

    await batch.commit();
  }

  Future<String> _uploadSnapImage(String localPath, String snapId) async {
    final file = File(localPath);
    final ref = _storage.ref('snaps/$_uid/$snapId.jpg');
    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await task.ref.getDownloadURL();
  }

  Future<void> markSnapViewed(StudySnap snap) async {
    if (_uid == null || snap.isViewed) return;
    final viewedAt = DateTime.now().toIso8601String();
    await _inboxRef.doc(snap.id).update({'viewedAt': viewedAt});
  }

  // ── Username setup ────────────────────────────────────────────────────────

  Future<String?> fetchCurrentUsername() async {
    if (_uid == null) return null;
    final doc = await _firestore.collection('users').doc(_uid).get();
    return doc.data()?['username'] as String?;
  }

  Future<void> saveUsername(String username) async {
    if (_uid == null) return;
    final clean = username.toLowerCase().trim();
    // Check uniqueness.
    final conflict = await _firestore
        .collection('users')
        .where('username', isEqualTo: clean)
        .limit(1)
        .get();
    if (conflict.docs.isNotEmpty && conflict.docs.first.id != _uid) {
      throw Exception('@$clean is already taken');
    }
    await _firestore
        .collection('users')
        .doc(_uid)
        .set({'username': clean}, SetOptions(merge: true));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _dayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static bool _isPreviousDay(String lastDay, String todayKey) {
    final last = DateTime.tryParse(lastDay);
    final today = DateTime.tryParse(todayKey);
    if (last == null || today == null) return false;
    return today.difference(last).inDays == 1;
  }
}
