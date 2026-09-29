import '../repositories/chat_repository.dart';

class SendMessageUseCase {
  final ChatRepository repository;

  SendMessageUseCase(this.repository);

  Future<String> execute({
    required String userId,
    required String conversationId,
    required String message,
    String? companionName,
    String? tone,
    String? language,
    String? imageBase64,
  }) {
    return repository.sendMessage(
      userId: userId,
      conversationId: conversationId,
      message: message,
      companionName: companionName,
      tone: tone,
      language: language,
      imageBase64: imageBase64,
    );
  }
}
