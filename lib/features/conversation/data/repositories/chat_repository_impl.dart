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
  }) async {
    try {
      final aiResponse = await remoteDataSource.sendMessage(
        userId: userId,
        conversationId: conversationId,
        message: message,
        companionName: companionName,
        tone: tone,
      );

      // Save/update local cache
      final currentCached = await localDataSource.getCachedMessages(conversationId);
      final updated = List<Message>.from(currentCached)
        ..add(Message(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}_u',
          role: 'user',
          text: message,
          timestamp: DateTime.now(),
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
      final fallbackResponse = _generateOfflineFallback(message, companionName ?? 'Aura');
      
      final currentCached = await localDataSource.getCachedMessages(conversationId);
      final updated = List<Message>.from(currentCached)
        ..add(Message(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}_u',
          role: 'user',
          text: message,
          timestamp: DateTime.now(),
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

  String _generateOfflineFallback(String input, String companionName) {
    final lower = input.toLowerCase().trim();
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
