import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';

class TutorContributeFormScreen extends StatefulWidget {
  const TutorContributeFormScreen({
    super.key,
    this.prefillTitle,
    this.prefillContent,
    this.prefillSubject,
    this.rewardPoints,
  });

  final String? prefillTitle;
  final String? prefillContent;
  final String? prefillSubject;
  final int? rewardPoints;

  @override
  State<TutorContributeFormScreen> createState() =>
      _TutorContributeFormScreenState();
}

class _TutorContributeFormScreenState extends State<TutorContributeFormScreen> {
  int _step = 0;

  static const _steps = ['Đề bài', 'Lời giải', 'Gợi ý SP', 'Duyệt'];

  void _next() {
    if (_step < _steps.length - 1) {
      setState(() => _step++);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            _FormTopBar(
              rewardPoints: widget.rewardPoints ?? 50,
              onBack: () => Navigator.of(context).pop(),
            ),
            _StepIndicator(current: _step, steps: _steps),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, AppSpacing.xxl),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: child,
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: switch (_step) {
                      0 => _StepProblem(
                        prefillTitle: widget.prefillTitle,
                        prefillContent: widget.prefillContent,
                        prefillSubject: widget.prefillSubject,
                      ),
                      1 => const _StepSolution(),
                      2 => const _StepHints(),
                      _ => const _StepReview(),
                    },
                  ),
                ),
              ),
            ),
            _FormFooter(
              step: _step,
              totalSteps: _steps.length,
              stepLabel: _step < _steps.length - 1 ? _steps[_step + 1] : null,
              onBack: _back,
              onNext: _next,
            ),
          ],
        ),
      ),
    );
  }
}

class _FormTopBar extends StatelessWidget {
  const _FormTopBar({required this.rewardPoints, required this.onBack});

