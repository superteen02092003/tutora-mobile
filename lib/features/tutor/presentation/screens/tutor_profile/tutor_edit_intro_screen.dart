import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/features/tutor/data/models/tutor_profile_models.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_profile_provider.dart';
import 'package:tutora/features/tutor/presentation/widgets/tutor_form_widgets.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

class TutorEditIntroScreen extends ConsumerStatefulWidget {
  const TutorEditIntroScreen({super.key});

  @override
  ConsumerState<TutorEditIntroScreen> createState() =>
      _TutorEditIntroScreenState();
}

class _TutorEditIntroScreenState extends ConsumerState<TutorEditIntroScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _bioCtrl;
  late final TextEditingController _educationCtrl;
  late final TextEditingController _experienceCtrl;
  late final TextEditingController _gpaCtrl;
  late final TextEditingController _gpaScaleCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final intro = ref.read(tutorProfileProvider).progress?.introduction;
    _bioCtrl = TextEditingController(text: intro?.bio ?? '');
    _educationCtrl = TextEditingController(text: intro?.education ?? '');
    _experienceCtrl = TextEditingController(text: intro?.experience ?? '');
    _gpaCtrl = TextEditingController(
      text: intro?.gpa != null ? intro!.gpa.toString() : '',
    );
    _gpaScaleCtrl = TextEditingController(
      text: intro?.gpaScale != null
          ? intro!.gpaScale!.toInt().toString()
          : '10',
    );
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _educationCtrl.dispose();
    _experienceCtrl.dispose();
    _gpaCtrl.dispose();
    _gpaScaleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final gpa = double.tryParse(_gpaCtrl.text.trim());
    final gpaScale = double.tryParse(_gpaScaleCtrl.text.trim());

    final ok = await ref
        .read(tutorProfileProvider.notifier)
        .updateIntroduction(
          UpdateIntroductionRequest(
            bio: _bioCtrl.text.trim(),
            education: _educationCtrl.text.trim(),
            experience: _experienceCtrl.text.trim(),
            gpa: gpa,
            gpaScale: gpa != null ? (gpaScale ?? 10) : null,
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

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            TutorScreenHeader(
              title: 'Giới thiệu & kinh nghiệm',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, bottomPad + 40),
                  children: [
                    TutorFormField(
                      label: 'Giới thiệu bản thân',
                      controller: _bioCtrl,
                      hint: 'Mô tả ngắn về bạn...',
                      maxLines: 4,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Không được để trống'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TutorFormField(
                      label: 'Học vấn',
                      controller: _educationCtrl,
                      hint: 'VD: Đại học Bách Khoa Hà Nội — Toán Tin',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Không được để trống'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TutorFormField(
                      label: 'Kinh nghiệm giảng dạy',
                      controller: _experienceCtrl,
                      hint: 'VD: 5 năm dạy kèm Toán THPT...',
                      maxLines: 3,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Không được để trống'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: TutorFormField(
                            label: 'GPA (tuỳ chọn)',
                            controller: _gpaCtrl,
                            hint: 'VD: 3.5',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _GpaScaleField(controller: _gpaScaleCtrl),
                        ),
                      ],
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

class _GpaScaleField extends StatelessWidget {
  const _GpaScaleField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hệ điểm',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.ink3,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _ScaleOption(label: '4', controller: controller),
            const SizedBox(width: 8),
            _ScaleOption(label: '10', controller: controller),
          ],
        ),
      ],
    );
  }
}

class _ScaleOption extends StatefulWidget {
  const _ScaleOption({required this.label, required this.controller});
  final String label;
  final TextEditingController controller;

  @override
  State<_ScaleOption> createState() => _ScaleOptionState();
}

class _ScaleOptionState extends State<_ScaleOption> {
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
    final selected = widget.controller.text == widget.label;
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.controller.text = widget.label,
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
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.ink3,
            ),
          ),
        ),
      ),
    );
  }
}
