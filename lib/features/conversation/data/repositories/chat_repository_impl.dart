import 'dart:math';
import '../../domain/entities/message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';
import '../datasources/chat_local_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;
  final ChatLocalDataSource localDataSource;

  ChatRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<String> startNewConversation({required String userId, String? title}) async {
    try {
      final convId = await remoteDataSource.createConversation(userId, title);
      await localDataSource.saveActiveConversationId(convId);
      return convId;
    } catch (_) {
      // Offline fallback: generate local conversation ID
      final convId = 'conv_local_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
      await localDataSource.saveActiveConversationId(convId);
      return convId;
    }
  }

  @override
  Future<String> sendMessage({
    required String userId,
    required String conversationId,
    required String message,
    String? companionName,
    String? tone,
    String? language,
    String? imageBase64,
  }) async {
    try {
      final aiResponse = await remoteDataSource.sendMessage(
        userId: userId,
        conversationId: conversationId,
        message: message,
        companionName: companionName,
        tone: tone,
        language: language,
        imageBase64: imageBase64,
      );

      // Save/update local cache
      final currentCached = await localDataSource.getCachedMessages(conversationId);
      final updated = List<Message>.from(currentCached)
        ..add(Message(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}_u',
          role: 'user',
          text: message,
          timestamp: DateTime.now(),
          imageBase64: imageBase64,
        ))
        ..add(Message(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}_a',
          role: 'assistant',
          text: aiResponse,
          timestamp: DateTime.now(),
        ));
      await localDataSource.cacheMessages(conversationId, updated);

      return aiResponse;
    } catch (_) {
      // Offline fallback companion responses
      final fallbackResponse = _generateOfflineFallback(message, companionName ?? 'Aura', language);
      
      final currentCached = await localDataSource.getCachedMessages(conversationId);
      final updated = List<Message>.from(currentCached)
        ..add(Message(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}_u',
          role: 'user',
          text: message,
          timestamp: DateTime.now(),
          imageBase64: imageBase64,
        ))
        ..add(Message(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}_a',
          role: 'assistant',
          text: fallbackResponse,
          timestamp: DateTime.now(),
        ));
      await localDataSource.cacheMessages(conversationId, updated);

      return fallbackResponse;
    }
  }

  @override
  Stream<String> streamMessage({
    required String userId,
    required String conversationId,
    required String message,
    String? companionName,
    String? tone,
    String? language,
    String? imageBase64,
  }) async* {
    String accumulated = '';
    try {
      await for (final token in remoteDataSource.streamMessage(
        userId: userId,
        conversationId: conversationId,
        message: message,
        companionName: companionName,
        tone: tone,
        language: language,
        imageBase64: imageBase64,
      )) {
        accumulated += token;
        yield token;
      }
    } catch (_) {
      final fallback = _generateOfflineFallback(message, companionName ?? 'Aura', language);
      accumulated = fallback;
      final words = fallback.split(' ');
      for (int i = 0; i < words.length; i++) {
        yield i < words.length - 1 ? '${words[i]} ' : words[i];
        await Future.delayed(const Duration(milliseconds: 30));
      }
    }

    if (accumulated.isNotEmpty) {
      final currentCached = await localDataSource.getCachedMessages(conversationId);
      final updated = List<Message>.from(currentCached)
        ..add(Message(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}_u',
          role: 'user',
          text: message,
          timestamp: DateTime.now(),
          imageBase64: imageBase64,
        ))
        ..add(Message(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}_a',
          role: 'assistant',
          text: accumulated,
          timestamp: DateTime.now(),
        ));
      await localDataSource.cacheMessages(conversationId, updated);
    }
  }

  @override
  Future<List<Message>> getHistory(String conversationId) async {
    try {
      final remoteList = await remoteDataSource.getHistory(conversationId);
      if (remoteList.isNotEmpty) {
        await localDataSource.cacheMessages(conversationId, remoteList);
        return remoteList;
      }
    } catch (_) {
      // Fall through to local cache
    }
    return localDataSource.getCachedMessages(conversationId);
  }

  @override
  Future<List<Conversation>> getUserConversations(String userId) async {
    try {
      return await remoteDataSource.getUserConversations(userId);
    } catch (_) {
      final activeId = await localDataSource.getActiveConversationId();
      if (activeId != null) {
        final cached = await localDataSource.getCachedMessages(activeId);
        return [
          Conversation(
            id: activeId,
            userId: userId,
            title: cached.isNotEmpty ? cached.first.text : 'Current Session',
            messages: cached,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          )
        ];
      }
      return [];
    }
  }

  @override
  Future<bool> deleteConversation(String conversationId) async {
    await localDataSource.clearCache(conversationId);
    final activeId = await localDataSource.getActiveConversationId();
    if (activeId == conversationId) {
      await localDataSource.saveActiveConversationId('');
    }
    try {
      return await remoteDataSource.deleteConversation(conversationId);
    } catch (_) {
      return true;
    }
  }

  String _generateOfflineFallback(String input, String companionName, [String? language]) {
    final lower = input.toLowerCase().trim();
    final lang = language?.toLowerCase().trim() ?? 'en';

    if (lang == 'mr' || lang.contains('marathi')) {
      if (lower.contains('नमस्कार') || lower.contains('hello') || lower.contains('hi')) {
        return 'नमस्कार! आज तुमच्याशी बोलून खूप छान वाटले. सांगा, मी कशी मदत करू शकेन?';
      } else if (lower.contains('कसा') || lower.contains('कशी') || lower.contains('how are you')) {
        return 'मी एकदम उत्तम आहे! तुमच्यासोबत गप्पा मारायला खूप उत्सुक आहे. दिवस कसा चालला आहे?';
      } else if (lower.contains('bye') || lower.contains('काळजी') || lower.contains('night')) {
        return 'शुभ रात्री! काळजी घ्या, जेव्हा हवं तेव्हा मी इथेच तुमच्यासोबत आहे.';
      } else {
        final responses = [
          'मी तुमचे म्हणणे काळजीपूर्वक ऐकत आहे. याविषयी आणखी सांगा!',
          'खूप छान विचार आहे हा. पुढे काय करायचे ठरवले आहे?',
          'तुमच्याशी गप्पा मारायला मला खूप आवडते. बोला, काय विचार करत आहात?',
        ];
        return responses[Random().nextInt(responses.length)];
      }
    }

    if (lang == 'hi' || lang.contains('hindi')) {
      if (lower.contains('नमस्ते') || lower.contains('hello') || lower.contains('hi')) {
        return 'नमस्ते! आज आपसे बात करके बहुत खुशी हुई। बताइए, मैं आपकी क्या सहायता करूँ?';
      } else if (lower.contains('कैसे') || lower.contains('कैसी') || lower.contains('how are you')) {
        return 'मैं बिल्कुल ठीक हूँ और आपसे बातें करने के लिए उत्साहित हूँ! आपका दिन कैसा बीत रहा है?';
      } else if (lower.contains('bye') || lower.contains('अलविदा') || lower.contains('night')) {
        return 'शुभ रात्रि! अपना ध्यान रखें, जब भी बात करनी हो, मैं यहीं मौजूद हूँ।';
      } else {
        final responses = [
          'मैं आपकी बात बहुत ध्यान से सुन रहा हूँ। इसके बारे में थोड़ा और बताइए!',
          'यह तो बहुत दिलचस्प बात है। आगे का क्या विचार है?',
          'आपसे बात करके हमेशा नया सीखने को मिलता है। आप क्या सोच रहे हैं?',
        ];
        return responses[Random().nextInt(responses.length)];
      }
    }

    // Default English
    if (lower.contains('hello') || lower.contains('hi') || lower.contains('hey')) {
      return 'Hey there! Wonderful to hear from you today. How is everything going?';
    } else if (lower.contains('how are you')) {
      return 'I am feeling great and ready to talk with you! What have you been working on?';
    } else if (lower.contains('bye') || lower.contains('night')) {
      return 'Rest well! I will be right here whenever you want to talk again.';
    } else {
      final responses = [
        'I hear you! That sounds interesting, tell me more about it.',
        'I am listening closely. What do you feel like doing next?',
        'I appreciate you sharing that with me! Let\'s chat more about it.',
      ];
      return responses[Random().nextInt(responses.length)];
    }
  }
}
