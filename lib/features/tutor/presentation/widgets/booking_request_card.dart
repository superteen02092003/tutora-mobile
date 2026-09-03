import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/core/utils/format_utils.dart';
import 'package:tutora/features/tutor/data/datasources/tutor_booking_datasource.dart';
import 'package:tutora/features/tutor/data/models/tutor_booking_models.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_booking_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_dashboard_provider.dart';
import 'package:tutora/features/tutor/presentation/widgets/tutor_ui.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

/// Thẻ một yêu cầu đặt lịch, kèm nút Nhận / Từ chối.
///
/// Dùng chung ở Home (khối "Cần xử lý") và màn Yêu cầu đặt lịch, nên tự chứa
/// toàn bộ hành động thay vì bắt màn cha truyền callback.
class BookingRequestCard extends ConsumerStatefulWidget {
  const BookingRequestCard({required this.booking, super.key});

  final TutorBookingDto booking;

  @override
  ConsumerState<BookingRequestCard> createState() => _BookingRequestCardState();
}

class _BookingRequestCardState extends ConsumerState<BookingRequestCard> {
  bool _busy = false;

  void _refreshAll() {
    ref
      ..invalidate(tutorBookingsProvider)
      // Nhận yêu cầu sinh buổi học mới → dashboard đổi theo.
      ..invalidate(tutorDashboardProvider);
  }

