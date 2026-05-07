import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';

const _kBg = Color(0xFF0B0E18);
// Height of StudentShell bottom nav bar (barFlatHeight + fabLift = 64 + 18)
const _kBarH = 82.0;

class StudentCapturePage extends StatefulWidget {
  const StudentCapturePage({super.key});

  @override
  State<StudentCapturePage> createState() => _StudentCapturePageState();
}

class _StudentCapturePageState extends State<StudentCapturePage>
    with SingleTickerProviderStateMixin {
  bool _flash = false;
  bool _aligning = true;
  int _modeIndex = 1; // 0=CÔNG THỨC  1=CẢ TRANG  2=HÌNH VẼ

  late final AnimationController _scanCtrl;
  late final Animation<double> _scanAnim;
  Timer? _alignTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    unawaited(_scanCtrl.repeat(reverse: true));
    _scanAnim = CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut);
    _alignTimer = Timer(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _aligning = false);
    });
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    _alignTimer?.cancel();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;
    final bottomOffset = _kBarH + botPad + 16;

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // Background radial gradient
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.1),
                  radius: 0.85,
                  colors: [Color(0xFF2A2C36), _kBg],
                  stops: [0.0, 0.8],
                ),
              ),
            ),
          ),

          // Simulated paper document
          _DocumentSim(topOffset: topPad + 60),

          // Dim overlay with frame hole
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _DimOverlayPainter(
                  frameLeft: 24,
                  frameTop: topPad + 100,
                  frameRight: 24,
                  frameBottom: bottomOffset + 120,
                ),
              ),
            ),
          ),

          // Frame overlay (border + corner brackets + scan line + status pill)
          Positioned(
            left: 24,
            right: 24,
            top: topPad + 100,
            bottom: bottomOffset + 120,
            child: _FrameOverlay(aligning: _aligning, scanAnim: _scanAnim),
          ),

          // Top chrome
          Positioned(
            top: topPad + 12,
            left: 16,
            right: 16,
            child: _TopChrome(
              flash: _flash,
              onClose: () => context.go('/student/home'),
              onFlashToggle: () => setState(() => _flash = !_flash),
            ),
          ),

          // Mode toggle
          Positioned(
            bottom: bottomOffset + 52,
            left: 0,
            right: 0,
            child: _ModeToggle(
              modeIndex: _modeIndex,
              onTap: (i) => setState(() => _modeIndex = i),
            ),
          ),

          // Shutter row
          Positioned(
            bottom: bottomOffset - 16,
            left: 0,
            right: 0,
            child: _ShutterRow(
              onShutter: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đang xử lý bài tập…'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Simulated paper document ───────────────────────────────────────────────
class _DocumentSim extends StatelessWidget {
  const _DocumentSim({required this.topOffset});
  final double topOffset;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: topOffset,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 260,
          height: 330,
          decoration: BoxDecoration(
            color: const Color(0xFFF4EFE2),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 60,
                offset: const Offset(0, 30),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BÀI 14 · §3.4',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: const Color(0xFF3E2F28),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Bài 7.',
                style: GoogleFonts.ibmPlexSerif(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3E2F28),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Cho phương trình bậc hai',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 9,
                  height: 1.6,
                  color: const Color(0xFF3E2F28),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'x² − 5x + 6 = 0',
                  style: GoogleFonts.ibmPlexSerif(
                    fontStyle: FontStyle.italic,
                    fontSize: 11,
                    color: const Color(0xFF3E2F28),
                  ),
                ),
              ),
              Text(
                'Tìm hai nghiệm x₁, x₂ và kiểm\ntra hệ thức Vi-ét:\n x₁ + x₂ = 5,   x₁ · x₂ = 6',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 9,
                  height: 1.6,
                  color: const Color(0xFF3E2F28),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'a) Áp dụng công thức nghiệm.\nb) Phân tích nhân tử kiểm chứng.\nc) Vẽ đồ thị y = x² − 5x + 6.',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 9,
                  height: 1.6,
                  color: const Color(0xFF3E2F28),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dim overlay with rectangular hole ─────────────────────────────────────
class _DimOverlayPainter extends CustomPainter {
  const _DimOverlayPainter({
    required this.frameLeft,
    required this.frameTop,
    required this.frameRight,
    required this.frameBottom,
  });

  final double frameLeft;
  final double frameTop;
  final double frameRight;
  final double frameBottom;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x8C0B0E18);
    final hole = RRect.fromLTRBR(
      frameLeft,
      frameTop,
      size.width - frameRight,
      size.height - frameBottom,
      const Radius.circular(18),
    );
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(hole)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DimOverlayPainter old) =>
      old.frameLeft != frameLeft ||
      old.frameTop != frameTop ||
      old.frameRight != frameRight ||
      old.frameBottom != frameBottom;
}

// ── Frame overlay ──────────────────────────────────────────────────────────
class _FrameOverlay extends StatelessWidget {
  const _FrameOverlay({required this.aligning, required this.scanAnim});

  final bool aligning;
  final Animation<double> scanAnim;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Frame border
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.55),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),

            // Corner brackets
            const Positioned.fill(
              child: CustomPaint(
                painter: _CornerBracketPainter(color: AppColors.gold),
              ),
            ),

            // Scan line (only while aligning)
            if (aligning)
              AnimatedBuilder(
                animation: scanAnim,
                builder: (context, _) => Positioned(
                  left: 8,
                  right: 8,
                  top: 12 + scanAnim.value * (constraints.maxHeight - 24),
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

            // Status pill
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: Center(child: _StatusPill(aligning: aligning)),
            ),
          ],
        );
      },
    );
  }
}

