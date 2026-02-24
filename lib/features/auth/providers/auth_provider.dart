import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/firestore_service.dart';

final authProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._auth, this._firestoreService)
      : super(const AsyncValue.data(null));

  final FirebaseAuth _auth;
  final FirestoreService _firestoreService;

  Future<void> signUp(String email, String password, String? displayName) async {
    state = const AsyncValue.loading();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
        await _firestoreService.createUserProfile(
          credential.user!.uid,
          {
            'email': email,
            'displayName': displayName,
            'createdAt': DateTime.now().toIso8601String(),
          },
        );
      }
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      // Some platform channel errors can occur after a successful native login.
      if (_auth.currentUser != null) {
        state = const AsyncValue.data(null);
        return;
      }
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(
    FirebaseAuth.instance,
    ref.read(firestoreServiceProvider),
  );
});
