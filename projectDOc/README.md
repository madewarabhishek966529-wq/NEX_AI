# AI Companion App — Project Docs

A voice-based AI friend/assistant app (JARVIS-style) built in Flutter. Talks back with a real response (not mimicry like Talking Tom), has a persistent personality, remembers past conversations, and is animated by a talking avatar (2.5D Rive to start, upgradeable to 3D).

## Doc Index

| File | Purpose |
|---|---|
| `ARCHITECTURE.md` | System design, data flow, tech choices and why |
| `SETUP.md` | Environment setup — Flutter, FastAPI, Firebase/Supabase, API keys |
| `ROADMAP.md` | Phased MVP build order with milestones |
| `API_SPEC.md` | FastAPI endpoint contracts |
| `PROMPTS.md` | Personality system prompt + memory strategy |
| `AVATAR.md` | Avatar plan — pre-rendered clip swap (v1) and real-time 3D VRM upgrade (v2) |
| `FOLDER_STRUCTURE.md` | Flutter project structure (Clean Architecture + Riverpod) |
| `TASKS.md` | Checkbox task list, split into evening-sized sessions per track |

## One-line stack

Flutter (Riverpod, GoRouter, Clean Architecture) → FastAPI → Gemini/Groq → Firebase/Supabase → avatar (pre-rendered clip swap, see AVATAR.md) → flutter_tts / ElevenLabs.

## Core principle

The "friend" feel comes from three things, not the 3D model:
1. A consistent personality system prompt
2. Persisted conversation memory (Firestore/Supabase)
3. An avatar state reacting to listening/thinking/speaking

Build these three first. The 3D upgrade is cosmetic and comes last.
