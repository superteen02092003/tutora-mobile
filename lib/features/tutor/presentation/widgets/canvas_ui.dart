import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';

/// Thành phần dùng chung theo design V5.6 (canvas "TopTutor tutor app V5.6",
/// 2026-11-12): nhãn nhỏ thường, tiêu đề Bricolage, thẻ bo 20 có bóng nhẹ, đường
/// kẻ mảnh 10%, nút xanh rêu dạng viên thuốc, thẻ sage "tiếp theo", nhãn
/// "Nháp AI" (quy tắc D1), bóng đèn cho mọi mẹo, chữ viết tay Charm.
///
/// Tên lớp và tham số giữ như bản "Swiss" trước để màn cũ vẫn dựng được.

/// Nhãn nhỏ đầu khối ("Cần bạn duyệt"). V5.6: chữ thường, không giãn.
class CanvasKicker extends StatelessWidget {
  const CanvasKicker(this.text, {this.color = TutorColors.ink3, super.key});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: TutorType.kicker(color: color));
}

/// Nút tròn quay lại (42 px, nền giấy sáng, bóng nhẹ).
class CanvasBackButton extends StatelessWidget {
  const CanvasBackButton({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CanvasCircleButton(
    onTap: onTap,
    tooltip: 'Quay lại',
    child: const Icon(
      Icons.chevron_left_rounded,
      size: 24,
      color: TutorColors.ink,
    ),
  );
}

/// Nút tròn 42 px (chuông, bóng đèn, quay lại).
class CanvasCircleButton extends StatelessWidget {
  const CanvasCircleButton({
    required this.child,
    required this.onTap,
    required this.tooltip,
    this.color = const Color(0xFFF8F7F4),
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String tooltip;
  final Color color;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Semantics(
      button: true,
      label: tooltip,
      excludeSemantics: true,
      child: Material(
        color: color,
        shape: const CircleBorder(),
        shadowColor: const Color(0x331F2A24),
        elevation: 1,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 44, height: 44, child: Center(child: child)),
        ),
      ),
    ),
  );
}

/// Đầu màn: nút quay lại tròn hoặc nhãn trái, nhãn phải, tiêu đề, mô tả.
class CanvasHeader extends StatelessWidget {
  const CanvasHeader({
    required this.title,
    this.left,
    this.right,
    this.lead,
    this.onBack,
    this.trailing,
    this.titleSize = 26,
    super.key,
  });

  final String title;
  final String? left;
  final String? right;
  final String? lead;
  final VoidCallback? onBack;
  final Widget? trailing;

  /// Cỡ tiêu đề; bản cũ dùng 34–46, V5.6 giới hạn tối đa 28.
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TutorSurface.gutter,
        16,
        TutorSurface.gutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onBack != null || right != null || trailing != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  if (onBack != null) CanvasBackButton(onTap: onBack!),
                  const Spacer(),
                  if (right != null)
                    Flexible(
                      child: Text(
                        right!,
                        textAlign: TextAlign.right,
                        style: TutorType.rowSub(),
                      ),
                    ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                ],
              ),
            ),
          if (left != null) ...[
            CanvasKicker(left!),
            const SizedBox(height: 4),
          ],
          Text(
            title,
            style: TutorType.display(size: math.min(titleSize, 28)),
          ),
          if (lead != null) ...[
            const SizedBox(height: 6),
            Text(lead!, style: TutorType.rowSub().copyWith(fontSize: 14)),
          ],
        ],
      ),
    );
  }
}

/// Hàng danh sách có đường kẻ mảnh phía trên (và tuỳ chọn phía dưới).
class CanvasRow extends StatelessWidget {
  const CanvasRow({
    required this.child,
    this.onTap,
    this.lastRule = false,
    this.padding = const EdgeInsets.symmetric(vertical: 13),
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool lastRule;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        border: Border(
          top: TutorSurface.rule,
          bottom: lastRule ? TutorSurface.rule : BorderSide.none,
        ),
      ),
      child: child,
    );
    if (onTap == null) return body;
    return InkWell(onTap: onTap, child: body);
  }
}

/// Mũi tên cuối hàng (mảnh, xám).
class CanvasChevron extends StatelessWidget {
  const CanvasChevron({this.color = const Color(0xFFA3A8A2), super.key});

  final Color color;

  @override
  Widget build(BuildContext context) =>
      Icon(Icons.chevron_right_rounded, size: 20, color: color);
}

