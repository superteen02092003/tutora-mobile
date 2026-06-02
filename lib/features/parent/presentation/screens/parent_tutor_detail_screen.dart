import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_filter_options.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/utils/format_utils.dart';
import 'package:tutora/features/parent/presentation/screens/parent_booking_sheet.dart';
import 'package:tutora/features/tutor_search/data/models/tutor_detail_models.dart';
import 'package:tutora/features/tutor_search/presentation/controllers/tutor_detail_controller.dart';
import 'package:tutora/shared/widgets/user_avatar.dart';
import 'package:tutora/shared/widgets/verify_pip.dart';

class ParentTutorDetailPage extends ConsumerWidget {
  const ParentTutorDetailPage({required this.tutorId, super.key});

  final String tutorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tutorDetailControllerProvider(tutorId));

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: switch (state) {
        TutorDetailLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
        TutorDetailError(:final message) => _ErrorView(
          message: message,
          onRetry: () =>
              ref.read(tutorDetailControllerProvider(tutorId).notifier).retry(),
        ),
        TutorDetailLoaded(:final profile) => _DetailBody(
          tutorId: tutorId,
          profile: profile,
        ),
      },
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.tutorId, required this.profile});
  final String tutorId;
  final TutorFullProfileDto profile;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    const barHeight = 72.0;

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.zero,
          children: [
            const _TopBar(),
            _HeroSection(profile: profile),
            const _Divider(),
            _AboutSection(profile: profile),
            if (profile.certificates != null &&
                profile.certificates!.isNotEmpty) ...[
              const _Divider(),
              _CertificatesSection(certificates: profile.certificates!),
            ],
            const _Divider(),
            _ReviewsSection(
              feedbacks: profile.feedbacks ?? [],
              averageRating: profile.averageRating,
              totalFeedbacks: profile.totalFeedbacks,
            ),
            SizedBox(height: barHeight + bottomPad + 16),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _BookingBar(
            tutorId: tutorId,
            profile: profile,
            bottomPad: bottomPad,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const Divider(
    height: 1,
    color: AppColors.line,
    indent: 16,
    endIndent: 16,
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.paper,
              border: Border.all(color: AppColors.line),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _BookingBar extends StatelessWidget {
  const _BookingBar({
    required this.tutorId,
    required this.profile,
    required this.bottomPad,
  });
  final String tutorId;
  final TutorFullProfileDto profile;
  final double bottomPad;

  String get _priceText {
    final rate = profile.hourlyRate;
    if (rate == null || rate == 0) return 'Thương lượng';
    if (rate >= 1000) return '${(rate / 1000).round()}.000đ/giờ';
    return '${rate.toStringAsFixed(0)}đ/giờ';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPad),
      decoration: BoxDecoration(
        color: AppColors.cream,
        border: const Border(top: BorderSide(color: AppColors.line)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _priceText,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              Text(
                'qua Tutora Escrow',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.ink3),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => showParentBookingSheet(
                context,
                profile,
                tutorId,
                onSuccess: () => context.go(AppRoutes.parentBookings),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  'Đặt lịch cho con',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
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

// Hero section

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.profile});
  final TutorFullProfileDto profile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        children: [
          UserAvatar(
            name: profile.displayName,
            size: 88,
            imageUrl: profile.avatarUrl,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                profile.displayName,
                style: GoogleFonts.bricolageGrotesque(
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 6),
              const VerifyPip(),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, size: 11, color: AppColors.gold),
              const SizedBox(width: 4),
              Text(
                profile.averageRating.toStringAsFixed(2),
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink2),
              ),
              Text(
                ' · ',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink3),
              ),
              Text(
                '${profile.totalFeedbacks} đánh giá',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink2),
              ),
              if (profile.teachingAreaCity != null) ...[
                Text(
                  ' · ',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink3),
                ),
                Text(
                  filterLabel(cityOptions, profile.teachingAreaCity),
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink2),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// About section

class _AboutSection extends StatefulWidget {
  const _AboutSection({required this.profile});
  final TutorFullProfileDto profile;

  @override
  State<_AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends State<_AboutSection> {
  static const int _collapsedLines = 4;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final firstName = profile.displayName.split(' ').last;
    final fullText = [
      if (profile.bio != null) profile.bio!,
      if (profile.experience != null) profile.experience!,
    ].join('\n\n');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Về Mentor $firstName',
            style: GoogleFonts.bricolageGrotesque(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppColors.ink,
            ),
          ),
          if (fullText.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              fullText,
              maxLines: _expanded ? null : _collapsedLines,
              overflow: _expanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: AppColors.ink2,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? 'Thu gọn ▲' : 'Xem thêm ▼',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.ink,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              if (profile.education != null)
                Expanded(
                  child: _CredentialCard(
                    icon: Icons.school_outlined,
                    label: 'Học vấn',
                    value: profile.education!,
                    sub: profile.gpaText.isNotEmpty
                        ? 'GPA ${profile.gpaText}'
                        : '',
                  ),
                ),
              if (profile.education != null && profile.teachingMode != null)
                const SizedBox(width: 8),
              if (profile.teachingMode != null)
                Expanded(
                  child: _CredentialCard(
                    icon: Icons.location_on_outlined,
                    label: 'Khu vực',
                    value: profile.teachingMode!,
                    sub: profile.teachingAreaCity ?? '',
                  ),
                ),
            ],
          ),
          if (profile.subjects != null && profile.subjects!.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('CẤP LỚP GIẢNG DẠY', style: AppTextStyles.eyebrow()),
            const SizedBox(height: 10),
            ...profile.subjects!
                .where((s) => s.subjectName != null)
                .map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 72,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${s.subjectName}:',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: formatGradeLevels(s.gradeLevels ?? [])
                                    .map(
                                      (g) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.cream2,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          g,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.ink3,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                              if ((s.tags ?? []).isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: (s.tags ?? [])
                                      .map(
                                        (t) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 9,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF0E3CA),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: Text(
                                            t,
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.ink2,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _CredentialCard extends StatelessWidget {
  const _CredentialCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
  });
  final IconData icon;
  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: AppColors.ink3),
              const SizedBox(width: 5),
              Text(label, style: AppTextStyles.eyebrow()),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          if (sub.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              sub,
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.ink4),
            ),
          ],
        ],
      ),
    );
  }
}

