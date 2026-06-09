import 'package:tutora/features/parent/data/models/parent_models.dart';

/// Toggle mock lessons on/off for UI testing.
const kUseMockLessons = true;

/// Remove an ID once real data is available for that student.
const _mockStudentIds = {'STU-D08A6FBD31'};

/// Returns a mock upcoming lesson for [studentId] if mocking is active and
/// [studentId] is in [_mockStudentIds], otherwise null.
ParentLessonDto? mockNextLessonFor(
  String? studentId,
  String? studentName,
) {
  if (!kUseMockLessons) return null;
  if (studentId == null || !_mockStudentIds.contains(studentId)) return null;

  final start = DateTime.now().add(const Duration(hours: 2));
  final end = start.add(const Duration(hours: 1));
  String iso(DateTime d) => d.toIso8601String();

  return ParentLessonDto.fromJson({
    'lessonId': -1,
    'scheduledStart': iso(start),
    'scheduledEnd': iso(end),
    'studentId': studentId,
    'studentName': studentName ?? '',
    'tutorId': 'mock-tutor',
    'tutorName': 'Cô Mai Anh',
    'subjectName': 'Toán 9',
    'status': 'scheduled',
    'teachingMode': 'online',
  });
}
