import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/mock/tutor_inbox_mock.dart';
import 'package:tutora/shared/widgets/user_avatar.dart';

class SwipeableConvoItem extends StatefulWidget {
  const SwipeableConvoItem({
    required this.convo,
    required this.onTap,
    required this.onHide,
    required this.onDelete,
    super.key,
  });

  final MockConversation convo;
  final VoidCallback onTap;
  final VoidCallback onHide;
  final VoidCallback onDelete;

  @override
  State<SwipeableConvoItem> createState() => _SwipeableConvoItemState();
}

class _SwipeableConvoItemState extends State<SwipeableConvoItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  static const _revealWidth = 140.0;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _slide =
        Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-_revealWidth, 0),
        ).animate(
          CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
        );
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
                    widget.onHide();
                  },
                  child: Container(
                    width: 70,
                    color: AppColors.ink3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.visibility_off_outlined,
                          size: 20,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ẩn',
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
                GestureDetector(
                  onTap: () {
                    _close();
                    widget.onDelete();
                  },
                  child: Container(
                    width: 70,
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
              convo: widget.convo,
              onTap: _revealed ? _close : widget.onTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConvoItem extends StatelessWidget {
  const _ConvoItem({required this.convo, required this.onTap});

  final MockConversation convo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasUnread = convo.unread > 0;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: hasUnread ? const Color(0xFFFDFCF8) : AppColors.cream,
          border: const Border(
            bottom: BorderSide(color: AppColors.line, width: 0.8),
          ),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                UserAvatar(name: convo.name, size: 46),
                if (convo.online)
                  Positioned(
                    bottom: 1,
                    right: 1,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.green,
                        border: Border.all(color: AppColors.cream, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          convo.name,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      Text(
                        convo.time,
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 10,
                          color: hasUnread ? AppColors.oxblood : AppColors.ink4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    convo.subject,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          convo.preview,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: hasUnread ? AppColors.ink2 : AppColors.ink4,
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.oxblood,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${convo.unread}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
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
