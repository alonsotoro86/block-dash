/// Abstraction over online leaderboards / daily challenge scores.
///
/// SWAP POINT: replace [LocalLeaderboardService] with Firebase Firestore
/// (one doc per user, a Cloud Function to recompute top-N), or with
/// Google Play Games Services / Game Center native leaderboards.
abstract class LeaderboardService {
  Future<void> submitScore(int score);
  Future<List<LeaderboardEntry>> topScores();
}

class LeaderboardEntry {
  final String name;
  final int score;
  const LeaderboardEntry(this.name, this.score);
}

class LocalLeaderboardService implements LeaderboardService {
  final List<LeaderboardEntry> _entries = [
    const LeaderboardEntry('Ana', 18200),
    const LeaderboardEntry('Luis', 15400),
    const LeaderboardEntry('Tú', 0),
  ];

  @override
  Future<void> submitScore(int score) async {
    final idx = _entries.indexWhere((e) => e.name == 'Tú');
    if (idx != -1 && score > _entries[idx].score) {
      _entries[idx] = LeaderboardEntry('Tú', score);
      _entries.sort((a, b) => b.score.compareTo(a.score));
    }
  }

  @override
  Future<List<LeaderboardEntry>> topScores() async => List.unmodifiable(_entries);
}
