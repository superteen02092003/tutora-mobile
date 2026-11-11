import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/features/tutor/data/datasources/topi_datasource.dart';
import 'package:tutora/features/tutor/data/models/topi_models.dart';

/// Cờ Topi v1. Không autoDispose: đọc một lần khi mở app, mọi màn dùng chung.
/// Lỗi mạng hay backend cũ chưa có endpoint → tắt hết, app chạy như trước.
final topiFlagsProvider = FutureProvider<TopiFlags>((ref) async {
  try {
    return await ref.read(topiDatasourceProvider).getFlags();
  } on Object catch (e) {
    debugPrint('Topi flags unavailable, all off: $e');
    return TopiFlags.off;
  }
});

/// Cờ hiện có, tắt hết khi đang tải hoặc lỗi — dùng trong `build` để quyết
/// định có vẽ phần Topi hay không mà không phải xử lý ba trạng thái.
final topiFlagsNowProvider = Provider<TopiFlags>(
  (ref) => ref.watch(topiFlagsProvider).valueOrNull ?? TopiFlags.off,
);

/// Kết quả Topi của một buổi (lessonId = recordingId của buổi ghi âm). Null
/// khi buổi chưa có kết quả.
final AutoDisposeFutureProviderFamily<LessonTopi?, String> lessonTopiProvider =
    FutureProvider.autoDispose.family<LessonTopi?, String>(
      (ref, lessonId) =>
          ref.read(topiDatasourceProvider).getLessonTopi(lessonId),
    );
