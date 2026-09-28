import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../providers/conversation_provider.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/mic_button.dart';
import '../widgets/message_bubble.dart';
import '../widgets/audio_visualizer.dart';
import '../widgets/state_badge.dart';
import '../widgets/conversation_drawer.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({super.key});

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showChatHistory = false;

  final List<String> _quickPrompts = [
    'How are you feeling today?',
    'Tell me an interesting thought.',
    'I had a busy day, let\'s chat.',
    'What should we work on together?',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage([String? customText]) {
    final text = customText ?? _textController.text;
    if (text.trim().isEmpty) return;

    ref.read(conversationProvider.notifier).sendSpokenMessage(text.trim());
    _textController.clear();
    FocusScope.of(context).unfocus();

    Future.delayed(const Duration(milliseconds: 150), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    final convState = ref.watch(conversationProvider);
    final notifier = ref.read(conversationProvider.notifier);

    // Auto-scroll on new messages
    ref.listen<ConversationStateData>(conversationProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length) {
        Future.delayed(const Duration(milliseconds: 150), _scrollToBottom);
      }
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text(next.errorMessage!),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      drawer: const ConversationDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: 'Conversation Sessions',
            icon: const Icon(Icons.history_rounded, color: AppTheme.textPrimary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryNeon.withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.blur_on_rounded, color: AppTheme.primaryNeon, size: 20),
            ),
            const SizedBox(width: 8),
            Text(
              convState.companionName.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'New Conversation',
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: () => notifier.startFreshConversation(),
          ),
          IconButton(
            tooltip: _showChatHistory ? 'Show Avatar' : 'Show History',
            icon: Icon(_showChatHistory ? Icons.face_rounded : Icons.chat_bubble_outline_rounded),
            onPressed: () {
              setState(() {
                _showChatHistory = !_showChatHistory;
              });
            },
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top State Pill Badge
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: StateBadge(
                state: convState.avatarState,
                companionName: convState.companionName,
              ),
            ),

            // Main Display: Avatar stage OR Chat history
            Expanded(
              child: _showChatHistory
                  ? _buildChatHistoryView(convState)
                  : _buildAvatarStage(convState, notifier),
            ),

            // Live Transcript or Quick Starters
            if (!_showChatHistory) _buildTranscriptOrPrompts(convState),

            // Bottom Audio & Input Bar
            _buildBottomControls(convState, notifier),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarStage(ConversationStateData convState, ConversationNotifier notifier) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        // Animated Reactive Avatar
        AvatarWidget(
          state: convState.avatarState,
          size: 260,
          onTap: () => notifier.triggerReaction(),
        ),
        const SizedBox(height: 24),

        // Live Audio Equalizer Waveform
        AudioVisualizer(
          state: convState.avatarState,
          barCount: 20,
          height: 32,
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildChatHistoryView(ConversationStateData convState) {
    if (convState.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 54, color: AppTheme.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text(
              'No messages yet in this session.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap the microphone below to begin talking!',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: convState.messages.length,
      itemBuilder: (context, index) {
        final msg = convState.messages[index];
        return MessageBubble(
          message: msg,
          companionName: convState.companionName,
          onSpeak: () {
            // Replay assistant speech
            ref.read(conversationProvider.notifier).sendSpokenMessage(msg.text);
          },
        );
      },
    );
  }

  Widget _buildTranscriptOrPrompts(ConversationStateData convState) {
    // If user is actively speaking or live transcript is available
    if (convState.currentTranscript.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.mic, color: AppTheme.accentGreen, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                convState.currentTranscript,
                style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, fontStyle: FontStyle.italic),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    // Otherwise show quick starter suggestions
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _quickPrompts.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final prompt = _quickPrompts[index];
          return ActionChip(
            label: Text(prompt),
            labelStyle: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            backgroundColor: AppTheme.surfaceElevated,
            side: const BorderSide(color: AppTheme.surfaceBorder),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: () => _sendMessage(prompt),
          );
        },
      ),
    );
  }

  Widget _buildBottomControls(ConversationStateData convState, ConversationNotifier notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(
          top: BorderSide(color: AppTheme.surfaceBorder, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Text Input for hybrid typing
              Expanded(
                child: TextField(
                  controller: _textController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Talk or type to ${convState.companionName}...',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send_rounded, color: AppTheme.primaryNeon, size: 20),
                      onPressed: () => _sendMessage(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Glowing Voice Mic Button
              MicButton(
                isListening: convState.isListening,
                state: convState.avatarState,
                onPressed: () => notifier.toggleListening(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
