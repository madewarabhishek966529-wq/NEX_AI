import '../repositories/chat_repository.dart';

class DeleteConversationUseCase {
  final ChatRepository repository;

  DeleteConversationUseCase(this.repository);

  Future<bool> execute(String conversationId) {
    return repository.deleteConversation(conversationId);
  }
}
