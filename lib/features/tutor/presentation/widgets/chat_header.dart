import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/mock/tutor_inbox_mock.dart';
import 'package:tutora/shared/widgets/user_avatar.dart';

class ChatHeader extends StatelessWidget {
  const ChatHeader({required this.convo, required this.onMoreTap, super.key});

  final MockConversation convo;
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
          Stack(
            children: [
              UserAvatar(name: convo.name, size: 38),
              if (convo.online)
                Positioned(
                  bottom: 1,
                  right: 1,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.green,
                      border: Border.all(color: AppColors.cream, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  convo.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  convo.online ? 'Đang hoạt động' : convo.subject,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: convo.online ? AppColors.green : AppColors.ink4,
                  ),
                ),
              ],
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
