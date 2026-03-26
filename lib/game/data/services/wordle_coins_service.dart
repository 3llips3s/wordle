import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/wordle_coins_model.dart';

class WordleCoinsService {
  static const String _coinsKey = 'wordle_coins_data';

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  WordleCoinsData getCoinsData() {
    try {
      if (_prefs == null) {
        return WordleCoinsData(
          totalCoins: 50,
          totalCoinsEarned: 0,
          totalCoinsSpent: 0,
        );
      }

      final jsonString = _prefs!.getString(_coinsKey);
      if (jsonString != null) {
        return WordleCoinsData.fromJson(
          Map<String, dynamic>.from(json.decode(jsonString)),
        );
      }

      return WordleCoinsData(
        totalCoins: 50,
        totalCoinsEarned: 0,
        totalCoinsSpent: 0,
      );
    } catch (e) {
      return WordleCoinsData(
        totalCoins: 50,
        totalCoinsEarned: 0,
        totalCoinsSpent: 0,
      );
    }
  }

  Future<bool> spendCoins(int amount) async {
    try {
      await initialize();
      final currentData = getCoinsData();
      if (currentData.totalCoins < amount) {
        return false;
      }

      final newData = currentData.copyWith(
        totalCoins: currentData.totalCoins - amount,
        totalCoinsSpent: currentData.totalCoinsSpent + amount,
      );

      await _prefs!.setString(_coinsKey, json.encode(newData.toJson()));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> earnCoins(int amount) async {
    try {
      await initialize();
      final currentData = getCoinsData();
      final newData = currentData.copyWith(
        totalCoins: currentData.totalCoins + amount,
        totalCoinsEarned: currentData.totalCoinsEarned + amount,
      );

      await _prefs!.setString(_coinsKey, json.encode(newData.toJson()));
    } catch (e) {
      // silently fail
    }
  }

  bool canAfford(int amount) {
    return getCoinsData().totalCoins >= amount;
  }
}

final wordleCoinsServiceProvider = Provider<WordleCoinsService>(
  (ref) {
    final service = WordleCoinsService();
    service.initialize();
    return service;
  },
);