  Future<void> _accept() async {
    final confirmed = await _confirmAccept();
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(tutorBookingDatasourceProvider)
          .acceptBooking(widget.booking.bookingId);
      if (!mounted) return;
      _refreshAll();
      AppToast.show(
        context,
        message: 'Đã nhận yêu cầu. Phụ huynh sẽ nhận được thông báo.',
        type: AppToastType.success,
      );
    } on TutorBookingException catch (e) {
      if (!mounted) return;
      // 409 = hết hạn hoặc phía kia đã đổi trạng thái → nạp lại cho khớp thật.
      if (e.isConflict) _refreshAll();
      AppToast.show(context, message: e.message, type: AppToastType.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _confirmAccept() => showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TutorSurface.radius),
      ),
      title: Text('Nhận yêu cầu này?', style: TutorType.sectionTitle()),
      content: Text(
        'Sau khi nhận, lịch học sẽ được tạo và bạn có trách nhiệm dạy đủ '
        'các buổi đã thoả thuận.',
        style: TutorType.rowSub(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('Để sau', style: TutorType.action(color: AppColors.ink3)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text('Nhận', style: TutorType.action()),
        ),
      ],
    ),
  );

  Future<void> _decline() async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      // Phủ lên cả bottom bar của shell, không mở trong nested navigator.
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DeclineSheet(),
    );
    if (reason == null || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(tutorBookingDatasourceProvider)
          .declineBooking(widget.booking.bookingId, reason);
      if (!mounted) return;
      _refreshAll();
      AppToast.show(
        context,
        message: 'Đã từ chối yêu cầu.',
        type: AppToastType.success,
      );
    } on TutorBookingException catch (e) {
      if (!mounted) return;
      if (e.isConflict) _refreshAll();
      AppToast.show(context, message: e.message, type: AppToastType.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;

    return TutorCard(
      borderColor: b.isActionable ? AppColors.ink : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TutorAvatar(name: b.studentName, size: 38),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.studentName,
                      style: TutorType.rowTitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (b.summaryLine.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        b.summaryLine,
                        style: TutorType.rowSub(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _statusChip(b),
            ],
          ),

          const SizedBox(height: 13),
          Container(height: 1, color: AppColors.line),
          const SizedBox(height: 11),

          if (b.sessionsLine.isNotEmpty)
            _InfoLine(icon: Icons.repeat_rounded, text: b.sessionsLine),
          for (final s in b.schedule)
            _InfoLine(icon: Icons.schedule_rounded, text: s.label),
          if (b.startDate != null)
            _InfoLine(
              icon: Icons.event_rounded,
              text: 'Bắt đầu ${_fmtDate(b.startDate!)}',
            ),
          if (b.tutorReceivable != null)
            _InfoLine(
              icon: Icons.payments_outlined,
              text: '${fmtVnd(b.tutorReceivable!.round())} bạn nhận được',
              emphasize: true,
            ),

          if (b.isActionable) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TutorButton(
                    label: _busy ? 'Đang xử lý…' : 'Nhận',
                    onTap: _busy ? null : _accept,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TutorButton(
                    label: 'Từ chối',
                    filled: false,
                    onTap: _busy ? null : _decline,
                  ),
                ),
              ],
            ),
          ] else if (b.isExpired) ...[
            const SizedBox(height: 12),
            Text(
              'Đã quá hạn phản hồi. Hệ thống sẽ tự huỷ yêu cầu này.',
              style: TutorType.caption(color: TutorStatusTone.attention),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(TutorBookingDto b) {
    if (b.isActionable) {
      final left = b.timeLeftLabel;
      // Dưới 6 giờ thì đổi sang tông đỏ để tách khỏi các việc chờ khác.
      final urgent = (b.timeLeft?.inHours ?? 99) < 6;
      if (left == null) return TutorStatusChip.attention(b.status.label);
      return urgent
          ? TutorStatusChip.attention(left, icon: Icons.timer_outlined)
          : TutorStatusChip.pending(left, icon: Icons.timer_outlined);
    }
    if (b.isExpired) return TutorStatusChip.neutral('Quá hạn');

    return switch (b.status) {
      TutorBookingStatus.cancelled ||
      TutorBookingStatus.cancelledNoshow ||
      TutorBookingStatus.paymentTimeout => TutorStatusChip.neutral(
        b.status.label,
      ),
      TutorBookingStatus.completed ||
      TutorBookingStatus.paid ||
      TutorBookingStatus.depositPaid => TutorStatusChip.done(b.status.label),
      _ => TutorStatusChip.pending(b.status.label),
    };
  }

  static String _fmtDate(DateTime t) => '${t.day}/${t.month}/${t.year}';
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.text,
    this.emphasize = false,
  });

  final IconData icon;
  final String text;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.ink4),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: emphasize
                  ? TutorType.rowSub(
                      color: AppColors.ink,
                    ).copyWith(fontWeight: FontWeight.w600)
                  : TutorType.rowSub(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sheet nhập lý do từ chối. Backend bắt buộc tối thiểu 10 ký tự nên nút gửi
/// khoá cho tới khi đủ — chặn tại chỗ thay vì để BE trả lỗi.
class _DeclineSheet extends StatefulWidget {
  const _DeclineSheet();

  @override
  State<_DeclineSheet> createState() => _DeclineSheetState();
}

class _DeclineSheetState extends State<_DeclineSheet> {
  final _controller = TextEditingController();
  static const _minLength = 10;

  static const _presets = [
    'Lịch của tôi đã kín vào khung giờ này.',
    'Môn học này không thuộc chuyên môn của tôi.',
    'Khoảng cách địa lý không phù hợp để dạy.',
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text.trim();
    final valid = text.length >= _minLength;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Lý do từ chối', style: TutorType.sectionTitle()),
            const SizedBox(height: 4),
            Text(
              'Phụ huynh sẽ đọc được lý do này.',
              style: TutorType.rowSub(),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in _presets)
                  GestureDetector(
                    onTap: () => _controller.text = preset,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Text(preset, style: TutorType.caption()),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _controller,
              maxLines: 4,
              minLines: 3,
              autofocus: true,
              style: TutorType.rowSub(color: AppColors.ink),
              decoration: InputDecoration(
                hintText: 'Nhập lý do…',
                hintStyle: TutorType.rowSub(color: AppColors.ink4),
                filled: true,
                fillColor: AppColors.paper,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TutorSurface.radius),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TutorSurface.radius),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TutorSurface.radius),
                  borderSide: const BorderSide(
                    color: AppColors.ink,
                    width: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              valid
                  ? 'Đủ điều kiện gửi.'
                  : 'Cần ít nhất $_minLength ký tự (hiện ${text.length}).',
              style: TutorType.caption(
                color: valid ? TutorStatusTone.done : AppColors.ink4,
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: TutorButton(
                label: 'Gửi từ chối',
                onTap: valid
                    ? () => Navigator.of(context).pop(_controller.text.trim())
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
