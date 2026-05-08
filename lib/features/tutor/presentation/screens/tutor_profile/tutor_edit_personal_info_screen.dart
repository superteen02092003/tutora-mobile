import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/features/tutor/data/models/tutor_profile_models.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_profile_provider.dart';
import 'package:tutora/features/tutor/presentation/widgets/tutor_form_widgets.dart';
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
  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _birthdateCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _genderCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(tutorProfileProvider).user;
    _fullNameCtrl = TextEditingController(text: user?.fullName ?? '');
    _birthdateCtrl = TextEditingController(text: user?.birthdate ?? '');
    _addressCtrl = TextEditingController(text: user?.address ?? '');
    _genderCtrl = TextEditingController(text: user?.gender ?? '');
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _birthdateCtrl.dispose();
    _addressCtrl.dispose();
    _genderCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final ok = await ref
        .read(tutorProfileProvider.notifier)
        .updateUser(
          UpdateTutorUserRequest(
            fullName: _fullNameCtrl.text.trim(),
            birthdate: _birthdateCtrl.text.trim(),
            address: _addressCtrl.text.trim(),
            gender: _genderCtrl.text.trim(),
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
            TutorScreenHeader(
              title: 'Thông tin cá nhân',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, bottomPad + 40),
                  children: [
                    TutorFormField(
                      label: 'Họ và tên',
                      controller: _fullNameCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Không được để trống'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TutorReadOnlyField(
                      label: 'Số điện thoại',
                      value: phone,
                      hint: 'Chưa cập nhật',
                    ),
                    const SizedBox(height: 16),
                    TutorFormField(
                      label: 'Ngày sinh',
                      controller: _birthdateCtrl,
                      hint: 'YYYY-MM-DD',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Không được để trống'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TutorFormField(
                      label: 'Địa chỉ',
                      controller: _addressCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Không được để trống'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _GenderField(controller: _genderCtrl),
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

class _GenderField extends StatelessWidget {
  const _GenderField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Giới tính',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.ink3,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _GenderOption(label: 'Nam', value: 'Male', controller: controller),
            const SizedBox(width: 10),
            _GenderOption(label: 'Nữ', value: 'Female', controller: controller),
          ],
        ),
      ],
    );
  }
}

class _GenderOption extends StatefulWidget {
  const _GenderOption({
    required this.label,
    required this.value,
    required this.controller,
  });

  final String label;
  final String value;
  final TextEditingController controller;

  @override
  State<_GenderOption> createState() => _GenderOptionState();
}

class _GenderOptionState extends State<_GenderOption> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.controller.text == widget.value;
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.controller.text = widget.value,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.ink : AppColors.paper,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.ink : AppColors.line,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.ink3,
            ),
          ),
        ),
      ),
    );
  }
}
