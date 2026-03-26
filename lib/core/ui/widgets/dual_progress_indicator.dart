import 'package:flutter/material.dart';
import 'package:wordle/config/game_config/constants.dart';

class DualProgressIndicator extends StatefulWidget {
  final double size;
  final List<Color> outerCircleColors;
  final List<Color> innerCircleColors;
  final double outerStrokeWidth;
  final double innerStrokeWidth;
  final Duration outerRotationDuration;
  final Duration innerRotationDuration;
  final double circleGap;
  final Curve animationCurve;
  final Curve colorCurve;

  const DualProgressIndicator({
    super.key,
    this.size = 40.0,
    this.outerCircleColors = const [colorYellowAccent, colorRed],
    this.innerCircleColors = const [colorRed, colorYellowAccent],
    this.outerStrokeWidth = 2,
    this.innerStrokeWidth = 2,
    this.outerRotationDuration = const Duration(seconds: 3),
    this.innerRotationDuration = const Duration(seconds: 3),
    this.circleGap = 0.8,
    this.animationCurve = Curves.easeInOut,
    this.colorCurve = Curves.easeInOut,
  });

  @override
  State<DualProgressIndicator> createState() => _DualProgressIndicatorState();
}

class _DualProgressIndicatorState extends State<DualProgressIndicator>
    with TickerProviderStateMixin {
  AnimationController? _outerController;
  AnimationController? _innerController;

  // Color animations
  Animation<Color?>? _outerColorAnimation;
  Animation<Color?>? _innerColorAnimation;

  // To keep track of color cycles
  int _outerColorCycle = 0;
  int _innerColorCycle = 0;

  @override
  void initState() {
    super.initState();

    // Initialize outer circle controller and listener
    _outerController = AnimationController(
      duration: widget.outerRotationDuration,
      vsync: this,
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          // When a rotation completes, increment the color cycle and reset controller
          setState(() {
            _outerColorCycle =
                (_outerColorCycle + 1) % widget.outerCircleColors.length;
            _setupOuterColorAnimation();
          });
          _outerController!.reset();
          _outerController!.forward();
        }
      })
      ..forward();

    // Initialize inner circle controller and listener
    _innerController = AnimationController(
      duration: widget.innerRotationDuration,
      vsync: this,
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          // When a rotation completes, increment the color cycle and reset controller
          setState(() {
            _innerColorCycle =
                (_innerColorCycle + 1) % widget.innerCircleColors.length;
            _setupInnerColorAnimation();
          });
          _innerController!.reset();
          _innerController!.forward();
        }
      })
      ..forward();

    // Setup initial color animations
    _setupOuterColorAnimation();
    _setupInnerColorAnimation();
  }

  void _setupOuterColorAnimation() {
    final currentColor = widget.outerCircleColors[_outerColorCycle];
    final nextColor = widget.outerCircleColors[
        (_outerColorCycle + 1) % widget.outerCircleColors.length];

    _outerColorAnimation = ColorTween(
      begin: currentColor,
      end: nextColor,
    ).animate(
      CurvedAnimation(
        parent: _outerController!,
        curve: Interval(
          0.9,
          1.0,
          curve: widget.colorCurve,
        ),
      ),
    );
  }

  void _setupInnerColorAnimation() {
    final currentColor = widget.innerCircleColors[_innerColorCycle];
    final nextColor = widget.innerCircleColors[
        (_innerColorCycle + 1) % widget.innerCircleColors.length];

    _innerColorAnimation = ColorTween(
      begin: currentColor,
      end: nextColor,
    ).animate(
      CurvedAnimation(
        parent: _innerController!,
        curve: Interval(
          0.9,
          1.0,
          curve: widget.colorCurve,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _outerController?.dispose();
    _innerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_outerController == null || _innerController == null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      height: widget.size,
      width: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // Outer circle with color animation
          AnimatedBuilder(
            animation: _outerController!,
            builder: (context, child) {
              return RotationTransition(
                turns: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _outerController!,
                    curve: widget.animationCurve,
                  ),
                ),
                child: SizedBox(
                  height: widget.size,
                  width: widget.size,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        _outerColorAnimation?.value ??
                            widget.outerCircleColors[0]),
                    strokeWidth: widget.outerStrokeWidth,
                    value: widget.circleGap,
                    strokeCap: StrokeCap.round,
                  ),
                ),
              );
            },
          ),

          // Inner circle with color animation
          AnimatedBuilder(
            animation: _innerController!,
            builder: (context, child) {
              return RotationTransition(
                turns: Tween<double>(begin: 1.0, end: 0.0).animate(
                  CurvedAnimation(
                    parent: _innerController!,
                    curve: widget.animationCurve,
                  ),
                ),
                child: SizedBox(
                  height: widget.size * 0.7,
                  width: widget.size * 0.7,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        _innerColorAnimation?.value ??
                            widget.innerCircleColors[0]),
                    strokeWidth: widget.innerStrokeWidth,
                    value: widget.circleGap,
                    strokeCap: StrokeCap.round,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