/// Chip nhỏ cao 22 ("Tiếp theo", "Bạn ở đây"); `filled` = nền mực chữ trắng.
class CanvasTag extends StatelessWidget {
  const CanvasTag(this.text, {this.filled = false, super.key});

  final String text;
  final bool filled;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: filled ? TutorColors.ink : const Color(0xFFEAEAE4),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Text(
      text,
      maxLines: 1,
      style: TutorType.caption(
        color: filled ? Colors.white : TutorColors.ink,
      ).copyWith(fontSize: 11.5, height: 1),
    ),
  );
}

/// Nhãn xám "Nháp AI" trên mọi khối do AI soạn (quy tắc D1).
class CanvasAiDraftTag extends StatelessWidget {
  const CanvasAiDraftTag({this.onSage = false, super.key});

  /// Trên thẻ sage dùng nền sáng hơn để không chìm.
  final bool onSage;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: onSage ? const Color(0xFFF8F7F4) : const Color(0xFFEAEAE4),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Text(
      'Nháp AI',
      style: TutorType.caption(
        color: const Color(0xFF4A514C),
      ).copyWith(fontSize: 11.5, height: 1),
    ),
  );
}

/// Nút chính: xanh rêu đậm, chữ trắng, dạng viên thuốc cao 48.
class CanvasCta extends StatelessWidget {
  const CanvasCta({
    required this.label,
    required this.onPressed,
    this.icon,
    this.secondary = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;

  /// Nút phụ: nền sage, chữ mực.
  final bool secondary;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    width: double.infinity,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: secondary ? TutorColors.sage : TutorColors.primary,
        foregroundColor: secondary ? TutorColors.ink : Colors.white,
        disabledBackgroundColor: TutorColors.surfaceSunken,
        shape: const StadiumBorder(),
        textStyle: TutorType.action().copyWith(fontSize: 15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 8)],
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    ),
  );
}

/// Nút phụ dạng chữ xám ("Về trang chủ").
class CanvasGhostLink extends StatelessWidget {
  const CanvasGhostLink({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(22),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Center(
        child: Text(label, style: TutorType.action(color: TutorColors.ink3)),
      ),
    ),
  );
}

/// Khối tối xanh rêu (banner, việc đang tập trung) — một lần mỗi màn.
class CanvasDarkCard extends StatelessWidget {
  const CanvasDarkCard({required this.child, this.onTap, super.key});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: TutorSurface.cardInk(),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(TutorSurface.radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: Colors.white),
            child: child,
          ),
        ),
      ),
    ),
  );
}

/// Thẻ mức 1 (nền sáng, bóng nhẹ). Tên giữ từ bản "viền mực" trước.
class CanvasOutlineCard extends StatelessWidget {
  const CanvasOutlineCard({
    required this.child,
    this.onTap,
    this.sage = false,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Thẻ sage nổi (mức 2) cho "việc tiếp theo / cần bạn".
  final bool sage;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: sage ? TutorSurface.sage() : TutorSurface.card(),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(TutorSurface.radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
}

/// Ô gợi ý có bóng đèn (mọi mẹo đều có bóng đèn — quy tắc của Michael).
class CanvasTipBox extends StatelessWidget {
  const CanvasTipBox(this.text, {this.bold, super.key});

  final String text;

  /// Phần in đậm đứng đầu ("Lần sau:").
  final String? bold;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: TutorColors.sage,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(
            Icons.lightbulb_outline_rounded,
            size: 18,
            color: TutorColors.ink,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                if (bold != null)
                  TextSpan(
                    text: '$bold ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                TextSpan(text: text),
              ],
            ),
            style: TutorType.rowSub(color: TutorColors.ink),
          ),
        ),
      ],
    ),
  );
}

/// Chữ viết tay Charm nghiêng −4° với nét gạch dưới (chỉ ở khoảng trống).
class CanvasHand extends StatelessWidget {
  const CanvasHand(this.text, {this.size = 19, this.swash = true, super.key});

  final String text;
  final double size;
  final bool swash;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: -4 * math.pi / 180,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text, style: TutorType.hand(size: size)),
        if (swash)
          CustomPaint(size: const Size(96, 10), painter: _SwashPainter()),
      ],
    ),
  );
}

class _SwashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF8E938D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(2, size.height - 2)
      ..quadraticBezierTo(size.width * 0.45, 0, size.width - 2, 4);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 4 chấm mức kỹ năng (thay thanh tiến độ).
class CanvasSkillDots extends StatelessWidget {
  const CanvasSkillDots({required this.level, this.max = 4, super.key});

