import 'package:flutter/foundation.dart';

import '../models/player_data.dart';
import '../services/ads_service.dart';
import '../services/iap_service.dart';
import '../services/leaderboard_service.dart';
import '../services/storage_service.dart';
import '../theme/block_themes.dart';

/// Central app state: player progress (coins, power-ups, themes) plus
/// access to the service layer (ads/IAP/storage/leaderboard). Kept as a
/// single ChangeNotifier for simplicity — a game of this size doesn't need
/// a heavier state-management architecture.
class AppState extends ChangeNotifier {
  final StorageService storage;
  final AdsService ads;
  final IapService iap;
  final LeaderboardService leaderboard;

  late PlayerData _data;
  PlayerData get data => _data;

  AppState({
    required this.storage,
    required this.ads,
    required this.iap,
    required this.leaderboard,
  });

  Future<void> init() async {
    _data = await storage.load();
    await ads.init();
    await iap.init();
    _applyDailyStreak();
    notifyListeners();
  }

  void _applyDailyStreak() {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    if (_data.lastPlayedDate == todayStr) return;

    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayStr = '${yesterday.year}-${yesterday.month}-${yesterday.day}';

    if (_data.lastPlayedDate == yesterdayStr) {
      _data.dailyStreak += 1;
    } else {
      _data.dailyStreak = 1;
    }
    _data.lastPlayedDate = todayStr;
    // Daily login reward: scales gently with streak, capped so it never
    // trivializes the coin economy.
    final reward = 20 + (_data.dailyStreak.clamp(0, 10) * 5);
    _data.coins += reward;
    _persist();
  }

  void _persist() => storage.save(_data);

  Future<void> addCoins(int amount) async {
    _data.coins += amount;
    notifyListeners();
    _persist();
  }

  Future<bool> spendCoins(int amount) async {
    if (_data.coins < amount) return false;
    _data.coins -= amount;
    notifyListeners();
    _persist();
    return true;
  }

  Future<void> recordScore(int score) async {
    if (score > _data.highScore) _data.highScore = score;
    await leaderboard.submitScore(score);
    notifyListeners();
    _persist();
  }

  int powerUpCount(String id) => _data.powerUps[id] ?? 0;

  Future<bool> usePowerUp(String id) async {
    final count = powerUpCount(id);
    if (count <= 0) return false;
    _data.powerUps[id] = count - 1;
    notifyListeners();
    _persist();
    return true;
  }

  Future<void> grantPowerUp(String id, {int amount = 1}) async {
    _data.powerUps[id] = powerUpCount(id) + amount;
    notifyListeners();
    _persist();
  }

  bool isThemeUnlocked(String id) => _data.unlockedThemeIds.contains(id);

  Future<bool> unlockTheme(BlockTheme theme) async {
    if (isThemeUnlocked(theme.id)) return true;
    if (!await spendCoins(theme.unlockCost)) return false;
    _data.unlockedThemeIds.add(theme.id);
    notifyListeners();
    _persist();
    return true;
  }

  Future<void> selectTheme(String id) async {
    _data.currentThemeId = id;
    notifyListeners();
    _persist();
  }

  Future<bool> buyProduct(IapProduct product) async {
    final ok = await iap.buy(product);
    if (!ok) return false;
    if (product == IapProduct.removeAds) {
      _data.adsRemoved = true;
    } else if (product.coinAmount > 0) {
      _data.coins += product.coinAmount;
    }
    notifyListeners();
    _persist();
    return true;
  }

  Future<void> watchRewardedFor(Future<void> Function() onReward) async {
    await ads.showRewarded(onReward: onReward);
  }
}
