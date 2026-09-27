import '../entities/message.dart';
import '../repositories/chat_repository.dart';

class GetHistoryUseCase {
  final ChatRepository repository;

  GetHistoryUseCase(this.repository);

  Future<List<Message>> execute(String conversationId) {
    return repository.getHistory(conversationId);
  }
}
