import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/features/student/presentation/screens/student_crop_screen.dart';

const _kBg = Color(0xFF0B0E18);

class StudentCapturePage extends StatefulWidget {
  const StudentCapturePage({super.key});

  @override
  State<StudentCapturePage> createState() => _StudentCapturePageState();
}

class _StudentCapturePageState extends State<StudentCapturePage>
    with WidgetsBindingObserver {
  CameraController? _camCtrl;
  bool _camReady = false;
  bool _flash = false;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    unawaited(_initCamera());
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty || !mounted) return;

    final back = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    final ctrl = CameraController(
      back,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await ctrl.initialize();
      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      setState(() {
        _camCtrl = ctrl;
        _camReady = true;
      });
    } catch (_) {
      await ctrl.dispose();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _camCtrl;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      unawaited(ctrl.dispose());
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_initCamera());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_camCtrl?.dispose() ?? Future.value());
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    final ctrl = _camCtrl;
    if (ctrl == null || !_camReady) return;
    final next = !_flash;
    await ctrl.setFlashMode(next ? FlashMode.torch : FlashMode.off);
    setState(() => _flash = next);
  }

  Future<void> _onShutter() async {
    final ctrl = _camCtrl;
    if (ctrl == null || !_camReady || _capturing) return;
    setState(() => _capturing = true);
    try {
      final xFile = await ctrl.takePicture();
      if (!mounted) return;
      await _cropAndNavigate(xFile.path);
    } catch (_) {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _onGallery() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery);
    if (xFile == null || !mounted) return;
    setState(() => _capturing = true);
    await _cropAndNavigate(xFile.path);
  }

  Future<void> _cropAndNavigate(String path) async {
    final raw = await File(path).readAsBytes();
    if (!mounted) return;

    final cropped = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        builder: (_) => StudentCropPage(imageBytes: raw),
        fullscreenDialog: true,
      ),
    );

    if (!mounted) return;

    if (cropped == null) {
      setState(() => _capturing = false);
      return;
    }

    await context.push('/student/solution', extra: cropped);
    if (mounted) setState(() => _capturing = false);
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // Camera preview hoặc loading placeholder
          Positioned.fill(
            child: _camReady && _camCtrl != null
                ? _CameraPreview(ctrl: _camCtrl!)
                : const _DarkPlaceholder(),
          ),

          // Dim vignette
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 1.2,
                    colors: [Colors.transparent, Color(0x660B0E18)],
                  ),
                ),
              ),
            ),
          ),

          // Scan frame
          Positioned(
            top: topPad + 80,
            left: 24,
            right: 24,
            bottom: botPad + 160,
            child: const _ScanFrame(),
          ),

          // Top chrome
          Positioned(
            top: topPad + 12,
            left: 16,
            right: 16,
            child: _TopChrome(
              flash: _flash,
              onClose: () => context.go('/student/home'),
              onFlashToggle: _toggleFlash,
            ),
          ),

          // Hint
          Positioned(
            top: topPad + 56,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Căn bài toán vào khung rồi chụp',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.7),
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),

          // Thinking overlay khi đang xử lý
          if (_capturing) const Positioned.fill(child: _ThinkingOverlay()),

          // Bottom controls
          Positioned(
            bottom: botPad + 24,
            left: 0,
            right: 0,
            child: _BottomControls(
              enabled: !_capturing,
              onShutter: _onShutter,
              onGallery: _onGallery,
            ),
          ),
        ],
      ),
    );
  }
}

// Camera preview
class _CameraPreview extends StatelessWidget {
  const _CameraPreview({required this.ctrl});
  final CameraController ctrl;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: OverflowBox(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: ctrl.value.previewSize?.height ?? 1,
            height: ctrl.value.previewSize?.width ?? 1,
            child: CameraPreview(ctrl),
          ),
        ),
      ),
    );
  }
}

class _DarkPlaceholder extends StatelessWidget {
  const _DarkPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: _kBg,
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.gold,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

// Scan frame
class _ScanFrame extends StatefulWidget {
  const _ScanFrame();

