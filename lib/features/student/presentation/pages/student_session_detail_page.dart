import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../../shared/widgets/verify_pip.dart';
import '../../../../mock/student_lessons_mock.dart';

class StudentSessionDetailPage extends StatelessWidget {
  const StudentSessionDetailPage({super.key, required this.lesson});
  final MockLesson lesson;

  bool get _isDone => lesson.status == LessonStatus.done;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _NavBar(title: _isDone ? 'Tổng kết buổi học' : 'Chi tiết buổi học'),
            Expanded(
              child: ListView(
                padding: EdgeInsets.only(bottom: bottomInset + 88),
                children: [
                  if (_isDone) ...[
                    _DoneBanner(lesson: lesson),
                    _TutorCard(lesson: lesson),
                    _DetailsCard(lesson: lesson),
                    const _RatingCard(),
                    const _AiRecapCard(),
                  ] else ...[
                    _ActiveBanner(lesson: lesson),
                    _TutorCard(lesson: lesson),
                    _DetailsCard(lesson: lesson),
                    const _AiPrepCard(),
                  ],
                ],
              ),
            ),
            if (_isDone)
              _DoneActions(lesson: lesson, bottomInset: bottomInset)
            else
              _ActiveActions(lesson: lesson, bottomInset: bottomInset),
          ],
        ),
      ),
    );
  }
}

// ── Nav bar ────────────────────────────────────────────────────────────────
class _NavBar extends StatelessWidget {
  const _NavBar({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.paper,
                border: Border.all(color: AppColors.line),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 14, color: AppColors.ink),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSerif(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: AppColors.ink,
              ),
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.paper,
              border: Border.all(color: AppColors.line),
            ),
            child: const Icon(Icons.more_vert_rounded,
                size: 16, color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}

// ── Done banner ────────────────────────────────────────────────────────────
class _DoneBanner extends StatelessWidget {
  const _DoneBanner({required this.lesson});
  final MockLesson lesson;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E7DF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC7D3CB)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.moss),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Đã kết thúc · ${lesson.timeRange}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.moss,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Active banner (with pulse dot) ────────────────────────────────────────
class _ActiveBanner extends StatelessWidget {
  const _ActiveBanner({required this.lesson});
  final MockLesson lesson;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, text) = switch (lesson.status) {
      LessonStatus.upcoming  => (AppColors.oxblood,       const Color(0xFFFFF1E6), 'Sắp diễn ra · bắt đầu sau 2 giờ'),
      LessonStatus.confirmed => (AppColors.moss,           const Color(0xFFE0E7DF), 'Đã xác nhận · chờ buổi học'),
      _                      => (const Color(0xFFF0E3CA), const Color(0xFF5C3A1A), 'Chờ gia sư xác nhận'),
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _PulseDot(color: fg),
          const SizedBox(width: 10),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});
  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.35, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
      ),
    );
  }
}

