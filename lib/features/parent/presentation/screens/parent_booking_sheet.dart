import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/storage/secure_storage.dart';
import 'package:tutora/core/utils/jwt_utils.dart';
import 'package:tutora/features/student/data/datasources/booking_datasource.dart';
import 'package:tutora/features/student/data/datasources/payment_datasource.dart';
import 'package:tutora/features/student/data/models/booking_models.dart';
import 'package:tutora/features/student/data/models/payment_models.dart';
import 'package:tutora/features/student/presentation/widgets/booking_constants.dart';
import 'package:tutora/features/student/presentation/widgets/booking_draft_store.dart';
import 'package:tutora/features/student/presentation/widgets/booking_form.dart';
import 'package:tutora/features/student/presentation/widgets/booking_shared.dart';
import 'package:tutora/features/student/presentation/widgets/booking_step1.dart';
import 'package:tutora/features/student/presentation/widgets/booking_step2.dart';
import 'package:tutora/features/student/presentation/widgets/booking_step3.dart';
import 'package:tutora/features/student/presentation/widgets/booking_step4.dart';
import 'package:tutora/features/student/presentation/widgets/booking_step_mode.dart';
import 'package:tutora/features/student/presentation/widgets/booking_step_payment.dart';
import 'package:tutora/features/tutor_search/data/models/tutor_detail_models.dart';
import 'package:tutora/shared/widgets/app_confirm_sheet.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

Future<void> showParentBookingSheet(
  BuildContext context,
  TutorFullProfileDto profile,
  String tutorId, {
  VoidCallback? onSuccess,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ProviderScope(
      child: _BookingSheet(
        profile: profile,
        tutorId: tutorId,
        onSuccess: onSuccess,
      ),
    ),
  );
}

// Sheet
class _BookingSheet extends ConsumerStatefulWidget {
  const _BookingSheet({
    required this.profile,
    required this.tutorId,
    this.onSuccess,
  });
  final TutorFullProfileDto profile;
  final String tutorId;
  final VoidCallback? onSuccess;

  @override
  ConsumerState<_BookingSheet> createState() => _BookingSheetState();
}

/// Bước xác nhận (gửi yêu cầu) và bước trả cọc
const int _reviewStep = 4;
const int _payStep = 5;

class _BookingSheetState extends ConsumerState<_BookingSheet> {
  int _step = 0;
  late BookingForm _form;
  List<StudentSummaryDto> _students = [];
  bool _loadingStudents = false;
  bool _submitting = false;
  String? _error;
  bool _success = false;
  int? _successBookingId;
  String _userRole = 'Parent';

  /// Lịch gia sư đã có
  List<({DateTime start, DateTime end})> _bookedSlots = const [];

  // Bước thanh toán (sau khi booking đã tạo).
  PaymentSummaryDto? _paySummary;
  PaymentInfoDto? _payInfo;
  bool _payLoading = false;
  String? _payError;
  PayMethod _payMethod = PayMethod.wallet;

  bool get _showingQr => _payInfo != null;

  void _saveDraft() {
    if (_success) return;
    BookingDraftStore.save(
      widget.tutorId,
      step: _step,
      form: _form,
      lastResumable: _reviewStep,
    );
  }

  void _clearDraft() => BookingDraftStore.clear(widget.tutorId);

  /// Draft chỉ sống trong phiên chạy app nên chỉ hỏi lại khi người dùng thực sự
  /// bỏ dở giữa chừng, thay vì tự nhảy bước như bản lưu xuống đĩa trước đây.
  Future<void> _restoreDraftIfAny() async {
    final draft = BookingDraftStore.read(widget.tutorId);
    if (draft == null || !mounted) return;

    final resume = await AppConfirmSheet.show(
      context,
      title: 'Tiếp tục đặt lịch?',
      message:
          'Bạn đang đặt lịch với ${widget.profile.displayName} và dừng ở '
          'bước ${_StepIndicator.labelAt(draft.step)} '
          '(${draft.step + 1}/${_StepIndicator.stepCount}). '
          'Bạn muốn tiếp tục hay bắt đầu lại?',
      confirmLabel: 'Tiếp tục',
      cancelLabel: 'Bắt đầu lại',
      useRootNavigator: false,
    );
    if (!mounted) return;

    // Vuốt bỏ (null) = chưa quyết định → giữ nguyên draft, mở lại vẫn hỏi.
    if (resume == null) return;

    if (!resume) {
      _clearDraft();
      return;
    }

    setState(() {
      _step = draft.step;
      // Giữ studentId vừa resolve: draft cũ có thể lưu từ phiên trước, ghi đè cả
      // form sẽ xoá mất con đang chọn.
      _form = draft.form.studentId.isEmpty
          ? draft.form.copyWith(studentId: _form.studentId)
          : draft.form;
    });
  }

