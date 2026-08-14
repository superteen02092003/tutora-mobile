import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

abstract final class ParentManagedGuard {
  static void showBookingBlocked(
    BuildContext context, {
    required String tutorName,
    required String tutorId,
  }) {
    AppToast.show(
      context,
      message:
          'Bạn không thể tự thực hiện đặt lịch, vui lòng nhờ bố mẹ đặt lịch giúp nhé.',
      type: AppToastType.info,
      actionLabel: 'Chia sẻ',
      duration: const Duration(seconds: 5),
      onAction: () => copyTutorLink(
        context,
        tutorName: tutorName,
        tutorId: tutorId,
      ),
    );
  }

  /// Chặn các hành động khác (ví, khiếu nại...) — chỉ báo lý do, không có hành
  /// động kèm theo.
  static void showBlocked(BuildContext context, String message) {
    AppToast.show(context, message: message, type: AppToastType.info);
  }

  /// Chưa thêm share_plus vào dự án chỉ vì một nút — copy link là đủ để các em
  /// gửi cho bố mẹ qua Zalo/tin nhắn.
  static Future<void> copyTutorLink(
    BuildContext context, {
    required String tutorName,
    required String tutorId,
  }) async {
    await Clipboard.setData(
      ClipboardData(
        text:
            'Con muốn học với gia sư $tutorName trên Tutora. '
            'Bố mẹ xem giúp con nhé: https://tutora.vn/tutor/$tutorId',
      ),
    );

    if (!context.mounted) return;
    AppToast.show(
      context,
      message: 'Đã sao chép, gửi cho bố mẹ để đặt lịch giúp con nhé!',
      type: AppToastType.success,
    );
  }
}