// Certificates section

class _CertificatesSection extends StatelessWidget {
  const _CertificatesSection({required this.certificates});
  final List<TutorDetailCertificateDto> certificates;

  @override
  Widget build(BuildContext context) {
    if (certificates.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hồ sơ năng lực học thuật',
                      style: GoogleFonts.bricolageGrotesque(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'TUTORA Academic Ledger v2.4',
                      style: AppTextStyles.eyebrow(),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD5EDD9),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_outlined,
                      size: 11,
                      color: Color(0xFF1D5C2D),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Xác thực 100%',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1D5C2D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.line)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 14,
                        color: AppColors.gold,
                        margin: const EdgeInsets.only(right: 8),
                      ),
                      Text(
                        'Văn bằng & Chứng chỉ',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                for (int i = 0; i < certificates.length; i++)
                  Column(
                    children: [
                      if (i > 0)
                        const Divider(
                          height: 1,
                          indent: 14,
                          color: AppColors.line,
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: AppColors.gold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.workspace_premium_outlined,
                                size: 16,
                                color: AppColors.gold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          certificates[i].certificateName,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                      ),
                                      if (certificates[i].isVerified) ...[
                                        const SizedBox(width: 6),
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          size: 13,
                                          color: Color(0xFF1D5C2D),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    [
                                      certificates[i].issuingOrganization,
                                      if (certificates[i].yearIssued != null)
                                        '${certificates[i].yearIssued}',
                                    ].join(' · '),
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.ink4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.cream2,
                    border: Border(top: BorderSide(color: AppColors.line)),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(AppRadius.lg),
                    ),
                  ),
                  child: const Row(
                    children: [
                      _FooterNote(text: 'Hồ sơ gốc lưu trữ bởi TUTORA'),
                      SizedBox(width: 14),
                      _FooterNote(text: 'Đã kiểm tra chéo'),
                    ],
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

class _FooterNote extends StatelessWidget {
  const _FooterNote({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFF1D5C2D),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: AppColors.ink3,
          ),
        ),
      ],
    );
  }
}

// Reviews section

class _ReviewsSection extends StatefulWidget {
  const _ReviewsSection({
    required this.feedbacks,
    required this.averageRating,
    required this.totalFeedbacks,
  });
  final List<TutorDetailFeedbackDto> feedbacks;
  final double averageRating;
  final int totalFeedbacks;

