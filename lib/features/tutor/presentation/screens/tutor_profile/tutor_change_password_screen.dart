import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/core/utils/input_validators.dart';
import 'package:tutora/features/tutor/data/models/tutor_profile_models.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_profile_provider.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

/// Đổi mật khẩu (design V5.6): nút tròn quay lại, thẻ bo 20, nút viên thuốc.
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
                  title: 'Đổi mật khẩu',
                  titleSize: 24,
                  lead: 'Tối thiểu $passwordMinLength ký tự, khác mật khẩu cũ.',
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
                      DecoratedBox(
                        decoration: TutorSurface.card(),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _PasswordField(
                                label: 'Mật khẩu hiện tại',
                                controller: _oldCtrl,
                                show: _showOld,
                                onToggle: () =>
                                    setState(() => _showOld = !_showOld),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Không được để trống'
                                    : null,
                              ),
                              const SizedBox(height: 14),
                              _PasswordField(
                                label: 'Mật khẩu mới',
                                controller: _newCtrl,
                                show: _showNew,
                                onToggle: () =>
                                    setState(() => _showNew = !_showNew),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Không được để trống';
                                  }
                                  // Cùng quy định với web: tối thiểu 8 ký tự,
                                  // khác mật khẩu cũ.
                                  if (v.length < passwordMinLength) {
                                    return 'Tối thiểu $passwordMinLength ký tự';
                                  }
                                  if (v == _oldCtrl.text) {
                                    return 'Mật khẩu mới không được trùng mật khẩu cũ';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              _PasswordField(
                                label: 'Xác nhận mật khẩu mới',
                                controller: _confirmCtrl,
                                show: _showConfirm,
                                onToggle: () => setState(
                                  () => _showConfirm = !_showConfirm,
                                ),
                                validator: (v) => v != _newCtrl.text
                                    ? 'Mật khẩu không khớp'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _PillButton(
                        label: 'Xác nhận',
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

/// Ô mật khẩu V5.6: nhãn nhỏ thường, nền lõm bo 12, nút ẩn/hiện.
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
          obscureText: !show,
          validator: validator,
          style: TutorType.body(),
          cursorColor: TutorColors.ink,
          decoration: InputDecoration(
            filled: true,
            fillColor: TutorColors.surfaceSunken,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            suffixIcon: IconButton(
              onPressed: onToggle,
              tooltip: show ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
              icon: Icon(
                show
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: TutorColors.ink3,
              ),
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
