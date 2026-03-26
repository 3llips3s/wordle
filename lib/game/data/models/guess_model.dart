enum LetterMatch {
  correct,
  present,
  absent,
}

class WordGuess {
  final String word;
  final List<LetterMatch> matches;

  WordGuess({required this.word, required this.matches});
}