  @override
  State<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<_ReviewsSection> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    final review = widget.feedbacks.isEmpty ? null : widget.feedbacks[_current];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nhật ký thành công',
            style: GoogleFonts.bricolageGrotesque(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          _RatingSummary(
            rating: widget.averageRating,
            total: widget.totalFeedbacks,
          ),
          if (review != null) ...[
            const SizedBox(height: 12),
            _ReviewCard(review: review),
          ] else ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Chưa có đánh giá nào.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: AppColors.ink4,
                ),
              ),
            ),
          ],
          if (widget.feedbacks.length > 1) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _NavBtn(
                      icon: Icons.arrow_back_rounded,
                      enabled: _current > 0,
                      onTap: () => setState(() => _current--),
                    ),
                    const SizedBox(width: 8),
                    _NavBtn(
                      icon: Icons.arrow_forward_rounded,
                      enabled: _current < widget.feedbacks.length - 1,
                      onTap: () => setState(() => _current++),
                    ),
                  ],
                ),
                Text(
                  'Đánh giá ${_current + 1} / ${widget.totalFeedbacks}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.ink4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RatingSummary extends StatelessWidget {
  const _RatingSummary({required this.rating, required this.total});
  final double rating;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                rating.toStringAsFixed(1),
                style: GoogleFonts.bricolageGrotesque(
                  fontWeight: FontWeight.w800,
                  fontSize: 30,
                  color: AppColors.ink,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  for (int i = 1; i <= 5; i++)
                    Icon(
                      Icons.star_rounded,
                      size: 10,
                      color: i <= rating.round()
                          ? AppColors.gold
                          : AppColors.line,
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '$total đánh giá',
                style: GoogleFonts.inter(fontSize: 10, color: AppColors.ink4),
              ),
            ],
          ),
          const SizedBox(width: 16),
          const VerticalDivider(width: 1, color: AppColors.line),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                for (int star = 5; star >= 1; star--)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Text(
                          '$star',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.ink4,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.star_rounded,
                          size: 9,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: star == 5
                                  ? 0.85
                                  : star == 4
                                  ? 0.10
                                  : 0.05,
                              minHeight: 5,
                              backgroundColor: AppColors.cream2,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.gold,
                              ),
                            ),
                          ),
                        ),
                      ],
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

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final TutorDetailFeedbackDto review;

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = review.fromUserName ?? 'Học viên';
    final initial = name.trim().split(' ').last[0];
    final rating = review.rating ?? 5.0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    if (review.createdAt != null)
                      Text(
                        _formatDate(review.createdAt!),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.ink4,
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  for (int i = 1; i <= 5; i++)
                    Icon(
                      Icons.star_rounded,
                      size: 11,
                      color: i <= rating.round()
                          ? AppColors.gold
                          : AppColors.line,
                    ),
                ],
              ),
            ],
          ),
          if (review.comment != null) ...[
            const SizedBox(height: 10),
            Text(
              '"${review.comment}"',
              style: GoogleFonts.ibmPlexSerif(
                fontStyle: FontStyle.italic,
                fontSize: 13.5,
                color: AppColors.ink2,
                height: 1.5,
              ),
            ),
          ],
          if (review.initialGoal != null || review.actualResult != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.cream2,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  if (review.initialGoal != null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mục tiêu ban đầu',
                            style: AppTextStyles.eyebrow(),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            review.initialGoal!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (review.initialGoal != null && review.actualResult != null)
                    Container(
                      width: 1,
                      height: 32,
                      color: AppColors.line,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  if (review.actualResult != null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kết quả thực tế',
                            style: AppTextStyles.eyebrow(),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            review.actualResult!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1D5C2D),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.cream2,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: AppColors.line),
            ),
            child: Text(
              'Xác thực bởi TUTORA LMS',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.ink3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? AppColors.paper : AppColors.cream2,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: AppColors.line),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? AppColors.ink : AppColors.ink4,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink3),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                'Thử lại',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.cream,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
