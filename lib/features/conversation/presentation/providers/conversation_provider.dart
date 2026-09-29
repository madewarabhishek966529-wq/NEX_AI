import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/send_message.dart';
import '../../domain/usecases/get_history.dart';
import '../../domain/usecases/start_new_conversation.dart';
import '../../domain/usecases/get_user_conversations.dart';
import '../../domain/usecases/delete_conversation.dart';
import '../../domain/usecases/stream_message.dart';
import '../../data/datasources/chat_remote_datasource.dart';
import '../../data/datasources/chat_local_datasource.dart';
import '../../data/repositories/chat_repository_impl.dart';

// ----------------- Dependency Injection Providers -----------------

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main()');
});

final dioClientProvider = Provider<DioClient>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final savedUrl = prefs.getString(AppConstants.keyBaseUrl);
  return DioClient(baseUrl: savedUrl);
});

final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ChatRemoteDataSourceImpl(dioClient);
});

final chatLocalDataSourceProvider = Provider<ChatLocalDataSource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ChatLocalDataSourceImpl(prefs);
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final remote = ref.watch(chatRemoteDataSourceProvider);
  final local = ref.watch(chatLocalDataSourceProvider);
  return ChatRepositoryImpl(remoteDataSource: remote, localDataSource: local);
});

final sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
  return SendMessageUseCase(ref.watch(chatRepositoryProvider));
});

final getHistoryUseCaseProvider = Provider<GetHistoryUseCase>((ref) {
  return GetHistoryUseCase(ref.watch(chatRepositoryProvider));
});

final startNewConversationUseCaseProvider = Provider<StartNewConversationUseCase>((ref) {
  return StartNewConversationUseCase(ref.watch(chatRepositoryProvider));
});

final getUserConversationsUseCaseProvider = Provider<GetUserConversationsUseCase>((ref) {
  return GetUserConversationsUseCase(ref.watch(chatRepositoryProvider));
});

final deleteConversationUseCaseProvider = Provider<DeleteConversationUseCase>((ref) {
  return DeleteConversationUseCase(ref.watch(chatRepositoryProvider));
});

final streamMessageUseCaseProvider = Provider<StreamMessageUseCase>((ref) {
  return StreamMessageUseCase(ref.watch(chatRepositoryProvider));
});

// ----------------- State Model -----------------

class ConversationStateData {
  final ConversationState avatarState;
  final List<Message> messages;
  final List<Conversation> conversations;
  final bool isLoadingConversations;
  final String? conversationId;
  final String? userId;
  final String currentTranscript;
  final bool isListening;
  final bool isSpeaking;
  final String? errorMessage;
  final String companionName;
  final CompanionTone companionTone;
  final bool isTtsEnabled;
  final AppLanguage selectedLanguage;
  final String? pendingImageBase64;
  final AuraTheme auraTheme;

  const ConversationStateData({
    this.avatarState = ConversationState.idle,
    this.messages = const [],
    this.conversations = const [],
    this.isLoadingConversations = false,
    this.conversationId,
    this.userId,
    this.currentTranscript = '',
    this.isListening = false,
    this.isSpeaking = false,
    this.errorMessage,
    this.companionName = AppConstants.defaultCompanionName,
    this.companionTone = AppConstants.defaultCompanionTone,
    this.isTtsEnabled = true,
    this.selectedLanguage = AppConstants.defaultLanguage,
    this.pendingImageBase64,
    this.auraTheme = AuraTheme.cyberCyan,
  });

