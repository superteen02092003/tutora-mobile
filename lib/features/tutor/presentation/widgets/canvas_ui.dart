import 'package:flutter/material.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';

/// Thành phần dùng chung theo design canvas "TopTutor: tutor app and parent Mini
/// App" (11/2026): nhãn nhỏ viết hoa, tiêu đề Bricolage lớn, hàng kẻ mực 1,5 px,
/// nút đồng, khối xanh rêu đậm, ô gợi ý có bóng đèn, mục mở/thu gọn.

/// Nhãn nhỏ viết hoa giãn chữ ("BUỔI TỚI · THỨ NĂM").
class CanvasKicker extends StatelessWidget {
  const CanvasKicker(this.text, {this.color = TutorColors.ink3, super.key});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: TutorType.kicker(color: color));
}

/// Đầu màn: dòng nhãn trái/phải + tiêu đề lớn + (tuỳ chọn) đoạn mô tả.
class CanvasHeader extends StatelessWidget {
  const CanvasHeader({
    required this.title,
    this.left,
    this.right,
    this.lead,
    this.onBack,
    this.trailing,
    this.titleSize = 46,
    super.key,
  });

  final String title;
  final String? left;
  final String? right;
  final String? lead;
  final VoidCallback? onBack;
  final Widget? trailing;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TutorSurface.gutter,
        20,
        TutorSurface.gutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (onBack != null)
                Semantics(
                  button: true,
                  label: 'Quay lại',
                  child: InkWell(
                    onTap: onBack,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: CanvasKicker('‹ Quay lại', color: TutorColors.ink),
                    ),
                  ),
                )
              else if (left != null)
                Flexible(child: CanvasKicker(left!, color: TutorColors.ink)),
              const Spacer(),
              if (right != null) Flexible(child: CanvasKicker(right!)),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
          const SizedBox(height: 10),
          Text(title, style: TutorType.display(size: titleSize)),
          if (lead != null) ...[
            const SizedBox(height: 10),
            Text(
              lead!,
              style: TutorType.rowSub().copyWith(fontSize: 15, height: 1.45),
            ),
          ],
        ],
      ),
    );
  }
}

/// Hàng có đường kẻ mực phía trên (và tuỳ chọn phía dưới) — kiểu danh sách của canvas.
class CanvasRow extends StatelessWidget {
  const CanvasRow({
    required this.child,
    this.onTap,
    this.lastRule = false,
    this.padding = const EdgeInsets.symmetric(vertical: 14),
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

/// Mũi tên "›" mảnh cuối hàng.
class CanvasChevron extends StatelessWidget {
  const CanvasChevron({this.color = TutorColors.ink, super.key});

  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    '›',
    style: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w300,
      height: 1,
      color: color,
    ),
  );
}

/// Thẻ nhỏ viền mực chữ hoa ("DUYỆT", "CHUẨN BỊ"); `filled` = nền đồng.
class CanvasTag extends StatelessWidget {
  const CanvasTag(this.text, {this.filled = false, super.key});

  final String text;
  final bool filled;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: filled ? TutorColors.accent : null,
      borderRadius: BorderRadius.circular(TutorSurface.radius),
      border: Border.all(
        color: TutorColors.ink,
        width: TutorSurface.ruleWidth,
      ),
    ),
    child: Text(
      text.toUpperCase(),
      style: TutorType.kicker(color: TutorColors.ink).copyWith(
        letterSpacing: 1.2,
      ),
    ),
  );
}

/// Nút hành động chính của canvas: nền đồng, chữ mực, cao 56.
class CanvasCta extends StatelessWidget {
  const CanvasCta({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    width: double.infinity,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: TutorColors.accent,
        foregroundColor: TutorColors.ink,
        disabledBackgroundColor: TutorColors.surfaceSunken,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TutorSurface.radius),
        ),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 10)],
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    ),
  );
}

/// Nút phụ dạng chữ xám ("Mẹo ghi âm").
class CanvasGhostLink extends StatelessWidget {
  const CanvasGhostLink({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: TutorColors.ink3,
          ),
        ),
      ),
    ),
  );
}

/// Khối xanh rêu đậm (việc đang tập trung) — dùng một lần mỗi màn.
class CanvasDarkCard extends StatelessWidget {
  const CanvasDarkCard({required this.child, this.onTap, super.key});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: TutorColors.ink2,
    borderRadius: BorderRadius.circular(TutorSurface.radius),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: Colors.white),
          child: child,
        ),
      ),
    ),
  );
}

/// Thẻ viền mực (khối nhấn thứ hai, nền giấy).
class CanvasOutlineCard extends StatelessWidget {
  const CanvasOutlineCard({required this.child, this.onTap, super.key});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(TutorSurface.radius),
      side: TutorSurface.rule,
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: child,
      ),
    ),
  );
}

/// Ô gợi ý có bóng đèn (mọi mẹo / thông tin đều có bóng đèn — cuộc họp 10/11).
class CanvasTipBox extends StatelessWidget {
  const CanvasTipBox(this.text, {this.bold, super.key});

  final String text;

  /// Phần in đậm đứng đầu ("Lần sau:").
  final String? bold;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: TutorColors.surfaceSunken,
      borderRadius: BorderRadius.circular(TutorSurface.radius),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(
            Icons.lightbulb_outline_rounded,
            size: 18,
            color: TutorColors.warning,
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
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                TextSpan(text: text),
              ],
            ),
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: TutorColors.ink,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Mục mở/thu gọn kiểu `<details>` của canvas: hàng kẻ trên, dấu + / −.
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
              constraints: const BoxConstraints(minHeight: 56),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: TutorColors.ink,
                      ),
                    ),
                  ),
                  if (widget.badge != null) ...[
                    CanvasTag(widget.badge!),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    _open ? '−' : '+',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      color: TutorColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DefaultTextStyle.merge(
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: TutorColors.ink3,
                ),
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

/// Hàng số liệu "NHÃN ........ 5" của canvas (số Bricolage mảnh).
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
    padding: const EdgeInsets.fromLTRB(0, 14, 0, 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(child: CanvasKicker(label, color: TutorColors.ink)),
        Text(value, style: TutorType.numeralLarge()),
        if (suffix != null)
          Text(
            ' · $suffix',
            style: TutorType.display(
              size: 20,
              weight: FontWeight.w300,
              color: TutorColors.ink3,
            ).copyWith(letterSpacing: 0),
          ),
      ],
    ),
  );
}
