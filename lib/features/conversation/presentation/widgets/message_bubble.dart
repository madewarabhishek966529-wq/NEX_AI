import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme.dart';
import '../../domain/entities/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final String companionName;
  final VoidCallback? onSpeak;

  const MessageBubble({
    super.key,
    required this.message,
    required this.companionName,
    this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final timeStr = DateFormat('hh:mm a').format(message.timestamp);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primaryNeon.withValues(alpha: 0.15) : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: Border.all(
            color: isUser ? AppTheme.primaryNeon.withValues(alpha: 0.4) : AppTheme.surfaceBorder,
            width: 1,
          ),
          boxShadow: isUser
              ? [
                  BoxShadow(
                    color: AppTheme.primaryNeon.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUser ? Icons.person_rounded : Icons.auto_awesome_rounded,
                  size: 13,
                  color: isUser ? AppTheme.primaryNeon : AppTheme.secondaryNeon,
                ),
                const SizedBox(width: 4),
                Text(
                  isUser ? 'You' : companionName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isUser ? AppTheme.primaryNeon : AppTheme.secondaryNeon,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (message.text.isEmpty && !isUser)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.secondaryNeon),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Thinking...',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textMuted.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              )
            else
              SelectableText(
                message.text,
                style: const TextStyle(
                  fontSize: 14.5,
                  color: AppTheme.textPrimary,
                  height: 1.4,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: message.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Message copied to clipboard'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.copy_rounded, size: 14, color: AppTheme.textMuted),
                  ),
                ),
                if (!isUser && onSpeak != null) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: onSpeak,
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.volume_up_rounded, size: 14, color: AppTheme.accentCyan),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
