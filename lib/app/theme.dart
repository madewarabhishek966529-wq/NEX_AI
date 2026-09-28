import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';

class AppTheme {
  // Brand Color Palette
  static const Color background = Color(0xFF080B14);
  static const Color surface = Color(0xFF101626);
  static const Color surfaceElevated = Color(0xFF161F36);
  static const Color surfaceBorder = Color(0xFF23304E);

  static const Color primaryNeon = Color(0xFF00F0FF);
  static const Color primaryGlow = Color(0x3300F0FF);

  static const Color secondaryNeon = Color(0xFF9D4EDD);
  static const Color secondaryGlow = Color(0x339D4EDD);

  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color accentGreen = Color(0xFF00E676);
  static const Color accentAmber = Color(0xFFFFAB00);
  static const Color accentPink = Color(0xFFFF4081);
  static const Color textPrimary = Color(0xFFF0F4FC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Dynamic state colors
  static Color stateColor(ConversationState state, [AuraTheme aura = AuraTheme.cyberCyan]) {
    final customPrimary = Color(aura.colorValue);
    switch (state) {
      case ConversationState.idle:
        return customPrimary;
      case ConversationState.listening:
        return accentGreen;
      case ConversationState.thinking:
        return secondaryNeon;
      case ConversationState.speaking:
        return accentAmber;
      case ConversationState.reacting:
        return accentPink;
    }
  }

  static String stateTitle(ConversationState state, [String companionName = 'Aura']) {
    switch (state) {
      case ConversationState.idle:
        return '$companionName is Ready';
      case ConversationState.listening:
        return 'Listening to you...';
      case ConversationState.thinking:
        return '$companionName is Thinking...';
      case ConversationState.speaking:
        return '$companionName is Speaking...';
      case ConversationState.reacting:
        return '$companionName is Delighted!';
    }
  }

  static ThemeData get darkTheme {
    final baseTextTheme = ThemeData.dark().textTheme;
    final textTheme = GoogleFonts.outfitTextTheme(baseTextTheme).apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primaryNeon,
        secondary: secondaryNeon,
        surface: surface,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background.withValues(alpha: 0.85),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: surfaceBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        hintStyle: GoogleFonts.outfit(color: textMuted, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: surfaceBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: surfaceBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: primaryNeon, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNeon,
          foregroundColor: Colors.black,
          elevation: 4,
          shadowColor: primaryGlow,
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
    );
  }
}
