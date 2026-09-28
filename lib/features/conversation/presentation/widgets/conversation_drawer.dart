import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme.dart';
import '../providers/conversation_provider.dart';

class ConversationDrawer extends ConsumerWidget {
  const ConversationDrawer({super.key});

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convState = ref.watch(conversationProvider);
    final notifier = ref.read(conversationProvider.notifier);

    return Drawer(
      backgroundColor: AppTheme.background,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppTheme.surfaceBorder, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryNeon.withValues(alpha: 0.15),
                        ),
                        child: const Icon(Icons.blur_on_rounded, color: AppTheme.primaryNeon, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${convState.companionName.toUpperCase()} ARCHIVE',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const Text(
                              'Conversation Sessions',
                              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // New Chat Button
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      notifier.startFreshConversation();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryNeon.withValues(alpha: 0.2),
                            AppTheme.secondaryNeon.withValues(alpha: 0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryNeon.withValues(alpha: 0.5)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_comment_rounded, color: AppTheme.primaryNeon, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Start Fresh Conversation',
                            style: TextStyle(
                              color: AppTheme.primaryNeon,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Conversation Sessions List
            Expanded(
              child: convState.isLoadingConversations && convState.conversations.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryNeon, strokeWidth: 2),
                    )
                  : convState.conversations.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history_rounded, size: 48, color: AppTheme.textMuted.withValues(alpha: 0.4)),
                                const SizedBox(height: 12),
                                const Text(
                                  'No Past Conversations',
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Your chat sessions with memory will be saved here automatically.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          itemCount: convState.conversations.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final session = convState.conversations[index];
                            final isActive = session.id == convState.conversationId;

                            return Dismissible(
                              key: Key(session.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                              ),
                              onDismissed: (_) {
                                notifier.deleteConversation(session.id);
                              },
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).pop();
                                  notifier.switchConversation(session.id);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isActive ? AppTheme.surfaceElevated : AppTheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isActive ? AppTheme.primaryNeon : AppTheme.surfaceBorder,
                                      width: isActive ? 1.2 : 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Indicator circle
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isActive ? AppTheme.primaryNeon : AppTheme.textMuted.withValues(alpha: 0.3),
                                          boxShadow: isActive
                                              ? [
                                                  BoxShadow(
                                                    color: AppTheme.primaryNeon.withValues(alpha: 0.6),
                                                    blurRadius: 6,
                                                    spreadRadius: 1,
                                                  )
                                                ]
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(width: 10),

                                      // Title and subtitle snippet
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              session.title.isNotEmpty ? session.title : 'Conversation',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                                color: isActive ? Colors.white : AppTheme.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              session.summary.isNotEmpty ? session.summary : _formatTime(session.updatedAt),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Delete button
                                      IconButton(
                                        icon: const Icon(Icons.close_rounded, size: 16, color: AppTheme.textMuted),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Delete session',
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              backgroundColor: AppTheme.surfaceElevated,
                                              title: const Text('Delete Session?'),
                                              content: const Text(
                                                'This will permanently delete this conversation and its memory context.',
                                                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(ctx).pop(),
                                                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(ctx).pop();
                                                    notifier.deleteConversation(session.id);
                                                  },
                                                  child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
