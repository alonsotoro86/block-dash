/// Everything about player progress that must survive between sessions.
class PlayerData {
  int coins;
  int highScore;
  Set<String> unlockedThemeIds;
  String currentThemeId;
  Map<String, int> powerUps; // id -> count owned
  bool adsRemoved;
  int dailyStreak;
  String? lastPlayedDate; // ISO yyyy-MM-dd, used for daily streak/reward

  PlayerData({
    this.coins = 100,
    this.highScore = 0,
    Set<String>? unlockedThemeIds,
    this.currentThemeId = 'classic',
    Map<String, int>? powerUps,
    this.adsRemoved = false,
    this.dailyStreak = 0,
    this.lastPlayedDate,
  })  : unlockedThemeIds = unlockedThemeIds ?? {'classic'},
        powerUps = powerUps ?? {'hammer': 3, 'bomb': 1, 'swap': 2, 'undo': 2};

  Map<String, dynamic> toJson() => {
        'coins': coins,
        'highScore': highScore,
        'unlockedThemeIds': unlockedThemeIds.toList(),
        'currentThemeId': currentThemeId,
        'powerUps': powerUps,
        'adsRemoved': adsRemoved,
        'dailyStreak': dailyStreak,
        'lastPlayedDate': lastPlayedDate,
      };

  factory PlayerData.fromJson(Map<String, dynamic> json) => PlayerData(
        coins: json['coins'] as int? ?? 100,
        highScore: json['highScore'] as int? ?? 0,
        unlockedThemeIds:
            (json['unlockedThemeIds'] as List?)?.map((e) => e as String).toSet() ??
                {'classic'},
        currentThemeId: json['currentThemeId'] as String? ?? 'classic',
        powerUps: (json['powerUps'] as Map?)?.map(
              (k, v) => MapEntry(k as String, v as int),
            ) ??
            {'hammer': 3, 'bomb': 1, 'swap': 2, 'undo': 2},
        adsRemoved: json['adsRemoved'] as bool? ?? false,
        dailyStreak: json['dailyStreak'] as int? ?? 0,
        lastPlayedDate: json['lastPlayedDate'] as String?,
      );
}
