import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:video_player/video_player.dart';

/// Trình phát video xem lại buổi học.
///
/// [streamUrl] là link proxy do BE ký token ngắn hạn (không phải link Drive),
/// hỗ trợ HTTP Range nên tua được.
class SessionRecordingPlayerScreen extends StatefulWidget {
  const SessionRecordingPlayerScreen({
    required this.streamUrl,
    super.key,
    this.title,
  });

  final String streamUrl;
  final String? title;

  @override
  State<SessionRecordingPlayerScreen> createState() =>
      _SessionRecordingPlayerScreenState();
}

class _SessionRecordingPlayerScreenState
    extends State<SessionRecordingPlayerScreen> {
  VideoPlayerController? _vpc;
  ChewieController? _chewie;
  String? _error;

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
    final vpc = VideoPlayerController.networkUrl(
      Uri.parse(widget.streamUrl),
      httpHeaders: const {'Accept': '*/*'},
    );
    _vpc = vpc;
    try {
      await vpc.initialize();
      if (!mounted) return;
      setState(() {
        _chewie = ChewieController(
          videoPlayerController: vpc,
          autoPlay: true,
          aspectRatio: vpc.value.aspectRatio,
          materialProgressColors: ChewieProgressColors(
            playedColor: AppColors.gold,
            handleColor: AppColors.gold,
            backgroundColor: Colors.white24,
            bufferedColor: Colors.white38,
          ),
          placeholder: const ColoredBox(color: Colors.black),
          errorBuilder: (_, msg) => _ErrorView(message: msg),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    unawaited(
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]),
    );
    _chewie?.dispose();
    unawaited(_vpc?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.title ?? 'Xem lại buổi học',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Center(
        child: _error != null
            ? _ErrorView(message: _error!)
            : _chewie == null
            ? const CircularProgressIndicator(
                color: AppColors.gold,
                strokeWidth: 2,
              )
            : Chewie(controller: _chewie!),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.videocam_off_rounded,
            size: 32,
            color: Colors.white54,
          ),
          const SizedBox(height: 12),
          Text(
            'Không phát được video',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Link xem lại có thể đã hết hạn. Quay lại màn buổi học và thử lại.\n$message',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white60,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