  final int level;
  final int max;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Mức $level trên $max',
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < max; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < level ? TutorColors.ink : const Color(0x241F2A24),
            ),
          ),
        ],
      ],
    ),
  );
}

/// Mục mở/thu gọn: hàng kẻ mảnh, dấu + / −.
class CanvasExpander extends StatefulWidget {
  const CanvasExpander({
    required this.title,
    required this.children,
    this.badge,
    this.lastRule = false,
    super.key,
  });

  final String title;
  final List<Widget> children;
  final String? badge;
  final bool lastRule;

  @override
  State<CanvasExpander> createState() => _CanvasExpanderState();
}

class _CanvasExpanderState extends State<CanvasExpander> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: TutorSurface.rule,
          bottom: widget.lastRule ? TutorSurface.rule : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.title, style: TutorType.rowTitle()),
                  ),
                  if (widget.badge != null) ...[
                    CanvasTag(widget.badge!),
                    const SizedBox(width: 10),
                  ],
                  Icon(
                    _open ? Icons.remove_rounded : Icons.add_rounded,
                    size: 20,
                    color: TutorColors.ink3,
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DefaultTextStyle.merge(
                style: TutorType.rowSub(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final c in widget.children) ...[
                      c,
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Hàng số liệu "Nhãn ........ 5".
class CanvasStatRow extends StatelessWidget {
  const CanvasStatRow({
    required this.label,
    required this.value,
    this.suffix,
    this.lastRule = false,
    super.key,
  });

  final String label;
  final String value;
  final String? suffix;
  final bool lastRule;

  @override
  Widget build(BuildContext context) => CanvasRow(
    lastRule: lastRule,
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(child: Text(label, style: TutorType.rowSub())),
        Text(value, style: TutorType.numeral()),
        if (suffix != null) Text(' · $suffix', style: TutorType.rowSub()),
      ],
    ),
  );
}

/// Thanh trượt xanh rêu (V5.6 "slide control"): kéo núm sang phải quá 85% mới
/// chạy [onDone] — dùng cho thao tác không nên bấm nhầm ("Trượt để gửi phụ
/// huynh"). Trình đọc màn hình bấm thẳng được qua [semanticsLabel].
class CanvasSlideAction extends StatefulWidget {
  const CanvasSlideAction({
    required this.label,
    required this.semanticsLabel,
    required this.onDone,
    this.busy = false,
    this.busyLabel = 'Đang gửi…',
    this.enabled = true,
    this.knobIcon = Icons.arrow_forward_rounded,
    super.key,
  });

  final String label;
  final String semanticsLabel;
  final VoidCallback onDone;
  final bool busy;
  final String busyLabel;
  final bool enabled;
  final IconData knobIcon;

  @override
  State<CanvasSlideAction> createState() => _CanvasSlideActionState();
}

class _CanvasSlideActionState extends State<CanvasSlideAction> {
  static const double _h = 56;
  static const double _knob = 46;
  static const double _inset = 5;
  double _dx = 0;

  bool get _active => widget.enabled && !widget.busy;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final max = c.maxWidth - _knob - _inset * 2;
        final t = max <= 0 ? 0.0 : (_dx / max).clamp(0.0, 1.0);
        return Semantics(
          button: true,
          label: widget.semanticsLabel,
          onTap: _active ? widget.onDone : null,
          child: Container(
            height: _h,
            decoration: BoxDecoration(
              color: widget.enabled
                  ? TutorColors.ink
                  : TutorColors.ink.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(_h / 2),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(left: _knob),
                    child: Opacity(
                      opacity: 1 - t,
                      child: Text(
                        widget.busy ? widget.busyLabel : widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TutorType.action(color: const Color(0xFFC8CEC8)),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: _inset + _dx,
                  child: GestureDetector(
                    onHorizontalDragUpdate: _active
                        ? (d) => setState(
                            () => _dx = (_dx + d.delta.dx).clamp(0.0, max),
                          )
                        : null,
                    onHorizontalDragEnd: _active
                        ? (_) {
                            final done = t > 0.85;
                            setState(() => _dx = 0);
                            if (done) widget.onDone();
                          }
                        : null,
                    child: Container(
                      width: _knob,
                      height: _knob,
                      decoration: BoxDecoration(
                        color: widget.enabled
                            ? TutorColors.surface
                            : TutorColors.surface.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: widget.busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: TutorColors.ink,
                              ),
                            )
                          : Icon(
                              widget.knobIcon,
                              size: 20,
                              color: TutorColors.ink,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
