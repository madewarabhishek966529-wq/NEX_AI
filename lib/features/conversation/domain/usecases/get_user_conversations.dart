import '../entities/conversation.dart';
import '../repositories/chat_repository.dart';

class GetUserConversationsUseCase {
  final ChatRepository repository;

  GetUserConversationsUseCase(this.repository);

  Future<List<Conversation>> execute(String userId) {
    return repository.getUserConversations(userId);
  }
}
