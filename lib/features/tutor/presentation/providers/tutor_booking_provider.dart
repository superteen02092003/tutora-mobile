import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/features/tutor/data/datasources/tutor_booking_datasource.dart';
import 'package:tutora/features/tutor/data/models/tutor_booking_models.dart';

/// Toàn bộ yêu cầu đặt lịch của gia sư (mọi trạng thái).
final AutoDisposeFutureProvider<TutorBookingPage> tutorBookingsProvider =
    FutureProvider.autoDispose<TutorBookingPage>((ref) {
      return ref.read(tutorBookingDatasourceProvider).getBookingRequests();
    });

/// Yêu cầu đang chờ gia sư quyết định — nguồn cho khối "Cần xử lý" ở Home.
///
/// Lọc phía client thay vì truyền `status=pending_tutor` để cùng một lần gọi
/// phục vụ được cả Home lẫn màn danh sách đầy đủ, tránh gọi API hai lần.
final AutoDisposeProvider<List<TutorBookingDto>> pendingBookingsProvider =
    Provider.autoDispose<List<TutorBookingDto>>((ref) {
      final page = ref.watch(tutorBookingsProvider).valueOrNull;
      if (page == null) return const [];
      return page.items.where((b) => b.status.needsDecision).toList()
        // Sắp hết hạn lên trước — đó là việc gấp nhất.
        ..sort((a, b) {
          final da = a.responseDeadline;
          final db = b.responseDeadline;
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });
    });
