import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_contribute_screen.dart';
import 'package:tutora/mock/tutor_forum_mock.dart';
import 'package:tutora/shared/widgets/user_avatar.dart';

class TutorForumDetailScreen extends StatefulWidget {
  const TutorForumDetailScreen({
    required this.authorName,
    required this.authorRole,
    required this.title,
    required this.content,
    required this.category,
    required this.timeAgo,
    required this.likes,
    required this.comments,
    super.key,
  });

  final String authorName;
  final String authorRole;
  final String title;
  final String content;
  final String category;
  final String timeAgo;
  final int likes;
  final int comments;

  @override
  State<TutorForumDetailScreen> createState() => _TutorForumDetailScreenState();
}

class _TutorForumDetailScreenState extends State<TutorForumDetailScreen> {
  final _replyController = TextEditingController();
  bool _liked = false;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.likes;
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _toggleLike() => setState(() {
    _liked = !_liked;
    _likeCount += _liked ? 1 : -1;
  });

  Color get _catFg => switch (widget.category) {
    'Phương pháp' => AppColors.oxblood,
    'Tài liệu' => AppColors.moss,
    'Hỏi đáp' => const Color(0xFF5C3A1A),
    _ => AppColors.ink3,
  };

  Color get _catBg => switch (widget.category) {
    'Phương pháp' => const Color(0xFFF5DEDE),
    'Tài liệu' => const Color(0xFFDDE6DD),
    'Hỏi đáp' => const Color(0xFFF0E3CA),
    _ => AppColors.cream2,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            _DetailTopBar(onBack: () => Navigator.of(context).pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, AppSpacing.xxl),
                children: [
                  // Post header
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        UserAvatar(name: widget.authorName, size: 40),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.authorName,
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              Text(
                                '${widget.authorRole} · ${widget.timeAgo}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.ink4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _catBg,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            widget.category,
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: _catFg,
                              letterSpacing: 0.06,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Title
                  Text(
                    widget.title,
                    style: GoogleFonts.ibmPlexSerif(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppColors.ink,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Full content
                  Text(
                    // Expand preview into full mock content
                    '${widget.content}\n\nCụ thể hơn, mình nhận thấy rằng khi cho học sinh tiếp cận theo hướng trực quan trước rồi mới đến lý thuyết, tỉ lệ ghi nhớ tăng rõ rệt. Mình thường dùng sơ đồ tư duy 5 phút đầu buổi để kích hoạt kiến thức nền.\n\nMong nhận được ý kiến từ các thầy cô có kinh nghiệm hơn!',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.ink2,
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Like + comment count row
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border.symmetric(
                        horizontal: BorderSide(color: AppColors.line),
                      ),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _toggleLike,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _liked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 18,
                                color: _liked
                                    ? AppColors.oxblood
                                    : AppColors.ink4,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '$_likeCount',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _liked
                                      ? AppColors.oxblood
                                      : AppColors.ink4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 18),
                        StatChip(
                          icon: Icons.chat_bubble_outline_rounded,
                          count: widget.comments,
                        ),
                      ],
                    ),
                  ),
                  // Comments section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
                    child: Text(
                      'BÌNH LUẬN',
                      style: AppTextStyles.eyebrow(color: AppColors.ink3),
                    ),
                  ),
                  ...kMockForumComments.map((c) => _CommentCard(comment: c)),
                ],
              ),
            ),
            // Reply input
            _ReplyBar(controller: _replyController),
          ],
        ),
      ),
    );
  }
}

class _DetailTopBar extends StatelessWidget {
  const _DetailTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 20, 4),
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
          const SizedBox(width: 12),
          Text(
            'Bài viết',
            style: GoogleFonts.ibmPlexSerif(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment});

  final MockForumComment comment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(name: comment.authorName, size: 30),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.authorName,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        '${comment.authorRole} · ${comment.timeAgo}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.ink4,
                        ),
                      ),
                    ],
                  ),
                ),
                StatChip(
                  icon: Icons.favorite_border_rounded,
                  count: comment.likes,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              comment.content,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.ink2,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplyBar extends StatelessWidget {
  const _ReplyBar({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottomPad),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: const Border(top: BorderSide(color: AppColors.line)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink),
              decoration: InputDecoration(
                hintText: 'Viết bình luận...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.ink4,
                ),
                filled: true,
                fillColor: AppColors.cream,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  borderSide: const BorderSide(
                    color: AppColors.ink,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.ink,
            ),
            child: const Icon(
              Icons.send_rounded,
              size: 18,
              color: AppColors.cream,
            ),
          ),
        ],
      ),
    );
  }
}
