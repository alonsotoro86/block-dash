import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/player_data.dart';

/// Local persistence for player progress.
///
/// SWAP POINT: to add cross-device cloud save, wrap this with a
/// `CloudStorageService` that mirrors `save()`/`load()` to Firebase
/// Firestore (or Google Play Games / Game Center cloud save) while keeping
/// this local copy as an offline cache.
class StorageService {
  static const _key = 'block_dash_player_data_v1';

  Future<PlayerData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return PlayerData();
    try {
      return PlayerData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return PlayerData();
    }
  }

  Future<void> save(PlayerData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data.toJson()));
  }
}
