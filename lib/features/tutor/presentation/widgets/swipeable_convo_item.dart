import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/features/tutor/data/models/chat_models.dart';
import 'package:tutora/shared/widgets/user_avatar.dart';

class SwipeableConvoItem extends StatefulWidget {
  const SwipeableConvoItem({
    required this.channel,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  final ChatChannelDto channel;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  State<SwipeableConvoItem> createState() => _SwipeableConvoItemState();
}

class _SwipeableConvoItemState extends State<SwipeableConvoItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  static const double _revealWidth = 70;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _slide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-_revealWidth, 0),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _open() {
    unawaited(_ctrl.forward());
    setState(() => _revealed = true);
  }

  void _close() {
    unawaited(_ctrl.reverse());
    setState(() => _revealed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (d) {
        if (d.primaryVelocity != null) {
          if (d.primaryVelocity! < -200) _open();
          if (d.primaryVelocity! > 200) _close();
        }
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    _close();
                    widget.onDelete();
                  },
                  child: Container(
                    width: _revealWidth,
                    color: AppColors.oxblood,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Xoá',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _slide,
            builder: (_, child) =>
                Transform.translate(offset: _slide.value, child: child),
            child: _ConvoItem(
              channel: widget.channel,
              onTap: _revealed ? _close : widget.onTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConvoItem extends StatelessWidget {
  const _ConvoItem({required this.channel, required this.onTap});

  final ChatChannelDto channel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.cream,
          border: Border(
            bottom: BorderSide(color: AppColors.line, width: 0.8),
          ),
        ),
        child: Row(
          children: [
            UserAvatar(name: channel.otherUserName, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          channel.otherUserName,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      Text(
                        channel.formattedTime,
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 10,
                          color: AppColors.ink4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    channel.displayPreview,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: AppColors.ink4,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
