# Roadmap

## Phase 0 — Skeleton (1–2 days)
- Flutter project with GoRouter, Riverpod set up
- FastAPI project with one `/health` endpoint
- Confirm Flutter can hit FastAPI locally

## Phase 1 — Text chat works (2–3 days)
- Chat screen: text input → FastAPI `/chat` → Gemini/Groq → text response shown in UI
- System prompt with personality (see `PROMPTS.md`)
- No voice yet, no avatar yet — prove the brain works first

## Phase 2 — Voice in/out (3–4 days)
- Add `speech_to_text` for mic input → text
- Add `flutter_tts` for response text → spoken audio
- Replace text input with mic button; app now "talks"

## Phase 3 — Memory (2 days)
- Persist messages to Firestore/Supabase per user
- On each `/chat` call, FastAPI fetches last N messages and includes them in the prompt
- Test: app should recall something you told it 5 messages ago

## Phase 4 — Avatar, Path A: clip swap (2–3 days)
- Source/commission 5 short looping clips: idle, listening, thinking, speaking, reacting (see AVATAR.md)
- `video_player` package swaps clip based on `ConversationState`
- No rigging, no rendering engine — just state-driven video swapping
- This alone matches the visual bar of most production companion apps

## Phase 5 — Real-time 3D upgrade, Path B (multi-week, optional, do last)
- Only after Phase 4 is solid and demoable
- VRoid Studio character (`.vrm`) + `three-vrm`/WebView or Unity embed
- Drive built-in VRM blendshapes for expressions + lip sync via ElevenLabs viseme data
- This is a portfolio "wow factor" stretch goal, not a functional requirement — see AVATAR.md for full plan

## Suggested order for placement portfolio

Ship Phases 0–4 as v1 and put it in your portfolio — a working voice companion with memory and a reactive avatar is already a strong project. Treat Phase 5–6 as stretch goals if time allows before interviews.
