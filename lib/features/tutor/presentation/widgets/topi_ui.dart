import 'package:flutter/material.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/models/topi_models.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';

/// Phần dùng chung cho các màn Topi: mức kỹ năng (4 chấm, design V5.6), hộp
/// gợi ý có bóng đèn, hàng sao.

/// Sắc độ bốn mức. V5.6 chỉ còn hai màu (giấy + xanh rêu) nên bốn mức là bốn
/// độ đậm của mực; mức đọc chủ yếu qua số chấm ([CanvasSkillDots]).
abstract final class TopiLevelColors {
  static const Color toDo = Color(0xFF8E938D);
  static const Color improving = Color(0xFF62686A);
  static const Color standard = Color(0xFF2E4A3A);
  static const Color mastered = Color(0xFF1F2A24);

  static Color of(TopiLevel l) => switch (l) {
    TopiLevel.toDo => toDo,
    TopiLevel.improving => improving,
    TopiLevel.standard => standard,
    TopiLevel.mastered => mastered,
  };
}

/// Nhãn mức như canvas V5.6 ("Vững · 2", "lên Chuẩn").
String topiLevelLabel(TopiLevel l) => switch (l) {
  TopiLevel.toDo => 'Cần học',
  TopiLevel.improving => 'Tiến bộ',
  TopiLevel.standard => 'Chuẩn',
  TopiLevel.mastered => 'Vững',
};

/// Số chấm sáng (1–4) của một mức.
int _dots(TopiLevel l) => switch (l) {
  TopiLevel.toDo => 1,
  TopiLevel.improving => 2,
  TopiLevel.standard => 3,
  TopiLevel.mastered => 4,
};

/// Mức kỹ năng: 4 chấm + nhãn, không nền.
class TopiLevelChip extends StatelessWidget {
  const TopiLevelChip({required this.level, super.key});

  final TopiLevel level;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Mức ${topiLevelLabel(level)}',
    excludeSemantics: true,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CanvasSkillDots(level: _dots(level)),
        const SizedBox(width: 7),
        Text(topiLevelLabel(level), style: TutorType.caption()),
      ],
    ),
  );
}

/// Chip nhỏ cao 22, bo tròn — chấm màu + nhãn trên nền giấy xám.
class TopiChip extends StatelessWidget {
  const TopiChip({required this.label, required this.color, super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFEAEAE4),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TutorType.caption(
            color: TutorColors.ink,
          ).copyWith(fontSize: 11.5, height: 1),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                Text(
                  title!,
                  style: TutorType.rowTitle().copyWith(fontSize: 14),
                ),
                const SizedBox(height: 3),
              ],
              Text(text, style: TutorType.rowSub(color: TutorColors.ink)),
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
            Icon(Icons.star_rounded, size: size, color: TutorColors.ink),
        ],
      ),
    );
  }
}