  @override
  State<_ScanFrame> createState() => _ScanFrameState();
}

class _ScanFrameState extends State<_ScanFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    unawaited(_ctrl.repeat(reverse: true));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const Positioned.fill(
            child: CustomPaint(
              painter: _CornerBracketPainter(color: AppColors.gold),
            ),
          ),
          AnimatedBuilder(
            animation: _anim,
            builder: (_, _) => Positioned(
              left: 12,
              right: 12,
              top: 12 + _anim.value * (constraints.maxHeight - 24),
              child: Container(
                height: 2,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.gold,
                      Colors.transparent,
                    ],
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

// Corner brackets
class _CornerBracketPainter extends CustomPainter {
  const _CornerBracketPainter({required this.color});
  final Color color;

  static const _len = 28.0;
  static const _r = 10.0;
  static const _sw = 3.0;

  void _drawBracket(
    Canvas canvas,
    Size size, {
    required bool top,
    required bool left,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final x = left ? 0.0 : size.width;
    final y = top ? 0.0 : size.height;
    final dx = left ? 1.0 : -1.0;
    final dy = top ? 1.0 : -1.0;
    final cw = !left || top;

    final path = Path()
      ..moveTo(x, y + dy * (_len + _r))
      ..lineTo(x, y + dy * _r)
      ..arcToPoint(
        Offset(x + dx * _r, y),
        radius: const Radius.circular(_r),
        clockwise: cw,
      )
      ..lineTo(x + dx * (_len + _r), y);

    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawBracket(canvas, size, top: true, left: true);
    _drawBracket(canvas, size, top: true, left: false);
    _drawBracket(canvas, size, top: false, left: true);
    _drawBracket(canvas, size, top: false, left: false);
  }

  @override
  bool shouldRepaint(_CornerBracketPainter old) => old.color != color;
}

// Top chrome
class _TopChrome extends StatelessWidget {
  const _TopChrome({
    required this.flash,
    required this.onClose,
    required this.onFlashToggle,
  });
  final bool flash;
  final VoidCallback onClose;
  final VoidCallback onFlashToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ChromeButton(
          color: Colors.black.withValues(alpha: 0.5),
          onTap: onClose,
          child: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'QUÉT BÀI TẬP',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Colors.white,
            ),
          ),
        ),
        const Spacer(),
        _ChromeButton(
          color: flash ? AppColors.gold : Colors.black.withValues(alpha: 0.5),
          onTap: onFlashToggle,
          child: Icon(
            Icons.flash_on_rounded,
            size: 16,
            color: flash ? AppColors.ink : Colors.white,
          ),
        ),
      ],
    );
  }
}

class _ChromeButton extends StatelessWidget {
  const _ChromeButton({
    required this.color,
    required this.onTap,
    required this.child,
  });
  final Color color;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        child: Center(child: child),
      ),
    );
  }
}

// Bottom controls
class _BottomControls extends StatelessWidget {
  const _BottomControls({
    required this.enabled,
    required this.onShutter,
    required this.onGallery,
  });
  final bool enabled;
  final VoidCallback onShutter;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: enabled ? onGallery : null,
            child: AnimatedOpacity(
              opacity: enabled ? 1 : 0.4,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white.withValues(alpha: 0.1),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: const Icon(
                  Icons.photo_library_outlined,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: enabled ? onShutter : null,
            child: AnimatedScale(
              scale: enabled ? 1.0 : 0.9,
              duration: const Duration(milliseconds: 150),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 4,
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48, height: 48),
        ],
      ),
    );
  }
}

// Thinking overlay
class _ThinkingOverlay extends StatefulWidget {
  const _ThinkingOverlay();

  @override
  State<_ThinkingOverlay> createState() => _ThinkingOverlayState();
}

class _ThinkingOverlayState extends State<_ThinkingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;
  int _labelIdx = 0;
  Timer? _labelTimer;

  static const _labels = [
    'Đang nhận diện bài toán…',
    'Đang phân tích cấu trúc…',
    'Đang kết nối Tora AI…',
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    unawaited(_ctrl.repeat(reverse: true));
    _pulse = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _labelTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (mounted) setState(() => _labelIdx = (_labelIdx + 1) % _labels.length);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _labelTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xCC0B0E18),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, _) => Container(
                width: 72 + _pulse.value * 10,
                height: 72 + _pulse.value * 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.gold.withValues(
                      alpha: 0.25 + _pulse.value * 0.5,
                    ),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 24,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _labels[_labelIdx],
                key: ValueKey(_labelIdx),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85),
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
