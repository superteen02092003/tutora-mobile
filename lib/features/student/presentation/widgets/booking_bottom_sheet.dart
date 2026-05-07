import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/storage/secure_storage.dart';
import 'package:tutora/core/utils/jwt_utils.dart';
import 'package:tutora/features/student/data/datasources/booking_datasource.dart';
import 'package:tutora/features/student/data/models/booking_models.dart';
import 'package:tutora/features/student/presentation/widgets/booking_form.dart';
import 'package:tutora/features/student/presentation/widgets/booking_shared.dart';
import 'package:tutora/features/student/presentation/widgets/booking_step1.dart';
import 'package:tutora/features/student/presentation/widgets/booking_step2.dart';
import 'package:tutora/features/student/presentation/widgets/booking_step3.dart';
import 'package:tutora/features/student/presentation/widgets/booking_step4.dart';
import 'package:tutora/features/tutor_search/data/models/tutor_detail_models.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

Future<void> showBookingSheet(
  BuildContext context,
  TutorFullProfileDto profile,
  String tutorId,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ProviderScope(
      child: _BookingSheet(profile: profile, tutorId: tutorId),
    ),
  );
}

// ── Sheet ──────────────────────────────────────────────────────────────────

class _BookingSheet extends ConsumerStatefulWidget {
  const _BookingSheet({required this.profile, required this.tutorId});
  final TutorFullProfileDto profile;
  final String tutorId;

  @override
  ConsumerState<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends ConsumerState<_BookingSheet> {
  int _step = 0;
  late BookingForm _form;
  List<StudentSummaryDto> _students = [];
  bool _loadingStudents = false;
  bool _submitting = false;
  String? _error;
  bool _success = false;
  int? _successBookingId;
  String _userRole = 'Student';

  String get _draftKey => 'booking_draft_${widget.tutorId}';

  Future<void> _saveDraft() async {
    if (_success) return;
    final prefs = await SharedPreferences.getInstance();
    final scheduleJson = jsonEncode(
      _form.schedule.map((s) => s.toJson()).toList(),
    );
    await prefs.setString(
      _draftKey,
      jsonEncode({
        'step': _step,
        'studentId': _form.studentId,
        'subjectId': _form.subjectId,
        'teachingMode': _form.teachingMode,
        'startDate': _form.startDate,
        'schedule': scheduleJson,
        'locationCity': _form.locationCity,
        'locationDistrict': _form.locationDistrict,
        'locationWard': _form.locationWard,
        'locationDetail': _form.locationDetail,
        'slotDurationHours': _form.slotDurationHours,
      }),
    );
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final scheduleRaw =
          jsonDecode(map['schedule'] as String) as List<dynamic>;
      final schedule = scheduleRaw
          .map((e) => ScheduleSlotDto.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _step = (map['step'] as int).clamp(0, 2); // max step 2, not 3
        _form = BookingForm(
          studentId: map['studentId'] as String,
          subjectId: map['subjectId'] as int,
          teachingMode: map['teachingMode'] as String,
          startDate: map['startDate'] as String,
          schedule: schedule,
          locationCity: map['locationCity'] as String,
          locationDistrict: map['locationDistrict'] as String,
          locationWard: map['locationWard'] as String,
          locationDetail: map['locationDetail'] as String,
          slotDurationHours: (map['slotDurationHours'] as num).toDouble(),
        );
      });
    } catch (_) {
      await _clearDraft();
    }
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }

  @override
  void initState() {
    super.initState();
    _form = BookingForm();
    unawaited(_initSheet());
  }

  Future<void> _initSheet() async {
    await _loadDraft();
    await _resolveRole();
  }

  Future<void> _resolveRole() async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.getAccessToken();
    if (token == null) return;
    final claims = parseJwt(token);
    if (claims == null) return;

    final roleName = switch (claims.role) {
      UserRole.student => 'Student',
      UserRole.tutor => 'Tutor',
      _ => 'Student',
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
    2 => _form.schedule.isNotEmpty && _startDateValid,
    _ => true,
  };

  void _next() {
    if (!_canNext) {
      _showValidationError();
      return;
    }
    setState(() => _step++);
    unawaited(_saveDraft());
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
      2 =>
        !_startDateValid
            ? 'Ngày bắt đầu không hợp lệ. Vui lòng chọn ngày từ hôm nay trở đi.'
            : 'Vui lòng chọn ít nhất 1 khung giờ.',
      _ => '',
    };
    AppToast.show(context, message: msg, type: AppToastType.error);
  }

  Future<void> _submit() async {
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
              teachingMode: _form.teachingMode,
              startDate: _form.startDate,
              schedule: _form.schedule,
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
      await _clearDraft();
      setState(() {
        _success = true;
        _successBookingId = res.bookingId;
      });
      unawaited(
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) Navigator.of(context).pop();
        }),
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _submitting = false);
    }
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
                          unawaited(_saveDraft());
                        },
                      ),
                      1 => BookingStep2(
                        form: _form,
                        onChanged: (v) {
                          setState(() => _form = v);
                          unawaited(_saveDraft());
                        },
                      ),
                      2 => BookingStep3(
                        form: _form,
                        profile: widget.profile,
                        onChanged: (v) {
                          setState(() => _form = v);
                          unawaited(_saveDraft());
                        },
                      ),
                      _ => BookingStep4(
                        form: _form,
                        profile: widget.profile,
                        students: _students,
                      ),
                    },
                  ),
          ),
          if (!_success)
            _Footer(
              step: _step,
              submitting: _submitting,
              onBack: _step > 0 ? () => setState(() => _step--) : null,
              onNext: _step < 3 ? _next : null,
              onSubmit: _step == 3 ? _submit : null,
            ),
        ],
      ),
    );
  }
}

// ── Chrome widgets ─────────────────────────────────────────────────────────

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

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});
  final int step;
  static const _labels = ['Môn học', 'Hình thức', 'Lịch học', 'Xác nhận'];

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    child: Row(
      children: [
        for (int i = 0; i < _labels.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 1,
                color: i <= step ? AppColors.ink : AppColors.line,
              ),
            ),
          _StepDot(index: i, current: step, label: _labels[i]),
        ],
      ],
    ),
  );
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.index,
    required this.current,
    required this.label,
  });
  final int index;
  final int current;
  final String label;

  @override
  Widget build(BuildContext context) {
    final done = index < current;
    final active = index == current;
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done
                ? AppColors.ink
                : active
                ? AppColors.gold
                : AppColors.paper,
            border: Border.all(
              color: done || active ? Colors.transparent : AppColors.line,
            ),
          ),
          child: Center(
            child: done
                ? const Icon(
                    Icons.check_rounded,
                    size: 13,
                    color: AppColors.cream,
                  )
                : Text(
                    '${index + 1}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: active ? AppColors.ink : AppColors.ink3,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.ink : AppColors.ink3,
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.step,
    required this.submitting,
    required this.onBack,
    required this.onNext,
    required this.onSubmit,
  });
  final int step;
  final bool submitting;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final VoidCallback? onSubmit;

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
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink3),
                ),
              ),
            ),
          const Spacer(),
          if (onNext != null)
            BookingPrimaryButton(label: 'Tiếp theo →', onTap: onNext!)
          else if (onSubmit != null)
            BookingPrimaryButton(
              label: submitting ? 'Đang xử lý...' : 'Xác nhận đặt lịch',
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
                'Mã booking: #$bookingId',
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
