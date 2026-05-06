import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/tutor_search/data/models/tutor_detail_models.dart';

class TutorReviewsSection extends StatefulWidget {
  const TutorReviewsSection({
    required this.feedbacks,
    required this.averageRating,
    required this.totalFeedbacks,
    super.key,
  });
  final List<TutorDetailFeedbackDto> feedbacks;
  final double averageRating;
  final int totalFeedbacks;

  @override
  State<TutorReviewsSection> createState() => _TutorReviewsSectionState();
}

class _TutorReviewsSectionState extends State<TutorReviewsSection> {
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

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return iso;
    }
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
