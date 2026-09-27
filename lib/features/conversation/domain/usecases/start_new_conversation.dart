import '../repositories/chat_repository.dart';

class StartNewConversationUseCase {
  final ChatRepository repository;

  StartNewConversationUseCase(this.repository);

  Future<String> execute({
    required String userId,
    String? title,
  }) {
    return repository.startNewConversation(
      userId: userId,
      title: title,
    );
  }
}
