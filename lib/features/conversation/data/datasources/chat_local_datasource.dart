import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants.dart';
import '../../domain/entities/message.dart';

abstract class ChatLocalDataSource {
  Future<String?> getActiveConversationId();
  Future<void> saveActiveConversationId(String id);
  Future<String> getOrCreateUserId();
  Future<void> cacheMessages(String conversationId, List<Message> messages);
  Future<List<Message>> getCachedMessages(String conversationId);
  Future<void> clearCache(String conversationId);
}

class ChatLocalDataSourceImpl implements ChatLocalDataSource {
  final SharedPreferences prefs;

  ChatLocalDataSourceImpl(this.prefs);

  @override
  Future<String?> getActiveConversationId() async {
    return prefs.getString(AppConstants.keyActiveConversationId);
  }

  @override
  Future<void> saveActiveConversationId(String id) async {
    await prefs.setString(AppConstants.keyActiveConversationId, id);
  }

  @override
  Future<String> getOrCreateUserId() async {
    String? userId = prefs.getString(AppConstants.keyUserId);
    if (userId == null || userId.isEmpty) {
      userId = 'user_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
      await prefs.setString(AppConstants.keyUserId, userId);
    }
    return userId;
  }

  @override
  Future<void> cacheMessages(String conversationId, List<Message> messages) async {
    final list = messages.map((m) => m.toMap()).toList();
    final jsonStr = jsonEncode(list);
    await prefs.setString('messages_$conversationId', jsonStr);
  }

  @override
  Future<List<Message>> getCachedMessages(String conversationId) async {
    final jsonStr = prefs.getString('messages_$conversationId');
    if (jsonStr == null || jsonStr.isEmpty) {
      return [];
    }
    try {
      final list = jsonDecode(jsonStr) as List;
      return list.map((item) => Message.fromMap(Map<String, dynamic>.from(item as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> clearCache(String conversationId) async {
    await prefs.remove('messages_$conversationId');
  }
}
