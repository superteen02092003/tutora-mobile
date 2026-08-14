import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/features/tutor/data/datasources/tutor_dispute_datasource.dart';
import 'package:tutora/features/tutor/data/models/tutor_dispute_models.dart';

/// Danh sách khiếu nại của gia sư.
final AutoDisposeFutureProvider<List<TutorDisputeDto>> tutorDisputesProvider =
    FutureProvider.autoDispose<List<TutorDisputeDto>>((ref) {
      return ref.read(tutorDisputeDatasourceProvider).getDisputes();
    });

/// Số khiếu nại chưa khép lại — badge ở hàng "Khiếu nại" trong Hồ sơ.
///
/// `watch` (không phải `read`) để chính widget badge kích hoạt việc nạp danh
/// sách: màn Hồ sơ thường là nơi gia sư nhìn thấy con số này trước tiên.
final AutoDisposeProvider<int> openDisputeCountProvider =
    Provider.autoDispose<int>((ref) {
      final disputes = ref.watch(tutorDisputesProvider).valueOrNull;
      if (disputes == null) return 0;
      return disputes.where((d) => d.status.isOpen).length;
    });

/// Chi tiết khiếu nại theo buổi học.
final AutoDisposeFutureProviderFamily<TutorDisputeDetailDto?, int>
tutorDisputeDetailProvider = FutureProvider.autoDispose
    .family<TutorDisputeDetailDto?, int>((
      ref,
      classSessionId,
    ) {
      return ref
          .read(tutorDisputeDatasourceProvider)
          .getDisputeBySession(classSessionId);
    });

/// Luồng trao đổi riêng với admin của một khiếu nại.
final AutoDisposeFutureProviderFamily<List<DisputeMessageDto>, int>
disputeThreadProvider = FutureProvider.autoDispose
    .family<List<DisputeMessageDto>, int>((
      ref,
      classSessionId,
    ) {
      return ref.read(tutorDisputeDatasourceProvider).getThread(classSessionId);
    });