  ConversationStateData copyWith({
    ConversationState? avatarState,
    List<Message>? messages,
    List<Conversation>? conversations,
    bool? isLoadingConversations,
    String? conversationId,
    String? userId,
    String? currentTranscript,
    bool? isListening,
    bool? isSpeaking,
    String? errorMessage,
    bool clearError = false,
    String? companionName,
    CompanionTone? companionTone,
    bool? isTtsEnabled,
    AppLanguage? selectedLanguage,
    String? pendingImageBase64,
    bool clearPendingImage = false,
    AuraTheme? auraTheme,
  }) {
    return ConversationStateData(
      avatarState: avatarState ?? this.avatarState,
      messages: messages ?? this.messages,
      conversations: conversations ?? this.conversations,
      isLoadingConversations: isLoadingConversations ?? this.isLoadingConversations,
      conversationId: conversationId ?? this.conversationId,
      userId: userId ?? this.userId,
      currentTranscript: currentTranscript ?? this.currentTranscript,
      isListening: isListening ?? this.isListening,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      companionName: companionName ?? this.companionName,
      companionTone: companionTone ?? this.companionTone,
      isTtsEnabled: isTtsEnabled ?? this.isTtsEnabled,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      pendingImageBase64: clearPendingImage ? null : (pendingImageBase64 ?? this.pendingImageBase64),
      auraTheme: auraTheme ?? this.auraTheme,
    );
  }
}

// ----------------- State Notifier -----------------

class ConversationNotifier extends StateNotifier<ConversationStateData> {
  final SendMessageUseCase sendMessageUseCase;
  final GetHistoryUseCase getHistoryUseCase;
  final StartNewConversationUseCase startNewConversationUseCase;
  final GetUserConversationsUseCase getUserConversationsUseCase;
  final DeleteConversationUseCase deleteConversationUseCase;
  final StreamMessageUseCase streamMessageUseCase;
  final ChatLocalDataSource localDataSource;
  final SharedPreferences prefs;

  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSttInitialized = false;
  bool _speechSubmitted = false;
  bool _isProcessingMessage = false;

