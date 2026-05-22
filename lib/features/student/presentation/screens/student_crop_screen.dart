import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:tutora/core/constants/app_colors.dart';

const _kBg = Color(0xFF0B0E18);

class StudentCropPage extends StatefulWidget {
  const StudentCropPage({required this.imageBytes, super.key});
  final Uint8List imageBytes;

  @override
  State<StudentCropPage> createState() => _StudentCropPageState();
}

class _StudentCropPageState extends State<StudentCropPage> {
  ui.Image? _image;
  bool _loading = true;
  bool _processing = false;
  Size? _displaySize;

  // Crop rect tính theo tỉ lệ [0,1] của ảnh hiển thị
  Rect _crop = const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8);

  @override
  void initState() {
    super.initState();
    unawaited(_loadImage());
  }

  Future<void> _loadImage() async {
    final codec = await ui.instantiateImageCodec(widget.imageBytes);
    final frame = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _image = frame.image;
        _loading = false;
      });
    }
  }

  Future<void> _confirmCrop() async {
    final uiImage = _image;
    final displaySize = _displaySize;
    if (uiImage == null || displaySize == null) return;
    setState(() => _processing = true);

    final scaleX = uiImage.width / displaySize.width;
    final scaleY = uiImage.height / displaySize.height;

    final srcRect = Rect.fromLTWH(
      _crop.left * displaySize.width * scaleX,
      _crop.top * displaySize.height * scaleY,
      _crop.width * displaySize.width * scaleX,
      _crop.height * displaySize.height * scaleY,
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final dstRect = Rect.fromLTWH(0, 0, srcRect.width, srcRect.height);
    canvas.drawImageRect(uiImage, srcRect, dstRect, Paint());
    final picture = recorder.endRecording();
    final cropped = await picture.toImage(
      srcRect.width.round(),
      srcRect.height.round(),
    );
    final byteData = await cropped.toByteData();
    if (!mounted) return;

    final rgba = byteData!.buffer.asUint8List();
    final decoded = img.Image.fromBytes(
      width: srcRect.width.round(),
      height: srcRect.height.round(),
      bytes: rgba.buffer,
      order: img.ChannelOrder.rgba,
    );
    final jpeg = img.encodeJpg(decoded, quality: 90);

    Navigator.of(context).pop(Uint8List.fromList(jpeg));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Khoanh vùng bài toán',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 38),
                ],
              ),
            ),

            // Image + crop overlay
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.gold,
                        strokeWidth: 2,
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        _displaySize = Size(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        );
                        return _CropEditor(
                          image: _image!,
                          displaySize: _displaySize!,
                          crop: _crop,
                          onCropChanged: (r) => setState(() => _crop = r),
                        );
                      },
                    ),
            ),

            // Bottom actions
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(
                      () => _crop = const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        'Đặt lại',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _processing
                          ? null
                          : () => unawaited(_confirmCrop()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: _processing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: AppColors.ink,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Xem giải',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
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
    );
  }
}

class _CropEditor extends StatelessWidget {
  const _CropEditor({
    required this.image,
    required this.displaySize,
    required this.crop,
    required this.onCropChanged,
  });

  final ui.Image image;
  final Size displaySize;
  final Rect crop;
  final ValueChanged<Rect> onCropChanged;

  static const _handleSize = 28.0;
  static const _minDim = 0.1;

  Rect _clamp(Rect r) {
    final l = r.left.clamp(0.0, 1.0 - _minDim);
    final t = r.top.clamp(0.0, 1.0 - _minDim);
    final w = r.width.clamp(_minDim, 1.0 - l);
    final h = r.height.clamp(_minDim, 1.0 - t);
    return Rect.fromLTWH(l, t, w, h);
  }

  Rect _toPixel(Rect n) => Rect.fromLTWH(
    n.left * displaySize.width,
    n.top * displaySize.height,
    n.width * displaySize.width,
    n.height * displaySize.height,
  );

  Rect _toNorm(Rect px) => Rect.fromLTWH(
    px.left / displaySize.width,
    px.top / displaySize.height,
    px.width / displaySize.width,
    px.height / displaySize.height,
  );

  void _handleDrag(DragUpdateDetails d, _Handle handle) {
    final px = _toPixel(crop);
    var l = px.left;
    var t = px.top;
    var r = px.right;
    var b = px.bottom;
    final dx = d.delta.dx;
    final dy = d.delta.dy;

    switch (handle) {
      case _Handle.topLeft:
        l += dx;
        t += dy;
      case _Handle.topRight:
        r += dx;
        t += dy;
      case _Handle.bottomLeft:
        l += dx;
        b += dy;
      case _Handle.bottomRight:
        r += dx;
        b += dy;
      case _Handle.center:
        l += dx;
        r += dx;
        t += dy;
        b += dy;
    }

    onCropChanged(_clamp(_toNorm(Rect.fromLTRB(l, t, r, b))));
  }

  @override
  Widget build(BuildContext context) {
    final px = _toPixel(crop);

    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: _ImagePainter(image: image),
          size: displaySize,
        ),
        CustomPaint(
          painter: _DimPainter(cropPx: px),
          size: displaySize,
        ),
        CustomPaint(
          painter: _CropBorderPainter(cropPx: px),
          size: displaySize,
        ),

        // Center drag — move whole rect
        Positioned(
          left: px.left + _handleSize,
          top: px.top + _handleSize,
          width: px.width - _handleSize * 2,
          height: px.height - _handleSize * 2,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (d) => _handleDrag(d, _Handle.center),
          ),
        ),

        // Corner handles
        _cornerHandle(px.left, px.top, _Handle.topLeft),
        _cornerHandle(px.right - _handleSize, px.top, _Handle.topRight),
        _cornerHandle(px.left, px.bottom - _handleSize, _Handle.bottomLeft),
        _cornerHandle(
          px.right - _handleSize,
          px.bottom - _handleSize,
          _Handle.bottomRight,
        ),
      ],
    );
  }

  Widget _cornerHandle(double left, double top, _Handle handle) {
    return Positioned(
      left: left,
      top: top,
      width: _handleSize,
      height: _handleSize,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (d) => _handleDrag(d, handle),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.15),
            border: Border.all(color: AppColors.gold, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

enum _Handle { topLeft, topRight, bottomLeft, bottomRight, center }

class _ImagePainter extends CustomPainter {
  const _ImagePainter({required this.image});
  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, src, dst, Paint());
  }

  @override
  bool shouldRepaint(_ImagePainter old) => old.image != image;
}

class _DimPainter extends CustomPainter {
  const _DimPainter({required this.cropPx});
  final Rect cropPx;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(cropPx)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, Paint()..color = const Color(0xBB0B0E18));
  }

  @override
  bool shouldRepaint(_DimPainter old) => old.cropPx != cropPx;
}

class _CropBorderPainter extends CustomPainter {
  const _CropBorderPainter({required this.cropPx});
  final Rect cropPx;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      cropPx,
      Paint()
        ..color = AppColors.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final gridPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 0.5;

    for (var i = 1; i < 3; i++) {
      final x = cropPx.left + cropPx.width * i / 3;
      canvas.drawLine(
        Offset(x, cropPx.top),
        Offset(x, cropPx.bottom),
        gridPaint,
      );
      final y = cropPx.top + cropPx.height * i / 3;
      canvas.drawLine(
        Offset(cropPx.left, y),
        Offset(cropPx.right, y),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CropBorderPainter old) => old.cropPx != cropPx;
}
