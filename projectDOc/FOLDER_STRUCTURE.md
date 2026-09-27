# Flutter Folder Structure (Clean Architecture + Riverpod)

```
lib/
├── main.dart
├── app/
│   ├── router.dart              # GoRouter config
│   └── theme.dart
├── core/
│   ├── constants.dart
│   ├── network/
│   │   └── dio_client.dart      # FastAPI HTTP client
│   └── errors/
│       └── failures.dart
├── features/
│   └── conversation/
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── message.dart
│       │   │   └── conversation.dart
│       │   ├── repositories/
│       │   │   └── chat_repository.dart     # abstract
│       │   └── usecases/
│       │       ├── send_message.dart
│       │       └── get_history.dart
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── chat_remote_datasource.dart  # calls FastAPI
│       │   │   └── chat_local_datasource.dart   # Firestore/Supabase cache
│       │   └── repositories/
│       │       └── chat_repository_impl.dart
│       └── presentation/
│           ├── providers/
│           │   └── conversation_provider.dart   # Riverpod StateNotifier
│           ├── screens/
│           │   └── conversation_screen.dart
│           └── widgets/
│               ├── avatar_widget.dart           # Rive integration
│               ├── mic_button.dart
│               └── message_bubble.dart
├── features/
│   └── auth/
│       ├── domain/ data/ presentation/          # same pattern
└── shared/
    └── widgets/
assets/
├── animations/
│   └── avatar.riv
```

## Notes

- Keep `AvatarWidget` dumb — it only reacts to a `ConversationState` enum passed in, it doesn't know about FastAPI or Firestore
- `ConversationProvider` is the single source of truth: holds messages, current avatar state, and orchestrates STT → API call → TTS → state transitions
- Each `features/` module is self-contained; adding a new feature (e.g. `settings/`) never touches `conversation/`
