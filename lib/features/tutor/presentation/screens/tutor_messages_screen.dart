import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_chat_page.dart';
import 'package:tutora/features/tutor/presentation/widgets/swipeable_convo_item.dart';
import 'package:tutora/mock/tutor_inbox_mock.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

class TutorMessagesScreen extends StatefulWidget {
  const TutorMessagesScreen({super.key});

  @override
  State<TutorMessagesScreen> createState() => _TutorMessagesScreenState();
}

class _TutorMessagesScreenState extends State<TutorMessagesScreen> {
  String _search = '';
  late List<MockConversation> _convos;

  @override
  void initState() {
    super.initState();
    _convos = List.from(kTutorConversations);
  }

  List<MockConversation> get _filtered {
    if (_search.isEmpty) return _convos;
    final q = _search.toLowerCase();
    return _convos
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.subject.toLowerCase().contains(q),
        )
        .toList();
  }

  void _openChat(MockConversation convo) {
    unawaited(
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(builder: (_) => TutorChatPage(convo: convo)),
      ),
    );
  }

  void _hideConvo(MockConversation convo) {
    setState(() => _convos.removeWhere((c) => c.id == convo.id));
    AppToast.show(
      context,
      message: 'Đã ẩn cuộc trò chuyện với ${convo.name}',
      actionLabel: 'Hoàn tác',
      onAction: () => setState(() {
        final idx = kTutorConversations.indexWhere((c) => c.id == convo.id);
        _convos.insert(idx.clamp(0, _convos.length), convo);
      }),
    );
  }

  void _deleteConvo(MockConversation convo) {
    setState(() => _convos.removeWhere((c) => c.id == convo.id));
    AppToast.show(
      context,
      message: 'Đã xoá cuộc trò chuyện với ${convo.name}',
      type: AppToastType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(child: Text('Tin nhắn', style: AppTextStyles.h2())),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.paper,
                        border: Border.all(color: AppColors.line),
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cream2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.search_rounded,
                      size: 16,
                      color: AppColors.ink4,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _search = v),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.ink,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: 'Tìm kiếm hội thoại...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.ink4,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: Row(
                children: [
                  Text('GẦN ĐÂY', style: AppTextStyles.eyebrow()),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Divider(color: AppColors.line, height: 1),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text(
                        'Không tìm thấy hội thoại nào.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.ink3,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.only(
                        bottom: bottomPad + AppSpacing.xxl,
                      ),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final convo = _filtered[i];
                        return SwipeableConvoItem(
                          key: ValueKey(convo.id),
                          convo: convo,
                          onTap: () => _openChat(convo),
                          onHide: () => _hideConvo(convo),
                          onDelete: () => _deleteConvo(convo),
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
