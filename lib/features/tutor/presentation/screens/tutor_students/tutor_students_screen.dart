import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/models/recorder_models.dart';
import 'package:tutora/features/tutor/presentation/providers/recorder_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_students/tutor_student_detail_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_students/tutor_student_form_screen.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';
import 'package:tutora/features/tutor/presentation/widgets/course_renew.dart';

/// Tab "Học sinh" (V5.6, canvas V56-Classes): mọi học sinh gia sư tự thêm,
/// học 1-1. Ô "Tìm theo tên hoặc lớp", thẻ hai cột (tên, "Lớp 8 · T2, T5");
/// bấm vào mở hồ sơ, "+ Thêm" mở form thêm học sinh.
class TutorStudentsScreen extends ConsumerStatefulWidget {
  const TutorStudentsScreen({super.key});

  @override
  ConsumerState<TutorStudentsScreen> createState() =>
      _TutorStudentsScreenState();
}

/// Khớp "tìm theo tên hoặc lớp": tên (không phân biệt hoa thường, dấu) hoặc
/// lớp ("8", "lớp 8", "lop 8").
bool studentMatchesQuery(RecorderStudentDto s, String query) {
  final q = foldVietnamese(query.trim());
  if (q.isEmpty) return true;
  if (foldVietnamese(s.fullName).contains(q)) return true;
  final grade = s.grade;
  if (grade == null) return false;
  return q == '$grade' || q == 'lop $grade' || q == 'lop$grade';
}

/// Chữ thường, bỏ dấu tiếng Việt ("Bảo" → "bao", "Lớp" → "lop").
String foldVietnamese(String s) {
  const from =
      'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
  const to =
      'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
  final lower = s.toLowerCase();
  final b = StringBuffer();
  for (final r in lower.runes) {
    final c = String.fromCharCode(r);
    final i = from.indexOf(c);
    b.write(i < 0 ? c : to[i]);
  }
  return b.toString();
}

class _TutorStudentsScreenState extends ConsumerState<TutorStudentsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(recorderStudentsProvider);
    final all = async.valueOrNull ?? const <RecorderStudentDto>[];
    final loading = async.isLoading && async.valueOrNull == null;
    final students = all.where((s) => studentMatchesQuery(s, _query)).toList();
    // Học sinh đã hết khóa lên đầu, kèm khối gia hạn tháng mới.
    final ended = students
        .where((s) => s.courseStatus() == CourseStatus.ended)
        .toList();
    final learning = students
        .where((s) => s.courseStatus() != CourseStatus.ended)
        .toList();
    final learningAll = all
        .where((s) => s.courseStatus() != CourseStatus.ended)
        .length;

    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: DecoratedBox(
        decoration: TutorSurface.paper,
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: TutorColors.primary,
            onRefresh: () => ref.refresh(recorderStudentsProvider.future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                TutorSurface.gutter,
                22,
                TutorSurface.gutter,
                32,
              ),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Học sinh', style: TutorType.screenTitle()),
                          const SizedBox(height: 4),
                          Text(
                            loading
                                ? 'Đang tải…'
                                : '$learningAll em đang học · học 1-1',
                            style: TutorType.rowSub(),
                          ),
                        ],
                      ),
                    ),
                    _AddChip(
                      onTap: () =>
                          unawaited(TutorStudentFormScreen.open(context)),
                    ),
                  ],
                ),
                if (all.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _SearchField(onChanged: (v) => setState(() => _query = v)),
                ],
                const SizedBox(height: 16),
                if (!loading && all.isEmpty)
                  _Empty(
                    onAdd: () =>
                        unawaited(TutorStudentFormScreen.open(context)),
                  )
                else if (students.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Text(
                      'Không có học sinh nào khớp "${_query.trim()}".',
                      textAlign: TextAlign.center,
                      style: TutorType.rowSub(),
                    ),
                  )
                else ...[
                  if (ended.isNotEmpty) ...[
                    Text(
                      'Hết khóa · ${ended.length}',
                      style: TutorType.kicker(),
                    ),
                    const SizedBox(height: 8),
                    for (final s in ended) ...[
                      _EndedCard(student: s),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 12),
                  ],
                  if (learning.isNotEmpty) ...[
                    Text('Đang học', style: TutorType.kicker()),
                    const SizedBox(height: 8),
                    _Grid(students: learning),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddChip extends StatelessWidget {
  const _AddChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: TutorColors.surface,
    shape: const StadiumBorder(),
    elevation: 1,
    shadowColor: const Color(0x331F2A24),
    child: InkWell(
      customBorder: const StadiumBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, size: 18, color: TutorColors.ink),
            const SizedBox(width: 4),
            Text('Thêm', style: TutorType.action()),
          ],
        ),
      ),
    ),
  );
}

