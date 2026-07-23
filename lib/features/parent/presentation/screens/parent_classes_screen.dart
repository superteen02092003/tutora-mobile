import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/features/parent/data/models/parent_models.dart';
import 'package:tutora/features/parent/presentation/providers/parent_classes_provider.dart';
import 'package:tutora/features/parent/presentation/providers/parent_provider.dart';
import 'package:tutora/features/parent/presentation/screens/parent_session_detail_screen.dart';
import 'package:tutora/features/parent/presentation/widgets/parent_child_avatar_strip.dart';
import 'package:tutora/features/parent/presentation/widgets/parent_lesson_row.dart';

/// Tab "Lớp học" của phụ huynh: chọn con → buổi cần xác nhận + buổi sắp tới.
/// Phụ huynh CHỈ theo dõi — không có nút vào phòng học.
class ParentClassesScreen extends ConsumerStatefulWidget {
  const ParentClassesScreen({super.key});

  @override
  ConsumerState<ParentClassesScreen> createState() =>
      _ParentClassesScreenState();
}

class _ParentClassesScreenState extends ConsumerState<ParentClassesScreen> {
  String? _selectedId;

  bool _matchesSelected(ParentLessonDto l) =>
      _selectedId == null || l.studentId == _selectedId;

  Future<void> _refresh() async {
    ref
      ..invalidate(parentUpcomingLessonsProvider)
      ..invalidate(parentPendingLessonsProvider);
    await ref.read(parentStudentsProvider.notifier).load();
  }

  void _openDetail(ParentLessonDto lesson) {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => ParentSessionDetailScreen(lessonId: lesson.lessonId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentsState = ref.watch(parentStudentsProvider);
    final upcoming = ref.watch(parentUpcomingLessonsProvider);
    final pending = ref.watch(parentPendingLessonsProvider);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Text(
                'Lớp học',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
            ParentChildAvatarStrip(
              students: studentsState.students,
              isLoading: studentsState.isLoading,
              selectedId: _selectedId,
              onSelect: (id) => setState(
                () => _selectedId = _selectedId == id ? null : id,
              ),
              onAddChild: () {},
              onNotif: () {},
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.oxblood,
                onRefresh: _refresh,
                child: ListView(
                  padding: EdgeInsets.only(top: 8, bottom: bottomPad + 24),
                  children: [
                    _PendingSection(
                      async: pending,
                      filter: _matchesSelected,
                      onTap: _openDetail,
                    ),
                    _UpcomingSection(
                      async: upcoming,
                      filter: _matchesSelected,
                      onTap: _openDetail,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingSection extends StatelessWidget {
  const _PendingSection({
    required this.async,
    required this.filter,
    required this.onTap,
  });
  final AsyncValue<List<ParentLessonDto>> async;
  final bool Function(ParentLessonDto) filter;
  final ValueChanged<ParentLessonDto> onTap;

  @override
  Widget build(BuildContext context) {
    final items = (async.valueOrNull ?? []).where(filter).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Cần xác nhận'),
        ...items.map((l) => ParentLessonRow(lesson: l, onTap: () => onTap(l))),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _UpcomingSection extends StatelessWidget {
  const _UpcomingSection({
    required this.async,
    required this.filter,
    required this.onTap,
  });
  final AsyncValue<List<ParentLessonDto>> async;
  final bool Function(ParentLessonDto) filter;
  final ValueChanged<ParentLessonDto> onTap;

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.oxblood,
            strokeWidth: 2,
          ),
        ),
      ),
      error: (_, _) => const _EmptyText('Không tải được lịch học.'),
      data: (all) {
        final items = all.where(filter).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel('Buổi học sắp tới'),
            if (items.isEmpty)
              const _EmptyText('Chưa có buổi học nào sắp tới.')
            else
              ...items.map(
                (l) => ParentLessonRow(lesson: l, onTap: () => onTap(l)),
              ),
          ],
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
          color: AppColors.ink4,
        ),
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink3),
        ),
      ),
    );
  }
}
