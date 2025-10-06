import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ngames/models/game_high_score_model.dart';
import 'package:ngames/services/auth_service.dart'; // To get current user info

final highScoreServiceProvider = Provider<HighScoreService>((ref) {
  return HighScoreService(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

class HighScoreService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth; // To get current user details
  final String _collectionPath = 'high_scores';

  HighScoreService(this._firestore, this._firebaseAuth);

  Future<void> addHighScore(GameHighScore highScore) async {
    try {
      await _firestore.collection(_collectionPath).add(highScore.toFirestore());
    } catch (e) {
      // print('Error adding high score: $e');
      // Optionally rethrow or handle specific errors
    }
  }

  // Fetches top scores. For 'lower is better' (like Wordle attempts), sort ascending.
  // For 'higher is better' (like Snake score), sort descending.
  Stream<List<GameHighScore>> getHighScores(
    String gameId, {
    int limit = 10,
    bool lowerIsBetter = false,
  }) {
    Query query = _firestore
        .collection(_collectionPath)
        .where('gameId', isEqualTo: gameId)
        .orderBy(
          lowerIsBetter ? 'attempts' : 'score',
          descending: !lowerIsBetter,
        )
        .orderBy(
          'timestamp',
          descending: true,
        ) // Secondary sort by time for tie-breaking
        .limit(limit);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => GameHighScore.fromFirestore(doc))
          .toList();
    });
  }

  // Helper to get current user's display name or email
  String? getCurrentUserName() {
    final user = _firebaseAuth.currentUser;
    return user?.displayName ?? user?.email;
  }

  String? getCurrentUserId() {
    final user = _firebaseAuth.currentUser;
    return user?.uid;
  }
}
