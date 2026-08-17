import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/features/tutor/data/models/chat_models.dart';
import 'package:tutora/features/tutor/presentation/providers/chat_provider.dart';
import 'package:tutora/features/tutor/presentation/widgets/chat_header.dart';
import 'package:tutora/features/tutor/presentation/widgets/chat_more_menu.dart';
import 'package:tutora/features/tutor/presentation/widgets/message_bubble.dart';

class TutorChatPage extends ConsumerStatefulWidget {
  const TutorChatPage({required this.channel, super.key});

  final ChatChannelDto channel;

  @override
  ConsumerState<TutorChatPage> createState() => _TutorChatPageState();
}

class _TutorChatPageState extends ConsumerState<TutorChatPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollCtrl = ScrollController();
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
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        unawaited(
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          ),
        );
      }
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    unawaited(
      ref.read(chatRoomProvider(widget.channel.channelId).notifier).send(text),
    );
    _scrollToBottom();
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
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ChatMoreMenu(convoName: widget.channel.otherUserName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(chatRoomProvider(widget.channel.channelId));
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    // Scroll to bottom when new messages arrive
    ref.listen(chatRoomProvider(widget.channel.channelId), (prev, next) {
      if ((prev?.messages.length ?? 0) < next.messages.length) {
        _scrollToBottom();
      }
    });

    return GestureDetector(
      onTap: _focusNode.unfocus,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFFFAFAF7),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              ChatHeader(
                channel: widget.channel,
                onMoreTap: _showMoreMenu,
              ),

              // Typing indicator
              if (roomState.isTyping)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${widget.channel.otherUserName} đang nhắn...',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: AppColors.ink4,
                        ),
                      ),
                    ],
                  ),
                ),

              // Messages
              Expanded(
                child: roomState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                        itemCount: roomState.messages.length,
                        itemBuilder: (_, i) => MessageBubble(
                          msg: roomState.messages[i],
                          otherUserName: widget.channel.otherUserName,
                          currentUserId: roomState.currentUserId,
                        ),
                      ),
              ),

              // Quick replies
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

              // Input bar
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
                      const Padding(
                        padding: EdgeInsets.only(bottom: 9),
                        child: Icon(
                          Icons.add_circle_outline_rounded,
                          size: 24,
                          color: AppColors.ink4,
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
                            onChanged: (_) => ref
                                .read(
                                  chatRoomProvider(
                                    widget.channel.channelId,
                                  ).notifier,
                                )
                                .notifyTyping(),
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
