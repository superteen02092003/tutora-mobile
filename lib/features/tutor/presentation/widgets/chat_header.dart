import 'package:flutter/material.dart';
import 'package:tutora/features/tutor/data/models/chat_models.dart';
import 'package:tutora/features/tutor/presentation/widgets/tutor_ui.dart';

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
    return TutorChildHeader(
      title: channel.otherUserName,
      action: IconButton(
        onPressed: onMoreTap,
        tooltip: 'Tùy chọn cuộc trò chuyện',
        icon: const Icon(Icons.more_vert_rounded, size: 22),
      ),
    );
  }
}
