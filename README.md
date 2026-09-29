<p align="center">
  <img src="assets/icons/app_logo.png" width="130" height="130" alt="NEX_AI App Logo" />
</p>

# NEX_AI — Voice AI Companion (JARVIS / Aura Style)

An autonomous voice-first AI companion built with **Flutter** (Clean Architecture + Riverpod) and **FastAPI** (Gemini/Groq + SQLite persistence). Talks back with spoken audio, remembers conversations using sliding-window & rolling-summary memory, and reacts dynamically through a multi-state holographic animated avatar.

---

## Architecture Overview

```
[Voice Microphone Input]
          │
          ▼
   speech_to_text (On-device STT)
          │
          ▼
   Text Query ───► FastAPI Backend (/chat)
                         │
                         ├──► Gemini / Groq LLM (Personality Prompt + Context)
                         ├──► Conversation Memory (Sliding Window & Rolling Summary)
                         └──► Persistent SQLite Database (Messages & Sessions)
                         │
          ◄──────────────┘
          │
          ▼
   flutter_tts (Voice Synthesis Engine)
          │
          ▼
   Reactive Avatar State Machine
   (idle ◄► listening ◄► thinking ◄► speaking ◄► reacting)
```

---

## Clean Architecture Directory Structure

```
nex_ai/
├── backend/
│   ├── main.py                  # FastAPI server with /chat, /history, /conversation/new
│   ├── config.py                # Personality prompts and environment settings
│   ├── database.py              # SQLite persistence layer for conversations & messages
│   ├── memory.py                # Sliding window and rolling summary engine
│   ├── requirements.txt         # FastAPI, Uvicorn, Google GenAI, Groq dependencies
│   └── .env.example             # API keys and host configuration
│
├── lib/
│   ├── main.dart                # Riverpod ProviderScope, system UI styling & GoRouter
│   ├── app/
│   │   ├── router.dart          # GoRouter declarations
│   │   └── theme.dart           # Neon cyberpunk/Aura dark theme & state colors
│   ├── core/
│   │   ├── constants.dart       # State machine enums, personality tones & storage keys
│   │   ├── network/
│   │   │   └── dio_client.dart  # Configurable Dio HTTP client with error mapping
│   │   └── errors/
│   │       └── failures.dart    # Domain failure definitions
│   ├── features/
│   │   ├── conversation/
│   │   │   ├── domain/
│   │   │   │   ├── entities/    # Message and Conversation entities
│   │   │   │   ├── repositories/# Abstract ChatRepository interface
│   │   │   │   └── usecases/    # SendMessage, GetHistory, StartNewConversation
│   │   │   ├── data/
│   │   │   │   ├── datasources/ # Remote (FastAPI) and Local (SharedPreferences)
│   │   │   │   └── repositories/# ChatRepositoryImpl with offline fallback
│   │   │   └── presentation/
│   │   │       ├── providers/   # ConversationProvider (Riverpod StateNotifier + STT/TTS)
│   │   │       ├── screens/     # ConversationScreen (Flagship companion UI)
│   │   │       └── widgets/     # AvatarWidget, MicButton, MessageBubble, AudioVisualizer, StateBadge
│   │   └── settings/
│   │       └── presentation/
│   │           └── screens/     # SettingsScreen (Companion name, tone, voice pitch, server URL)
│   └── shared/
│       └── widgets/             # GlassCard, NeonButton
│
└── test/
    └── widget_test.dart         # Unit & widget tests with FakeChatRepository
```

---

## Companion Personality Tones

Configure Aura/Jarvis with four distinct personalities in `SettingsScreen`:
- **Warm & Supportive**: Gentle, encouraging, and deeply empathetic.
- **Hype Friend**: High energy, motivating, and cheerful.
- **Chill & Relaxed**: Laid-back, comforting, and calm.
- **JARVIS Intellectual**: Sharp, witty, curious, and thoughtful.

---

## Quick Start

### 1. Run Backend (FastAPI)
```bash
cd backend
pip install -r requirements.txt
cp .env.example .env     # (Optional: Add your GEMINI_API_KEY or GROQ_API_KEY)
python main.py
```
*Note: The backend automatically falls back to smart offline conversational responses if no API key is set.*

### 2. Run Flutter App
```bash
flutter pub get
flutter run
```

---

## Automated Verification

- **Static Analysis**: `flutter analyze` (Zero issues found)
- **Automated Tests**: `flutter test` (All tests passing)