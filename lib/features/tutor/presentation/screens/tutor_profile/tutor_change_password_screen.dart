import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/features/tutor/data/models/tutor_profile_models.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_profile_provider.dart';
import 'package:tutora/features/tutor/presentation/widgets/tutor_form_widgets.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

class TutorChangePasswordScreen extends ConsumerStatefulWidget {
  const TutorChangePasswordScreen({super.key});

  @override
  ConsumerState<TutorChangePasswordScreen> createState() =>
      _TutorChangePasswordScreenState();
}

class _TutorChangePasswordScreenState
    extends ConsumerState<TutorChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _saving = false;
  bool _showOld = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final ok = await ref
        .read(tutorProfileProvider.notifier)
        .changePassword(
          TutorChangePasswordRequest(
            oldPassword: _oldCtrl.text,
            newPassword: _newCtrl.text,
          ),
        );

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      Navigator.of(context).pop();
      AppToast.show(
        context,
        message: 'Đổi mật khẩu thành công',
        type: AppToastType.success,
      );
    } else {
      AppToast.show(
        context,
        message: 'Mật khẩu hiện tại không đúng, thử lại',
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
              title: 'Đổi mật khẩu',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, bottomPad + 40),
                  children: [
                    _PasswordField(
                      label: 'Mật khẩu hiện tại',
                      controller: _oldCtrl,
                      show: _showOld,
                      onToggle: () => setState(() => _showOld = !_showOld),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Không được để trống'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _PasswordField(
                      label: 'Mật khẩu mới',
                      controller: _newCtrl,
                      show: _showNew,
                      onToggle: () => setState(() => _showNew = !_showNew),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Không được để trống';
                        }
                        if (v.length < 6) return 'Tối thiểu 6 ký tự';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _PasswordField(
                      label: 'Xác nhận mật khẩu mới',
                      controller: _confirmCtrl,
                      show: _showConfirm,
                      onToggle: () =>
                          setState(() => _showConfirm = !_showConfirm),
                      validator: (v) =>
                          v != _newCtrl.text ? 'Mật khẩu không khớp' : null,
                    ),
                    const SizedBox(height: 32),
                    TutorSaveButton(
                      saving: _saving,
                      onSave: _save,
                      label: 'Xác nhận',
                    ),
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

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.controller,
    required this.show,
    required this.onToggle,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final bool show;
  final VoidCallback onToggle;
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
          obscureText: !show,
          validator: validator,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.paper,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            suffixIcon: IconButton(
              onPressed: onToggle,
              icon: Icon(
                show
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: AppColors.ink4,
              ),
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
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.oxblood,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
