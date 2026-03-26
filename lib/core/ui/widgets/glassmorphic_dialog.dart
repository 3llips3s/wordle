import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:wordle/config/game_config/constants.dart';

/// Renders an alert dialog overlaid with a frosted glassmorphism style.
///
/// This [Widget] displays the primary [child] content inside a blur-filtered,
/// semi-transparent bordered container. Use [width] and [height] to explicitly
/// size the resulting modal.

class GlassmorphicDialog extends StatelessWidget {
  final Widget child;
  final double? height;
  final double? width;
  final List<Widget>? actions;
  final double blur;
  final EdgeInsets padding;
  final BorderRadius borderRadius;

  const GlassmorphicDialog({
    super.key,
    required this.child,
    this.height,
    this.width,
    this.actions,
    this.blur = 5,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: UnconstrainedBox(
        child: AlertDialog(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius,
          ),
          insetPadding: EdgeInsets.zero,
          contentPadding: EdgeInsets.zero,
          content: Container(
            height: height,
            width: width,
            decoration: BoxDecoration(
              borderRadius: borderRadius,
            ),
            child: height != null
              ? _buildStack()
              : IntrinsicHeight(
                  child: _buildStack(),
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildStack() {
    return Stack(
      fit: height != null ? StackFit.expand : StackFit.loose,
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: borderRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: blur,
                sigmaY: blur,
              ),
              child: Container(),
            ),
          ),
        ),

        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              borderRadius: borderRadius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withAlpha((255 * 0.7).toInt()),
                  Colors.white.withAlpha((255 * 0.1).toInt()),
                ],
              ),
            ),
          ),
        ),

        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: padding,
              child: child,
            ),
            if (actions != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: actions!,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// helper function to show dialog
Future<T?> showCustomDialog<T>({
  required BuildContext context,
  required Widget child,
  double? height,
  double? width,
  List<Widget>? actions,
  bool barrierDismissible = false,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => GlassmorphicDialog(
      height: height,
      width: width,
      actions: actions,
      child: child,
    ),
  );
}

class GlassMorphicButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const GlassMorphicButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding = const EdgeInsets.symmetric(
      vertical: 8,
      horizontal: 2,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
        ),
        overlayColor: colorBlack,
        side: BorderSide(color: Colors.white70),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
