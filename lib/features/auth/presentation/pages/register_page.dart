import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/core/constants/legal_links.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/utils/input_validators.dart';
import 'package:tutora/features/auth/presentation/controllers/register_controller.dart';
import 'package:tutora/features/auth/presentation/widgets/auth_input.dart';
import 'package:tutora/features/auth/presentation/widgets/auth_top_deco.dart';
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
      body: Column(
        children: [
          const AuthTopDeco(
            bgColor: AppColors.ink,
            line1: 'Chia sẻ tri thức,',
            italicWord: 'truyền',
            line2Suffix: 'cảm hứng học tập',
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BackLink(onTap: _backToLogin),
                    const SizedBox(height: 22),

                    Text('Đăng ký gia sư', style: AppTextStyles.h2()),
                    const SizedBox(height: 4),
                    Text(
                      'Mã xác minh sẽ được gửi qua Zalo tới số điện thoại.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.ink3,
                      ),
                    ),
                    const SizedBox(height: 22),

                    AuthInput(
                      label: 'Họ và tên',
                      controller: _nameCtrl,
                      hint: 'Nguyễn Văn A',
                      textInputAction: TextInputAction.next,
                      errorText: _nameError,
                      enabled: !isLoading,
                      onChanged: (_) => setState(() => _nameError = null),
                    ),
                    const SizedBox(height: 14),

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
                    const SizedBox(height: 14),

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
                    const SizedBox(height: 14),

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
                    const SizedBox(height: 18),

                    _ConsentRow(
                      checked: _acceptedTerms,
                      enabled: !isLoading,
                      linkLabel: 'Điều khoản sử dụng',
                      url: LegalLinks.terms,
                      onChanged: (v) => setState(() => _acceptedTerms = v),
                      onOpenLink: _openLink,
                    ),
                    const SizedBox(height: 10),
                    _ConsentRow(
                      checked: _acceptedPrivacy,
                      enabled: !isLoading,
                      linkLabel: 'Chính sách quyền riêng tư',
                      url: LegalLinks.privacy,
                      onChanged: (v) => setState(() => _acceptedPrivacy = v),
                      onOpenLink: _openLink,
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ink,
                        foregroundColor: AppColors.cream,
                        minimumSize: const Size(double.infinity, 52),
                        shape: const StadiumBorder(),
                        textStyle: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      onPressed: isLoading || !_canSubmit ? null : _submit,
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.cream,
                              ),
                            )
                          : const Text('Tạo tài khoản'),
                    ),

                    const SizedBox(height: 28),

                    Center(
                      child: GestureDetector(
                        onTap: isLoading ? null : _backToLogin,
                        child: Text.rich(
                          TextSpan(
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.ink3,
                            ),
                            children: [
                              const TextSpan(text: 'Đã có tài khoản? '),
                              TextSpan(
                                text: 'Đăng nhập',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.oxblood,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackLink extends StatelessWidget {
  const _BackLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 14,
            color: AppColors.ink3,
          ),
          const SizedBox(width: 4),
          Text(
            'Quay lại',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink3),
          ),
        ],
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
      < 8 => (1, AppColors.error, 'Yếu'),
      < 12 => (2, AppColors.gold, 'Trung bình'),
      _ => (3, AppColors.green, 'Mạnh'),
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
                  color: filled ? color : AppColors.line,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: color,
          ),
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
      fontSize: 12.5,
      color: AppColors.ink3,
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
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: checked ? AppColors.ink : AppColors.paper,
              borderRadius: BorderRadius.circular(5),
              border: checked
                  ? null
                  : Border.all(color: AppColors.line, width: 1.5),
            ),
            child: checked
                ? const Icon(
                    Icons.check_rounded,
                    size: 12,
                    color: AppColors.cream,
                  )
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
                          color: AppColors.oxblood,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.oxblood,
                        ),
                      ),
                    ),
                  ),
                  const TextSpan(text: ' của Tutora.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
