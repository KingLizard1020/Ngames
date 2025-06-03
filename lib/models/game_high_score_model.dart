import 'package:cloud_firestore/cloud_firestore.dart';

class GameHighScore {
  final String userId;
  final String userName; // Or userEmail, for display
  final String gameId; // e.g., 'wordle', 'snake', 'hangman'
  final int score; // General score value
  final int?
  attempts; // For games like Wordle (guesses) or Hangman (incorrect guesses)
  final DateTime timestamp;
  final String?
  scoreType; // e.g., 'guesses' (lower is better), 'points' (higher is better)

  GameHighScore({
    required this.userId,
    required this.userName,
    required this.gameId,
    required this.score,
    this.attempts,
    required this.timestamp,
    this.scoreType = 'points', // Default to higher is better
  });

  factory GameHighScore.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return GameHighScore(
      userId: data['userId'] as String,
      userName: data['userName'] as String,
      gameId: data['gameId'] as String,
      score: data['score'] as int,
      attempts: data['attempts'] as int?,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      scoreType: data['scoreType'] as String? ?? 'points',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'gameId': gameId,
      'score': score,
      if (attempts != null) 'attempts': attempts,
      'timestamp': Timestamp.fromDate(timestamp),
      'scoreType': scoreType,
    };
  }
}
