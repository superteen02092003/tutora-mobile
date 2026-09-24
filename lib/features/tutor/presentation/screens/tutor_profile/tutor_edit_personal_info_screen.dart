import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/utils/input_validators.dart';
import 'package:tutora/features/tutor/data/models/tutor_profile_models.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_profile_provider.dart';
import 'package:tutora/features/tutor/presentation/widgets/tutor_form_widgets.dart';
import 'package:tutora/features/tutor/presentation/widgets/tutor_ui.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

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
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            TutorChildHeader(
              title: 'Thông tin cá nhân',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, bottomPad + 40),
                  children: [
                    // Đổi tên, SĐT, giới tính phải qua web — mobile chỉ xem.
                    TutorReadOnlyField(
                      label: 'Họ và tên',
                      value: _fullName,
                      hint: 'Chưa cập nhật',
                    ),
                    const SizedBox(height: 16),
                    TutorReadOnlyField(
                      label: 'Số điện thoại',
                      value: phone,
                      hint: 'Chưa cập nhật',
                    ),
                    const SizedBox(height: 16),
                    TutorReadOnlyField(
                      label: 'Giới tính',
                      value: switch (_gender) {
                        'Male' => 'Nam',
                        'Female' => 'Nữ',
                        'Other' => 'Khác',
                        _ => '',
                      },
                      hint: 'Chưa cập nhật',
                    ),
                    const SizedBox(height: 16),
                    TutorFormField(
                      label: 'Ngày sinh',
                      controller: _birthdateCtrl,
                      hint: 'Chọn ngày sinh',
                      readOnly: true,
                      onTap: _pickBirthdate,
                      suffixIcon: const Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: AppColors.ink4,
                      ),
                      validator: (v) =>
                          validateBirthdate(v, minAge: tutorMinAge),
                    ),
                    const SizedBox(height: 16),
                    TutorFormField(
                      label: 'Địa chỉ',
                      controller: _addressCtrl,
                      validator: validateAddress,
                    ),
                    const SizedBox(height: 32),
                    TutorSaveButton(saving: _saving, onSave: _save),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
