import 'package:flutter/foundation.dart';

/// Conversation & Avatar reactive state machine states
enum ConversationState {
  idle,
  listening,
  thinking,
  speaking,
  reacting,
}

/// Customizable Aura Theme Colors for the Holographic Avatar
enum AuraTheme {
  cyberCyan,
  royalViolet,
  solarAmber,
  matrixGreen,
  hotMagenta,
}

extension AuraThemeX on AuraTheme {
  String get value {
    switch (this) {
      case AuraTheme.cyberCyan:
        return 'cyber_cyan';
      case AuraTheme.royalViolet:
        return 'royal_violet';
      case AuraTheme.solarAmber:
        return 'solar_amber';
      case AuraTheme.matrixGreen:
        return 'matrix_green';
      case AuraTheme.hotMagenta:
        return 'hot_magenta';
    }
  }

  String get displayName {
    switch (this) {
      case AuraTheme.cyberCyan:
        return 'Cyber Cyan';
      case AuraTheme.royalViolet:
        return 'Royal Violet';
      case AuraTheme.solarAmber:
        return 'Solar Amber';
      case AuraTheme.matrixGreen:
        return 'Matrix Green';
      case AuraTheme.hotMagenta:
        return 'Hot Magenta';
    }
  }

  int get colorValue {
    switch (this) {
      case AuraTheme.cyberCyan:
        return 0xFF00F0FF;
      case AuraTheme.royalViolet:
        return 0xFF9D4EDD;
      case AuraTheme.solarAmber:
        return 0xFFFFAB00;
      case AuraTheme.matrixGreen:
        return 0xFF00E676;
      case AuraTheme.hotMagenta:
        return 0xFFFF007F;
    }
  }

  static AuraTheme fromString(String val) {
    switch (val.toLowerCase()) {
      case 'royal_violet':
        return AuraTheme.royalViolet;
      case 'solar_amber':
        return AuraTheme.solarAmber;
      case 'matrix_green':
        return AuraTheme.matrixGreen;
      case 'hot_magenta':
        return AuraTheme.hotMagenta;
      case 'cyber_cyan':
      default:
        return AuraTheme.cyberCyan;
    }
  }
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

/// Supported languages for Speech-To-Text (STT), Text-To-Speech (TTS), and AI prompts
enum AppLanguage {
  marathi,
  hindi,
  englishUS,
  englishIN,
  gujarati,
  tamil,
  telugu,
  bengali,
  kannada,
  malayalam,
  spanish,
  french,
  german,
  japanese,
}

extension AppLanguageX on AppLanguage {
  String get code {
    switch (this) {
      case AppLanguage.marathi:
        return 'mr';
      case AppLanguage.hindi:
        return 'hi';
      case AppLanguage.englishUS:
        return 'en_us';
      case AppLanguage.englishIN:
        return 'en_in';
      case AppLanguage.gujarati:
        return 'gu';
      case AppLanguage.tamil:
        return 'ta';
      case AppLanguage.telugu:
        return 'te';
      case AppLanguage.bengali:
        return 'bn';
      case AppLanguage.kannada:
        return 'kn';
      case AppLanguage.malayalam:
        return 'ml';
      case AppLanguage.spanish:
        return 'es';
      case AppLanguage.french:
        return 'fr';
      case AppLanguage.german:
        return 'de';
      case AppLanguage.japanese:
        return 'ja';
    }
  }

  /// Speech-To-Text locale identifier
  String get sttLocale {
    switch (this) {
      case AppLanguage.marathi:
        return 'mr_IN';
      case AppLanguage.hindi:
        return 'hi_IN';
      case AppLanguage.englishUS:
        return 'en_US';
      case AppLanguage.englishIN:
        return 'en_IN';
      case AppLanguage.gujarati:
        return 'gu_IN';
      case AppLanguage.tamil:
        return 'ta_IN';
      case AppLanguage.telugu:
        return 'te_IN';
      case AppLanguage.bengali:
        return 'bn_IN';
      case AppLanguage.kannada:
        return 'kn_IN';
      case AppLanguage.malayalam:
        return 'ml_IN';
      case AppLanguage.spanish:
        return 'es_ES';
      case AppLanguage.french:
        return 'fr_FR';
      case AppLanguage.german:
        return 'de_DE';
      case AppLanguage.japanese:
        return 'ja_JP';
    }
  }

