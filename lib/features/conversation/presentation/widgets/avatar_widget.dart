import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants.dart';
import '../../../../app/theme.dart';

class AvatarWidget extends StatefulWidget {
  final ConversationState state;
  final VoidCallback? onTap;
  final double size;
  final AuraTheme auraTheme;

  const AvatarWidget({
    super.key,
    required this.state,
    this.onTap,
    this.size = 260,
    this.auraTheme = AuraTheme.cyberCyan,
  });

  @override
  State<AvatarWidget> createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends State<AvatarWidget> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _blinkController;
  late AnimationController _mouthController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();

    _mouthController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant AvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state != oldWidget.state) {
      if (widget.state == ConversationState.thinking) {
        _rotationController.duration = const Duration(milliseconds: 2500);
        _rotationController.repeat();
      } else {
        _rotationController.duration = const Duration(milliseconds: 6000);
        _rotationController.repeat();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _blinkController.dispose();
    _mouthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateColor = AppTheme.stateColor(widget.state, widget.auraTheme);

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _pulseController,
            _rotationController,
            _blinkController,
            _mouthController,
          ]),
          builder: (context, child) {
            return CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _AuraAvatarPainter(
                state: widget.state,
                pulseValue: _pulseController.value,
                rotationAngle: _rotationController.value * 2 * pi,
                blinkValue: _blinkController.value,
                mouthValue: _mouthController.value,
                accentColor: stateColor,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AuraAvatarPainter extends CustomPainter {
  final ConversationState state;
  final double pulseValue;
  final double rotationAngle;
  final double blinkValue;
  final double mouthValue;
  final Color accentColor;

  _AuraAvatarPainter({
    required this.state,
    required this.pulseValue,
    required this.rotationAngle,
    required this.blinkValue,
    required this.mouthValue,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.34;

    // 1. Ambient Glow Aura
    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          accentColor.withValues(alpha: 0.35 + (0.15 * pulseValue)),
          accentColor.withValues(alpha: 0.12),
          Colors.transparent,
        ],
        stops: const [0.2, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: baseRadius * 1.55));

    canvas.drawCircle(center, baseRadius * 1.55, auraPaint);

    // 2. Listening Ripple Waves (Active when listening)
    if (state == ConversationState.listening) {
      for (int i = 0; i < 3; i++) {
        final rippleProgress = (pulseValue + (i * 0.33)) % 1.0;
        final rippleRadius = baseRadius + (rippleProgress * 45);
        final ripplePaint = Paint()
          ..color = accentColor.withValues(alpha: (1.0 - rippleProgress) * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(center, rippleRadius, ripplePaint);
      }
    }

    // 3. Orbital Celestial Rings
    final ringPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationAngle);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: baseRadius * 2.3, height: baseRadius * 1.6),
      ringPaint,
    );

    // Orbital Nodes
    final nodePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final nodeRadius = (baseRadius * 2.3) / 2;
    canvas.drawCircle(Offset(nodeRadius, 0), 4.5, nodePaint);
    canvas.drawCircle(Offset(-nodeRadius, 0), 3.5, nodePaint);

    // Second inclined ring
    canvas.rotate(pi / 3);
    final innerRingPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: baseRadius * 2.1, height: baseRadius * 1.4),
      innerRingPaint,
    );
    canvas.restore();

    // 4. Character Holographic Head / Core Sphere
    final headRect = Rect.fromCircle(center: center, radius: baseRadius);
    final headGradient = RadialGradient(
      center: const Alignment(-0.25, -0.35),
      radius: 0.95,
      colors: [
        const Color(0xFF2A3654),
        const Color(0xFF131A2D),
        const Color(0xFF090D18),
      ],
      stops: const [0.0, 0.65, 1.0],
    );

    final headPaint = Paint()..shader = headGradient.createShader(headRect);
    canvas.drawCircle(center, baseRadius, headPaint);

    // Head Border Glow
    final borderPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          accentColor,
          accentColor.withValues(alpha: 0.2),
          accentColor,
        ],
      ).createShader(headRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    canvas.drawCircle(center, baseRadius, borderPaint);

    // 5. Expressive Facial Elements
    _drawFace(canvas, center, baseRadius);
  }

  void _drawFace(Canvas canvas, Offset center, double headRadius) {
    final eyeSpacing = headRadius * 0.42;
    final eyeY = center.dy - (headRadius * 0.12);
    final leftEyeCenter = Offset(center.dx - eyeSpacing, eyeY);
    final rightEyeCenter = Offset(center.dx + eyeSpacing, eyeY);

    // Check blink phase
    final isBlinking = (blinkValue > 0.92 && blinkValue < 0.98);

    if (state == ConversationState.reacting) {
      // Happy Cheerful Arcs (^_^)
      final happyEyePaint = Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.5;

      canvas.drawArc(
        Rect.fromCircle(center: leftEyeCenter, radius: 10),
        pi,
        pi,
        false,
        happyEyePaint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: rightEyeCenter, radius: 10),
        pi,
        pi,
        false,
        happyEyePaint,
      );
    } else if (isBlinking) {
      // Closed blinking eyes (-)
      final blinkPaint = Paint()
        ..color = accentColor
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.0;

      canvas.drawLine(
        Offset(leftEyeCenter.dx - 10, leftEyeCenter.dy),
        Offset(leftEyeCenter.dx + 10, leftEyeCenter.dy),
        blinkPaint,
      );
      canvas.drawLine(
        Offset(rightEyeCenter.dx - 10, rightEyeCenter.dy),
        Offset(rightEyeCenter.dx + 10, rightEyeCenter.dy),
        blinkPaint,
      );
    } else {
      // Expressive Glowing Neon Eyes
      final eyeWidth = state == ConversationState.listening ? 12.0 : 10.0;
      final eyeHeight = state == ConversationState.listening ? 16.0 : 13.0;

      final eyePaint = Paint()
        ..color = accentColor
        ..style = PaintingStyle.fill;

      // Eye sclera glow
      canvas.drawOval(
        Rect.fromCenter(center: leftEyeCenter, width: eyeWidth, height: eyeHeight),
        eyePaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: rightEyeCenter, width: eyeWidth, height: eyeHeight),
        eyePaint,
      );

      // Eye specular highlights
      final highlightPaint = Paint()..color = Colors.white;
      canvas.drawCircle(
        Offset(leftEyeCenter.dx + 2, leftEyeCenter.dy - 3),
        2.5,
        highlightPaint,
      );
      canvas.drawCircle(
        Offset(rightEyeCenter.dx + 2, rightEyeCenter.dy - 3),
        2.5,
        highlightPaint,
      );
    }

    // 6. Expressive Reactive Mouth
    final mouthY = center.dy + (headRadius * 0.32);
    final mouthCenter = Offset(center.dx, mouthY);

    if (state == ConversationState.speaking) {
      // Dynamic moving mouth wave
      final openH = 6.0 + (mouthValue * 12.0);
      final mouthPaint = Paint()
        ..color = accentColor
        ..style = PaintingStyle.fill;

      canvas.drawOval(
        Rect.fromCenter(center: mouthCenter, width: 22.0, height: openH),
        mouthPaint,
      );

      final teethPaint = Paint()..color = Colors.white;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(mouthCenter.dx, mouthCenter.dy - (openH * 0.25)), width: 14, height: 3),
          const Radius.circular(2),
        ),
        teethPaint,
      );
    } else if (state == ConversationState.reacting) {
      // Big delight smile
      final smilePaint = Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.2;

      canvas.drawArc(
        Rect.fromCenter(center: Offset(center.dx, mouthY - 4), width: 28, height: 16),
        0,
        pi,
        false,
        smilePaint,
      );
    } else if (state == ConversationState.thinking) {
      // Small thoughtful neutral mouth
      final mouthPaint = Paint()
        ..color = accentColor
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.8;

      canvas.drawLine(
        Offset(center.dx - 8, mouthY),
        Offset(center.dx + 8, mouthY - 2),
        mouthPaint,
      );
    } else {
      // Gentle friendly resting smile (idle & listening)
      final smilePaint = Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.6;

      canvas.drawArc(
        Rect.fromCenter(center: Offset(center.dx, mouthY - 3), width: 20, height: 10),
        0.15,
        pi - 0.3,
        false,
        smilePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AuraAvatarPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
        oldDelegate.rotationAngle != rotationAngle ||
        oldDelegate.blinkValue != blinkValue ||
        oldDelegate.mouthValue != mouthValue ||
        oldDelegate.state != state ||
        oldDelegate.accentColor != accentColor;
  }
}