// ── Corner brackets painter ────────────────────────────────────────────────
class _CornerBracketPainter extends CustomPainter {
  const _CornerBracketPainter({required this.color});
  final Color color;

  static const _len = 28.0;
  static const _r = 8.0;
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

    // Verified arc direction:
    //   TL (L=T=true):  clockwise=true
    //   TR (L=false,T=true): clockwise=true
    //   BL (L=true,T=false): clockwise=false
    //   BR (L=false,T=false): clockwise=true
    // Formula: clockwise = left ? top : true
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

// ── Status pill ────────────────────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.aligning});
  final bool aligning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: aligning ? AppColors.gold : const Color(0xFF5BD27D),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            aligning ? 'Đang căn chỉnh trang…' : 'Đã nhận diện bài tập',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top chrome ─────────────────────────────────────────────────────────────
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'QUÉT BÀI TẬP',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
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
        width: 36,
        height: 36,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        child: child,
      ),
    );
  }
}

// ── Mode toggle ────────────────────────────────────────────────────────────
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.modeIndex, required this.onTap});

  final int modeIndex;
  final ValueChanged<int> onTap;

  static const _modes = ['CÔNG THỨC', 'CẢ TRANG', 'HÌNH VẼ'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < _modes.length; i++) ...[
          if (i > 0) const SizedBox(width: 18),
          GestureDetector(
            onTap: () => onTap(i),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _modes[i],
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: i == modeIndex
                        ? AppColors.gold
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                if (i == modeIndex)
                  Container(
                    height: 1.5,
                    width: _modes[i].length * 7.0,
                    color: AppColors.gold,
                  )
                else
                  const SizedBox(height: 1.5),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── Shutter row ────────────────────────────────────────────────────────────
class _ShutterRow extends StatelessWidget {
  const _ShutterRow({required this.onShutter});
  final VoidCallback onShutter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const _SideButton(
            child: Icon(
              Icons.photo_library_outlined,
              size: 18,
              color: Colors.white,
            ),
          ),
          _ShutterButton(onTap: onShutter),
          _SideButton(
            child: Text(
              'AUTO',
              style: GoogleFonts.ibmPlexMono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  const _SideButton({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.1),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Center(child: child),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.5),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.gold,
          ),
        ),
      ),
    );
  }
}

// ── Pulsing dot helper ─────────────────────────────────────────────────────
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
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    unawaited(_ctrl.repeat(reverse: true));
    _anim = Tween<double>(begin: 0.4, end: 1).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}