  /// Text-To-Speech locale identifier
  String get ttsLocale {
    switch (this) {
      case AppLanguage.marathi:
        return 'mr-IN';
      case AppLanguage.hindi:
        return 'hi-IN';
      case AppLanguage.englishUS:
        return 'en-US';
      case AppLanguage.englishIN:
        return 'en-IN';
      case AppLanguage.gujarati:
        return 'gu-IN';
      case AppLanguage.tamil:
        return 'ta-IN';
      case AppLanguage.telugu:
        return 'te-IN';
      case AppLanguage.bengali:
        return 'bn-IN';
      case AppLanguage.kannada:
        return 'kn-IN';
      case AppLanguage.malayalam:
        return 'ml-IN';
      case AppLanguage.spanish:
        return 'es-ES';
      case AppLanguage.french:
        return 'fr-FR';
      case AppLanguage.german:
        return 'de-DE';
      case AppLanguage.japanese:
        return 'ja-JP';
    }
  }

  String get displayName {
    switch (this) {
      case AppLanguage.marathi:
        return 'मराठी (Marathi)';
      case AppLanguage.hindi:
        return 'हिन्दी (Hindi)';
      case AppLanguage.englishUS:
        return 'English (US)';
      case AppLanguage.englishIN:
        return 'English (India)';
      case AppLanguage.gujarati:
        return 'ગુજરાતી (Gujarati)';
      case AppLanguage.tamil:
        return 'தமிழ் (Tamil)';
      case AppLanguage.telugu:
        return 'తెలుగు (Telugu)';
      case AppLanguage.bengali:
        return 'বাংলা (Bengali)';
      case AppLanguage.kannada:
        return 'ಕನ್ನಡ (Kannada)';
      case AppLanguage.malayalam:
        return 'മലയാളം (Malayalam)';
      case AppLanguage.spanish:
        return 'Español (Spanish)';
      case AppLanguage.french:
        return 'Français (French)';
      case AppLanguage.german:
        return 'Deutsch (German)';
      case AppLanguage.japanese:
        return '日本語 (Japanese)';
    }
  }

  String get nativeName {
    switch (this) {
      case AppLanguage.marathi:
        return 'मराठी';
      case AppLanguage.hindi:
        return 'हिन्दी';
      case AppLanguage.englishUS:
        return 'English';
      case AppLanguage.englishIN:
        return 'English (IN)';
      case AppLanguage.gujarati:
        return 'ગુજરાતી';
      case AppLanguage.tamil:
        return 'தமிழ்';
      case AppLanguage.telugu:
        return 'తెలుగు';
      case AppLanguage.bengali:
        return 'বাংলা';
      case AppLanguage.kannada:
        return 'ಕನ್ನಡ';
      case AppLanguage.malayalam:
        return 'മലയാളം';
      case AppLanguage.spanish:
        return 'Español';
      case AppLanguage.french:
        return 'Français';
      case AppLanguage.german:
        return 'Deutsch';
      case AppLanguage.japanese:
        return '日本語';
    }
  }

  String get flag {
    switch (this) {
      case AppLanguage.marathi:
      case AppLanguage.hindi:
      case AppLanguage.englishIN:
      case AppLanguage.gujarati:
      case AppLanguage.tamil:
      case AppLanguage.telugu:
      case AppLanguage.bengali:
      case AppLanguage.kannada:
      case AppLanguage.malayalam:
        return '🇮🇳';
      case AppLanguage.englishUS:
        return '🇺🇸';
      case AppLanguage.spanish:
        return '🇪🇸';
      case AppLanguage.french:
        return '🇫🇷';
      case AppLanguage.german:
        return '🇩🇪';
      case AppLanguage.japanese:
        return '🇯🇵';
    }
  }

