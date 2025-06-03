class WordleStats {
  int gamesPlayed;
  int gamesWon;
  int currentStreak;
  int maxStreak;
  Map<int, int>
  guessDistribution; // e.g., {1: 0, 2: 5, 3: 10, 4: 8, 5: 3, 6: 1}

  WordleStats({
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.currentStreak = 0,
    this.maxStreak = 0,
    Map<int, int>? guessDistribution,
  }) : guessDistribution =
           guessDistribution ?? {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};

  // Method to update stats after a game
  void recordGame(bool won, int attempts) {
    gamesPlayed++;
    if (won) {
      gamesWon++;
      currentStreak++;
      if (currentStreak > maxStreak) {
        maxStreak = currentStreak;
      }
      if (attempts >= 1 && attempts <= 6) {
        guessDistribution[attempts] = (guessDistribution[attempts] ?? 0) + 1;
      }
    } else {
      currentStreak = 0;
    }
  }

  // Serialization to/from JSON for SharedPreferences
  factory WordleStats.fromJson(Map<String, dynamic> json) {
    Map<int, int> dist = {};
    if (json['guessDistribution'] != null) {
      (json['guessDistribution'] as Map<String, dynamic>).forEach((key, value) {
        dist[int.parse(key)] = value as int;
      });
    }
    return WordleStats(
      gamesPlayed: json['gamesPlayed'] as int? ?? 0,
      gamesWon: json['gamesWon'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      maxStreak: json['maxStreak'] as int? ?? 0,
      guessDistribution:
          dist.isEmpty ? {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0} : dist,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gamesPlayed': gamesPlayed,
      'gamesWon': gamesWon,
      'currentStreak': currentStreak,
      'maxStreak': maxStreak,
      // Convert int keys to String for JSON compatibility
      'guessDistribution': guessDistribution.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    };
  }
}
