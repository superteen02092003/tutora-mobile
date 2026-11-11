import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/models/topi_models.dart';
import 'package:tutora/features/tutor/presentation/providers/topi_provider.dart';
import 'package:tutora/features/tutor/presentation/widgets/topi_ui.dart';

/// T5 "Kỹ năng": số kỹ năng tìm thấy, thanh chia theo bốn mức kèm chú thích,
/// danh sách theo mức với sao (một sao cho mỗi bậc lên).
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

class TopiSkillsView extends StatelessWidget {
  const TopiSkillsView({required this.items, required this.title, super.key});

  final List<TopiSkillItem> items;
  final String title;

  /// Thứ tự hiển thị danh sách: mức cao trước.
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
      padding: TutorSurface.cardPadding,
      decoration: TutorSurface.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TutorType.sectionTitle()),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${items.length}', style: TutorType.numeralLarge()),
              const SizedBox(width: 8),
              Expanded(
                child: Text('kỹ năng', style: TutorType.rowSub()),
              ),
              if (stars > 0) ...[
                const Icon(
                  Icons.star_rounded,
                  size: 18,
                  color: TutorColors.accent,
                ),
                const SizedBox(width: 3),
                Text('$stars sao', style: TutorType.action()),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Thanh chia theo bốn mức, cùng thứ tự với chú thích.
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  for (final l in TopiLevel.values)
                    if (byLevel[l]!.isNotEmpty)
                      Expanded(
                        flex: byLevel[l]!.length,
                        child: ColoredBox(color: TopiLevelColors.of(l)),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              for (final l in TopiLevel.values)
                _Legend(level: l, count: byLevel[l]!.length),
            ],
          ),
          for (final l in _order)
            if (byLevel[l]!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                topiLevelLabel(l).toUpperCase(),
                style: TutorType.caption(
                  color: TopiLevelColors.of(l),
                ).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.6),
              ),
              const SizedBox(height: 4),
              for (final i in byLevel[l]!) _SkillRow(item: i),
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
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: TopiLevelColors.of(level),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 5),
      Text(
        '${topiLevelLabel(level)} $count',
        style: TutorType.caption(color: TutorColors.ink3),
      ),
    ],
  );
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({required this.item});

  final TopiSkillItem item;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: TopiLevelColors.of(item.level),
            shape: BoxShape.circle,
          ),
        ),
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
