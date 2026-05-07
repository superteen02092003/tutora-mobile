import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';

// Hard-coded prototype — API not yet available
const _kProblem = _Problem(
  book: 'Cánh Diều',
  subject: 'Toán 10',
  section: '§3.4',
  topic: 'Hệ thức Vi-ét',
  statement:
      'Cho phương trình bậc hai x² − 5x + 6 = 0. Tìm hai nghiệm và kiểm chứng hệ thức Vi-ét.',
  mathExpr: 'x² − 5x + 6 = 0',
  hints: [
    _Hint(
      'Nhận diện dạng',
      'Phương trình bậc hai một ẩn dạng ax² + bx + c = 0 với a = 1, b = −5, c = 6.',
    ),
    _Hint('Công thức cần nhớ', 'Δ = b² − 4ac. Nếu Δ ≥ 0, x = (−b ± √Δ) / 2a.'),
    _Hint('Hệ thức Vi-ét', 'Khi Δ ≥ 0: x₁ + x₂ = −b/a,  x₁ · x₂ = c/a.'),
  ],
  steps: [
    _Step(
      'Tính Δ',
      'Δ = (−5)² − 4·1·6 = 25 − 24 = 1.',
      'Δ = b² − 4ac = 25 − 24 = 1',
    ),
    _Step(
      'Tìm hai nghiệm',
      'x₁ = (5 + 1)/2 = 3,  x₂ = (5 − 1)/2 = 2.',
      'x₁,₂ = (5 ± 1) / 2',
    ),
    _Step(
      'Kiểm chứng Vi-ét',
      'x₁ + x₂ = 3 + 2 = 5 = −b/a ✓ và x₁ · x₂ = 6 = c/a ✓',
      'x₁ + x₂ = 5,  x₁ · x₂ = 6',
    ),
  ],
  answer: 'x₁ = 3,  x₂ = 2',
  pitfalls: [
    'Quên đổi dấu của b khi áp dụng Vi-ét.',
    'Nhầm dấu Δ khi a < 0.',
  ],
);

class StudentSolutionPage extends StatefulWidget {
  const StudentSolutionPage({super.key});

  @override
  State<StudentSolutionPage> createState() => _StudentSolutionPageState();
}

