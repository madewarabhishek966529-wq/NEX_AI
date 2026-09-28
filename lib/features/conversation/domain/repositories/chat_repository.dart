import '../entities/message.dart';
import '../entities/conversation.dart';

abstract class ChatRepository {
  /// Creates a new conversation session
  Future<String> startNewConversation({
    required String userId,
    String? title,
  });

  /// Sends a user message to the AI companion and returns the generated speech text response
  Future<String> sendMessage({
    required String userId,
    required String conversationId,
    required String message,
    String? companionName,
    String? tone,
    String? imageBase64,
  });

  /// Streams generated speech text response chunk by chunk
  Stream<String> streamMessage({
    required String userId,
    required String conversationId,
    required String message,
    String? companionName,
    String? tone,
    String? imageBase64,
  });

  /// Retrieves the message history for a given conversation
  Future<List<Message>> getHistory(String conversationId);

  /// Retrieves all conversation sessions belonging to the user
  Future<List<Conversation>> getUserConversations(String userId);

  /// Deletes a conversation session
  Future<bool> deleteConversation(String conversationId);
}