  String get sampleGreeting {
    switch (this) {
      case AppLanguage.marathi:
        return 'नमस्कार! मी ओरा, तुमची व्हॉइस साथीदार आहे.';
      case AppLanguage.hindi:
        return 'नमस्ते! मैं ऑरा हूँ, आपका वॉइस साथी।';
      case AppLanguage.englishUS:
        return 'Hello! I am Aura, your voice companion.';
      case AppLanguage.englishIN:
        return 'Hello! I am Aura, your personal AI companion.';
      case AppLanguage.gujarati:
        return 'નમસ્તે! હું ઓરા છું, તમારો અવાજ સાથી.';
      case AppLanguage.tamil:
        return 'வணக்கம்! நான் ஆரா, உங்கள் குரல் துணைவன்.';
      case AppLanguage.telugu:
        return 'నమస్కారం! నేను ఆరా, మీ వాయిస్ స్నేహితుడిని.';
      case AppLanguage.bengali:
        return 'নমস্কার! আমি অরা, আপনার ভয়েস সঙ্গী।';
      case AppLanguage.kannada:
        return 'ನಮಸ್ಕಾರ! ನಾನು ಆರಾ, ನಿಮ್ಮ ಧ್ವನಿ ಒಡನಾಡಿ.';
      case AppLanguage.malayalam:
        return 'നമസ്കാരം! ഞാൻ ഓറ, നിങ്ങളുടെ വോയ്‌സ് കൂട്ടുകാരൻ.';
      case AppLanguage.spanish:
        return '¡Hola! Soy Aura, tu compañera de voz.';
      case AppLanguage.french:
        return 'Bonjour! Je suis Aura, votre compagne vocale.';
      case AppLanguage.german:
        return 'Hallo! Ich bin Aura, deine Sprachbegleiterin.';
      case AppLanguage.japanese:
        return 'こんにちは！私はオーラ、あなたの音声コンパニオンです。';
    }
  }

  static AppLanguage fromString(String? val) {
    if (val == null) return AppLanguage.englishUS;
    final lower = val.toLowerCase().trim();
    switch (lower) {
      case 'marathi':
      case 'mr':
      case 'mr_in':
      case 'mr-in':
        return AppLanguage.marathi;
      case 'hindi':
      case 'hi':
      case 'hi_in':
      case 'hi-in':
        return AppLanguage.hindi;
      case 'en_in':
      case 'en-in':
      case 'english_in':
        return AppLanguage.englishIN;
      case 'gujarati':
      case 'gu':
      case 'gu_in':
      case 'gu-in':
        return AppLanguage.gujarati;
      case 'tamil':
      case 'ta':
      case 'ta_in':
      case 'ta-in':
        return AppLanguage.tamil;
      case 'telugu':
      case 'te':
      case 'te_in':
      case 'te-in':
        return AppLanguage.telugu;
      case 'bengali':
      case 'bn':
      case 'bn_in':
      case 'bn-in':
        return AppLanguage.bengali;
      case 'kannada':
      case 'kn':
      case 'kn_in':
      case 'kn-in':
        return AppLanguage.kannada;
      case 'malayalam':
      case 'ml':
      case 'ml_in':
      case 'ml-in':
        return AppLanguage.malayalam;
      case 'spanish':
      case 'es':
      case 'es_es':
      case 'es-es':
        return AppLanguage.spanish;
      case 'french':
      case 'fr':
      case 'fr_fr':
      case 'fr-fr':
        return AppLanguage.french;
      case 'german':
      case 'de':
      case 'de_de':
      case 'de-de':
        return AppLanguage.german;
      case 'japanese':
      case 'ja':
      case 'ja_jp':
      case 'ja-jp':
        return AppLanguage.japanese;
      case 'english':
      case 'en':
      case 'en_us':
      case 'en-us':
      default:
        return AppLanguage.englishUS;
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
  static const String keyLanguage = 'nex_ai_language';
  static const String keyBaseUrl = 'nex_ai_base_url';
  static const String keyTtsRate = 'nex_ai_tts_rate';
  static const String keyTtsPitch = 'nex_ai_tts_pitch';
  static const String keyAutoSpeak = 'nex_ai_auto_speak';
  static const String keyAuraTheme = 'nex_ai_aura_theme';

  // Default Companion Settings
  static const String defaultCompanionName = 'Aura';
  static const CompanionTone defaultCompanionTone = CompanionTone.supportive;
  static const AuraTheme defaultAuraTheme = AuraTheme.cyberCyan;
  static const AppLanguage defaultLanguage = AppLanguage.englishUS;
  static const double defaultTtsRate = 0.5;
  static const double defaultTtsPitch = 1.0;
}
