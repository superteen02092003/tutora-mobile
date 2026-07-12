import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/features/student/presentation/screens/tutor_detail/tutor_about_section.dart';
import 'package:tutora/features/student/presentation/screens/tutor_detail/tutor_certificates_section.dart';
import 'package:tutora/features/student/presentation/screens/tutor_detail/tutor_hero_section.dart';
import 'package:tutora/features/student/presentation/screens/tutor_detail/tutor_reviews_section.dart';
import 'package:tutora/features/student/presentation/widgets/booking_bottom_sheet.dart';
import 'package:tutora/features/tutor_search/data/models/tutor_detail_models.dart';
import 'package:tutora/features/tutor_search/presentation/controllers/tutor_detail_controller.dart';
import 'package:tutora/shared/widgets/skeletons.dart';
import 'package:video_player/video_player.dart';

class TutorDetailPage extends ConsumerWidget {
  const TutorDetailPage({required this.tutorId, super.key});

  final String tutorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tutorDetailControllerProvider(tutorId));

    final loaded = state is TutorDetailLoaded ? state.profile : null;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: switch (state) {
        TutorDetailLoading() => const TutorDetailSkeleton(),
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
      // Fixed booking button pinned to the bottom.
      bottomNavigationBar: loaded == null
          ? null
          : _BookingBar(tutorId: tutorId, profile: loaded),
    );
  }
}

// Loaded body — layout order:
// top bar (back + share/wishlist) → video → avatar+name → key info
// → about → certificates → reviews → inline booking button at the bottom.
class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.tutorId, required this.profile});
  final String tutorId;
  final TutorFullProfileDto profile;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return ListView(
      padding: EdgeInsets.only(bottom: bottomPad + 8),
      children: [
        _TopBar(tutorId: tutorId, profile: profile),
        if (profile.videoIntroUrl != null)
          _VideoSection(videoUrl: profile.videoIntroUrl!),
        TutorHeroSection(profile: profile),
        const _Divider(),
        TutorAboutSection(profile: profile),
        if (profile.certificates != null &&
            profile.certificates!.isNotEmpty) ...[
          const _Divider(),
          TutorCertificatesSection(certificates: profile.certificates!),
        ],
        const _Divider(),
        TutorReviewsSection(
          feedbacks: profile.feedbacks ?? [],
          averageRating: profile.averageRating,
          totalFeedbacks: profile.totalFeedbacks,
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

// Top bar: back (left), share + wishlist (right).
class _TopBar extends StatelessWidget {
  const _TopBar({required this.tutorId, required this.profile});
  final String tutorId;
  final TutorFullProfileDto profile;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _CircleIconBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => context.pop(),
          ),
          Row(
            children: [
              _CircleIconBtn(
                icon: Icons.ios_share_rounded,
                onTap: () => _onShare(context),
              ),
              const SizedBox(width: 10),
              _CircleIconBtn(
                icon: Icons.favorite_border_rounded,
                onTap: () => _onWishlist(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onShare(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Chia sẻ hồ sơ ${profile.displayName}')),
    );
  }

  void _onWishlist(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu vào danh sách yêu thích')),
    );
  }
}

class _CircleIconBtn extends StatelessWidget {
  const _CircleIconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.paper,
          border: Border.all(color: AppColors.line),
        ),
        child: Icon(icon, size: 15, color: AppColors.ink),
      ),
    );
  }
}

// Video section
class _VideoSection extends StatelessWidget {
  const _VideoSection({required this.videoUrl});
  final String videoUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Video giới thiệu',
                style: GoogleFonts.bricolageGrotesque(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.oxblood.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  'TUTORA Original',
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.oxblood,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _VideoPlayerScreen(videoUrl: videoUrl),
              ),
            ),
            child: Container(
              height: 190,
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
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black26, Colors.black54],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.4),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: AppColors.ink,
                        size: 30,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    bottom: 14,
                    child: Text(
                      'Bấm để xem video giới thiệu',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Video player screen
class _VideoPlayerScreen extends StatefulWidget {
  const _VideoPlayerScreen({required this.videoUrl});
  final String videoUrl;

  @override
  State<_VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<_VideoPlayerScreen> {
  late VideoPlayerController _vpc;
  ChewieController? _chewieController;
  bool _error = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
        DeviceOrientation.portraitUp,
      ]),
    );
    unawaited(_init());
  }

  Future<void> _init() async {
    _vpc = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
      httpHeaders: const {'Accept': '*/*'},
    );
    try {
      await _vpc.initialize();
      if (!mounted) return;
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _vpc,
          autoPlay: true,
          placeholder: Container(color: Colors.black),
          errorBuilder: (_, msg) => Center(
            child: Text(msg, style: const TextStyle(color: Colors.white)),
          ),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    unawaited(
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
    );
    _chewieController?.dispose();
    unawaited(_vpc.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'Video giới thiệu',
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: Center(
        child: _error
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white54,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Không thể tải video. Vui lòng thử lại.',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: GoogleFonts.inter(
                        color: Colors.white30,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              )
            : _chewieController == null
            ? const CircularProgressIndicator(color: Colors.white)
            : Chewie(controller: _chewieController!),
      ),
    );
  }
}

// Booking button pinned to the bottom of the screen (no price — pricing is
// shown per subject/grade in the "cấp lớp giảng dạy" section).
class _BookingBar extends StatelessWidget {
  const _BookingBar({required this.tutorId, required this.profile});
  final String tutorId;
  final TutorFullProfileDto profile;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPad),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: GestureDetector(
        onTap: () => showBookingSheet(context, profile, tutorId),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Text(
            'Đặt lịch học ngay',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
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