class _StudentSolutionPageState extends State<StudentSolutionPage> {
  int? _openStep;
  bool _revealAnswer = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EA),
      bottomNavigationBar: _SolutionBottomBar(),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            _SolutionAppBar(book: _kProblem.book, section: _kProblem.section),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Topic header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _kProblem.topic,
                          style: GoogleFonts.ibmPlexSerif(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            letterSpacing: -0.5,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'theo cách của bạn.',
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

                  // Problem statement card
                  const _ProblemCard(problem: _kProblem),
                  const SizedBox(height: 24),

                  // Section label
                  const _SectionLabel(
                    number: '①',
                    title: 'Gợi ý dẫn đường',
                    subtitle: 'Đọc trước khi xem lời giải',
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(
                    _kProblem.hints.length,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _HintCard(index: i, hint: _kProblem.hints[i]),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Steps
                  const _SectionLabel(number: '②', title: 'Lời giải từng bước'),
                  const SizedBox(height: 10),
                  ...List.generate(
                    _kProblem.steps.length,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _StepCard(
                        index: i,
                        step: _kProblem.steps[i],
                        isOpen: _openStep == i,
                        onTap: () => setState(
                          () => _openStep = _openStep == i ? null : i,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Answer reveal
                  const _SectionLabel(number: '③', title: 'Đáp án'),
                  const SizedBox(height: 10),
                  _AnswerCard(
                    answer: _kProblem.answer,
                    revealed: _revealAnswer,
                    onReveal: () => setState(() => _revealAnswer = true),
                  ),
                  const SizedBox(height: 20),

                  // CTA
                  _FindTutorButton(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SolutionAppBar extends StatelessWidget {
  const _SolutionAppBar({required this.book, required this.section});
  final String book;
  final String section;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.pop(),
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
                  color: Color(0xFF2A1F14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _Chip(book),
            const SizedBox(width: 8),
            Text(
              section,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                color: const Color(0xFF8A7060),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProblemCard extends StatelessWidget {
  const _ProblemCard({required this.problem});
  final _Problem problem;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0D8CA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ĐỀ BÀI',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: const Color(0xFF8A7060),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            problem.statement,
            style: GoogleFonts.ibmPlexSerif(
              fontSize: 14,
              height: 1.5,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          _MathBlock(problem.mathExpr),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.number,
    required this.title,
    this.subtitle,
  });
  final String number;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
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
        if (subtitle != null) ...[
          const Spacer(),
          Text(
            subtitle!,
            style: GoogleFonts.ibmPlexSerif(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: const Color(0xFF8A7060),
            ),
          ),
        ],
      ],
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.index, required this.hint});
  final int index;
  final _Hint hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          left: BorderSide(color: AppColors.gold, width: 3),
          top: BorderSide(color: Color(0xFFE0D8CA)),
          right: BorderSide(color: Color(0xFFE0D8CA)),
          bottom: BorderSide(color: Color(0xFFE0D8CA)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '0${index + 1}',
            style: GoogleFonts.ibmPlexSerif(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hint.title,
                  style: GoogleFonts.ibmPlexSerif(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hint.description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.55,
                    color: const Color(0xFF5A4A3A),
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

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.index,
    required this.step,
    required this.isOpen,
    required this.onTap,
  });
  final int index;
  final _Step step;
  final bool isOpen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE0D8CA)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
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
                        '${index + 1}',
                        style: GoogleFonts.ibmPlexSerif(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFF7F3EA),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      step.title,
                      style: GoogleFonts.ibmPlexSerif(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: Color(0xFF8A7060),
                    ),
                  ),
                ],
              ),
            ),
            if (isOpen)
              Padding(
                padding: const EdgeInsets.fromLTRB(48, 0, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.description,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        height: 1.55,
                        color: const Color(0xFF5A4A3A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _MathBlock(step.mathExpr),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ĐÁP ÁN',
              style: GoogleFonts.ibmPlexMono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 8),
            ImageFiltered(
              imageFilter: revealed
                  ? ImageFilter.blur()
                  : ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Text(
                answer,
                style: GoogleFonts.ibmPlexSerif(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFF7F3EA),
                ),
              ),
            ),
            if (!revealed) ...[
              const SizedBox(height: 14),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Chạm để xem đáp án',
                    style: GoogleFonts.inter(
                      fontSize: 11,
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

class _FindTutorButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () => context.go('/student/search'),
        style: TextButton.styleFrom(
          backgroundColor: AppColors.oxblood,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
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

class _MathBlock extends StatelessWidget {
  const _MathBlock(this.expr);
  final String expr;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF6EC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8DEC2)),
      ),
      child: Text(
        expr,
        style: GoogleFonts.ibmPlexMono(
          fontSize: 13,
          letterSpacing: 0.3,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    const bg = AppColors.oxblood;
    const fg = Color(0xFFF7F3EA);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.ibmPlexMono(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: fg,
        ),
      ),
    );
  }
}

// Data classes
class _Problem {
  const _Problem({
    required this.book,
    required this.subject,
    required this.section,
    required this.topic,
    required this.statement,
    required this.mathExpr,
    required this.hints,
    required this.steps,
    required this.answer,
    required this.pitfalls,
  });
  final String book;
  final String subject;
  final String section;
  final String topic;
  final String statement;
  final String mathExpr;
  final String answer;
  final List<_Hint> hints;
  final List<_Step> steps;
  final List<String> pitfalls;
}

class _Hint {
  const _Hint(this.title, this.description);
  final String title;
  final String description;
}

class _Step {
  const _Step(this.title, this.description, this.mathExpr);
  final String title;
  final String description;
  final String mathExpr;
}

class _SolutionBottomBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final botPad = MediaQuery.of(context).padding.bottom;
    return Container(
      height: 64 + botPad,
      decoration: BoxDecoration(
        color: AppColors.paper,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8),
        ],
      ),
      padding: EdgeInsets.only(bottom: botPad),
      child: Row(
        children: [
          _BarTab(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Trang chủ',
            onTap: () => context.go('/student/home'),
          ),
          _BarTab(
            icon: Icons.search_outlined,
            activeIcon: Icons.search_rounded,
            label: 'Gia sư',
            onTap: () => context.go('/student/search'),
          ),
          _BarTab(
            icon: Icons.calendar_today_outlined,
            activeIcon: Icons.calendar_today_rounded,
            label: 'Lịch học',
            onTap: () => context.go('/student/lessons'),
          ),
          _BarTab(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Hồ sơ',
            onTap: () => context.go('/student/profile'),
          ),
        ],
      ),
    );
  }
}

class _BarTab extends StatelessWidget {
  const _BarTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: AppColors.ink4),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9.5,
                fontWeight: FontWeight.w400,
                color: AppColors.ink4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
