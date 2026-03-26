/// Represents the evaluation state of a guessed letter against the target word.
enum LetterMatch {
  correct,
  present,
  absent,
}

/// Defines a single player guess.
///
/// Contains the guessed [word] string and the calculated [matches] for each
/// letter against the target solution.
class WordGuess {
  final String word;
  final List<LetterMatch> matches;

  WordGuess({required this.word, required this.matches});
}
