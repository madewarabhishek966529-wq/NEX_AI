import 'package:flutter/foundation.dart';

/// Conversation & Avatar reactive state machine states
enum ConversationState {
  idle,
  listening,
  thinking,
  speaking,
  reacting,
}

/// Personality tones for the AI companion
enum CompanionTone {
  supportive,
  hypeFriend,
  chill,
  intellectual,
}

extension CompanionToneX on CompanionTone {
  String get value {
    switch (this) {
      case CompanionTone.supportive:
        return 'supportive';
      case CompanionTone.hypeFriend:
        return 'hype-friend';
      case CompanionTone.chill:
        return 'chill';
      case CompanionTone.intellectual:
        return 'intellectual';
    }
  }

  String get displayName {
    switch (this) {
      case CompanionTone.supportive:
        return 'Warm & Supportive';
      case CompanionTone.hypeFriend:
        return 'Hype Friend';
      case CompanionTone.chill:
        return 'Chill & Relaxed';
      case CompanionTone.intellectual:
        return 'JARVIS Intellectual';
    }
  }

  String get description {
    switch (this) {
      case CompanionTone.supportive:
        return 'Gentle, encouraging, and deeply empathetic.';
      case CompanionTone.hypeFriend:
        return 'High energy, motivating, and cheerful.';
      case CompanionTone.chill:
        return 'Laid-back, comforting, and calm.';
      case CompanionTone.intellectual:
        return 'Sharp, witty, curious, and thoughtful.';
    }
  }

  static CompanionTone fromString(String val) {
    switch (val.toLowerCase()) {
      case 'hype-friend':
      case 'hypefriend':
        return CompanionTone.hypeFriend;
      case 'chill':
        return CompanionTone.chill;
      case 'intellectual':
        return CompanionTone.intellectual;
      case 'supportive':
      default:
        return CompanionTone.supportive;
    }
  }
}

class AppConstants {
  static const String appName = 'NEX_AI';
  static const String appTagline = 'Your Autonomous Voice AI Companion';

  // Network Defaults
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // 10.0.2.2 points to host machine from Android Emulator
      return 'http://10.0.2.2:8000';
    } else {
      // Windows, macOS, Linux, iOS Simulator
      return 'http://127.0.0.1:8000';
    }
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Storage Keys
  static const String keyUserId = 'nex_ai_user_id';
  static const String keyActiveConversationId = 'nex_ai_active_conv_id';
  static const String keyCompanionName = 'nex_ai_companion_name';
  static const String keyCompanionTone = 'nex_ai_companion_tone';
  static const String keyBaseUrl = 'nex_ai_base_url';
  static const String keyTtsRate = 'nex_ai_tts_rate';
  static const String keyTtsPitch = 'nex_ai_tts_pitch';
  static const String keyAutoSpeak = 'nex_ai_auto_speak';

  // Default Companion Settings
  static const String defaultCompanionName = 'Aura';
  static const CompanionTone defaultCompanionTone = CompanionTone.supportive;
  static const double defaultTtsRate = 0.5;
  static const double defaultTtsPitch = 1.0;
}
