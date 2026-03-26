import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wordle/config/game_config/constants.dart';
import 'package:wordle/core/ui/widgets/glassmorphic_dialog.dart';
import '../../data/models/wordle_game_state.dart';
import '../../data/repositories/wordle_word_repo.dart';

/// Renders the post-match summary and educational feedback modal.
///
/// Displays the game outcome, coin rewards, and allows the player to guess the
/// German article for the target word to reinforce learning.
class GameResultDialog extends ConsumerStatefulWidget {
  final WordleGameState gameState;
  final Animation<double> hoverAnimation;

  const GameResultDialog({
    super.key,
    required this.gameState,
    required this.hoverAnimation,
  });

  @override
  ConsumerState<GameResultDialog> createState() => _GameResultDialogState();
}

class _GameResultDialogState extends ConsumerState<GameResultDialog> {
  bool _showingArticleResult = false;
  bool _isLoading = true;
  String _selectedArticle = '';
  bool _isCorrect = false;
  String _correctArticle = '';
  String _englishTranslation = '';

  void _onArticleSelected(String article) async {
    setState(() {
      _selectedArticle = article;
      _isLoading = true;
      _showingArticleResult = true;
    });

    final isCorrectFuture = ref
        .read(wordleGameStateProvider.notifier)
        .checkArticle(article);
    final correctArticleFuture = ref
        .read(wordleWordRepoProvider)
        .getWordArticle(widget.gameState.targetWord);
    final englishTranslationFuture = ref
        .read(wordleWordRepoProvider)
        .getEnglishTranslation(widget.gameState.targetWord);

    final results = await Future.wait([
      isCorrectFuture,
      correctArticleFuture,
      englishTranslationFuture,
    ]);

    if (mounted) {
      setState(() {
        _isCorrect = results[0] as bool;
        _correctArticle = results[1] as String;
        _englishTranslation = results[2] as String;
        _isLoading = false;
      });
    }
  }

  Widget _buildInitialContent() {
    final isWon = widget.gameState.status == GameStatus.won;
    final targetWord = widget.gameState.targetWord;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isWon && widget.gameState.coinsEarnedThisGame > 0)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: AnimatedBuilder(
                animation: widget.hoverAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, widget.hoverAnimation.value),
                    child: _buildCoinsEarnedDisplay(),
                  );
                },
              ),
            ),

          Padding(
            padding: EdgeInsets.only(top: isWon ? 24 : 48),
            child: AnimatedBuilder(
              animation: widget.hoverAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, widget.hoverAnimation.value),
                  child:
                      isWon
                          ? Text(
                            ref
                                .read(wordleGameStateProvider.notifier)
                                .getWinFeedback(),
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorBlack,
                            ),
                            textAlign: TextAlign.center,
                          )
                          : RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontSize: 16, color: colorBlack),
                              children: [
                                TextSpan(text: 'Das Wort war: '),
                                TextSpan(
                                  text: '$targetWord  😔',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.copyWith(
                                    fontSize: 24,
                                    color: colorBlack,
                                  ),
                                ),
                              ],
                            ),
                          ),
                );
              },
            ),
          ),

          const SizedBox(height: 80),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text(
                  'Artikel zu:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorBlack,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Row(
                children: List.generate(
                  targetWord.length,
                  (index) => Container(
                    height: 28,
                    width: 28,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Center(
                      child: Text(
                        targetWord[index],
                        style: const TextStyle(
                          color: colorWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // article selection buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GlassMorphicButton(
                padding: EdgeInsets.symmetric(vertical: 12),
                onPressed: () => _onArticleSelected('der'),
                child: const Text(
                  'der',
                  style: TextStyle(fontSize: 20, color: colorBlack),
                ),
              ),
              GlassMorphicButton(
                padding: EdgeInsets.symmetric(vertical: 12),
                onPressed: () => _onArticleSelected('die'),
                child: const Text(
                  'die',
                  style: TextStyle(fontSize: 20, color: colorBlack),
                ),
              ),
              GlassMorphicButton(
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: () => _onArticleSelected('das'),
                child: const Text(
                  'das',
                  style: TextStyle(fontSize: 20, color: colorBlack),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCoinsEarnedDisplay() {
    final totalCoins = widget.gameState.coinsEarnedThisGame;
    final noHintsBonus = widget.gameState.usedNoHintsBonus ? 5 : 0;
    final mainCoins = totalCoins - noHintsBonus;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$mainCoins 🪙',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: colorBlack,
          ),
        ),
        if (noHintsBonus > 0) ...[
          const SizedBox(width: 16),
          Text(
            '+$noHintsBonus',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.lightGreenAccent,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildArticleResultContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // result
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: AnimatedBuilder(
              animation: widget.hoverAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, widget.hoverAnimation.value),
                  child: Icon(
                    _isCorrect ? Icons.check_circle_sharp : Icons.cancel_sharp,
                    size: 70,
                    color: _isCorrect ? Color(0xFF32CD32) : colorRed,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: kToolbarHeight * 0.75),

          // word with article + translation
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isCorrect)
                    Text(
                      '$_selectedArticle  ${widget.gameState.targetWord} ',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 30,
                        color: colorBlack,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  if (!_isCorrect)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // incorrect article
                        Text(
                          _selectedArticle,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(
                            fontSize: 30,
                            fontStyle: FontStyle.italic,
                            color: colorRed,
                            decoration: TextDecoration.lineThrough,
                            decorationThickness: 1,
                          ),
                        ),
                        const SizedBox(width: 20),
                        // correct article
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: colorBlack, width: 2),
                            ),
                          ),
                          child: Text(
                            _correctArticle,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(
                              fontSize: 30,
                              color: Color.fromARGB(255, 0, 97, 0),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // word itself
                        Text(
                          ' ${widget.gameState.targetWord}',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontSize: 30, color: colorBlack),
                        ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // translation
              Text(
                ' - $_englishTranslation',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 18,
                  color: colorBlack,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),

          const SizedBox(height: 45),

          // action buttons
          GlassMorphicButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(wordleGameStateProvider.notifier).newGame();
            },
            padding: const EdgeInsets.all(20),
            child: const Icon(
              Icons.refresh_rounded,
              color: colorYellow,
              size: 36,
            ),
          ),

          const SizedBox(height: 25),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 600),
      firstChild: _buildInitialContent(),
      secondChild: _buildArticleResultContent(),
      crossFadeState:
          _showingArticleResult
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
      firstCurve: Curves.easeOutCubic,
      secondCurve: Curves.easeInCubic,
      sizeCurve: Curves.easeInOutCubic,

      // account for size differences
      layoutBuilder: (topChild, topChildKey, bottomChild, bottomChildKey) {
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned(key: bottomChildKey, child: bottomChild),
            Positioned(key: topChildKey, child: topChild),
          ],
        );
      },
    );
  }
}
