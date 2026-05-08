import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/features/tutor/data/models/chat_models.dart';
import 'package:tutora/shared/widgets/user_avatar.dart';

class ChatHeader extends StatelessWidget {
  const ChatHeader({
    required this.channel,
    required this.onMoreTap,
    super.key,
  });

  final ChatChannelDto channel;
  final VoidCallback onMoreTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 0.8)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.paper,
                border: Border.all(color: AppColors.line),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 14,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 10),
          UserAvatar(name: channel.otherUserName, size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              channel.otherUserName,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          GestureDetector(
            onTap: onMoreTap,
            child: const Icon(
              Icons.more_vert_rounded,
              size: 22,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