  final int rewardPoints;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.paper,
                border: Border.all(color: AppColors.line),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 18,
                color: AppColors.ink,
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.oxblood,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              '+${rewardPoints}k / bài duyệt',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFFF1E6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.steps});

  final int current;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: List.generate(steps.length, (i) {
          final done = i <= current;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < steps.length - 1 ? 6 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 3,
                    decoration: BoxDecoration(
                      color: done ? AppColors.ink : AppColors.line,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '0${i + 1} ${steps[i]}',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 9,
                      letterSpacing: 0.05,
                      color: i == current ? AppColors.ink : AppColors.ink4,
                      fontWeight: i == current
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _StepProblem extends StatelessWidget {
  const _StepProblem({
    this.prefillTitle,
    this.prefillContent,
    this.prefillSubject,
  });

  final String? prefillTitle;
  final String? prefillContent;
  final String? prefillSubject;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          eyebrow: 'Ngân hàng câu hỏi · Tutora Vault',
          title: 'Đóng góp bài tập',
          subtitle: 'để AI thông minh hơn.',
        ),
        const SizedBox(height: 16),
        const _FieldCard(
          label: 'Chương trình',
          child: Wrap(
            spacing: 6,
            children: [
              _CurriculumChip(label: 'Cánh Diều', active: true),
              _CurriculumChip(label: 'Kết nối tri thức'),
              _CurriculumChip(label: 'Chân trời sáng tạo'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const _FieldCard(
          label: 'Môn · Lớp · Chương',
          child: Row(
            children: [
              Expanded(child: _PickDropdown(value: 'Toán')),
              SizedBox(width: 8),
              Expanded(child: _PickDropdown(value: '10')),
              SizedBox(width: 8),
              Expanded(child: _PickDropdown(value: '§3.4')),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _FieldCard(
          label: 'Đề bài (LaTeX hoặc văn bản)',
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF6EC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE8DEC2)),
            ),
            child: Text(
              prefillContent ??
                  'Cho phương trình bậc hai\nx² − 5x + 6 = 0.\nTìm hai nghiệm và kiểm chứng hệ thức Vi-ét.',
              style: GoogleFonts.ibmPlexMono(
                fontSize: 12.5,
                color: AppColors.ink,
                height: 1.6,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _FieldCard(
          label: 'Đính kèm',
          child: Row(
            children: [
              _ImagePlaceholder(),
              const SizedBox(width: 8),
              _AddImageButton(),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepSolution extends StatelessWidget {
  const _StepSolution();

  static const _solutionSteps = [
    'Tính Δ = b² − 4ac = 1',
    'x₁ = 3,  x₂ = 2',
    'Kiểm chứng x₁ + x₂ = 5;  x₁ · x₂ = 6',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldCard(
          label: 'Bước giải',
          child: Column(
            children: [
              ..._solutionSteps.asMap().entries.map(
                (e) => Padding(
                  padding: EdgeInsets.only(
                    bottom: e.key < _solutionSteps.length - 1 ? 0 : 0,
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.ink,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${e.key + 1}',
                                style: GoogleFonts.ibmPlexMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.cream,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                e.value,
                                style: GoogleFonts.ibmPlexMono(
                                  fontSize: 12.5,
                                  color: AppColors.ink,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (e.key < _solutionSteps.length - 1)
                        const Divider(
                          height: 1,
                          color: AppColors.line,
                          thickness: 1,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () {},
                child: Text(
                  '+ Thêm bước',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.oxblood,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _FieldCard(
          label: 'Đáp án',
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'x₁ = 3,  x₂ = 2',
              style: GoogleFonts.ibmPlexMono(
                fontSize: 13,
                color: AppColors.cream,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepHints extends StatelessWidget {
  const _StepHints();

  static const _hints = [
    'Nhận diện dạng phương trình bậc hai',
    'Nhắc công thức Δ = b² − 4ac',
    'Liên hệ Vi-ét: tổng/tích nghiệm',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0E3CA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE0D2A8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VÌ SAO CẦN GỢI Ý?',
                style: AppTextStyles.eyebrow(color: AppColors.oxblood),
              ),
              const SizedBox(height: 6),
              Text(
                'Tutora hiển thị gợi ý trước đáp án — giúp học sinh suy luận. AI sẽ học cách diễn đạt từ chính bạn.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppColors.ink2,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ..._hints.asMap().entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _FieldCard(
              label: 'Gợi ý ${e.key + 1}',
              child: Text(
                e.value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.ink2,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepReview extends StatelessWidget {
  const _StepReview();

  static const _rows = [
    ('Chương trình', 'Cánh Diều · Toán 10 · §3.4'),
    ('Số bước giải', '3'),
    ('Số gợi ý', '3'),
    ('Phần thưởng dự kiến', '+50.000đ + 0,5% AI'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TÓM TẮT', style: AppTextStyles.eyebrow()),
              const SizedBox(height: 12),
              ..._rows.asMap().entries.map(
                (e) => Padding(
                  padding: EdgeInsets.only(
                    bottom: e.key < _rows.length - 1 ? 10 : 0,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            e.value.$1,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: AppColors.ink3,
                            ),
                          ),
                          Text(
                            e.value.$2,
                            style: GoogleFonts.ibmPlexSerif(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                      if (e.key < _rows.length - 1) ...[
                        const SizedBox(height: 10),
                        const Divider(
                          height: 1,
                          color: AppColors.line,
                          thickness: 1,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE0E7DF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFC7D3CB)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 15,
                color: AppColors.moss,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bài viết được kiểm duyệt bởi 2 gia sư senior trước khi vào ngân hàng câu hỏi AI.',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppColors.ink2,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FormFooter extends StatelessWidget {
  const _FormFooter({
    required this.step,
    required this.totalSteps,
    required this.onBack,
    required this.onNext,
    this.stepLabel,
  });

  final int step;
  final int totalSteps;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final String? stepLabel;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPad),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            AppColors.cream,
            AppColors.cream.withValues(alpha: 0),
          ],
          stops: const [0.6, 1.0],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Text(
                'Quay lại',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: onNext,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  stepLabel != null ? 'Tiếp tục · $stepLabel' : 'Gửi để duyệt',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cream,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow, style: AppTextStyles.eyebrow()),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$title ',
                style: GoogleFonts.bricolageGrotesque(
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  letterSpacing: -0.5,
                  height: 1.1,
                  color: AppColors.ink,
                ),
              ),
              TextSpan(
                text: subtitle,
                style: GoogleFonts.ibmPlexSerif(
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w400,
                  fontSize: 22,
                  color: AppColors.ink2,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.eyebrow(color: AppColors.ink3)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _CurriculumChip extends StatelessWidget {
  const _CurriculumChip({required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? AppColors.ink : AppColors.cream,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: active ? AppColors.ink : AppColors.line),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: active ? AppColors.cream : AppColors.ink3,
        ),
      ),
    );
  }
}

class _PickDropdown extends StatelessWidget {
  const _PickDropdown({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF6EC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 14,
            color: AppColors.ink3,
          ),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.cream2,
        border: Border.all(color: AppColors.line),
      ),
      child: const Icon(Icons.image_outlined, size: 24, color: AppColors.ink4),
    );
  }
}

class _AddImageButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.paper,
        border: Border.all(
          color: AppColors.line,
        ),
      ),
      child: const Icon(Icons.add_rounded, size: 24, color: AppColors.ink3),
    );
  }
}
