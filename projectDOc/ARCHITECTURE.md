# Architecture

## Data Flow

```
[Mic Input]
     |
     v
speech_to_text (on-device STT)
     |
     v
Text query -----------------------------+
     |                                  |
     v                                  v
FastAPI /chat endpoint            Firestore/Supabase
     |                             (save user message)
     v
Gemini/Groq LLM call
  + system prompt (personality)
  + recent conversation history
     |
     v
Response text ---------------------------+
     |                                    |
     v                                    v
TTS (flutter_tts or ElevenLabs)     Firestore/Supabase
     |                              (save AI response)
     v
Audio + (optional) viseme timeline
     |
     v
Rive avatar state machine
  (idle -> listening -> thinking -> speaking)
     |
     v
[Rendered on screen, avatar "talks"]
```

## Layers (Flutter — Clean Architecture)

- **Presentation**: UI widgets, avatar screen, mic button, Riverpod providers/notifiers for conversation state
- **Domain**: use cases (`SendMessageUseCase`, `GetHistoryUseCase`), entities (`Message`, `Conversation`)
- **Data**: repositories (`ChatRepository`, `AuthRepository`), data sources (FastAPI client, Firestore client)

Keep the LLM call server-side (FastAPI), never call Gemini/Groq directly from the Flutter app. Reasons:
- API keys stay off the client
- You can swap models without an app update
- You control rate limiting, logging, and prompt injection safely

## Backend (FastAPI)

Single responsibility: receive `{user_id, message}`, fetch recent history, call LLM with system prompt, return `{response, conversation_id}`. Stateless per request — all state lives in Firestore/Supabase.

## State Management (Riverpod)

- `conversationProvider` — StateNotifier holding message list + avatar state enum (`idle`, `listening`, `thinking`, `speaking`)
- `authProvider` — current user
- Avatar widget listens to `conversationProvider` and switches Rive state machine inputs accordingly

## Why not call the LLM directly from Flutter?

Because you lose: key security, per-user rate limiting, and the ability to inject a consistent personality prompt server-side without shipping it in the app binary (where it can be extracted).

## Scaling note

For MVP, one FastAPI endpoint and synchronous request/response is fine. If you later want streaming responses (so the avatar starts speaking before the full reply is generated), move to Server-Sent Events or WebSockets between FastAPI and Flutter.
