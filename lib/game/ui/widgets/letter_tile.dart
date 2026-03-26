import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:wordle/config/game_config/constants.dart';
import '../../data/models/guess_model.dart';

/// Renders a single interactive letter tile on the game board.
///
/// Handles flip animations when evaluating a [match], and handles scale/shimmer
/// animations when a tile [isRevealed] via a hint.
class LetterTile extends StatefulWidget {
  final String letter;
  final LetterMatch? match;
  final Duration animationDelay;
  final bool isCurrentGuess;
  final bool isEmpty;
  final bool isRevealed;

  const LetterTile({
    super.key,
    this.letter = '',
    this.match,
    this.animationDelay = Duration.zero,
    this.isCurrentGuess = false,
    this.isEmpty = false,
    this.isRevealed = false,
  });

  @override
  State<LetterTile> createState() => _LetterTileState();
}

class _LetterTileState extends State<LetterTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flipAnimation;
  bool _showingBack = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.match != null) {
      Future.delayed(
        widget.animationDelay,
        () {
          if (mounted) {
            _controller.forward();
          }
        },
      );
    }
  }

  @override
  void didUpdateWidget(LetterTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.match != oldWidget.match && widget.match != null) {
      _showingBack = false;
      _controller.reset();

      Future.delayed(
        widget.animationDelay,
        () {
          if (mounted) {
            _controller.forward();
          }
        },
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getColorForMatch(LetterMatch match) {
    switch (match) {
      case LetterMatch.correct:
        return Colors.green;
      case LetterMatch.present:
        return colorYellow;
      case LetterMatch.absent:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEmpty) {
      return _buildEmptyTile();
    }

    if (widget.isCurrentGuess) {
      return _buildCurrentGuessTile();
    }

    if (widget.match != null) {
      return _buildAnimatedTile();
    }

    if (widget.isRevealed) {
      return _buildRevealedTile();
    }

    return _buildEmptyTile();
  }

  Widget _buildEmptyTile() {
    return Container(
      width: 50,
      height: 50,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: colorGrey600),
      ),
    );
  }

  Widget _buildCurrentGuessTile() {
    return Container(
      width: 50,
      height: 50,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: colorGrey300, width: 1.5),
      ),
      child: Center(
        child: Text(
          widget.letter,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colorGrey300,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTile() {
    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        final value = _flipAnimation.value;

        if (value >= 0.5 && !_showingBack) {
          _showingBack = true;
        }

        final rotation = value < 0.5 ? value * pi : (1 - value) * pi;

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(rotation),
          alignment: Alignment.center,
          child: Container(
            width: 50,
            height: 50,
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _showingBack
                  ? _getColorForMatch(widget.match!)
                  : Colors.black,
            ),
            child: Center(
              child: Text(
                widget.letter,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorWhite,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRevealedTile() {
    return Container(
      width: 50,
      height: 50,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: Text(
          widget.letter,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colorWhite,
          ),
        ),
      ),
    )
        .animate(delay: 150.ms)
        .scale(begin: const Offset(0.8, 0.8), duration: 300.ms)
        .then()
        .shimmer(
          duration: 600.ms,
          color: colorWhite.withValues(alpha: 0.5),
        );
  }
}
