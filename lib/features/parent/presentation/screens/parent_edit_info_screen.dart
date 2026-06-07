import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/parent/data/datasources/parent_profile_datasource.dart';
import 'package:tutora/features/parent/presentation/providers/parent_profile_provider.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

class ParentEditInfoScreen extends ConsumerStatefulWidget {
  const ParentEditInfoScreen({super.key});

  @override
  ConsumerState<ParentEditInfoScreen> createState() =>
      _ParentEditInfoScreenState();
}

class _ParentEditInfoScreenState extends ConsumerState<ParentEditInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _birthdateCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _genderCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(parentProfileProvider).profile;
    _fullNameCtrl = TextEditingController(text: profile?.fullName ?? '');
    _birthdateCtrl = TextEditingController(text: profile?.birthdate ?? '');
    _addressCtrl = TextEditingController(text: profile?.address ?? '');
    _genderCtrl = TextEditingController(text: profile?.gender ?? '');
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
        .read(parentProfileProvider.notifier)
        .updateProfile(
          UpdateProfileRequest(
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
        message: 'Cập nhật thông tin thành công',
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
    final phone = ref.read(parentProfileProvider).profile?.phone ?? '';

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.line, width: 0.8),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                    ),
                    color: AppColors.ink,
                  ),
                  Expanded(
                    child: Text(
                      'Thông tin cá nhân',
                      style: AppTextStyles.h3(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  children: [
                    _FormField(
                      label: 'Họ và tên',
                      controller: _fullNameCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Không được để trống'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    _ReadOnlyField(
                      label: 'Số điện thoại',
                      value: phone,
                      hint: 'Chưa cập nhật',
                    ),
                    const SizedBox(height: 20),
                    _DateField(
                      label: 'Ngày sinh',
                      controller: _birthdateCtrl,
                    ),
                    const SizedBox(height: 20),
                    _FormField(
                      label: 'Địa chỉ',
                      controller: _addressCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Không được để trống'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    _GenderField(controller: _genderCtrl),
                  ],
                ),
              ),
            ),

            // Save button — cố định ở bottom, dễ bấm
            Container(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomPad),
              decoration: const BoxDecoration(
                color: AppColors.cream,
                border: Border(
                  top: BorderSide(color: AppColors.line, width: 0.8),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    disabledBackgroundColor: AppColors.ink3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Lưu thay đổi',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  String _display() {
    final raw = controller.text;
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  Future<void> _pick(BuildContext context) async {
    final initial = DateTime.tryParse(controller.text) ?? DateTime(2000);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary: AppColors.ink,
            onPrimary: AppColors.cream,
            surface: AppColors.paper,
            onSurface: AppColors.ink,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      controller.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.ink3,
          ),
        ),
        const SizedBox(height: 6),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => GestureDetector(
            onTap: () => _pick(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _display().isNotEmpty ? _display() : 'Chọn ngày sinh',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: _display().isNotEmpty
                            ? AppColors.ink
                            : AppColors.ink4,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: AppColors.ink4,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.controller,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.ink3,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.paper,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.oxblood),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.label,
    required this.value,
    this.hint = '',
  });

  final String label;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.ink3,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.cream2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.line),
          ),
          child: Text(
            value.isNotEmpty ? value : hint,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: value.isNotEmpty ? AppColors.ink3 : AppColors.ink4,
            ),
          ),
        ),
      ],
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
