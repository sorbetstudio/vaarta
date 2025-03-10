// lib/widgets/src/processing_animation.dart

import 'package:flutter/material.dart';

// An animated widget showing a "processing" indicator with bouncing dots and text
class ProcessingAnimation extends StatefulWidget {
  final Color color; // Color of the dots and text
  final String processingText; // Text to display next to the animation

  const ProcessingAnimation({
    super.key,
    required this.color,
    this.processingText = "processing...",
  });

  @override
  State<ProcessingAnimation> createState() => _ProcessingAnimationState();
}

class _ProcessingAnimationState extends State<ProcessingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _dotController;
  late AnimationController _textController;
  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _textOpacity = Tween<double>(begin: 0.6, end: 1.0).animate(_textController);
  }

  @override
  void dispose() {
    _dotController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha:0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.color.withValues(alpha:0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _dotController,
            builder: (context, child) {
              return Row(
                children: List.generate(3, (index) {
                  final delay = index * 0.2;
                  final progress = (_dotController.value + delay) % 1.0;
                  final size = 4.0 + 4.0 * _bounceCurve(progress);
                  return Container(
                    width: 8,
                    height: 20,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: widget.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(width: 8),
          FadeTransition(
            opacity: _textOpacity,
            child: Text(
              widget.processingText,
              style: TextStyle(
                color: widget.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Custom curve for bouncing dot animation
  double _bounceCurve(double value) {
    if (value < 0.5) {
      return 4 * value * value * value;
    } else {
      final f = (2 * value) - 2;
      return 0.5 * f * f * f + 1;
    }
  }
}