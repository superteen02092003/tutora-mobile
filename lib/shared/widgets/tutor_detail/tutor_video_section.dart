import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// The tutor intro-video card (thumbnail + play button). Tapping opens a
/// full-screen player. Shared by the student and parent tutor-detail screens.
class TutorVideoSection extends StatelessWidget {
  const TutorVideoSection({required this.videoUrl, super.key});
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

class _VideoPlayerScreen extends StatefulWidget {
  const _VideoPlayerScreen({required this.videoUrl});
  final String videoUrl;

  @override
  State<_VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<_VideoPlayerScreen> {
  // YouTube path
  YoutubePlayerController? _ytController;
  // Direct-file path (mp4 etc.)
  VideoPlayerController? _vpc;
  ChewieController? _chewieController;

  bool _error = false;
  String? _errorMessage;

  bool get _isYoutube {
    final id = YoutubePlayerController.convertUrlToId(widget.videoUrl);
    return id != null && id.isNotEmpty;
  }

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
    if (_isYoutube) {
      _initYoutube();
    } else {
      unawaited(_initFile());
    }
  }

  void _initYoutube() {
    final id = YoutubePlayerController.convertUrlToId(widget.videoUrl)!;
    _ytController = YoutubePlayerController.fromVideoId(
      videoId: id,
      autoPlay: true,
    );
  }

  Future<void> _initFile() async {
    final vpc = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
      httpHeaders: const {'Accept': '*/*'},
    );
    _vpc = vpc;
    try {
      await vpc.initialize();
      if (!mounted) return;
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: vpc,
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
    unawaited(_ytController?.close() ?? Future.value());
    _chewieController?.dispose();
    unawaited(_vpc?.dispose() ?? Future.value());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isYoutube && _ytController != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(
            'Video giới thiệu',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          elevation: 0,
        ),
        body: Center(
          child: YoutubePlayer(controller: _ytController!),
        ),
      );
    }

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
