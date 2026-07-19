import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/features/student/data/models/ai_chat_models.dart';
import 'package:tutora/features/student/presentation/providers/ai_solve_provider.dart';
import 'package:tutora/shared/widgets/math_text.dart';

class StudentSolveChatPage extends ConsumerStatefulWidget {
  const StudentSolveChatPage({super.key, this.imageBytes, this.openSessionId});

  final Uint8List? imageBytes;
  final String? openSessionId;

  @override
  ConsumerState<StudentSolveChatPage> createState() =>
      _StudentSolveChatPageState();
}

class _StudentSolveChatPageState extends ConsumerState<StudentSolveChatPage> {
  final _scrollCtrl = ScrollController();
  final _inputCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(solveChatProvider.notifier);
      if (widget.openSessionId != null) {
        unawaited(notifier.openSession(widget.openSessionId!));
      } else if (widget.imageBytes != null) {
        unawaited(notifier.startWithImage(base64Encode(widget.imageBytes!)));
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _inputCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollCtrl.hasClients) return;
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

  /// Gửi nội dung đang gõ trong ô nhập (nút gửi / phím Enter).
  void _sendCurrent() => _sendText(_inputCtrl.text);

  void _sendText(String text) {
    if (text.trim().isEmpty) return;
    _inputCtrl.clear();
    FocusScope.of(context).unfocus();
    unawaited(ref.read(solveChatProvider.notifier).sendFollowUp(text));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(solveChatProvider);
    ref.listen<SolveChatState>(
      solveChatProvider,
      (_, _) => _scrollToBottom(),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(child: _buildBody(state)),
          _QuickActions(
            visible:
                state.status == ChatStatus.ready && state.messages.isNotEmpty,
            onTap: _sendText,
          ),
          _InputBar(
            controller: _inputCtrl,
            enabled: state.canSend,
            onSend: _sendCurrent,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        color: AppColors.ink,
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: AppColors.oxblood,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Tutora',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
      centerTitle: true,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(0.5),
        child: Divider(height: 0.5, color: AppColors.line2),
      ),
    );
  }

  Widget _buildBody(SolveChatState state) {
    if (state.status == ChatStatus.loadingSession) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.oxblood),
      );
    }
    if (state.status == ChatStatus.error && state.messages.isEmpty) {
      return _ErrorView(
        message: state.error ?? 'Có lỗi xảy ra',
        onRetry: () {
          if (widget.imageBytes != null) {
            unawaited(
              ref
                  .read(solveChatProvider.notifier)
                  .startWithImage(base64Encode(widget.imageBytes!)),
            );
          } else if (widget.openSessionId != null) {
            unawaited(
              ref
                  .read(solveChatProvider.notifier)
                  .openSession(widget.openSessionId!),
            );
          }
        },
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        // Ảnh đề bài nằm trong chính user message (localImage) -> _UserBubble lo.
        final msg = state.messages[index];
        return msg.isUser ? _UserBubble(message: msg) : _AiBubble(message: msg);
      },
    );
  }
}

// Bong bóng của user (ảnh đề và/hoặc text)
class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.message});
  final AiChatMessage message;

  // Content placeholder khi user gửi ảnh -> không hiện dưới dạng text.
  static bool _isPlaceholder(String c) {
    final t = c.trim();
    return t.isEmpty || t == '[hình ảnh]';
  }

  @override
  Widget build(BuildContext context) {
    final showText = !_isPlaceholder(message.content);
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (message.localImage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8, left: 48),
              constraints: const BoxConstraints(maxWidth: 240),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.memory(message.localImage!, fit: BoxFit.cover),
            ),
          if (showText)
            Container(
              margin: const EdgeInsets.only(bottom: 14, left: 48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: const BoxDecoration(
                color: AppColors.oxblood,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Text(
                message.content,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.4,
                  color: Colors.white,
                ),
              ),
            )
          else if (message.localImage == null)
            // History cũ: chỉ có "[hình ảnh]" nhưng không còn ảnh -> chip nhẹ.
            Container(
              margin: const EdgeInsets.only(bottom: 14, left: 48),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.oxblood.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.image_outlined,
                    size: 16,
                    color: AppColors.oxblood,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Ảnh đề bài',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.oxblood,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// Bong bóng lời giải AI
class _AiBubble extends StatelessWidget {
  const _AiBubble({required this.message});
  final AiChatMessage message;

  @override
  Widget build(BuildContext context) {
    final empty = message.content.trim().isEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 20, top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nhãn "Tutora" nhỏ phía trên lời giải.
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: AppColors.oxblood,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 11,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  'Tutora',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink3,
                  ),
                ),
              ],
            ),
          ),
          if (empty && message.isStreaming)
            const _TypingDots()
          else ...[
            SolutionMarkdown(text: message.content),
            if (message.isStreaming) ...const [
              SizedBox(height: 8),
              _TypingDots(),
            ],
          ],
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    unawaited(_ctrl.repeat());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final t = (_ctrl.value - i * 0.2) % 1.0;
          final scale = 0.6 + 0.4 * (t < 0.5 ? t * 2 : (1 - t) * 2);
          return Container(
            margin: const EdgeInsets.only(right: 5),
            width: 7 * scale,
            height: 7 * scale,
            decoration: const BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }
}

// Quick-action chips (bấm nhanh, không phải gõ)
class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.visible, required this.onTap});
  final bool visible;
  final void Function(String) onTap;

  // (icon, nhãn hiển thị, câu gửi cho AI)
  static const _actions = <(IconData, String, String)>[
    (
      Icons.lightbulb_outline_rounded,
      'Giải thích kỹ hơn',
      'Giải thích kỹ hơn bước vừa rồi giúp mình',
    ),
    (Icons.autorenew_rounded, 'Cách khác', 'Có cách giải nào khác không?'),
    (
      Icons.assignment_outlined,
      'Bài tương tự',
      'Cho mình một bài tương tự để luyện tập',
    ),
    (
      Icons.short_text_rounded,
      'Ngắn gọn',
      'Tóm tắt lời giải thật ngắn gọn giúp mình',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _actions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (icon, label, prompt) = _actions[i];
          return Center(
            child: GestureDetector(
              onTap: () => onTap(prompt),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 15, color: AppColors.ink3),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Thanh nhập
class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        8 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line2, width: 0.5)),
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final hasText = value.text.trim().isNotEmpty;
          final canTapSend = enabled && hasText;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: TextField(
                    controller: controller,
                    enabled: enabled,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => canTapSend ? onSend() : null,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppColors.ink,
                    ),
                    decoration: InputDecoration(
                      hintText: enabled
                          ? 'Hỏi tiếp về bài này…'
                          : 'Tutora đang giải…',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppColors.ink4,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              // Nút gửi chỉ hiện khi đã nhập chữ (giống Gauth).
              AnimatedSize(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                child: hasText
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: GestureDetector(
                          onTap: canTapSend ? onSend : null,
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: canTapSend
                                  ? AppColors.oxblood
                                  : AppColors.line,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_upward_rounded,
                              size: 20,
                              color: canTapSend ? Colors.white : AppColors.ink4,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Error view
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 44,
              color: AppColors.ink4,
            ),
            const SizedBox(height: 12),
            Text(
              'Không thể tải lời giải',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.ink,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Thử lại',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