// ── Tutor card ─────────────────────────────────────────────────────────────
class _TutorCard extends StatelessWidget {
  const _TutorCard({required this.lesson});
  final MockLesson lesson;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          UserAvatar(name: lesson.tutorName, size: 56),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        lesson.tutorName,
                        style: GoogleFonts.bricolageGrotesque(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const VerifyPip(),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Senior · Top 1% · ${lesson.subject}',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink3),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 11, color: AppColors.gold),
                    const SizedBox(width: 4),
                    Text(
                      '4.96',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      ' · 482 buổi',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.ink3),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Details card (no fee row) ──────────────────────────────────────────────
class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.lesson});
  final MockLesson lesson;

  @override
  Widget build(BuildContext context) {
    final rows = [
      (icon: Icons.access_time_rounded,  label: 'Thời gian', value: '${lesson.date} · ${lesson.timeRange}'),
      (icon: Icons.menu_book_rounded,    label: 'Môn học',   value: '${lesson.subject} · Cánh Diều'),
      (icon: Icons.auto_awesome_rounded, label: 'Chủ đề',    value: lesson.topic),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('THÔNG TIN BUỔI HỌC', style: AppTextStyles.eyebrow()),
          const SizedBox(height: 14),
          ...rows.asMap().entries.map((e) => Padding(
                padding:
                    EdgeInsets.only(bottom: e.key < rows.length - 1 ? 14 : 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.cream2,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(e.value.icon, size: 16, color: AppColors.ink),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.value.label.toUpperCase(),
                              style: AppTextStyles.eyebrow()),
                          const SizedBox(height: 3),
                          Text(
                            e.value.value,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ── Rating card (done sessions only) ──────────────────────────────────────
class _RatingCard extends StatefulWidget {
  const _RatingCard();

  @override
  State<_RatingCard> createState() => _RatingCardState();
}

class _RatingCardState extends State<_RatingCard> {
  int _stars = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ĐÁNH GIÁ BUỔI HỌC', style: AppTextStyles.eyebrow()),
          const SizedBox(height: 10),
          Text(
            'Bạn đánh giá buổi học thế nào?',
            style: GoogleFonts.ibmPlexSerif(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < _stars;
              return GestureDetector(
                onTap: () => setState(() => _stars = i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 38,
                    color: filled ? AppColors.gold : AppColors.line,
                  ),
                ),
              );
            }),
          ),
          if (_stars > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.cream2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.line),
              ),
              child: Text(
                'Nhận xét thêm (không bắt buộc)…',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink3),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Gửi đánh giá',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cream,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── AI recap card (done sessions) ──────────────────────────────────────────
class _AiRecapCard extends StatelessWidget {
  const _AiRecapCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                gradient: RadialGradient(
                  center: const Alignment(1.1, -1.1),
                  radius: 1.2,
                  colors: [
                    AppColors.gold.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TUTORA AI TÓM TẮT',
                  style: AppTextStyles.eyebrow(color: AppColors.gold)),
              const SizedBox(height: 12),
              const _RecapRow(
                icon: Icons.check_circle_outline_rounded,
                label: 'Đã học',
                text: 'Đạo hàm cơ bản — quy tắc lũy thừa, tích, thương',
              ),
              const SizedBox(height: 10),
              const _RecapRow(
                icon: Icons.trending_up_rounded,
                label: 'Tiến bộ',
                text: 'Nắm lý thuyết tốt, cần luyện thêm bài tập ứng dụng',
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded,
                        size: 13, color: AppColors.gold),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.cream.withValues(alpha: 0.8),
                              height: 1.4),
                          children: [
                            const TextSpan(text: 'Ôn cho buổi sau: '),
                            TextSpan(
                              text: 'đạo hàm hàm hợp (chain rule)',
                              style: GoogleFonts.ibmPlexSerif(
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                                color: AppColors.gold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    'Xem lại bài giải đã quét',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecapRow extends StatelessWidget {
  const _RecapRow(
      {required this.icon, required this.label, required this.text});
  final IconData icon;
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.gold),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppColors.cream.withValues(alpha: 0.85),
                  height: 1.4),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cream,
                  ),
                ),
                TextSpan(text: text),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── AI prep card (upcoming sessions) ──────────────────────────────────────
class _AiPrepCard extends StatelessWidget {
  const _AiPrepCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                gradient: RadialGradient(
                  center: const Alignment(1.1, -1.1),
                  radius: 1.2,
                  colors: [
                    AppColors.gold.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TUTORA AI CHUẨN BỊ',
                  style: AppTextStyles.eyebrow(color: AppColors.gold)),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.ibmPlexSerif(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    height: 1.35,
                    color: AppColors.cream,
                  ),
                  children: [
                    const TextSpan(text: 'Bạn đã quét 3 bài Vi-ét — '),
                    TextSpan(
                      text: 'sai bước đổi dấu b',
                      style: GoogleFonts.ibmPlexSerif(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.gold,
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Đề xuất: nhờ gia sư ôn lại quy tắc dấu trước khi vào bài mới.',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: AppColors.cream.withValues(alpha: 0.65),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    'Xem lại bài gần nhất',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Done actions ───────────────────────────────────────────────────────────
class _DoneActions extends StatelessWidget {
  const _DoneActions({required this.lesson, required this.bottomInset});
  final MockLesson lesson;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, bottomInset + 12),
      color: AppColors.cream,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.oxblood,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            'Đặt buổi học tiếp theo với ${lesson.tutorName}',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFFF1E6),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Active actions ─────────────────────────────────────────────────────────
class _ActiveActions extends StatelessWidget {
  const _ActiveActions({required this.lesson, required this.bottomInset});
  final MockLesson lesson;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, bottomInset + 12),
      color: AppColors.cream,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showCancelSheet(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: Text(
                'Hủy buổi',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.oxblood,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.oxblood,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Vào phòng học',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFFF1E6),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelSheet(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Hủy buổi học?',
              style: GoogleFonts.bricolageGrotesque(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Bạn có chắc muốn hủy buổi học với ${lesson.tutorName}?',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.ink2, height: 1.55),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0E3CA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0D2A8)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_outlined,
                      size: 14, color: AppColors.oxblood),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hủy trước 2 giờ — hoàn tiền 100%. Hủy muộn — giữ 30% phí nền tảng.',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.ink2, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.oxblood,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Xác nhận hủy · Hoàn 100%',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFFF1E6),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Text(
                    'Giữ nguyên',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
