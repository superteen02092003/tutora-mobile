import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/models/topi_models.dart';
import 'package:tutora/features/tutor/presentation/providers/topi_provider.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';
import 'package:tutora/features/tutor/presentation/widgets/topi_ui.dart';

/// Thẻ "Kỹ năng" (canvas V5.6 Pupil): số kỹ năng tìm thấy, lưới bốn mức với
/// 4 chấm ("Vững · 2"), rồi danh sách theo mức với sao (một sao mỗi bậc lên).
///
/// Không vẽ gì khi cờ `skills` tắt, khi đang tải, lỗi hoặc chưa có kỹ năng.
class TopiSkillsSection extends ConsumerWidget {
  const TopiSkillsSection({
    required this.lessonId,
    this.title = 'Kỹ năng tìm thấy trong buổi',
    this.padding = const EdgeInsets.only(top: 20),
    super.key,
  });

  final String lessonId;
  final String title;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(topiFlagsNowProvider).skills) {
      return const SizedBox.shrink();
    }
    final skills = ref.watch(lessonTopiProvider(lessonId)).valueOrNull?.skills;
    final items = skills?.items ?? const <TopiSkillItem>[];
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: padding,
      child: TopiSkillsView(items: items, title: title),
    );
  }
}

int _dots(TopiLevel l) => switch (l) {
  TopiLevel.toDo => 1,
  TopiLevel.improving => 2,
  TopiLevel.standard => 3,
  TopiLevel.mastered => 4,
};

class TopiSkillsView extends StatelessWidget {
  const TopiSkillsView({required this.items, required this.title, super.key});

  final List<TopiSkillItem> items;
  final String title;

  /// Thứ tự hiển thị: mức cao trước (như lưới trên canvas).
  static const List<TopiLevel> _order = [
    TopiLevel.mastered,
    TopiLevel.standard,
    TopiLevel.improving,
    TopiLevel.toDo,
  ];

  @override
  Widget build(BuildContext context) {
    final byLevel = {
      for (final l in TopiLevel.values)
        l: items.where((i) => i.level == l).toList(),
    };
    final stars = items.fold<int>(0, (s, i) => s + i.stars);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: TutorSurface.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TutorType.caption(color: TutorColors.ink3)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${items.length}', style: TutorType.numeral()),
              const SizedBox(width: 6),
              Expanded(child: Text('kỹ năng', style: TutorType.rowSub())),
              if (stars > 0)
                Text(
                  '$stars ngôi sao',
                  style: TutorType.rowSub(color: TutorColors.ink),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Lưới 2 × 2: bốn mức, mỗi mức một hàng chấm + số kỹ năng.
          LayoutBuilder(
            builder: (context, c) {
              final w = (c.maxWidth - 14) / 2;
              return Wrap(
                spacing: 14,
                runSpacing: 10,
                children: [
                  for (final l in _order)
                    SizedBox(
                      width: w,
                      child: _Legend(level: l, count: byLevel[l]!.length),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 6),
          for (final l in _order)
            if (byLevel[l]!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(topiLevelLabel(l), style: TutorType.kicker()),
              const SizedBox(height: 2),
              for (var i = 0; i < byLevel[l]!.length; i++)
                _SkillRow(item: byLevel[l]![i], first: i == 0),
            ],
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.level, required this.count});

  final TopiLevel level;
  final int count;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      CanvasSkillDots(level: _dots(level)),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          '${topiLevelLabel(level)} · $count',
          overflow: TextOverflow.ellipsis,
          style: TutorType.rowSub(),
        ),
      ),
    ],
  );
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({required this.item, required this.first});

  final TopiSkillItem item;
  final bool first;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      border: Border(top: first ? BorderSide.none : TutorSurface.rule),
    ),
    child: Row(
      children: [
        CanvasSkillDots(level: _dots(item.level)),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                if (item.name != null)
                  TextSpan(
                    text: '${item.name}  ',
                    style: TutorType.rowTitle().copyWith(fontSize: 14),
                  ),
                TextSpan(
                  text: item.node,
                  style: item.name == null
                      ? TutorType.rowTitle().copyWith(fontSize: 14)
                      : TutorType.caption(),
                ),
              ],
            ),
          ),
        ),
        TopiStars(count: item.stars),
      ],
    ),
  );
}
