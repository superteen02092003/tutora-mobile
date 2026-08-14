import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/network/api_client.dart';
import 'package:tutora/features/student/data/models/student_access_models.dart';

/// Học sinh do phụ huynh tạo: chỉ học & theo dõi — vẫn XEM được gia sư, nhưng không tự chốt được
final bookingEligibilityProvider = FutureProvider<BookingEligibilityDto>((
  ref,
) async {
  final dio = ref.read(apiClientProvider);
  try {
    final response = await dio.get<dynamic>('/students/me/booking-eligibility');
    return BookingEligibilityDto.fromJson(
      response.data as Map<String, dynamic>,
    );
  } on DioException {
    // Fail-safe theo hướng AN TOÀN: lỗi mạng → không mở nút đặt lịch. BE vẫn
    // chặn lần nữa ở BookingService nên đây chỉ là lớp UX, không phải lớp bảo mật.
    return const BookingEligibilityDto.blocked();
  }
});

/// `true` khi học sinh chắc chắn được tự đặt lịch. Lúc đang tải trả `false` để
/// nút không kịp hiện rồi ẩn (giống `!loading && ...` bên web).
final canSelfBookProvider = Provider<bool>((ref) {
  return ref
      .watch(bookingEligibilityProvider)
      .maybeWhen(data: (e) => e.canBook, orElse: () => false);
});

/// `true` khi tài khoản do phụ huynh quản lý — dùng để ẩn ví, khiếu nại và
/// "Booking của tôi" trong màn hồ sơ.
final isParentManagedProvider = Provider<bool>((ref) {
  return ref
      .watch(bookingEligibilityProvider)
      .maybeWhen(data: (e) => e.isParentManaged, orElse: () => false);
});
