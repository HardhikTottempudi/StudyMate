import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../shared/models/study_session.dart';
import '../shared/models/flashcard_set.dart';
import '../shared/models/mindmap.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // User Profile
  Future<void> createUserProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).set(data);
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  // Study Sessions
  Future<void> saveStudySession(StudySession session) async {
    if (currentUserId == null) return;
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('studySessions')
        .doc(session.id)
        .set(session.toMap());
  }

  Stream<List<StudySession>> getStudySessions() {
    if (currentUserId == null) {
      return Stream.value([]);
    }
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('studySessions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudySession.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<List<StudySession>> getStudySessionsForPeriod(
      DateTime start, DateTime end) async {
    if (currentUserId == null) return [];
    final snapshot = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('studySessions')
        .where('createdAt',
            isGreaterThanOrEqualTo: start.toIso8601String())
        .where('createdAt', isLessThanOrEqualTo: end.toIso8601String())
        .get();
    return snapshot.docs
        .map((doc) => StudySession.fromMap(doc.id, doc.data()))
        .toList();
  }

  // Flashcard Sets
  Future<void> saveFlashcardSet(FlashcardSet set) async {
    if (currentUserId == null) return;
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('flashcardSets')
        .doc(set.id)
        .set(set.toMap());
  }

  Stream<List<FlashcardSet>> getFlashcardSets() {
    if (currentUserId == null) {
      return Stream.value([]);
    }
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('flashcardSets')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FlashcardSet.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<FlashcardSet?> getFlashcardSet(String setId) async {
    if (currentUserId == null) return null;
    final doc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('flashcardSets')
        .doc(setId)
        .get();
    if (!doc.exists) return null;
    return FlashcardSet.fromMap(doc.id, doc.data()!);
  }

  // Mindmaps
  Future<void> saveMindmap(Mindmap mindmap) async {
    if (currentUserId == null) return;
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('mindmaps')
        .doc(mindmap.id)
        .set(mindmap.toMap());
  }

  Stream<List<Mindmap>> getMindmaps() {
    if (currentUserId == null) {
      return Stream.value([]);
    }
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('mindmaps')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Mindmap.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<Mindmap?> getMindmap(String mindmapId) async {
    if (currentUserId == null) return null;
    final doc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('mindmaps')
        .doc(mindmapId)
        .get();
    if (!doc.exists) return null;
    return Mindmap.fromMap(doc.id, doc.data()!);
  }
}
