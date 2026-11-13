import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/core/utils/input_validators.dart';
import 'package:tutora/features/tutor/data/models/tutor_profile_models.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_profile_provider.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

/// Thông tin cá nhân (design V5.6): nút tròn quay lại, thẻ bo 20, nút viên
/// thuốc. Tên, SĐT, giới tính chỉ xem; ngày sinh và địa chỉ sửa được.
class TutorEditPersonalInfoScreen extends ConsumerStatefulWidget {
  const TutorEditPersonalInfoScreen({super.key});

  @override
  ConsumerState<TutorEditPersonalInfoScreen> createState() =>
      _TutorEditPersonalInfoScreenState();
}

class _TutorEditPersonalInfoScreenState
    extends ConsumerState<TutorEditPersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _birthdateCtrl;
  late final TextEditingController _addressCtrl;

  // Tên và giới tính chỉ đọc, nhưng vẫn phải gửi lại để BE không xoá mất.
  late final String _fullName;
  late final String _gender;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(tutorProfileProvider).user;
    _fullName = user?.fullName ?? '';
    _gender = user?.gender ?? '';
    // BE có thể trả ISO datetime — chỉ giữ phần yyyy-MM-dd.
    final birth = parseIsoDate(user?.birthdate);
    _birthdateCtrl = TextEditingController(
      text: birth == null ? (user?.birthdate ?? '') : formatIsoDate(birth),
    );
    _addressCtrl = TextEditingController(text: user?.address ?? '');
  }

  @override
  void dispose() {
    _birthdateCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Gia sư phải từ 18 tuổi: lịch chỉ cho chọn tới ngày vừa đủ 18.
    final last = latestBirthdateForAge(tutorMinAge, today);
    final current = parseIsoDate(_birthdateCtrl.text);
    final picked = await showDatePicker(
      context: context,
      initialDate: current != null && !current.isAfter(last)
          ? current
          : DateTime(today.year - 25),
      firstDate: DateTime(1900),
      lastDate: last,
      helpText: 'Chọn ngày sinh',
    );
    if (picked != null) {
      setState(() => _birthdateCtrl.text = formatIsoDate(picked));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final ok = await ref
        .read(tutorProfileProvider.notifier)
        .updateUser(
          UpdateTutorUserRequest(
            fullName: _fullName,
            birthdate: _birthdateCtrl.text.trim(),
            address: collapseSpaces(_addressCtrl.text),
            gender: _gender,
          ),
        );

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      Navigator.of(context).pop();
      AppToast.show(
        context,
        message: 'Cập nhật thành công',
        type: AppToastType.success,
      );
    } else {
      AppToast.show(
        context,
        message: 'Cập nhật thất bại, thử lại sau',
        type: AppToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final phone = ref.watch(tutorProfileProvider).user?.phone ?? '';

    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: DecoratedBox(
        decoration: TutorSurface.paper,
        child: SafeArea(
          bottom: false,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.only(bottom: bottomPad + 40),
              children: [
                CanvasHeader(
                  title: 'Thông tin cá nhân',
                  titleSize: 24,
                  onBack: () => Navigator.of(context).pop(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TutorSurface.gutter,
                    18,
                    TutorSurface.gutter,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Đổi tên, SĐT, giới tính phải qua web — mobile chỉ xem.
                      Text(
                        'Chỉ đổi được trên web',
                        style: TutorType.caption(color: TutorColors.ink3),
                      ),
                      const SizedBox(height: 6),
                      DecoratedBox(
                        decoration: TutorSurface.card(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ReadOnlyRow(label: 'Họ và tên', value: _fullName),
                            const _Rule(),
                            _ReadOnlyRow(label: 'Số điện thoại', value: phone),
                            const _Rule(),
                            _ReadOnlyRow(
                              label: 'Giới tính',
                              value: switch (_gender) {
                                'Male' => 'Nam',
                                'Female' => 'Nữ',
                                'Other' => 'Khác',
                                _ => '',
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      DecoratedBox(
                        decoration: TutorSurface.card(),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _Field(
                                label: 'Ngày sinh',
                                controller: _birthdateCtrl,
                                hint: 'Chọn ngày sinh',
                                readOnly: true,
                                onTap: _pickBirthdate,
                                suffixIcon: const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 18,
                                  color: TutorColors.ink3,
                                ),
                                validator: (v) =>
                                    validateBirthdate(v, minAge: tutorMinAge),
                              ),
                              const SizedBox(height: 14),
                              _Field(
                                label: 'Địa chỉ',
                                controller: _addressCtrl,
                                validator: validateAddress,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _PillButton(
                        label: 'Lưu thay đổi',
                        busy: _saving,
                        onPressed: _save,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 16),
    child: Divider(height: 1, thickness: 1, color: TutorColors.line),
  );
}

/// Hàng chỉ xem: nhãn xám bên trái, giá trị bên phải ("Chưa cập nhật" nếu trống).
class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    child: Row(
      children: [
        Text(label, style: TutorType.rowSub()),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : 'Chưa cập nhật',
            textAlign: TextAlign.right,
            style: TutorType.body(
              color: value.isNotEmpty ? TutorColors.ink : TutorColors.ink4,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Ô nhập V5.6: nhãn nhỏ thường, nền lõm bo 12, viền mực khi đang nhập.
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.validator,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? Function(String?)? validator;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(TutorSurface.radiusSmall),
      borderSide: BorderSide(color: c, width: w),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TutorType.caption(color: TutorColors.ink3)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          readOnly: readOnly,
          onTap: onTap,
          style: TutorType.body(),
          cursorColor: TutorColors.ink,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TutorType.body(color: TutorColors.ink4),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: TutorColors.surfaceSunken,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            border: border(Colors.transparent),
            enabledBorder: border(Colors.transparent),
            focusedBorder: border(TutorColors.ink, 1.2),
            errorBorder: border(TutorColors.danger),
            focusedErrorBorder: border(TutorColors.danger, 1.2),
            errorStyle: TutorType.caption(color: TutorColors.danger),
          ),
        ),
      ],
    );
  }
}

/// Nút chính dạng viên thuốc, hiện vòng quay khi đang lưu.
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    width: double.infinity,
    child: FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: TutorColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: TutorColors.primary.withValues(alpha: 0.6),
        shape: const StadiumBorder(),
        textStyle: TutorType.action().copyWith(fontSize: 15),
      ),
      child: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(label),
    ),
  );
}
