import 'package:flutter/material.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/models/topi_models.dart';

/// Phần dùng chung cho các màn Topi: màu và nhãn bốn mức kỹ năng, hộp thông
/// tin có bóng đèn, hàng sao.

/// Màu bốn mức (skills-detector, quyết định 2026-11-10).
abstract final class TopiLevelColors {
  static const Color toDo = Color(0xFFC8553D);
  static const Color improving = Color(0xFFD9A15B);
  static const Color standard = Color(0xFF3F6B57);
  static const Color mastered = Color(0xFF24443A);

  static Color of(TopiLevel l) => switch (l) {
    TopiLevel.toDo => toDo,
    TopiLevel.improving => improving,
    TopiLevel.standard => standard,
    TopiLevel.mastered => mastered,
  };
}

String topiLevelLabel(TopiLevel l) => switch (l) {
  TopiLevel.toDo => 'Cần học',
  TopiLevel.improving => 'Đang tiến bộ',
  TopiLevel.standard => 'Đạt chuẩn',
  TopiLevel.mastered => 'Thành thạo',
};

/// Chip mức kỹ năng: chấm màu + nhãn, nền nhạt cùng tông.
class TopiLevelChip extends StatelessWidget {
  const TopiLevelChip({required this.level, super.key});

  final TopiLevel level;

  @override
  Widget build(BuildContext context) {
    final c = TopiLevelColors.of(level);
    return TopiChip(
      label: topiLevelLabel(level),
      color: c,
    );
  }
}

/// Chip nhỏ một màu (nền 12% cùng tông) — cho mức kỹ năng và vai trò lỗ hổng.
class TopiChip extends StatelessWidget {
  const TopiChip({
    required this.label,
    required this.color,
    super.key,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TutorType.caption(
            color: color,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

/// Hộp thông tin / gợi ý, luôn có bóng đèn (quyết định họp 2026-11-10).
class TopiInfoBox extends StatelessWidget {
  const TopiInfoBox({required this.text, this.title, super.key});

  final String? title;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: TutorColors.accentBg,
      borderRadius: BorderRadius.circular(TutorSurface.radiusSmall),
      border: Border.all(color: TutorColors.accentBorder),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.lightbulb_outline_rounded,
          size: 18,
          color: TutorColors.warning,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                Text(title!, style: TutorType.rowTitle().copyWith(fontSize: 14)),
                const SizedBox(height: 3),
              ],
              Text(text, style: TutorType.rowSub(color: TutorColors.ink2)),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Hàng sao — một sao cho mỗi bậc lên.
class TopiStars extends StatelessWidget {
  const TopiStars({required this.count, this.size = 14, super.key});

  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Semantics(
      label: '$count sao',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            Icon(Icons.star_rounded, size: size, color: TutorColors.accent),
        ],
      ),
    );
  }
}
