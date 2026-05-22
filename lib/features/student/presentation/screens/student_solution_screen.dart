import 'dart:async';
import 'dart:convert';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/features/student/presentation/providers/ai_solve_provider.dart';

class StudentSolutionPage extends ConsumerStatefulWidget {
  const StudentSolutionPage({super.key, this.imageBytes});
  final Uint8List? imageBytes;

  @override
  ConsumerState<StudentSolutionPage> createState() =>
      _StudentSolutionPageState();
}

class _StudentSolutionPageState extends ConsumerState<StudentSolutionPage> {
  bool _answerRevealed = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    if (widget.imageBytes != null) {
      // Kick off solve after first frame so provider is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(Future.microtask(_solve));
      });
    }
  }

  void _solve() {
    final bytes = widget.imageBytes;
    if (bytes == null) return;
    final b64 = base64Encode(bytes);
    unawaited(ref.read(aiSolveProvider.notifier).solve(b64));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiSolveProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EA),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            _AppBar(onBack: () => context.pop()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lời giải',
                          style: GoogleFonts.ibmPlexSerif(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            letterSpacing: -0.5,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          'từng bước, rõ ràng.',
                          style: GoogleFonts.ibmPlexSerif(
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF8A7060),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Image preview
                  if (widget.imageBytes != null) ...[
                    _ImagePreview(bytes: widget.imageBytes!),
                    const SizedBox(height: 20),
                  ],

                  // Body theo trạng thái
                  _buildBody(state),

                  const SizedBox(height: 20),

                  // CTA tìm gia sư
                  if (state.isDone || state.isStreaming) _FindTutorButton(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(SolveState state) {
    switch (state.status) {
      case SolveStatus.idle:
        return const SizedBox.shrink();

      case SolveStatus.loading:
        return const _LoadingCard();

      case SolveStatus.error:
        return _ErrorCard(
          message: state.error ?? 'Có lỗi xảy ra',
          onRetry: _solve,
        );

      case SolveStatus.streaming:
      case SolveStatus.done:
        return _SolutionBody(
          state: state,
          answerRevealed: _answerRevealed,
          onRevealAnswer: () => setState(() => _answerRevealed = true),
        );
    }
  }
}

// App bar
class _AppBar extends StatelessWidget {
  const _AppBar({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          children: [
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE0D8CA)),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 15,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.oxblood,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Tora AI',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: const Color(0xFFF7F3EA),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Image preview
class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.bytes});
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0D8CA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(bytes, fit: BoxFit.contain, width: double.infinity),
      ),
    );
  }
}

// Loading
class _LoadingCard extends StatefulWidget {
  const _LoadingCard();

  @override
  State<_LoadingCard> createState() => _LoadingCardState();
}

class _LoadingCardState extends State<_LoadingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;
  int _idx = 0;
  Timer? _timer;

  static const _msgs = [
    'Đang đọc bài toán…',
    'Đang phân tích cấu trúc…',
    'Đang tạo lời giải…',
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    unawaited(_ctrl.repeat(reverse: true));
    _pulse = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _timer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
      if (mounted) setState(() => _idx = (_idx + 1) % _msgs.length);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0D8CA)),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, _) => Container(
              width: 56 + _pulse.value * 8,
              height: 56 + _pulse.value * 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(
                  alpha: 0.15 + _pulse.value * 0.1,
                ),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 26,
                color: AppColors.gold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _msgs[_idx],
              key: ValueKey(_idx),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tora đang giải cho bạn…',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF8A7060),
            ),
          ),
        ],
      ),
    );
  }
}

// Error
class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0D8CA)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: AppColors.error,
          ),
          const SizedBox(height: 12),
          Text(
            'Không thể giải bài toán',
            style: GoogleFonts.ibmPlexSerif(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF8A7060),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.ink,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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
    );
  }
}

// Solution body
class _SolutionBody extends StatelessWidget {
  const _SolutionBody({
    required this.state,
    required this.answerRevealed,
    required this.onRevealAnswer,
  });

  final SolveState state;
  final bool answerRevealed;
  final VoidCallback onRevealAnswer;

  @override
  Widget build(BuildContext context) {
    final steps = state.steps;
    final answer = state.finalAnswer;
    final isStreaming = state.isStreaming;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (steps.isNotEmpty) ...[
          _SectionLabel(
            number: '①',
            title: 'Lời giải từng bước',
            trailing: isStreaming ? _StreamingIndicator() : null,
          ),
          const SizedBox(height: 10),
          _StepsChat(steps: steps),
          const SizedBox(height: 16),
        ] else if (isStreaming) ...[
          _SectionLabel(
            number: '①',
            title: 'Đang giải…',
            trailing: _StreamingIndicator(),
          ),
          const SizedBox(height: 10),
          _RawStreamCard(text: state.rawText),
          const SizedBox(height: 16),
        ],

        if (answer.isNotEmpty && !isStreaming) ...[
          const _SectionLabel(number: '②', title: 'Đáp số'),
          const SizedBox(height: 10),
          _AnswerCard(
            answer: answer,
            revealed: answerRevealed,
            onReveal: onRevealAnswer,
          ),
        ],
      ],
    );
  }
}

