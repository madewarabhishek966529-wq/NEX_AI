# Tasks — Checkbox Sessions

Each block is sized for one evening session. Do one track per session — don't mix Dart and Python work in the same sitting.

## Track: Backend

- [ ] FastAPI project scaffold + `/health` endpoint
- [ ] `/chat` endpoint calling Gemini/Groq with hardcoded system prompt
- [ ] Test via Postman/curl — confirm response text comes back
- [ ] Add Firestore/Supabase — save user + assistant messages
- [ ] `/chat` fetches last N messages and includes as context
- [ ] `/history/{conversation_id}` endpoint
- [ ] `/conversation/new` endpoint

## Track: App shell

- [ ] Flutter project + GoRouter + Riverpod setup
- [ ] Chat screen UI with text input (mock API response, hardcoded string)
- [ ] Wire real `/chat` call via Dio, replace mock
- [ ] Add `speech_to_text` — mic button → text input
- [ ] Add `flutter_tts` — response text → spoken audio
- [ ] `ConversationState` enum (idle/listening/thinking/speaking/reacting) wired to provider

## Track: Avatar (Path A — clip swap)

- [ ] Source/commission 5 looping clips (idle, listening, thinking, speaking, reacting)
- [ ] Add `video_player` package, load clips as assets
- [ ] `AvatarWidget` swaps clip based on `ConversationState`
- [ ] Confirm smooth looping, no visible seam/flash on loop restart
- [ ] Wire avatar widget into chat screen alongside mic button

## Track: Polish (do last)

- [ ] Rolling summary memory (see PROMPTS.md) instead of raw sliding window
- [ ] Personality config — let user name companion + pick tone at onboarding
- [ ] Error states (no internet, API failure) — avatar shows a neutral/idle fallback, not a crash

## Stretch (only if time remains before interviews)

- [ ] Path B: VRoid character + real-time 3D rendering (see AVATAR.md)
