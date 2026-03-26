import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordle/game/data/models/guess_model.dart';
import 'package:wordle/game/data/models/wordle_game_state.dart';
import 'package:wordle/game/data/repositories/wordle_word_repo.dart';
import '../data/services/wordle_coins_service.dart';
import 'wordle_hints_service.dart';

/// Orchestrates the core game rules, progression, and economy interactions.
class WordleLogic {
  final WordleWordRepo repository;
  final WordleCoinsService coinsService;
  final WordleHintsService hintsService;

  WordleLogic({
    required this.repository,
    required this.coinsService,
    required this.hintsService,
  });

  /// Initializes and returns a fresh [WordleGameState] instance.
  Future<WordleGameState> createNewGame() async {
    await repository.ready;

    final targetWordData = await repository.getRandomWord();
    final targetWord = targetWordData['word']!.toUpperCase();

    return WordleGameState(
      targetWord: targetWord,
      guesses: [],
      status: GameStatus.playing,
      startTime: DateTime.now(),
    );
  }

  /// Evaluates a user [guess] against the active game [state].
  ///
  /// Returns an updated [WordleGameState] preserving immutability.
  Future<WordleGameState> makeGuess(WordleGameState state, String guess) async {
    if (state.isGameOver || !state.canGuess) {
      return state;
    }

    final uppercaseGuess = guess.toUpperCase();

    if (uppercaseGuess.length != state.targetWord.length) {
      return state;
    }

    final isValid = await repository.isValidWord(uppercaseGuess);
    if (!isValid) {
      return state;
    }

    final matches = checkWord(state.targetWord, uppercaseGuess);
    final newGuess = WordGuess(word: uppercaseGuess, matches: matches);

    final newGuesses = List<WordGuess>.from(state.guesses)..add(newGuess);

    GameStatus newStatus = state.status;
    DateTime? newEndTime = state.endTime;
    int coinsEarnedThisGame = state.coinsEarnedThisGame;

    if (uppercaseGuess == state.targetWord) {
      newStatus = GameStatus.won;
      newEndTime = DateTime.now();

      final coinsEarned = calculateCoinsEarned(newGuesses.length);
      final noHintsBonus = state.hintsUsed == 0 ? 5 : 0;
      final totalCoinsEarned = coinsEarned + noHintsBonus;

      await coinsService.earnCoins(totalCoinsEarned);
      coinsEarnedThisGame = totalCoinsEarned;
    } else if (newGuesses.length >= state.maxAttempts) {
      newStatus = GameStatus.lost;
      newEndTime = DateTime.now();
    }

    return state.copyWith(
      guesses: newGuesses,
      status: newStatus,
      endTime: newEndTime,
      coinsEarnedThisGame: coinsEarnedThisGame,
    );
  }

  /// Generates a list of [LetterMatch] states comparing [guess] to [target].
  List<LetterMatch> checkWord(String target, String guess) {
    if (target.length != guess.length) {
      throw ArgumentError('target and guess must be the same length');
    }

    final targetChars = target.toUpperCase().split('');
    final guessChars = guess.toUpperCase().split('');
    final results = List<LetterMatch>.filled(guess.length, LetterMatch.absent);

    final availableLetters = <String, int>{};
    for (final char in targetChars) {
      availableLetters[char] = (availableLetters[char] ?? 0) + 1;
    }

    for (var i = 0; i < guess.length; i++) {
      if (guessChars[i] == targetChars[i]) {
        results[i] = LetterMatch.correct;
        availableLetters[guessChars[i]] = availableLetters[guessChars[i]]! - 1;
      }
    }

    for (var i = 0; i < guess.length; i++) {
      if (results[i] == LetterMatch.correct) continue;

      final letter = guessChars[i];
      if (availableLetters.containsKey(letter) &&
          availableLetters[letter]! > 0) {
        results[i] = LetterMatch.present;
        availableLetters[letter] = availableLetters[letter]! - 1;
      }
    }

    return results;
  }

  /// Deducts coins and reveals a random letter position if affordable.
  Future<WordleGameState?> useHint(
      WordleGameState state, int hintNumber) async {
    if (!state.canGuess || state.hintsUsed >= state.maxHints) return null;

    final cost = hintsService.getHintCost(hintNumber);
    if (!coinsService.canAfford(cost)) return null;

    final positionToReveal = hintsService.getRandomHintPosition(state);
    if (positionToReveal == -1) return null;

    final success = await coinsService.spendCoins(cost);
    if (!success) return null;

    final newRevealedPositions = List<int>.from(state.revealedPositions)
      ..add(positionToReveal);

    return state.copyWith(
      hintsUsed: state.hintsUsed + 1,
      revealedPositions: newRevealedPositions,
      coinsSpentThisGame: state.coinsSpentThisGame + cost,
    );
  }

  /// Calculates the coin reward based on the number of [attempts].
  int calculateCoinsEarned(int attempts) {
    const coinValues = [50, 40, 30, 20, 10, 5];
    if (attempts <= 0 || attempts > 6) return 0;
    return coinValues[attempts - 1];
  }

  /// Retrieves the current available coin balance.
  int getCurrentCoins() {
    return coinsService.getCoinsData().totalCoins;
  }

  bool canAffordHint(int hintNumber) {
    final cost = hintsService.getHintCost(hintNumber);
    return coinsService.canAfford(cost);
  }

  /// Returns localized feedback text based on the performance in [state].
  String winFeedback(WordleGameState state) {
    final attempts = state.guesses.length;

    if (attempts == 1) {
      return 'Du bist ein Wortgenie! 🤓';
    } else if (attempts == 2) {
      return 'Das war der Hammer! 😎';
    } else if (attempts == 3) {
      return 'Sehr gut gemacht! 👏';
    } else if (attempts == 4) {
      return 'Gut gemacht! 👍';
    } else if (attempts == 5) {
      return 'Gerade noch erwischt! 😅';
    } else {
      return 'Das war knapp! 😮‍💨';
    }
  }

  /// Evaluates whether the [selectedArticle] matches the target word.
  Future<bool> checkArticle(
      WordleGameState state, String selectedArticle) async {
    final correctArticle = await repository.getWordArticle(state.targetWord);
    return selectedArticle == correctArticle;
  }
}

/// Provides a singleton injection of the [WordleLogic] orchestrator.
final wordleLogicProvider = Provider<WordleLogic>((ref) {
  final repository = ref.watch(wordleWordRepoProvider);
  final coinsService = ref.watch(wordleCoinsServiceProvider);
  final hintsService = WordleHintsService();

  return WordleLogic(
    repository: repository,
    coinsService: coinsService,
    hintsService: hintsService,
  );
});
