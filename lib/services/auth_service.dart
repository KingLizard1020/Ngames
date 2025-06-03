import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

// Provider for FirebaseAuth instance
final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

// Provider for FirebaseFirestore instance (can be shared with HighScoreService)
final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider), // Pass Firestore instance
  );
});

// StreamProvider for auth state changes
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

class AuthService {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore; // Add Firestore instance
  final String _usersCollectionPath = 'users';

  AuthService(this._firebaseAuth, this._firestore); // Updated constructor

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<User?> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      if (user != null) {
        // Store user details in Firestore
        await _firestore.collection(_usersCollectionPath).doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          // You might want to allow users to set a displayName later
          'displayName':
              user.email?.split('@')[0] ??
              'User', // Simple default display name
          'createdAt': Timestamp.now(),
        });
      }
      return user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