  ConversationNotifier({
    required this.sendMessageUseCase,
    required this.getHistoryUseCase,
    required this.startNewConversationUseCase,
    required this.getUserConversationsUseCase,
    required this.deleteConversationUseCase,
    required this.streamMessageUseCase,
    required this.localDataSource,
    required this.prefs,
  }) : super(const ConversationStateData()) {
    _initTts();
    _loadInitialState();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage(state.selectedLanguage.ttsLocale);
      final rate = prefs.getDouble(AppConstants.keyTtsRate) ?? AppConstants.defaultTtsRate;
      final pitch = prefs.getDouble(AppConstants.keyTtsPitch) ?? AppConstants.defaultTtsPitch;
      await _tts.setSpeechRate(rate);
      await _tts.setPitch(pitch);
      await _tts.awaitSynthCompletion(true);

      _tts.setStartHandler(() {
        state = state.copyWith(
          isSpeaking: true,
          avatarState: ConversationState.speaking,
        );
      });

      _tts.setCompletionHandler(() {
        state = state.copyWith(
          isSpeaking: false,
          avatarState: ConversationState.idle,
        );
      });

      _tts.setCancelHandler(() {
        state = state.copyWith(
          isSpeaking: false,
          avatarState: ConversationState.idle,
        );
      });

      _tts.setErrorHandler((msg) {
        state = state.copyWith(
          isSpeaking: false,
          avatarState: ConversationState.idle,
        );
      });
    } catch (e) {
      debugPrint('TTS Init Error: $e');
    }
  }

  Future<void> _loadInitialState() async {
    final userId = await localDataSource.getOrCreateUserId();
    final companionName = prefs.getString(AppConstants.keyCompanionName) ?? AppConstants.defaultCompanionName;
    final toneStr = prefs.getString(AppConstants.keyCompanionTone) ?? AppConstants.defaultCompanionTone.value;
    final tone = CompanionToneX.fromString(toneStr);
    final autoSpeak = prefs.getBool(AppConstants.keyAutoSpeak) ?? true;
    final auraName = prefs.getString(AppConstants.keyAuraTheme);
    final auraTheme = AuraTheme.values.firstWhere(
      (e) => e.name == auraName,
      orElse: () => AuraTheme.cyberCyan,
    );
    final savedLangCode = prefs.getString(AppConstants.keyLanguage);
    final language = AppLanguageX.fromString(savedLangCode);

    var convId = await localDataSource.getActiveConversationId();
    if (convId == null || convId.isEmpty) {
      convId = await startNewConversationUseCase.execute(userId: userId);
      await localDataSource.saveActiveConversationId(convId);
    }

    final history = await getHistoryUseCase.execute(convId);

    state = state.copyWith(
      userId: userId,
      conversationId: convId,
      companionName: companionName,
      companionTone: tone,
      isTtsEnabled: autoSpeak,
      selectedLanguage: language,
      messages: history,
      avatarState: ConversationState.idle,
      auraTheme: auraTheme,
    );

    // Apply language to TTS
    try {
      await _tts.setLanguage(language.ttsLocale);
    } catch (_) {}

    loadUserConversations();
  }

  void updateAuraTheme(AuraTheme theme) {
    prefs.setString(AppConstants.keyAuraTheme, theme.name);
    state = state.copyWith(auraTheme: theme);
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final base64Str = base64Encode(bytes);
        state = state.copyWith(pendingImageBase64: base64Str);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void clearPendingImage() {
    state = state.copyWith(clearPendingImage: true);
  }

  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (_) {}
    state = state.copyWith(
      isSpeaking: false,
      avatarState: ConversationState.idle,
    );
  }

  Future<void> toggleListening() async {
    if (state.isSpeaking) {
      await stopSpeaking();
      await startListening();
      return;
    }
    if (state.isListening) {
      await stopListening();
    } else {
      await startListening();
    }
  }

  Future<void> startListening() async {
    // If TTS is talking, cancel it before user speaks
    if (state.isSpeaking) {
      await _tts.stop();
      state = state.copyWith(isSpeaking: false, avatarState: ConversationState.idle);
    }

    _speechSubmitted = false;

    try {
      bool isAvailable = _isSttInitialized;
      if (!isAvailable) {
        isAvailable = await _stt.initialize(
          onError: (val) {
            debugPrint('STT Error: ${val.errorMsg}');
            state = state.copyWith(
              isListening: false,
              avatarState: ConversationState.idle,
              errorMessage: val.errorMsg.isNotEmpty ? val.errorMsg : 'Speech recognition error',
            );
          },
          onStatus: (val) {
            debugPrint('STT Status: $val');
            if (val == 'done' || val == 'notListening') {
              _onSpeechSessionEnded();
            }
          },
        );
        _isSttInitialized = isAvailable;
      }

      if (_isSttInitialized) {
        state = state.copyWith(
          isListening: true,
          avatarState: ConversationState.listening,
          currentTranscript: '',
          clearError: true,
        );

        final targetLocale = state.selectedLanguage.sttLocale;
        debugPrint('STT Listening with locale: $targetLocale');

        await _stt.listen(
          onResult: (result) {
            final words = result.recognizedWords;
            state = state.copyWith(
              currentTranscript: words,
            );

            // If final result arrived and hasn't been submitted yet
            if (result.finalResult && words.trim().isNotEmpty && !_speechSubmitted) {
              _speechSubmitted = true;
              _stt.stop();
              sendSpokenMessage(words.trim());
            }
          },
          listenOptions: SpeechListenOptions(
            listenMode: ListenMode.dictation,
            cancelOnError: true,
            partialResults: true,
            localeId: targetLocale,
          ),
        );
      } else {
        state = state.copyWith(
          isListening: false,
          avatarState: ConversationState.idle,
          errorMessage: 'Speech recognition unavailable on this device.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isListening: false,
        avatarState: ConversationState.idle,
        errorMessage: 'Microphone permission or STT error: $e',
      );
    }
  }

  void _onSpeechSessionEnded() {
    if (state.isListening && !_speechSubmitted && state.currentTranscript.trim().isNotEmpty) {
      _speechSubmitted = true;
      final text = state.currentTranscript.trim();
      sendSpokenMessage(text);
    } else if (state.isListening && !_speechSubmitted) {
      state = state.copyWith(
        isListening: false,
        avatarState: ConversationState.idle,
      );
    }
  }

  Future<void> stopListening() async {
    try {
      await _stt.stop();
    } catch (_) {}

    final transcript = state.currentTranscript.trim();
    if (!_speechSubmitted && transcript.isNotEmpty) {
      _speechSubmitted = true;
      state = state.copyWith(
        isListening: false,
        avatarState: ConversationState.thinking,
      );
      await sendSpokenMessage(transcript);
    } else {
      state = state.copyWith(
        isListening: false,
        avatarState: ConversationState.idle,
      );
    }
  }

  Future<void> sendSpokenMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (_isProcessingMessage) return; // Prevent concurrent processing / duplicates
    _isProcessingMessage = true;

    final trimmed = text.trim();
    final convId = state.conversationId;
    final userId = state.userId;

    if (convId == null || userId == null) {
      _isProcessingMessage = false;
      return;
    }

    // Interrupt any ongoing speech
    if (state.isSpeaking) {
      try {
        await _tts.stop();
      } catch (_) {}
    }

    final image = state.pendingImageBase64;

    // 1. Add user message optimistically and initialize empty assistant message placeholder
    final userMsg = Message(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}_u',
      role: 'user',
      text: trimmed,
      timestamp: DateTime.now(),
      imageBase64: image,
    );

    final assistantMsgId = 'msg_${DateTime.now().millisecondsSinceEpoch}_a';
    final initialAssistantMsg = Message(
      id: assistantMsgId,
      role: 'assistant',
      text: '',
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg, initialAssistantMsg],
      currentTranscript: '',
      isListening: false,
      isSpeaking: false,
      avatarState: ConversationState.thinking,
      clearError: true,
      clearPendingImage: true,
    );

    try {
      // 2. Stream AI tokens chunk by chunk
      String accumulated = '';
      await for (final token in streamMessageUseCase.execute(
        userId: userId,
        conversationId: convId,
        message: trimmed,
        companionName: state.companionName,
        tone: state.companionTone.value,
        language: state.selectedLanguage.code,
        imageBase64: image,
      )) {
        accumulated += token;

        final updated = state.messages.map((m) {
          if (m.id == assistantMsgId) {
            return Message(
              id: m.id,
              role: m.role,
              text: accumulated,
              timestamp: m.timestamp,
            );
          }
          return m;
        }).toList();

        state = state.copyWith(
          messages: updated,
          avatarState: ConversationState.speaking,
          isSpeaking: true,
        );
      }

      // Refresh archive preview
      loadUserConversations();

      // 3. Voice output (TTS)
      if (state.isTtsEnabled && accumulated.trim().isNotEmpty) {
        try {
          await _tts.stop();
          await _tts.setLanguage(state.selectedLanguage.ttsLocale);
          await _tts.speak(accumulated.trim());

          // Safety timeout in case TTS engine never fires completion callback
          final wordCount = accumulated.trim().split(RegExp(r'\s+')).length;
          final estimatedMs = (wordCount * 450).clamp(2500, 15000);
          Future.delayed(Duration(milliseconds: estimatedMs), () {
            if (state.isSpeaking) {
              state = state.copyWith(
                isSpeaking: false,
                avatarState: ConversationState.idle,
              );
            }
          });
        } catch (ttsErr) {
          debugPrint('TTS Error: $ttsErr');
          state = state.copyWith(
            isSpeaking: false,
            avatarState: ConversationState.idle,
          );
        }
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
        state = state.copyWith(
          isSpeaking: false,
          avatarState: ConversationState.idle,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isListening: false,
        isSpeaking: false,
        avatarState: ConversationState.idle,
        errorMessage: e.toString(),
      );
    } finally {
      _isProcessingMessage = false;
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    await prefs.setString(AppConstants.keyLanguage, language.code);
    state = state.copyWith(selectedLanguage: language);
    try {
      await _tts.setLanguage(language.ttsLocale);
    } catch (e) {
      debugPrint('Error updating TTS language: $e');
    }
  }

  Future<void> loadUserConversations() async {
    final userId = state.userId;
    if (userId == null) return;
    state = state.copyWith(isLoadingConversations: true);
    try {
      final list = await getUserConversationsUseCase.execute(userId);
      state = state.copyWith(conversations: list, isLoadingConversations: false);
    } catch (_) {
      state = state.copyWith(isLoadingConversations: false);
    }
  }

  Future<void> switchConversation(String conversationId) async {
    if (state.conversationId == conversationId) return;
    await _tts.stop();
    state = state.copyWith(
      conversationId: conversationId,
      messages: [],
      avatarState: ConversationState.thinking,
      isSpeaking: false,
      isListening: false,
    );
    await localDataSource.saveActiveConversationId(conversationId);
    final history = await getHistoryUseCase.execute(conversationId);
    state = state.copyWith(
      messages: history,
      avatarState: ConversationState.idle,
    );
    loadUserConversations();
  }

  Future<void> deleteConversation(String conversationId) async {
    await deleteConversationUseCase.execute(conversationId);
    if (state.conversationId == conversationId) {
      await startFreshConversation();
    } else {
      await loadUserConversations();
    }
  }

  Future<void> startFreshConversation() async {
    final userId = state.userId;
    if (userId == null) return;

    await _tts.stop();
    state = state.copyWith(
      avatarState: ConversationState.thinking,
      isSpeaking: false,
      isListening: false,
    );

    final newConvId = await startNewConversationUseCase.execute(userId: userId);
    await localDataSource.saveActiveConversationId(newConvId);

    state = state.copyWith(
      conversationId: newConvId,
      messages: [],
      avatarState: ConversationState.idle,
      currentTranscript: '',
    );

    loadUserConversations();
  }

  void triggerReaction() {
    state = state.copyWith(avatarState: ConversationState.reacting);
    Future.delayed(const Duration(seconds: 3), () {
      if (state.avatarState == ConversationState.reacting) {
        state = state.copyWith(avatarState: ConversationState.idle);
      }
    });
  }

  void updateCompanionSettings({
    String? name,
    CompanionTone? tone,
    bool? ttsEnabled,
    AppLanguage? language,
  }) {
    if (name != null) {
      prefs.setString(AppConstants.keyCompanionName, name);
    }
    if (tone != null) {
      prefs.setString(AppConstants.keyCompanionTone, tone.value);
    }
    if (ttsEnabled != null) {
      prefs.setBool(AppConstants.keyAutoSpeak, ttsEnabled);
    }
    if (language != null) {
      prefs.setString(AppConstants.keyLanguage, language.code);
      _tts.setLanguage(language.ttsLocale);
    }

    state = state.copyWith(
      companionName: name ?? state.companionName,
      companionTone: tone ?? state.companionTone,
      isTtsEnabled: ttsEnabled ?? state.isTtsEnabled,
      selectedLanguage: language ?? state.selectedLanguage,
    );
  }

  @override
  void dispose() {
    _tts.stop();
    _stt.stop();
    super.dispose();
  }
}

final conversationProvider = StateNotifierProvider<ConversationNotifier, ConversationStateData>((ref) {
  return ConversationNotifier(
    sendMessageUseCase: ref.watch(sendMessageUseCaseProvider),
    getHistoryUseCase: ref.watch(getHistoryUseCaseProvider),
    startNewConversationUseCase: ref.watch(startNewConversationUseCaseProvider),
    getUserConversationsUseCase: ref.watch(getUserConversationsUseCaseProvider),
    deleteConversationUseCase: ref.watch(deleteConversationUseCaseProvider),
    streamMessageUseCase: ref.watch(streamMessageUseCaseProvider),
    localDataSource: ref.watch(chatLocalDataSourceProvider),
    prefs: ref.watch(sharedPreferencesProvider),
  );
});
