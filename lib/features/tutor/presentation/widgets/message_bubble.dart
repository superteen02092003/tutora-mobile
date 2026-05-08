import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/features/tutor/data/models/chat_models.dart';
import 'package:tutora/shared/widgets/user_avatar.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    required this.msg,
    required this.otherUserName,
    required this.currentUserId,
    super.key,
  });

  final ChatMessageDto msg;
  final String otherUserName;
  final String currentUserId;

  bool get _isMe => msg.senderId == currentUserId;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.72;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: _isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!_isMe) ...[
            UserAvatar(name: otherUserName, size: 26),
            const SizedBox(width: 8),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: _isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (msg.isImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      msg.content,
                      width: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.ink4,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: _isMe ? AppColors.ink : AppColors.paper,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(_isMe ? 16 : 4),
                        bottomRight: Radius.circular(_isMe ? 4 : 16),
                      ),
                      border: _isMe ? null : Border.all(color: AppColors.line),
                      boxShadow: _isMe
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                    ),
                    child: Text(
                      msg.content,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: _isMe ? AppColors.cream : AppColors.ink,
                        height: 1.5,
                      ),
                    ),
                  ),
                const SizedBox(height: 3),
                Text(
                  msg.formattedTime,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 9.5,
                    color: AppColors.ink4,
                  ),
                ),
              ],
            ),
          ),
          if (_isMe) const SizedBox(width: 2),
        ],
      ),
    );
  }
}