// Section label
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.number,
    required this.title,
    this.trailing,
  });
  final String number;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$number ',
          style: GoogleFonts.ibmPlexMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppColors.gold,
          ),
        ),
        Text(
          title,
          style: GoogleFonts.ibmPlexMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: const Color(0xFF5A4A3A),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }
}

// Streaming indicator
class _StreamingIndicator extends StatefulWidget {
  @override
  State<_StreamingIndicator> createState() => _StreamingIndicatorState();
}

class _StreamingIndicatorState extends State<_StreamingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    unawaited(_ctrl.repeat(reverse: true));
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
      builder: (_, _) => Opacity(
        opacity: 0.4 + _ctrl.value * 0.6,
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.gold,
          ),
        ),
      ),
    );
  }
}

// Raw stream card — shown while steps are not yet parsed
class _RawStreamCard extends StatelessWidget {
  const _RawStreamCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0D8CA)),
      ),
      child: _MathText(text: text.isEmpty ? '…' : text),
    );
  }
}

// Tất cả steps trong 1 khung chat liên tục
class _StepsChat extends StatelessWidget {
  const _StepsChat({required this.steps});
  final List<SolveStep> steps;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0D8CA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(steps.length, (i) {
          final step = steps[i];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step header
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.ink,
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: GoogleFonts.ibmPlexSerif(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFF7F3EA),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MathText(
                        text: step.title,
                        baseStyle: GoogleFonts.ibmPlexSerif(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                        mathColor: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              // Step content
              Padding(
                padding: const EdgeInsets.fromLTRB(48, 0, 14, 14),
                child: _MathText(text: step.content),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// Answer card
class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.answer,
    required this.revealed,
    required this.onReveal,
  });
  final String answer;
  final bool revealed;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: revealed ? null : onReveal,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ĐÁP SỐ',
              style: GoogleFonts.ibmPlexMono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 10),
            ImageFiltered(
              imageFilter: revealed
                  ? ImageFilter.blur()
                  : ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: _MathText(
                text: answer,
                baseStyle: GoogleFonts.ibmPlexSerif(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFF7F3EA),
                ),
                mathColor: const Color(0xFFF7F3EA),
              ),
            ),
            if (!revealed) ...[
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Chạm để xem đáp số',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Renders text với inline LaTeX ($...$) và display LaTeX ($$...$$).
// Tách theo dòng trước, sau đó mỗi dòng tách inline math.
class _MathText extends StatelessWidget {
  const _MathText({required this.text, this.baseStyle, this.mathColor});

  final String text;
  final TextStyle? baseStyle;
  final Color? mathColor;

  // $$...$$ display block | $...$ inline
  static final _inlineRe = RegExp(r'\$\$(.+?)\$\$|\$(.+?)\$', dotAll: true);

  @override
  Widget build(BuildContext context) {
    final style =
        baseStyle ??
        GoogleFonts.inter(
          fontSize: 13,
          height: 1.6,
          color: const Color(0xFF5A4A3A),
        );
    final mColor = mathColor ?? AppColors.ink;

    // Tách thành các dòng, render từng dòng
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines
          .map((line) => _buildLine(line.trim(), style, mColor))
          .toList(),
    );
  }

  Widget _buildLine(String line, TextStyle style, Color mColor) {
    if (line.isEmpty) return const SizedBox(height: 6);

    // Display block: $$...$$  → render to center
    if (line.startsWith(r'$$') && line.endsWith(r'$$') && line.length > 4) {
      final expr = line.substring(2, line.length - 2).trim();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Math.tex(
            expr,
            textStyle: style,
            onErrorFallback: (_) => Text(expr, style: style),
          ),
        ),
      );
    }

    // Inline: tách $...$ trong dòng
    final segments = <InlineSpan>[];
    var cursor = 0;
    for (final m in _inlineRe.allMatches(line)) {
      if (m.start > cursor) {
        segments.add(
          TextSpan(text: line.substring(cursor, m.start), style: style),
        );
      }
      final expr = (m.group(1) ?? m.group(2) ?? '').trim();
      segments.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Math.tex(
            expr,
            textStyle: style.copyWith(color: mColor),
            onErrorFallback: (_) => Text(expr, style: style),
          ),
        ),
      );
      cursor = m.end;
    }
    if (cursor < line.length) {
      segments.add(TextSpan(text: line.substring(cursor), style: style));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text.rich(TextSpan(children: segments)),
    );
  }
}

// Find tutor button
class _FindTutorButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () => context.go('/student/search'),
        style: TextButton.styleFrom(
          backgroundColor: AppColors.oxblood,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              size: 14,
              color: Color(0xFFF0E3CA),
            ),
            const SizedBox(width: 8),
            Text(
              'Tìm gia sư cho bài này',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: const Color(0xFFF0E3CA),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
