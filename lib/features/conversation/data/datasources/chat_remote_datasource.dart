import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/conversation.dart';

abstract class ChatRemoteDataSource {
  Future<String> createConversation(String userId, [String? title]);
  Future<String> sendMessage({
    required String userId,
    required String conversationId,
    required String message,
    String? companionName,
    String? tone,
    String? language,
    String? imageBase64,
  });
  Stream<String> streamMessage({
    required String userId,
    required String conversationId,
    required String message,
    String? companionName,
    String? tone,
    String? language,
    String? imageBase64,
  });
  Future<List<Message>> getHistory(String conversationId);
  Future<List<Conversation>> getUserConversations(String userId);
  Future<bool> deleteConversation(String conversationId);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final DioClient dioClient;

  ChatRemoteDataSourceImpl(this.dioClient);

  @override
  Future<String> createConversation(String userId, [String? title]) async {
    try {
      final response = await dioClient.dio.post(
        '/conversation/new',
        data: {
          'user_id': userId,
          'title': ?title,
        },
      );
      return response.data['conversation_id'] as String;
    } on DioException catch (e) {
      throw dioClient.handleError(e);
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
      final response = await dioClient.dio.post(
        '/chat',
        data: {
          'user_id': userId,
          'conversation_id': conversationId,
          'message': message,
          'companion_name': ?companionName,
          'tone': ?tone,
          'language': ?language,
          'image_base64': ?imageBase64,
        },
      );
      return response.data['response'] as String;
    } on DioException catch (e) {
      throw dioClient.handleError(e);
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
    try {
      final response = await dioClient.dio.post<ResponseBody>(
        '/chat/stream',
        data: {
          'user_id': userId,
          'conversation_id': conversationId,
          'message': message,
          'companion_name': ?companionName,
          'tone': ?tone,
          'language': ?language,
          'image_base64': ?imageBase64,
        },
        options: Options(responseType: ResponseType.stream),
      );

      final stream = response.data?.stream;
      if (stream == null) return;

      String buffer = '';
      await for (final chunk in stream) {
        final text = utf8.decode(chunk);
        buffer += text;
        final lines = buffer.split('\n');
        buffer = lines.removeLast();

        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.startsWith('data:')) {
            final dataStr = trimmed.substring(5).trim();
            if (dataStr.isNotEmpty) {
              try {
                final map = jsonDecode(dataStr);
                final token = map['token'] as String? ?? '';
                if (token.isNotEmpty) {
                  yield token;
                }
              } catch (_) {}
            }
          }
        }
      }
    } on DioException catch (e) {
      throw dioClient.handleError(e);
    }
  }

  @override
  Future<List<Message>> getHistory(String conversationId) async {
    try {
      final response = await dioClient.dio.get('/history/$conversationId');
      final data = response.data;
      if (data is Map && data.containsKey('messages')) {
        final list = data['messages'] as List;
        return list.map((item) => Message.fromMap(Map<String, dynamic>.from(item as Map))).toList();
      }
      return [];
    } on DioException catch (e) {
      throw dioClient.handleError(e);
    }
  }

  @override
  Future<List<Conversation>> getUserConversations(String userId) async {
    try {
      final response = await dioClient.dio.get('/conversations/$userId');
      final data = response.data;
      if (data is Map && data.containsKey('conversations')) {
        final list = data['conversations'] as List;
        return list.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          return Conversation(
            id: map['conversation_id']?.toString() ?? '',
            userId: userId,
            title: map['title']?.toString() ?? 'Conversation',
            summary: map['summary']?.toString() ?? '',
            createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
            updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
          );
        }).toList();
      }
      return [];
    } on DioException catch (e) {
      throw dioClient.handleError(e);
    }
  }

  @override
  Future<bool> deleteConversation(String conversationId) async {
    try {
      final response = await dioClient.dio.delete('/conversation/$conversationId');
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw dioClient.handleError(e);
    }
  }
}