  @override
  void initState() {
    super.initState();
    _form = BookingForm();
    unawaited(_initSheet());
  }

  Future<void> _initSheet() async {
    unawaited(_loadBookedSlots());
    await _resolveRole();
    if (!mounted) return;
    // Đợi sheet vào xong rồi mới hỏi, nếu không modal confirm bị chồng lên
    // animation của chính sheet này và không hiện ra.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    // Chạy sau _resolveRole để học sinh đã chọn trong draft không bị ghi đè.
    await _restoreDraftIfAny();
  }

  @override
  void dispose() {
    // Bắt mọi kiểu đóng sheet (nút X, vuốt xuống, back) — nếu chỉ lưu ở _next
    // thì thoát giữa chừng là mất sạch những gì đã chọn.
    _saveDraft();
    super.dispose();
  }

  Future<void> _resolveRole() async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.getAccessToken();
    if (token == null) return;
    final claims = parseJwt(token);
    if (claims == null) return;

    // Sheet này mở từ luồng phụ huynh nên mặc định là Parent
    final roleName = switch (claims.role) {
      UserRole.student => 'Student',
      UserRole.tutor => 'Tutor',
      UserRole.parent => 'Parent',
      _ => 'Parent',
    };
    setState(() => _userRole = roleName);

    if (roleName == 'Student') {
      // Users.Id != Studentprofile.Studentid — must fetch the real profile ID
      final profileId = await ref
          .read(bookingDatasourceProvider)
          .getMyStudentProfileId();
      setState(
        () => _form = _form.copyWith(studentId: profileId ?? claims.userId),
      );
    } else if (roleName == 'Parent') {
      await _loadStudents();
    }
  }

  /// Lấy dư 2 tháng để đủ phủ cửa sổ đặt lịch kể cả khi lùi ngày bắt đầu.
  Future<void> _loadBookedSlots() async {
    final now = DateTime.now();
    final slots = await ref
        .read(bookingDatasourceProvider)
        .getTutorBookedSlots(
          widget.tutorId,
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month + 2, now.day),
        );
    if (!mounted) return;
    setState(() => _bookedSlots = slots);
  }

  Future<void> _loadStudents() async {
    setState(() => _loadingStudents = true);
    try {
      final list = await ref.read(bookingDatasourceProvider).getMyStudents();
      setState(() => _students = list);
    } catch (_) {
      setState(() => _students = []);
    } finally {
      setState(() => _loadingStudents = false);
    }
  }

  bool get _startDateValid {
    final d = DateTime.tryParse(_form.startDate);
    if (d == null) return false;
    final today = DateTime.now();
    return !d.isBefore(DateTime(today.year, today.month, today.day));
  }

  bool get _canNext => switch (_step) {
    0 =>
      _userRole == 'Student'
          ? _form.subjectId != 0
          : _form.studentId.isNotEmpty && _form.subjectId != 0,
    1 =>
      !_form.needsLocation ||
          (_form.locationCity.isNotEmpty && _form.locationDistrict.isNotEmpty),
    2 =>
      _form.bookingMode == BookingMode.manual || _form.selectedPackage != null,
    3 => _form.schedule.isNotEmpty && _startDateValid,
    _ => true,
  };

  void _next() {
    if (!_canNext) {
      _showValidationError();
      return;
    }
    // Chọn gói xong thì lịch đã cố định, đổ thẳng vào form để bước lịch chỉ còn
    // xác nhận ngày bắt đầu.
    if (_step == 2 && _form.bookingMode == BookingMode.package) {
      _applyPackageSchedule();
    }
    setState(() => _step++);
    _saveDraft();
  }

  /// fixedSlots lưu UTC — phải quy về local, bỏ qua là lệch 7 tiếng.
  void _applyPackageSchedule() {
    final pkg = _form.selectedPackage;
    if (pkg == null) return;

    final local =
        pkg.fixedSlots
            .map(
              (s) => fixedSlotToLocal(
                isoDayOfWeek: s.dayOfWeek,
                startUtc: s.startTime,
                endUtc: s.endTime,
              ),
            )
            .toList()
          ..sort((a, b) {
            final d = a.dayOfWeek.compareTo(b.dayOfWeek);
            return d != 0
                ? d
                : toMins(a.startTime).compareTo(toMins(b.startTime));
          });

    setState(() {
      _form = _form.copyWith(
        schedule: local
            .map(
              (s) => ScheduleSlotDto(
                dayOfWeek: s.dayOfWeek,
                startTime: s.startTime,
                endTime: s.endTime,
              ),
            )
            .toList(),
      );
    });
  }

  void _showValidationError() {
    final msg = switch (_step) {
      0 =>
        _userRole == 'Student'
            ? 'Vui lòng chọn môn học.'
            : _form.studentId.isEmpty
            ? 'Vui lòng chọn học sinh.'
            : 'Vui lòng chọn môn học.',
      1 => 'Vui lòng nhập Thành phố và Quận/Huyện.',
      2 => 'Vui lòng chọn một gói của gia sư.',
      3 =>
        !_startDateValid
            ? 'Ngày bắt đầu không hợp lệ. Vui lòng chọn ngày từ hôm nay trở đi.'
            : 'Vui lòng chọn ít nhất 1 khung giờ.',
      _ => '',
    };
    AppToast.show(context, message: msg, type: AppToastType.error);
  }

  List<FlexibleSlotDto> _buildFlexibleSlots() {
    final slots = <FlexibleSlotDto>[];
    final start = DateTime.tryParse(_form.startDate);
    if (start == null) return slots;
    final windowEnd = bookingWindowEnd(start);

    for (final s in _form.schedule) {
      final startParts = s.startTime.split(':');
      final endParts = s.endTime.split(':');
      if (startParts.length < 2 || endParts.length < 2) continue;
      final sh = int.tryParse(startParts[0]) ?? 0;
      final sm = int.tryParse(startParts[1]) ?? 0;
      final eh = int.tryParse(endParts[0]) ?? 0;
      final em = int.tryParse(endParts[1]) ?? 0;

      for (
        var d = start;
        !d.isAfter(windowEnd);
        d = d.add(const Duration(days: 1))
      ) {
        final dow = d.weekday == DateTime.sunday ? 0 : d.weekday;
        if (dow != s.dayOfWeek) continue;
        final localStart = DateTime(d.year, d.month, d.day, sh, sm);
        final localEnd = DateTime(d.year, d.month, d.day, eh, em);
        slots.add(
          FlexibleSlotDto(
            scheduledStart: localStart.toUtc().toIso8601String(),
            scheduledEnd: localEnd.toUtc().toIso8601String(),
          ),
        );
      }
    }
    slots.sort((a, b) => a.scheduledStart.compareTo(b.scheduledStart));
    return slots;
  }

  Future<void> _submit() async {
    final isPackage = _form.bookingMode == BookingMode.package;
    // Gói cố định gửi packageId của gói đã chọn;
    final packageId = isPackage
        ? _form.selectedPackage?.packageId
        : widget.profile.flexiblePackageId;
    if (_form.tutorSubjectGradePriceId == 0 || packageId == null) {
      setState(
        () => _error =
            'Gia sư chưa cấu hình đủ giá/gói cho môn học này. Vui lòng chọn lại.',
      );
      return;
    }

    final flexibleSlots = isPackage
        ? const <FlexibleSlotDto>[]
        : _buildFlexibleSlots();
    final totalSessions = isPackage
        ? _form.totalSessions
        : flexibleSlots.length;

    if (totalSessions <= 3) {
      setState(
        () => _error =
            'Cần ít nhất 4 buổi học. Vui lòng chọn thêm khung giờ hoặc lùi ngày bắt đầu.',
      );
      return;
    }

    final requiredMins = _form.selectedGradePrice?.durationMinutesPerSession;
    if (!isPackage && requiredMins != null) {
      final wrong = _form.schedule.any(
        (s) => (toMins(s.endTime) - toMins(s.startTime)) != requiredMins,
      );
      if (wrong) {
        setState(
          () => _error =
              'Mỗi buổi học phải kéo dài $requiredMins phút theo quy định của gia sư. '
              'Vui lòng chọn lại khung giờ.',
        );
        return;
      }
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final res = await ref
          .read(bookingDatasourceProvider)
          .createBooking(
            CreateBookingRequest(
              studentId: _form.studentId,
              tutorId: widget.tutorId,
              subjectId: _form.subjectId,
              tutorSubjectGradePriceId: _form.tutorSubjectGradePriceId,
              packageId: packageId,
              startDate: _form.startDate,
              teachingMode: _form.teachingMode,
              totalSessions: totalSessions,
              flexibleSlots: flexibleSlots,
              locationCity: _form.locationCity.isEmpty
                  ? null
                  : _form.locationCity,
              locationDistrict: _form.locationDistrict.isEmpty
                  ? null
                  : _form.locationDistrict,
              locationWard: _form.locationWard.isEmpty
                  ? null
                  : _form.locationWard,
              locationDetail: _form.locationDetail.isEmpty
                  ? null
                  : _form.locationDetail,
            ),
          );
      _clearDraft();
      // Booking đã tạo nhưng chưa trả cọc — BE tự huỷ sau ít phút, nên phải đưa
      // phụ huynh sang bước trả tiền chứ không đóng sheet.
      if (!mounted) return;
      setState(() {
        _successBookingId = res.bookingId;
        _step = _payStep;
      });
      await _loadPaymentSummary();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _loadPaymentSummary() async {
    final id = _successBookingId;
    if (id == null) return;
    setState(() {
      _payLoading = true;
      _payError = null;
    });
    try {
      final s = await ref.read(paymentDatasourceProvider).getPaymentSummary(id);
      if (!mounted) return;
      setState(() {
        _paySummary = s;
        // Ví đủ tiền thì ưu tiên, vì trả trong app nhanh hơn ra PayOS.
        _payMethod = s.canPayWithWallet && s.walletBalance >= s.amount
            ? PayMethod.wallet
            : PayMethod.transfer;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _payError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _payLoading = false);
    }
  }

  /// Phụ huynh chuyển khoản xong bấm "Tôi đã chuyển khoản" → đối soát.
  Future<void> _checkPaid() async {
    final id = _successBookingId;
    if (id == null) return;
    setState(() => _submitting = true);
    try {
      final status = await ref
          .read(paymentDatasourceProvider)
          .getPaymentStatus(id);
      if (!mounted) return;
      if (status.depositSettled) {
        _finishSuccess();
      } else {
        AppToast.show(
          context,
          message:
              'Chưa nhận được tiền. Nếu bạn vừa chuyển, đợi một lát rồi kiểm tra lại.',
          type: AppToastType.warning,
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: e.toString().replaceFirst('Exception: ', ''),
        type: AppToastType.error,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Ví thì trừ thẳng; chuyển khoản thì lấy thông tin để dựng QR trong app.
  Future<void> _pay() async {
    final id = _successBookingId;
    if (id == null) return;

    setState(() {
      _submitting = true;
      _payError = null;
    });
    final ds = ref.read(paymentDatasourceProvider);
    try {
      if (_payMethod == PayMethod.wallet) {
        await ds.payWithWallet(id);
        if (!mounted) return;
        _finishSuccess();
        return;
      }

      // Hiện QR ngay trong app (giống web) thay vì đẩy ra trang PayOS.
      final info = await ds.getPaymentInfo(id);
      if (!mounted) return;
      setState(() => _payInfo = info);
    } catch (e) {
      if (!mounted) return;
      setState(() => _payError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Trả tiền xong: hiện màn thành công và báo cho màn gọi để nó tải lại danh sách.
  void _finishSuccess() {
    setState(() => _success = true);
    widget.onSuccess?.call();
  }

  @override
  Widget build(BuildContext context) {
    final mediaHeight = MediaQuery.of(context).size.height;
    return Container(
      height: mediaHeight * 0.92,
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _Handle(),
          _Header(
            tutorName: widget.profile.displayName,
            onClose: () => Navigator.of(context).pop(),
          ),
          _StepIndicator(step: _step),
          if (_error != null)
            BookingErrorBanner(
              message: _error!,
              onDismiss: () => setState(() => _error = null),
            ),
          Expanded(
            child: _success
                ? _SuccessView(
                    tutorName: widget.profile.displayName,
                    bookingId: _successBookingId,
                    onClose: () => Navigator.of(context).pop(),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: switch (_step) {
                      0 => BookingStep1(
                        form: _form,
                        profile: widget.profile,
                        students: _students,
                        loadingStudents: _loadingStudents,
                        userRole: _userRole,
                        onChanged: (v) {
                          setState(() => _form = v);
                          _saveDraft();
                        },
                      ),
                      1 => BookingStep2(
                        form: _form,
                        onChanged: (v) {
                          setState(() => _form = v);
                          _saveDraft();
                        },
                      ),
                      2 => BookingStepMode(
                        form: _form,
                        profile: widget.profile,
                        onChanged: (v) {
                          setState(() => _form = v);
                          _saveDraft();
                        },
                      ),
                      3 => BookingStep3(
                        form: _form,
                        profile: widget.profile,
                        bookedSlots: _bookedSlots,
                        onChanged: (v) {
                          setState(() => _form = v);
                          _saveDraft();
                        },
                      ),
                      4 => BookingStep4(
                        form: _form,
                        profile: widget.profile,
                        students: _students,
                      ),
                      _ => BookingStepPayment(
                        summary: _paySummary,
                        info: _payInfo,
                        loading: _payLoading,
                        method: _payMethod,
                        onMethodChanged: (m) => setState(() => _payMethod = m),
                        error: _payError,
                        onRetry: () => unawaited(_loadPaymentSummary()),
                      ),
                    },
                  ),
          ),
          if (!_success)
            _Footer(
              step: _step,
              submitting: _submitting,
              // Booking đã tạo ở bước thanh toán nên không cho lùi về sửa nữa.
              onBack: _step > 0 && _step < _payStep
                  ? () => setState(() => _step--)
                  : null,
              onNext: _step < _reviewStep ? _next : null,
              onSubmit: _step == _reviewStep
                  ? _submit
                  : _step == _payStep && _showingQr
                  ? () => unawaited(_checkPaid())
                  : _step == _payStep && _paySummary != null
                  ? () => unawaited(_pay())
                  : null,
              payLabel: _showingQr ? 'Tôi đã chuyển khoản' : null,
            ),
        ],
      ),
    );
  }
}

// Chrome widgets

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.only(top: 10, bottom: 6),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.line,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.tutorName, required this.onClose});
  final String tutorName;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 4, 16, 8),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Đặt lịch học',
                style: GoogleFonts.bricolageGrotesque(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: AppColors.ink,
                ),
              ),
              Text(
                'với $tutorName',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink3),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onClose,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.line),
            ),
            child: const Icon(
              Icons.close_rounded,
              size: 16,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Thanh tiến trình chia đoạn: mỗi bước một vạch, kèm tên bước hiện tại — gọn
/// hơn hàng chấm tròn có nhãn, hợp với bề ngang máy điện thoại.
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});
  final int step;
  static const _labels = [
    'Môn học',
    'Hình thức',
    'Cách đặt',
    'Lịch học',
    'Xác nhận',
    'Thanh toán',
  ];

  static int get stepCount => _labels.length;

  static String labelAt(int step) => _labels[step.clamp(0, _labels.length - 1)];

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              labelAt(step),
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const Spacer(),
            Text(
              'Bước ${step + 1}/$stepCount',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink3),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (int i = 0; i < _labels.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 5,
                  decoration: BoxDecoration(
                    color: i <= step ? AppColors.ink : AppColors.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    ),
  );
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.step,
    required this.submitting,
    required this.onBack,
    required this.onNext,
    required this.onSubmit,
    this.payLabel,
  });
  final int step;
  final bool submitting;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final VoidCallback? onSubmit;
  final String? payLabel;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          if (onBack != null)
            GestureDetector(
              onTap: onBack,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  '← Quay lại',
                  style: GoogleFonts.inter(fontSize: 15, color: AppColors.ink3),
                ),
              ),
            ),
          const Spacer(),
          if (onNext != null)
            BookingPrimaryButton(label: 'Tiếp theo →', onTap: onNext!)
          else if (onSubmit != null)
            BookingPrimaryButton(
              label: submitting
                  ? 'Đang xử lý...'
                  : payLabel ??
                        (step == _payStep
                            ? 'Thanh toán ngay'
                            : 'Xác nhận đặt lịch'),
              onTap: submitting ? () {} : onSubmit!,
              gold: true,
            ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.tutorName,
    required this.bookingId,
    required this.onClose,
  });
  final String tutorName;
  final int? bookingId;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.shade50,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 40,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Đặt lịch thành công!',
            style: GoogleFonts.bricolageGrotesque(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gia sư $tutorName sẽ xác nhận lịch sớm nhất.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.ink3,
              height: 1.5,
            ),
          ),
          if (bookingId != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(color: AppColors.line),
              ),
              child: Text(
                'Mã lịch đặt: #$bookingId',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink2,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          GestureDetector(
            onTap: onClose,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                'Đóng',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
