import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../core/constants.dart';
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

    // Auto-scroll on new messages and live speech transcription into textfield
    ref.listen<ConversationStateData>(conversationProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length) {
        Future.delayed(const Duration(milliseconds: 150), _scrollToBottom);
      }
      // When user speaks to mic, automatically enter live text to textfield!
      if (next.isListening && next.currentTranscript.isNotEmpty && next.currentTranscript != _textController.text) {
        _textController.text = next.currentTranscript;
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: _textController.text.length),
        );
      }
      // When speech finalizes and is submitted, clear the text field
      if (prev?.isListening == true && !next.isListening && next.currentTranscript.isEmpty && _textController.text.isNotEmpty) {
        _textController.clear();
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
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryNeon.withValues(alpha: 0.35),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/icons/app_logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              convState.companionName.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          ],
        ),
        actions: [
          // Language Switcher Chip in AppBar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showLanguageSelector(context, convState.selectedLanguage, notifier),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(convState.selectedLanguage.flag, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      convState.selectedLanguage.nativeName,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 14, color: AppTheme.textSecondary),
                  ],
                ),
              ),
            ),
          ),
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
          auraTheme: convState.auraTheme,
          size: 260,
          onTap: () {
            if (convState.isSpeaking) {
              notifier.stopSpeaking();
            } else {
              notifier.triggerReaction();
            }
          },
        ),
        const SizedBox(height: 20),

        // Live Audio Equalizer Waveform
        AudioVisualizer(
          state: convState.avatarState,
          barCount: 20,
          height: 32,
        ),
        const SizedBox(height: 12),

        // Interrupt Speech Pill
        if (convState.isSpeaking)
          TextButton.icon(
            onPressed: () => notifier.stopSpeaking(),
            icon: const Icon(Icons.stop_circle_rounded, color: Color(0xFFEF4444), size: 16),
            label: const Text(
              'Tap to interrupt speech',
              style: TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            ),
          )
        else
          const SizedBox(height: 32),

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pending image preview chip
          if (convState.pendingImageBase64 != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.memory(
                      base64Decode(convState.pendingImageBase64!),
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Vision image attached',
                    style: TextStyle(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16, color: AppTheme.textMuted),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Remove Image',
                    onPressed: () => notifier.clearPendingImage(),
                  ),
                ],
              ),
            ),

          // Active Listening Banner: Confirms microphone is actively listening and shows language
          if (convState.isListening)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFEF4444)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Listening in ${convState.selectedLanguage.displayName}... (Words type into textfield below)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEF4444),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () => _showLanguageSelector(context, convState.selectedLanguage, notifier),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'Change Lang',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.accentCyan,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Row(
            children: [
              // Text Input for hybrid typing
              Expanded(
                child: TextField(
                  controller: _textController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: convState.isListening
                        ? 'Listening to your voice...'
                        : 'Talk or type to ${convState.companionName} (${convState.selectedLanguage.nativeName})...',
                    prefixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.camera_alt_outlined, size: 20, color: AppTheme.textSecondary),
                          tooltip: 'Camera ("See what I see")',
                          onPressed: () => notifier.pickImage(ImageSource.camera),
                        ),
                        IconButton(
                          icon: const Icon(Icons.photo_library_outlined, size: 20, color: AppTheme.textSecondary),
                          tooltip: 'Photo Library',
                          onPressed: () => notifier.pickImage(ImageSource.gallery),
                        ),
                      ],
                    ),
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

  void _showLanguageSelector(BuildContext context, AppLanguage currentLang, ConversationNotifier notifier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.translate_rounded, color: AppTheme.primaryNeon, size: 22),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Voice & Chat Language',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                            Text(
                              'भाषा निवडा / भाषा चुनें / Choose Language',
                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20, color: AppTheme.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppTheme.surfaceBorder, height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    children: [
                      // Indian Languages Section
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        child: Text(
                          'INDIAN REGIONAL LANGUAGES (भारतीय भाषा)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: AppTheme.primaryNeon,
                          ),
                        ),
                      ),
                      _buildLanguageTile(ctx, AppLanguage.marathi, currentLang, notifier),
                      _buildLanguageTile(ctx, AppLanguage.hindi, currentLang, notifier),
                      _buildLanguageTile(ctx, AppLanguage.englishIN, currentLang, notifier),
                      _buildLanguageTile(ctx, AppLanguage.gujarati, currentLang, notifier),
                      _buildLanguageTile(ctx, AppLanguage.tamil, currentLang, notifier),
                      _buildLanguageTile(ctx, AppLanguage.telugu, currentLang, notifier),
                      _buildLanguageTile(ctx, AppLanguage.bengali, currentLang, notifier),
                      _buildLanguageTile(ctx, AppLanguage.kannada, currentLang, notifier),
                      _buildLanguageTile(ctx, AppLanguage.malayalam, currentLang, notifier),

                      const SizedBox(height: 16),
                      // Global Languages Section
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        child: Text(
                          'GLOBAL LANGUAGES',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: AppTheme.primaryNeon,
                          ),
                        ),
                      ),
                      _buildLanguageTile(ctx, AppLanguage.englishUS, currentLang, notifier),
                      _buildLanguageTile(ctx, AppLanguage.spanish, currentLang, notifier),
                      _buildLanguageTile(ctx, AppLanguage.french, currentLang, notifier),
                      _buildLanguageTile(ctx, AppLanguage.german, currentLang, notifier),
                      _buildLanguageTile(ctx, AppLanguage.japanese, currentLang, notifier),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLanguageTile(
    BuildContext ctx,
    AppLanguage language,
    AppLanguage currentLanguage,
    ConversationNotifier notifier,
  ) {
    final isSelected = language == currentLanguage;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryNeon.withValues(alpha: 0.1) : AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? AppTheme.primaryNeon : AppTheme.surfaceBorder,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(language.flag, style: const TextStyle(fontSize: 18)),
        ),
        title: Text(
          language.nativeName,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isSelected ? AppTheme.primaryNeon : AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          '${language.displayName} • STT: ${language.sttLocale}',
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryNeon, size: 20)
            : const Icon(Icons.radio_button_unchecked_rounded, color: AppTheme.textMuted, size: 18),
        onTap: () {
          notifier.setLanguage(language);
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.accentGreen,
              duration: const Duration(seconds: 2),
              content: Row(
                children: [
                  Text(language.flag, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text('Language switched to ${language.displayName}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
