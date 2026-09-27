import 'package:flutter/material.dart';
import '../../app/theme.dart';

class NeonButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color glowColor;
  final bool isLoading;
  final double height;
  final EdgeInsetsGeometry padding;

  const NeonButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.glowColor = AppTheme.primaryNeon,
    this.isLoading = false,
    this.height = 48,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.25),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: glowColor,
          foregroundColor: Colors.black,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
              )
            : child,
      ),
    );
  }
}
