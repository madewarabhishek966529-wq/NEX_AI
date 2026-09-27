# Setup

## 1. Flutter project

```bash
flutter create ai_companion_app
cd ai_companion_app
```

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter_riverpod: ^2.5.1
  go_router: ^14.2.0
  speech_to_text: ^7.0.0
  flutter_tts: ^4.0.2
  rive: ^0.13.13
  dio: ^5.5.0          # for FastAPI calls
  cloud_firestore: ^5.2.0
  firebase_core: ^3.3.0
  firebase_auth: ^5.1.3
```

Run `flutter pub get`.

## 2. Permissions

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSMicrophoneUsageDescription</key>
<string>Needed for voice conversation</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>Needed to understand your speech</string>
```

## 3. Firebase/Supabase

Pick one (both listed since your stack uses either depending on project):
- Firebase: `flutterfire configure` after creating a project in Firebase console, enable Firestore + Auth
- Supabase: create project, get URL + anon key, add `supabase_flutter` package instead

Schema (either backend):
```
conversations/{conversation_id}
  - user_id
  - created_at
messages/{message_id}
  - conversation_id
  - role: "user" | "assistant"
  - text
  - timestamp
```

## 4. FastAPI backend

```bash
mkdir companion_backend && cd companion_backend
python -m venv venv
source venv/bin/activate   # or venv\Scripts\activate on Windows
pip install fastapi uvicorn google-generativeai groq python-dotenv
```

`.env`:
```
GEMINI_API_KEY=your_key
GROQ_API_KEY=your_key
```

Run: `uvicorn main:app --reload --port 8000`

## 5. Rive

- Download Rive editor (free) or use community avatar files from rive.app/community
- Export `.riv` file with a state machine containing states: `Idle`, `Listening`, `Thinking`, `Speaking`
- Place in `assets/animations/avatar.riv`, register in `pubspec.yaml`

## 6. TTS choice

- MVP: `flutter_tts` — zero cost, no API key, works offline
- Upgrade: ElevenLabs API — natural voice + viseme timestamps for accurate lip sync, paid
