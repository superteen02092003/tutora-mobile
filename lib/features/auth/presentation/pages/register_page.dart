import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/legal_links.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/core/utils/input_validators.dart';
import 'package:tutora/features/auth/presentation/controllers/register_controller.dart';
import 'package:tutora/features/auth/presentation/widgets/auth_input.dart';
import 'package:tutora/features/auth/presentation/widgets/auth_top_deco.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

/// Đăng ký tài khoản gia sư: họ tên + SĐT + mật khẩu → OTP gửi qua Zalo.
/// Bắt buộc đồng ý Điều khoản sử dụng và Chính sách quyền riêng tư.
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;

  String? _nameError;
  String? _phoneError;
  String? _passError;
  String? _confirmError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _nameCtrl.text.trim().isNotEmpty &&
      _phoneCtrl.text.trim().isNotEmpty &&
      _passCtrl.text.isNotEmpty &&
      _confirmCtrl.text.isNotEmpty &&
      _acceptedTerms &&
      _acceptedPrivacy;

  void _backToLogin() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.login);
    }
  }

  void _openLink(String url) => unawaited(_launchLink(url));

  Future<void> _launchLink(String url) async {
    final opened = await openExternalUrl(url);
    if (!opened && mounted) {
      AppToast.show(
        context,
        message: 'Không mở được liên kết.',
        type: AppToastType.error,
      );
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final phone = normalizePhone(_phoneCtrl.text);
    final nameError = validatePersonName(_nameCtrl.text);
    final phoneError = validatePhone(phone);
    final passError = _passCtrl.text.length < passwordMinLength
        ? 'Mật khẩu phải có ít nhất $passwordMinLength ký tự'
        : null;
    final confirmError = _passCtrl.text == _confirmCtrl.text
        ? null
        : 'Mật khẩu không khớp';
    setState(() {
      _nameError = nameError;
      _phoneError = phoneError;
      _passError = passError;
      _confirmError = confirmError;
    });
    if (nameError != null ||
        phoneError != null ||
        passError != null ||
        confirmError != null) {
      return;
    }

    await ref
        .read(registerControllerProvider.notifier)
        .register(
          fullName: collapseSpaces(_nameCtrl.text),
          phone: phone,
          password: _passCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(registerControllerProvider, (_, state) {
      if (!context.mounted) return;
      if (state is RegisterSuccess) {
        unawaited(
          context.push(
            AppRoutes.otp,
            extra: OtpArgs(phone: state.phone, mode: OtpMode.register),
          ),
        );
      } else if (state is RegisterError) {
        AppToast.show(
          context,
          message: state.message,
          type: AppToastType.error,
        );
        ref.read(registerControllerProvider.notifier).resetError();
      }
    });

    final state = ref.watch(registerControllerProvider);
    final isLoading = state is RegisterLoading;

    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: DecoratedBox(
        decoration: TutorSurface.paper,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthTopDeco(
                  onBack: _backToLogin,
                  hand: 'Chào gia sư mới',
                  title: 'Đăng ký gia sư',
                  lead: const Text(
                    'Mã xác minh sẽ được gửi qua Zalo tới số điện thoại.',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TutorSurface.gutter,
                    24,
                    TutorSurface.gutter,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuthInput(
                        label: 'Họ và tên',
                        controller: _nameCtrl,
                        hint: 'Nguyễn Văn A',
                        textInputAction: TextInputAction.next,
                        errorText: _nameError,
                        enabled: !isLoading,
                        onChanged: (_) => setState(() => _nameError = null),
                      ),
                      const SizedBox(height: 12),

                      AuthInput(
                        label: 'Số điện thoại (Zalo)',
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        hint: '09x xxx xxxx',
                        errorText: _phoneError,
                        enabled: !isLoading,
                        onChanged: (_) => setState(() => _phoneError = null),
                      ),
                      const SizedBox(height: 12),

                      AuthInput(
                        label: 'Mật khẩu',
                        controller: _passCtrl,
                        obscureText: true,
                        hint: 'Tối thiểu $passwordMinLength ký tự',
                        textInputAction: TextInputAction.next,
                        errorText: _passError,
                        enabled: !isLoading,
                        onChanged: (_) => setState(() => _passError = null),
                      ),
                      if (_passCtrl.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _PasswordStrength(password: _passCtrl.text),
                      ],
                      const SizedBox(height: 12),

                      AuthInput(
                        label: 'Xác nhận mật khẩu',
                        controller: _confirmCtrl,
                        obscureText: true,
                        hint: 'Nhập lại mật khẩu',
                        textInputAction: TextInputAction.done,
                        errorText: _confirmError,
                        enabled: !isLoading,
                        onChanged: (_) => setState(() => _confirmError = null),
                      ),
                      const SizedBox(height: 20),

                      _ConsentRow(
                        checked: _acceptedTerms,
                        enabled: !isLoading,
                        linkLabel: 'Điều khoản sử dụng',
                        url: LegalLinks.terms,
                        onChanged: (v) => setState(() => _acceptedTerms = v),
                        onOpenLink: _openLink,
                      ),
                      const SizedBox(height: 12),
                      _ConsentRow(
                        checked: _acceptedPrivacy,
                        enabled: !isLoading,
                        linkLabel: 'Chính sách quyền riêng tư',
                        url: LegalLinks.privacy,
                        onChanged: (v) => setState(() => _acceptedPrivacy = v),
                        onOpenLink: _openLink,
                      ),
                      const SizedBox(height: 24),

                      CanvasCta(
                        label: 'Tạo tài khoản',
                        onPressed: isLoading || !_canSubmit ? null : _submit,
                        icon: isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: TutorColors.ink3,
                                ),
                              )
                            : null,
                      ),

                      const SizedBox(height: 28),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: TutorColors.line,
                      ),
                      const SizedBox(height: 8),

                      Center(
                        child: InkWell(
                          onTap: isLoading ? null : _backToLogin,
                          borderRadius: BorderRadius.circular(22),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 44),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Center(
                                widthFactor: 1,
                                child: Text.rich(
                                  TextSpan(
                                    style: TutorType.rowSub().copyWith(
                                      fontSize: 14,
                                    ),
                                    children: [
                                      const TextSpan(text: 'Đã có tài khoản? '),
                                      TextSpan(
                                        text: 'Đăng nhập',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: TutorColors.ink,
                                          decoration: TextDecoration.underline,
                                          decorationColor: TutorColors.ink,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
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

class _PasswordStrength extends StatelessWidget {
  const _PasswordStrength({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final (strength, color, label) = switch (password.length) {
      < 8 => (1, TutorColors.danger, 'Yếu'),
      < 12 => (2, TutorColors.warning, 'Trung bình'),
      _ => (3, TutorColors.success, 'Mạnh'),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(3, (i) {
            final filled = i < strength;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: EdgeInsets.only(left: i > 0 ? 4 : 0),
                height: 3,
                decoration: BoxDecoration(
                  color: filled ? color : TutorColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TutorType.caption(color: color),
        ),
      ],
    );
  }
}

/// Ô đồng ý bắt buộc, kèm liên kết mở văn bản trên tutora.vn.
class _ConsentRow extends StatelessWidget {
  const _ConsentRow({
    required this.checked,
    required this.enabled,
    required this.linkLabel,
    required this.url,
    required this.onChanged,
    required this.onOpenLink,
  });

  final bool checked;
  final bool enabled;
  final String linkLabel;
  final String url;
  final ValueChanged<bool> onChanged;
  final ValueChanged<String> onOpenLink;

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: TutorColors.ink3,
      height: 1.5,
    );
    return GestureDetector(
      onTap: enabled ? () => onChanged(!checked) : null,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: checked ? TutorColors.ink : const Color(0xFFFBFAF7),
              borderRadius: BorderRadius.circular(6),
              border: checked
                  ? null
                  : Border.all(color: const Color(0x291F2A24), width: 1.4),
            ),
            child: checked
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: textStyle,
                children: [
                  const TextSpan(text: 'Tôi đã đọc và đồng ý với '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: GestureDetector(
                      onTap: () => onOpenLink(url),
                      child: Text(
                        linkLabel,
                        style: textStyle.copyWith(
                          fontWeight: FontWeight.w600,
                          color: TutorColors.ink,
                          decoration: TextDecoration.underline,
                          decorationColor: TutorColors.ink,
                        ),
                      ),
                    ),
                  ),
                  const TextSpan(text: ' của TopTutor.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
