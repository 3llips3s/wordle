# Wördle

A clean, responsive, standalone Flutter web implementation of the classic word-guessing game, completely localized for 5-letter German nouns. Playable on web browsers with a mobile-first design.

## How to Play

1. Guess the secret **5-letter German noun** in six tries.
2. Every guess must be a valid 5-letter noun.
3. After each guess, the color of the tiles will change to show how close your guess was to the word:
    - **Green:** The letter is in the word and in the correct spot.
    - **Yellow:** The letter is in the word but in the wrong spot.
    - **Grey:** The letter is not in the word in any spot.

*As you play, you earn coins based on the accuracy of your deductions! Use standard or premium hints to reveal letters directly into your exact grid.*

## Tech Stack

- **Framework:** Flutter Web (adaptive UI focused)
- **State Management:** Riverpod 
- **Storage:** `shared_preferences` (fast local caching + user session persistence)
- **Language/Theme Engine:** Native Dart/Material Dart structures, customized into a pure standalone dark mode aesthetic

## License

This project is licensed under the MIT License - see the `LICENSE` file for details.
