import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/streak_models.dart';

class StudyStreaksService {
  StudyStreaksService(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const List<FriendContact> defaultFriends = [
    FriendContact(id: 'aarav_demo', name: 'Aarav'),
    FriendContact(id: 'maya_demo', name: 'Maya'),
  ];

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _streaksRef => _firestore
      .collection('users')
      .doc(_uid)
      .collection('studyStreaks');

  CollectionReference<Map<String, dynamic>> get _inboxRef =>
      _firestore.collection('users').doc(_uid).collection('inboxSnaps');

  Stream<List<FriendStreak>> watchStreaks() {
    if (_uid == null) return Stream.value([]);
    return _streaksRef
        .orderBy('streakCount', descending: true)
        .snapshots()
        .map((snapshot) {
      final items =
          snapshot.docs.map((doc) => FriendStreak.fromMap(doc.data())).toList();
      for (final friend in defaultFriends) {
        if (items.indexWhere((item) => item.friendId == friend.id) == -1) {
          items.add(FriendStreak(
            friendId: friend.id,
            friendName: friend.name,
            streakCount: 0,
            pendingCount: 0,
          ));
        }
      }
      return items;
    });
  }

  Stream<List<StudySnap>> watchInbox() {
    if (_uid == null) return Stream.value([]);
    return _inboxRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudySnap.fromMap(doc.data()))
            .where((snap) => !snap.isViewed)
            .toList());
  }

  Stream<List<StudySnap>> watchFriendHistory(String friendId) {
    if (_uid == null) return Stream.value([]);
    return _streaksRef
        .doc(friendId)
        .collection('snaps')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => StudySnap.fromMap(doc.data())).toList());
  }

  Future<String> persistCapturedImage(String sourcePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final snapDir = Directory('${appDir.path}/streak_snaps');
    if (!await snapDir.exists()) {
      await snapDir.create(recursive: true);
    }
    final fileId = const Uuid().v4();
    final savedPath = '${snapDir.path}/$fileId.jpg';
    await File(sourcePath).copy(savedPath);
    return savedPath;
  }

  Future<void> sendDailySnap({
    required FriendContact friend,
    required String imagePath,
    String? caption,
    String? emoji,
  }) async {
    if (_uid == null) return;
    final now = DateTime.now();
    final todayKey = _dayKey(now);
    final streakDoc = _streaksRef.doc(friend.id);
    final snapId = const Uuid().v4();
    final existingToday = await streakDoc
        .collection('snaps')
        .where('dayKey', isEqualTo: todayKey)
        .limit(1)
        .get();
    if (existingToday.docs.isNotEmpty) {
      throw Exception('You already sent today\'s study moment to ${friend.name}.');
    }

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
      friendId: friend.id,
      friendName: friend.name,
      imagePath: imagePath,
      createdAtIso: now.toIso8601String(),
      dayKey: todayKey,
      caption: caption,
      emoji: emoji,
      viewedAtIso: null,
    );

    final batch = _firestore.batch();
    batch.set(streakDoc, {
      'friendId': friend.id,
      'friendName': friend.name,
      'streakCount': streakCount,
      'lastSentAt': now.toIso8601String(),
      'lastDayKey': todayKey,
      'pendingCount': (streakSnapshot.data()?['pendingCount'] ?? 0) + 1,
      'updatedAt': now.toIso8601String(),
    }, SetOptions(merge: true));
    batch.set(streakDoc.collection('snaps').doc(snapId), snap.toMap());
    batch.set(_inboxRef.doc(snapId), snap.toMap());
    await batch.commit();
  }

  Future<void> markSnapViewed(StudySnap snap) async {
    if (_uid == null || snap.isViewed) return;
    final viewedAt = DateTime.now().toIso8601String();
    final batch = _firestore.batch();
    final updates = {'viewedAt': viewedAt};
    batch.update(_inboxRef.doc(snap.id), updates);
    batch.update(_streaksRef.doc(snap.friendId).collection('snaps').doc(snap.id),
        updates);
    batch.set(_streaksRef.doc(snap.friendId), {
      'pendingCount': FieldValue.increment(-1),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  static String _dayKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static bool _isPreviousDay(String lastDay, String todayKey) {
    final last = DateTime.tryParse(lastDay);
    final today = DateTime.tryParse(todayKey);
    if (last == null || today == null) return false;
    return today.difference(last).inDays == 1;
  }
}
