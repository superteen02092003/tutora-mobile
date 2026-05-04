import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/features/tutor/presentation/widgets/chat_header.dart';
import 'package:tutora/features/tutor/presentation/widgets/chat_more_menu.dart';
import 'package:tutora/features/tutor/presentation/widgets/message_bubble.dart';
import 'package:tutora/mock/tutor_inbox_mock.dart';

class TutorChatPage extends StatefulWidget {
  const TutorChatPage({required this.convo, super.key});

  final MockConversation convo;

  @override
  State<TutorChatPage> createState() => _TutorChatPageState();
}

class _TutorChatPageState extends State<TutorChatPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollCtrl = ScrollController();
  final List<MockChatMessage> _msgs = List.from(kTutorChatMessages);
  bool _canSend = false;

  static const _quickReplies = [
    'Thầy có thể dạy thứ 6',
    'Em đặt lịch nhé',
    'OK, thầy ghi nhận',
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final can = _controller.text.trim().isNotEmpty;
      if (can != _canSend) setState(() => _canSend = can);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      unawaited(
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        ),
      );
    }
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _msgs.add(
        MockChatMessage(
          id: DateTime.now().millisecondsSinceEpoch,
          sender: MessageSender.me,
          text: text,
          time: 'Vừa xong',
        ),
      );
    });
    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _quickReply(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
    _focusNode.requestFocus();
  }

  void _showMoreMenu() {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => ChatMoreMenu(convoName: widget.convo.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return GestureDetector(
      onTap: _focusNode.unfocus,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFFFAFAF7),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              ChatHeader(convo: widget.convo, onMoreTap: _showMoreMenu),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Divider(color: AppColors.line, height: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Hôm nay, 02/05',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink4,
                          letterSpacing: 0.06,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(color: AppColors.line, height: 1),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                  itemCount: _msgs.length,
                  itemBuilder: (_, i) =>
                      MessageBubble(msg: _msgs[i], convo: widget.convo),
                ),
              ),
              // ── Quick replies ──
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: _quickReplies.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => _quickReply(_quickReplies[i]),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Text(
                        _quickReplies[i],
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // ── Input bar ──
              AnimatedPadding(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(
                  bottom: bottomInset > 0 ? bottomInset : bottomPad,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.cream,
                    border: Border(
                      top: BorderSide(color: AppColors.line, width: 0.8),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {},
                        child: const Padding(
                          padding: EdgeInsets.only(bottom: 9),
                          child: Icon(
                            Icons.add_circle_outline_rounded,
                            size: 24,
                            color: AppColors.ink4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(
                            minHeight: 40,
                            maxHeight: 120,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cream2,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            minLines: 1,
                            maxLines: 5,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              color: AppColors.ink,
                              height: 1.4,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              hintText: 'Nhắn tin...',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 13.5,
                                color: AppColors.ink4,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _canSend ? _send : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _canSend ? AppColors.ink : AppColors.line,
                          ),
                          child: Icon(
                            Icons.send_rounded,
                            size: 16,
                            color: _canSend ? AppColors.cream : AppColors.ink4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
