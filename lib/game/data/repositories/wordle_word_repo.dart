import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles loading, caching, and querying the internal dictionary of 5-letter nouns.
class WordleWordRepo {
  static const _cacheKey = 'wordle_five_letter_nouns';
  static const _assetPath = 'assets/data/german_nouns.csv';

  List<Map<String, String>> _cachedWords = [];
  bool _isInitialized = false;

  final _wordleWordsReadyCompleter = Completer<void>();
  Future<void> get ready => _wordleWordsReadyCompleter.future;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadFromCsv();
      _isInitialized = true;

      if (!_wordleWordsReadyCompleter.isCompleted) {
        _wordleWordsReadyCompleter.complete();
      }
    } catch (e) {
      _cachedWords = _getFallbackWords();
      _isInitialized = true;

      if (!_wordleWordsReadyCompleter.isCompleted) {
        _wordleWordsReadyCompleter.complete();
      }
    }
  }

  Future<void> _loadFromCsv() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getStringList(_cacheKey);

    if (cached != null && cached.isNotEmpty) {
      for (final entry in cached) {
        final parts = entry.split('|');
        if (parts.length >= 4) {
          _cachedWords.add({
            'article': parts[0],
            'word': parts[1],
            'plural': parts[2],
            'english': parts[3],
          });
        }
      }
      if (_cachedWords.isNotEmpty) return;
    }

    final raw = await rootBundle.loadString(_assetPath);
    final lines = raw.split('\n');

    // Skip header row (article,noun,plural,english)
    final cacheEntries = <String>[];

    for (final line in lines.skip(1)) {
      final cleanLine = line.trim();
      if (cleanLine.isEmpty) continue;

      final parts = cleanLine.split(',');
      if (parts.length < 2) continue;

      final noun = parts[1].trim();
      if (noun.length != 5) continue;

      final article = parts.isNotEmpty ? parts[0].trim() : '';
      final plural = parts.length > 2 ? parts[2].trim() : '';
      final english = parts.length > 3 ? parts[3].trim() : '';

      _cachedWords.add({
        'article': article,
        'word': noun,
        'plural': plural,
        'english': english,
      });

      cacheEntries.add('$article|$noun|$plural|$english');
    }

    if (cacheEntries.isNotEmpty) {
      await prefs.setStringList(_cacheKey, cacheEntries);
    }

    if (_cachedWords.isEmpty) {
      throw Exception('No 5-letter words found in CSV');
    }
  }

  Future<void> refreshWords() async {
    _isInitialized = false;
    _cachedWords = [];
    return initialize();
  }

  /// Retrieves a random 5-letter [word] entry from the dictionary.
  Future<Map<String, String>> getRandomWord() async {
    await initialize();

    if (_cachedWords.isEmpty) {
      _cachedWords = _getFallbackWords();
    }

    final random = Random();
    final index = random.nextInt(_cachedWords.length);
    return _cachedWords[index];
  }

  /// Evaluates whether the passed [word] exists in the internal dictionary.
  Future<bool> isValidWord(String word) async {
    await initialize();

    final uppercaseWord = word.toUpperCase();
    return _cachedWords
        .any((entry) => entry['word']!.toUpperCase() == uppercaseWord);
  }

  Future<String?> getWordArticle(String word) async {
    await initialize();

    final uppercaseWord = word.toUpperCase();
    final matchingEntry = _cachedWords.firstWhere(
      (entry) => entry['word']!.toUpperCase() == uppercaseWord,
      orElse: () => {},
    );

    if (matchingEntry.isEmpty) return null;
    return matchingEntry['article'];
  }

  Future<String?> getEnglishTranslation(String word) async {
    await initialize();

    final uppercaseWord = word.toUpperCase();
    final matchingEntry = _cachedWords.firstWhere(
      (entry) => entry['word']!.toUpperCase() == uppercaseWord,
      orElse: () => {},
    );

    if (matchingEntry.isEmpty) return null;
    return matchingEntry['english'];
  }

  List<Map<String, String>> _getFallbackWords() {
    return [
      {
        'word': 'TASSE',
        'article': 'die',
        'english': 'cup',
        'plural': 'Tassen',
      },
      {
        'word': 'TISCH',
        'article': 'der',
        'english': 'table',
        'plural': 'Tische'
      },
      {
        'word': 'BLATT',
        'article': 'das',
        'english': 'leaf',
        'plural': 'Blätter'
      },
      {
        'word': 'LAMPE',
        'article': 'die',
        'english': 'lamp',
        'plural': 'Lampen'
      },
      {
        'word': 'STUHL',
        'article': 'der',
        'english': 'chair',
        'plural': 'Stühle'
      },
    ];
  }
}

/// Provides a singleton instance of [WordleWordRepo].
final wordleWordRepoProvider = Provider<WordleWordRepo>((ref) {
  final repo = WordleWordRepo();
  repo.initialize();
  return repo;
});

/// Exposes a [Future] that completes when the dictionary is fully initialized.
final wordleRepoReadyProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(wordleWordRepoProvider);
  await repo.ready;
  return true;
});