class _Grid extends StatelessWidget {
  const _Grid({required this.students});

  final List<RecorderStudentDto> students;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 10.0;
        final w = (c.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final s in students)
              SizedBox(
                width: w,
                child: _StudentCard(student: s, glyph: studentGlyph(s)),
              ),
          ],
        );
      },
    );
  }
}

/// Ký hiệu chìm góc thẻ (V56-Classes): x², √ hoặc π, cố định theo học sinh
/// (không đổi khi lọc tìm kiếm).
String studentGlyph(RecorderStudentDto s) {
  const glyphs = ['x²', '√', 'π'];
  final sum = s.studentId.codeUnits.fold<int>(0, (a, c) => a + c);
  return glyphs[sum % glyphs.length];
}

/// "Lớp 8 · T2, T5" — lớp và các ngày học trong tuần (V56-Classes).
String studentCardLine(RecorderStudentDto s) {
  final days = {for (final x in s.schedule) x.dayOfWeek}.toList()..sort();
  return [
    if (s.grade != null) 'Lớp ${s.grade}',
    if (days.isNotEmpty)
      days.map((d) => RecorderScheduleSlot.dayLabels[d - 1]).join(', '),
  ].join(' · ');
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.student, required this.glyph});

  final RecorderStudentDto student;
  final String glyph;

  @override
  Widget build(BuildContext context) {
    final s = student;
    return DecoratedBox(
      decoration: TutorSurface.card(),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(TutorSurface.radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () =>
              unawaited(TutorStudentDetailScreen.open(context, s.studentId)),
          child: Stack(
            children: [
              Positioned(
                right: -2,
                bottom: -16,
                child: ExcludeSemantics(
                  child: Text(
                    glyph,
                    style: TutorType.display(
                      size: 72,
                      weight: FontWeight.w500,
                      color: const Color(0x122E4A3A),
                      height: 1,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TutorType.body(),
                    ),
                    Text(
                      studentCardLine(s).isEmpty
                          ? 'Học 1-1'
                          : studentCardLine(s),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TutorType.rowSub(),
                    ),
                    const SizedBox(height: 10),
                    CourseStatusLabel(student: s),
                    if (!s.hasConsent) ...[
                      const SizedBox(height: 6),
                      const CanvasTag('Chờ phụ huynh đồng ý'),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Học sinh đã hết khóa: tên (bấm mở hồ sơ) + khối gia hạn tháng mới.
class _EndedCard extends StatelessWidget {
  const _EndedCard({required this.student});

  final RecorderStudentDto student;

  @override
  Widget build(BuildContext context) {
    final s = student;
    return DecoratedBox(
      decoration: TutorSurface.card(),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => unawaited(
                TutorStudentDetailScreen.open(context, s.studentId),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 4, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.fullName, style: TutorType.body()),
                          if (s.subtitle.isNotEmpty)
                            Text(s.subtitle, style: TutorType.rowSub()),
                        ],
                      ),
                    ),
                    CourseStatusLabel(student: s),
                    const SizedBox(width: 4),
                    const CanvasChevron(),
                  ],
                ),
              ),
            ),
            CourseRenewPanel(student: s),
          ],
        ),
      ),
    );
  }
}

/// Ô "Tìm theo tên hoặc lớp" (V56-Classes): viên thuốc sáng, viền mảnh.
class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    onChanged: onChanged,
    textInputAction: TextInputAction.search,
    style: TutorType.body(),
    decoration: InputDecoration(
      isDense: true,
      hintText: 'Tìm theo tên hoặc lớp',
      hintStyle: TutorType.rowSub(),
      prefixIcon: const Icon(
        Icons.search_rounded,
        size: 20,
        color: TutorColors.ink3,
      ),
      filled: true,
      fillColor: TutorColors.surface,
      contentPadding: const EdgeInsets.symmetric(vertical: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(21),
        borderSide: const BorderSide(color: Color(0x0F1F2A24)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(21),
        borderSide: const BorderSide(color: Color(0x0F1F2A24)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(21),
        borderSide: const BorderSide(color: TutorColors.ink3),
      ),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 60),
    child: Column(
      children: [
        const CanvasHand('Bắt đầu với em đầu tiên'),
        const SizedBox(height: 18),
        Text('Chưa có học sinh', style: TutorType.sectionTitle()),
        const SizedBox(height: 6),
        Text(
          'Thêm học sinh để ghi âm và gửi báo cáo cho phụ huynh.',
          textAlign: TextAlign.center,
          style: TutorType.rowSub(),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: 200,
          child: CanvasCta(
            label: '+ Thêm học sinh',
            onPressed: onAdd,
            secondary: true,
          ),
        ),
      ],
    ),
  );
}
