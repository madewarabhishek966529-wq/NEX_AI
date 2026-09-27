import 'package:flutter/material.dart';
import '../../../../app/theme.dart';
import '../../../../core/constants.dart';

class MicButton extends StatefulWidget {
  final bool isListening;
  final ConversationState state;
  final VoidCallback onPressed;

  const MicButton({
    super.key,
    required this.isListening,
    required this.state,
    required this.onPressed,
  });

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    if (widget.isListening) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !oldWidget.isListening) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isListening && oldWidget.isListening) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isListening ? AppTheme.accentGreen : AppTheme.primaryNeon;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = widget.isListening ? 1.0 + (_pulseController.value * 0.12) : 1.0;
        final glowSpread = widget.isListening ? 8.0 + (_pulseController.value * 16.0) : 6.0;

        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: activeColor.withValues(alpha: widget.isListening ? 0.6 : 0.25),
                  blurRadius: glowSpread,
                  spreadRadius: widget.isListening ? 3 : 1,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: widget.onPressed,
                customBorder: const CircleBorder(),
                splashColor: activeColor.withValues(alpha: 0.4),
                child: Ink(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.isListening
                          ? [AppTheme.accentGreen, const Color(0xFF00B0FF)]
                          : [AppTheme.primaryNeon, const Color(0xFF0072FF)],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      widget.isListening ? Icons.mic : Icons.mic_none_rounded,
                      color: Colors.black,
                      size: 34,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
