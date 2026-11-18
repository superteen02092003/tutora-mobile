import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/features/tutor/data/datasources/app_recording_datasource.dart';
import 'package:tutora/features/tutor/data/datasources/recorder_datasource.dart';
import 'package:tutora/features/tutor/data/datasources/tutor_lesson_datasource.dart';
import 'package:tutora/features/tutor/data/models/recorder_insights_models.dart';
import 'package:tutora/features/tutor/data/models/recorder_models.dart';
import 'package:tutora/features/tutor/presentation/providers/recorder_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_lesson_provider.dart';

/// Số liệu buổi học từ bản ghi (theo lessonId của recorder). Chỉ hiển thị khi
/// `available` = true.
final AutoDisposeFutureProviderFamily<LessonInsightsDto, String>
lessonInsightsProvider = FutureProvider.autoDispose
    .family<LessonInsightsDto, String>(
      (ref, lessonId) =>
          ref.read(appRecordingDatasourceProvider).getInsights(lessonId),
    );

/// "Ghi âm tốt" theo tuần + các buổi thiếu bản ghi (màn Ghi âm, Lộ trình);
/// tải 2 tuần (tuần này + tuần trước).
final AutoDisposeFutureProvider<WeeklyRecordingDto> weeklyRecordingProvider =
    FutureProvider.autoDispose<WeeklyRecordingDto>(
      (ref) => ref.read(recorderDatasourceProvider).getWeeklyRecording(),
    );

/// Khoá của [studentJournalProvider]: học sinh + tháng "YYYY-MM"
/// (dùng [formatJournalMonth]). Record so sánh theo giá trị.
typedef StudentJournalKey = ({String studentId, String month});

/// Nhật ký học của một học sinh trong một tháng.
final AutoDisposeFutureProviderFamily<StudentJournalDto, StudentJournalKey>
studentJournalProvider = FutureProvider.autoDispose
    .family<StudentJournalDto, StudentJournalKey>(
      (ref, key) => ref
          .read(recorderDatasourceProvider)
          .getJournal(key.studentId, key.month),
    );

/// Cài đặt nhắc lịch / thông báo báo cáo. `save` gọi PUT rồi cập nhật state;
/// lỗi thì giữ giá trị cũ và ném lại để màn hình báo.
class RecorderSettingsNotifier
    extends AutoDisposeAsyncNotifier<RecorderSettingsDto> {
  @override
  Future<RecorderSettingsDto> build() =>
      ref.read(recorderDatasourceProvider).getSettings();

  Future<RecorderSettingsDto> save(RecorderSettingsDto settings) async {
    final saved = await ref
        .read(recorderDatasourceProvider)
        .saveSettings(settings);
    state = AsyncData(saved);
    return saved;
  }
}

final AutoDisposeAsyncNotifierProvider<
  RecorderSettingsNotifier,
  RecorderSettingsDto
>
recorderSettingsProvider =
    AsyncNotifierProvider.autoDispose<
      RecorderSettingsNotifier,
      RecorderSettingsDto
    >(RecorderSettingsNotifier.new);

/// Điểm danh / dời / huỷ buổi recorder, rồi làm mới các danh sách liên quan
/// (buổi hôm nay, lịch dạy, buổi của học sinh, ghi âm theo tuần, nhật ký).
///
/// Dùng: `ref.read(recorderLessonActionsProvider).setAttendance(...)`.
class RecorderLessonActions {
  RecorderLessonActions(this._ref);

  final Ref _ref;

  RecorderDatasource get _ds => _ref.read(recorderDatasourceProvider);

  Future<RecorderLessonDto> setAttendance(
    String lessonId,
    String status, {
    String? reason,
    String? note,
  }) async {
    final lesson = await _ds.setAttendance(
      lessonId,
      status,
      reason: reason,
      note: note,
    );
    _reload();
    return lesson;
  }

  Future<RecorderLessonDto> moveLesson(
    String lessonId,
    DateTime start,
    DateTime end,
    RecorderMoveScope scope,
  ) async {
    final lesson = await _ds.moveLesson(lessonId, start, end, scope);
    _reload();
    return lesson;
  }

  Future<void> cancelLesson(String lessonId, {String? reason}) async {
    await _ds.cancelLesson(lessonId, reason: reason);
    _reload();
  }

  /// Đề xuất dời buổi booking (phụ huynh phải đồng ý — lịch chưa đổi ngay).
  Future<RescheduleProposalDto> proposeReschedule(
    int classSessionId,
    DateTime proposedStart, {
    String? reason,
  }) async {
    final proposal = await _ref
        .read(tutorLessonDatasourceProvider)
        .proposeReschedule(classSessionId, proposedStart, reason);
    _ref.invalidate(tutorAgendaLessonsProvider);
    return proposal;
  }

  void _reload() {
    _ref
      // `refresh` cho provider không autoDispose (xem reloadRecorderStudentData).
      // ignore: unused_result
      ..refresh(recorderTodayLessonsProvider)
      ..invalidate(tutorAgendaLessonsProvider)
      ..invalidate(recorderStudentLessonsProvider)
      ..invalidate(recorderAllLessonsProvider)
      ..invalidate(weeklyRecordingProvider)
      ..invalidate(studentJournalProvider);
  }
}

final recorderLessonActionsProvider = Provider<RecorderLessonActions>(
  RecorderLessonActions.new,
);
