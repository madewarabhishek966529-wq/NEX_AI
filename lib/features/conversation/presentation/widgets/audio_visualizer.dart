import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../app/theme.dart';
import '../../../../core/constants.dart';

class AudioVisualizer extends StatefulWidget {
  final ConversationState state;
  final int barCount;
  final double height;

  const AudioVisualizer({
    super.key,
    required this.state,
    this.barCount = 18,
    this.height = 36,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.state == ConversationState.listening || widget.state == ConversationState.speaking;
    final color = AppTheme.stateColor(widget.state);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          height: widget.height,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.barCount, (index) {
              final phase = (index / widget.barCount) * 2 * pi;
              final t = _controller.value * 2 * pi;
              final sinVal = sin(t + phase).abs();

              final double barHeight = active
                  ? 6.0 + (sinVal * (widget.height - 6.0))
                  : 4.0 + (sinVal * 4.0);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 3.5,
                height: barHeight,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: active ? 0.9 : 0.35),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 4,
                          )
                        ]
                      : null,
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
