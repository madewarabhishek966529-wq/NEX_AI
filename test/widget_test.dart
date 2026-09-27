import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nex_ai/main.dart';
import 'package:nex_ai/core/constants.dart';
import 'package:nex_ai/features/conversation/domain/entities/conversation.dart';
import 'package:nex_ai/features/conversation/domain/entities/message.dart';
import 'package:nex_ai/features/conversation/domain/repositories/chat_repository.dart';
import 'package:nex_ai/features/conversation/presentation/providers/conversation_provider.dart';

class FakeChatRepository implements ChatRepository {
  @override
  Future<List<Message>> getHistory(String conversationId) async => [];

  @override
  Future<List<Conversation>> getUserConversations(String userId) async => [];

  @override
  Future<String> sendMessage({
    required String userId,
    required String conversationId,
    required String message,
    String? companionName,
    String? tone,
  }) async => 'Hello from fake companion';

  @override
  Future<String> startNewConversation({required String userId, String? title}) async => 'conv_test_123';
}

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      AppConstants.keyActiveConversationId: 'conv_test_123',
      AppConstants.keyUserId: 'user_test',
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          chatRepositoryProvider.overrideWithValue(FakeChatRepository()),
        ],
        child: const NexAiApp(),
      ),
    );

    await tester.pump();

    expect(find.byType(NexAiApp), findsOneWidget);
  });
}
