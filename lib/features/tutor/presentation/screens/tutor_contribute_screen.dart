import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_contribute_form_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_forum_detail_screen.dart';
import 'package:tutora/mock/tutor_forum_mock.dart';
import 'package:tutora/shared/widgets/user_avatar.dart';

class TutorContributeScreen extends StatefulWidget {
  const TutorContributeScreen({super.key});

  @override
  State<TutorContributeScreen> createState() => _TutorContributeScreenState();
}

class _TutorContributeScreenState extends State<TutorContributeScreen> {
  int _selectedCategory = 0;

  List<MockForumPost> get _filtered {
    if (_selectedCategory == 0) return kForumPosts;
    final cat = kForumCategories[_selectedCategory];
    return kForumPosts.where((p) => p.category == cat).toList();
  }

  bool get _showPinned =>
      _selectedCategory == 0 ||
      kPinnedPost.category == kForumCategories[_selectedCategory];

  Future<void> _openPost(MockForumPost post) async {
    if (post.isQuestion) {
      await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => TutorContributeFormScreen(
            prefillTitle: post.title,
            prefillContent: post.preview,
            prefillSubject: post.authorRole,
            rewardPoints: post.rewardPoints,
          ),
        ),
      );
    } else {
      await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => TutorForumDetailScreen(
            authorName: post.authorName,
            authorRole: post.authorRole,
            title: post.title,
            content: post.preview,
            category: post.category,
            timeAgo: post.timeAgo,
            likes: post.likes,
            comments: post.comments,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopBar(onSearch: () {}),
            _CategoryBar(
              selected: _selectedCategory,
              onSelect: (i) => setState(() => _selectedCategory = i),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, AppSpacing.xxl),
                children: [
                  if (_showPinned) ...[
                    _PinnedPost(
                      post: kPinnedPost,
                      onTap: () => _openPost(kPinnedPost),
                    ),
                    const SizedBox(height: 10),
                  ],
                  ..._filtered.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: p.isQuestion
                          ? _QuestionCard(post: p, onTap: () => _openPost(p))
                          : _PostCard(post: p, onTap: () => _openPost(p)),
                    ),
                  ),
                  if (_filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: Center(
                        child: Text(
                          'Chưa có bài viết nào.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.ink4,
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
      floatingActionButton: _ComposeFab(onTap: () {}),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onSearch});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DIỄN ĐÀN GIA SƯ',
                  style: AppTextStyles.eyebrow(color: AppColors.oxblood),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Chia sẻ',
                        style: GoogleFonts.bricolageGrotesque(
                          fontWeight: FontWeight.w800,
                          fontSize: 26,
                          letterSpacing: -0.5,
                          height: 1.05,
                          color: AppColors.ink,
                        ),
                      ),
                      TextSpan(
                        text: ' & học hỏi.',
                        style: GoogleFonts.ibmPlexSerif(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w400,
                          fontSize: 24,
                          color: AppColors.ink2,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onSearch,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.paper,
                border: Border.all(color: AppColors.line),
              ),
              child: const Icon(
                Icons.search_rounded,
                size: 18,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        scrollDirection: Axis.horizontal,
        itemCount: kForumCategories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final active = i == selected;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active ? AppColors.ink : AppColors.paper,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: active ? AppColors.ink : AppColors.line,
                ),
              ),
              child: Text(
                kForumCategories[i],
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.cream : AppColors.ink3,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PinnedPost extends StatelessWidget {
  const _PinnedPost({required this.post, required this.onTap});

  final MockForumPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const RadialGradient(
                    center: Alignment(1.1, -1.1),
                    radius: 1.2,
                    colors: [Color(0x28D4B483), Colors.transparent],
                    stops: [0.0, 0.6],
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    UserAvatar(name: post.authorName, size: 34),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.authorName,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.cream,
                            ),
                          ),
                          Text(
                            post.authorRole,
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              color: AppColors.cream.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _PinnedBadge(),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  post.title,
                  style: GoogleFonts.ibmPlexSerif(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.cream,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  post.preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.cream.withValues(alpha: 0.6),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    StatChip(
                      icon: Icons.favorite_border_rounded,
                      count: post.likes,
                      onInk: true,
                    ),
                    const SizedBox(width: 10),
                    StatChip(
                      icon: Icons.chat_bubble_outline_rounded,
                      count: post.comments,
                      onInk: true,
                    ),
                    const Spacer(),
                    Text(
                      post.timeAgo,
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        color: AppColors.cream.withValues(alpha: 0.38),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.post, required this.onTap});

  final MockForumPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent bar
              Container(
                width: 3,
                decoration: BoxDecoration(
                  color: AppColors.oxblood,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        UserAvatar(name: post.authorName, size: 30),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.authorName,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              Text(
                                post.authorRole,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: AppColors.ink4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          post.timeAgo,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.ink4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text(
                      post.title,
                      style: GoogleFonts.ibmPlexSerif(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.ink,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      post.preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.ink3,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Reward pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.ink,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 11,
                                color: AppColors.gold,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Trả lời · +${post.rewardPoints ?? 50} uy tín',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.cream,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (post.comments > 0)
                          StatChip(
                            icon: Icons.chat_bubble_outline_rounded,
                            count: post.comments,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.onTap});

  final MockForumPost post;
  final VoidCallback onTap;

  Color get _catFg => switch (post.category) {
    'Phương pháp' => AppColors.oxblood,
    'Tài liệu' => AppColors.moss,
    'Hỏi đáp' => const Color(0xFF5C3A1A),
    _ => AppColors.ink3,
  };

  Color get _catBg => switch (post.category) {
    'Phương pháp' => const Color(0xFFF5DEDE),
    'Tài liệu' => const Color(0xFFDDE6DD),
    'Hỏi đáp' => const Color(0xFFF0E3CA),
    _ => AppColors.cream2,
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(name: post.authorName, size: 34),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        post.authorRole,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: AppColors.ink4,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  post.timeAgo,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: AppColors.ink4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              post.title,
              style: GoogleFonts.ibmPlexSerif(
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
                color: AppColors.ink,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              post.preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppColors.ink3,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
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
                    post.category,
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: _catFg,
                      letterSpacing: 0.06,
                    ),
                  ),
                ),
                const Spacer(),
                StatChip(
                  icon: Icons.favorite_border_rounded,
                  count: post.likes,
                ),
                const SizedBox(width: 10),
                StatChip(
                  icon: Icons.chat_bubble_outline_rounded,
                  count: post.comments,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposeFab extends StatelessWidget {
  const _ComposeFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(AppRadius.full),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_outlined, size: 16, color: AppColors.cream),
            const SizedBox(width: 8),
            Text(
              'Viết bài',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.cream,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pinned badge ──────────────────────────────────────────────────────────

class _PinnedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.push_pin_rounded, size: 9, color: AppColors.gold),
          const SizedBox(width: 3),
          Text(
            'NỔI BẬT',
            style: GoogleFonts.inter(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: AppColors.gold,
              letterSpacing: 0.15,
            ),
          ),
        ],
      ),
    );
  }
}

class StatChip extends StatelessWidget {
  const StatChip({
    required this.icon,
    required this.count,
    super.key,
    this.onInk = false,
  });

  final IconData icon;
  final int count;
  final bool onInk;

  Color get _color =>
      onInk ? AppColors.cream.withValues(alpha: 0.45) : AppColors.ink4;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: _color),
        const SizedBox(width: 3),
        Text(
          '$count',
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: _color,
          ),
        ),
      ],
    );
  }
}
