import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/auth/presentation/controllers/register_controller.dart';
import 'package:tutora/features/auth/presentation/widgets/auth_input.dart';
import 'package:tutora/features/auth/presentation/widgets/auth_top_deco.dart';
import 'package:tutora/features/auth/presentation/widgets/role_tab.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  int _step = 1;
  AuthRole _role = AuthRole.student;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _agreed = false;

  String? _emailError;
  String? _confirmError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool get _step1Valid =>
      _nameCtrl.text.trim().isNotEmpty && _emailCtrl.text.trim().isNotEmpty;

  bool get _step2Valid =>
      _passCtrl.text.isNotEmpty &&
      _confirmCtrl.text.isNotEmpty &&
      _passCtrl.text == _confirmCtrl.text &&
      _agreed;

  int _passStrength(String p) {
    if (p.isEmpty) return 0;
    if (p.length < 6) return 1;
    if (p.length < 10) return 2;
    return 3;
  }

  Color _strengthColor(int s) =>
      [Colors.transparent, AppColors.error, AppColors.gold, AppColors.green][s];

  String _strengthLabel(int s) => ['', 'Yếu', 'Trung bình', 'Mạnh'][s];

  Future<void> _goNext() async {
    if (_step == 1) {
      if (!_emailCtrl.text.contains('@')) {
        setState(() => _emailError = 'Email không hợp lệ');
        return;
      }
      setState(() {
        _emailError = null;
        _step = 2;
      });
      return;
    }

    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() => _confirmError = 'Mật khẩu không khớp');
      return;
    }
    setState(() => _confirmError = null);

    await ref
        .read(registerControllerProvider.notifier)
        .register(
          email: _emailCtrl.text,
          password: _passCtrl.text,
          fullName: _nameCtrl.text,
          role: _role.apiValue,
          phone: _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(registerControllerProvider, (_, state) {
      if (state is RegisterSuccess) {
        AppToast.show(
          context,
          message: 'Đăng ký thành công! Vui lòng đăng nhập.',
          type: AppToastType.success,
        );
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (context.mounted) context.pop();
        });
      }
      if (state is RegisterError) {
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
            line1: 'Hiểu sâu hơn,',
            italicWord: 'không chỉ',
            line2Suffix: 'tìm đáp án',
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StepHeader(
                      step: _step,
                      onBack: () {
                        if (_step == 1) {
                          context.pop();
                        } else {
                          setState(() => _step = 1);
                        }
                      },
                    ),
                    const SizedBox(height: 22),

                    Text(
                      _step == 1 ? 'Tạo tài khoản' : 'Thiết lập mật khẩu',
                      style: AppTextStyles.h2(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _step == 1
                          ? 'Bạn là học sinh hay gia sư?'
                          : 'Mật khẩu mạnh bảo vệ tài khoản của bạn.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.ink3,
                      ),
                    ),
                    const SizedBox(height: 22),

                    if (_step == 1) ...[
                      RoleTab(
                        active: _role,
                        onChanged: (r) => setState(() => _role = r),
                      ),
                      const SizedBox(height: 20),
                      _Step1Fields(
                        nameCtrl: _nameCtrl,
                        emailCtrl: _emailCtrl,
                        phoneCtrl: _phoneCtrl,
                        emailError: _emailError,
                        enabled: !isLoading,
                        onEmailChanged: (_) =>
                            setState(() => _emailError = null),
                      ),
                    ] else ...[
                      _Step2Fields(
                        passCtrl: _passCtrl,
                        confirmCtrl: _confirmCtrl,
                        confirmError: _confirmError,
                        agreed: _agreed,
                        enabled: !isLoading,
                        onConfirmChanged: (_) =>
                            setState(() => _confirmError = null),
                        onPassChanged: (_) => setState(() {}),
                        onAgreedChanged: (v) => setState(() => _agreed = v),
                        passStrength: _passStrength(_passCtrl.text),
                        strengthColor: _strengthColor(
                          _passStrength(_passCtrl.text),
                        ),
                        strengthLabel: _strengthLabel(
                          _passStrength(_passCtrl.text),
                        ),
                      ),
                    ],

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
                      onPressed:
                          isLoading ||
                              (_step == 1 && !_step1Valid) ||
                              (_step == 2 && !_step2Valid)
                          ? null
                          : _goNext,
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.cream,
                              ),
                            )
                          : Text(_step == 1 ? 'Tiếp theo →' : 'Tạo tài khoản'),
                    ),

                    const SizedBox(height: 32),

                    Center(
                      child: Text.rich(
                        TextSpan(
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.ink3,
                          ),
                          children: [
                            const TextSpan(text: 'Đã có tài khoản? '),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: GestureDetector(
                                onTap: () => context.pop(),
                                child: Text(
                                  'Đăng nhập',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.oxblood,
                                  ),
                                ),
                              ),
                            ),
                          ],
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

// ── Step header (back button + progress dots) ──────────────────────────────

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step, required this.onBack});

  final int step;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: onBack,
          child: Row(
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
        ),
        Row(
          children: List.generate(2, (i) {
            final active = i < step;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(left: 5),
              width: active ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? AppColors.ink : AppColors.line,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ── Step 1 fields ──────────────────────────────────────────────────────────

class _Step1Fields extends StatelessWidget {
  const _Step1Fields({
    required this.nameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.enabled,
    this.emailError,
    this.onEmailChanged,
  });

  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final bool enabled;
  final String? emailError;
  final ValueChanged<String>? onEmailChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AuthInput(
          label: 'Họ và tên',
          controller: nameCtrl,
          hint: 'Nguyễn Văn A',
          textInputAction: TextInputAction.next,
          enabled: enabled,
        ),
        const SizedBox(height: 14),
        AuthInput(
          label: 'Email',
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          hint: 'ten@email.com',
          errorText: emailError,
          onChanged: onEmailChanged,
          enabled: enabled,
        ),
        const SizedBox(height: 14),
        AuthInput(
          label: 'Số điện thoại (tuỳ chọn)',
          controller: phoneCtrl,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          hint: '09x xxx xxxx',
          enabled: enabled,
        ),
      ],
    );
  }
}

// ── Step 2 fields ──────────────────────────────────────────────────────────

class _Step2Fields extends StatelessWidget {
  const _Step2Fields({
    required this.passCtrl,
    required this.confirmCtrl,
    required this.agreed,
    required this.enabled,
    required this.passStrength,
    required this.strengthColor,
    required this.strengthLabel,
    required this.onAgreedChanged,
    this.confirmError,
    this.onPassChanged,
    this.onConfirmChanged,
  });

  final TextEditingController passCtrl;
  final TextEditingController confirmCtrl;
  final bool agreed;
  final bool enabled;
  final int passStrength;
  final Color strengthColor;
  final String strengthLabel;
  final ValueChanged<bool> onAgreedChanged;
  final String? confirmError;
  final ValueChanged<String>? onPassChanged;
  final ValueChanged<String>? onConfirmChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthInput(
          label: 'Mật khẩu',
          controller: passCtrl,
          obscureText: true,
          hint: 'Tối thiểu 8 ký tự',
          textInputAction: TextInputAction.next,
          enabled: enabled,
          onChanged: onPassChanged,
        ),

        if (passCtrl.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: List.generate(3, (i) {
              final filled = i < passStrength;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: EdgeInsets.only(left: i > 0 ? 4 : 0),
                  height: 3,
                  decoration: BoxDecoration(
                    color: filled ? strengthColor : AppColors.line,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Text(
            strengthLabel,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: strengthColor,
            ),
          ),
        ],

        const SizedBox(height: 14),

        AuthInput(
          label: 'Xác nhận mật khẩu',
          controller: confirmCtrl,
          obscureText: true,
          hint: 'Nhập lại mật khẩu',
          textInputAction: TextInputAction.done,
          enabled: enabled,
          errorText: confirmError,
          onChanged: onConfirmChanged,
        ),

        const SizedBox(height: 16),

        GestureDetector(
          onTap: enabled ? () => onAgreedChanged(!agreed) : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 18,
                height: 18,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: agreed ? AppColors.ink : AppColors.paper,
                  borderRadius: BorderRadius.circular(5),
                  border: agreed
                      ? null
                      : Border.all(color: AppColors.line, width: 1.5),
                ),
                child: agreed
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
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.ink3,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'Tôi đồng ý với '),
                      TextSpan(
                        text: 'Điều khoản sử dụng',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.oxblood,
                        ),
                      ),
                      const TextSpan(text: ' và '),
                      TextSpan(
                        text: 'Chính sách bảo mật',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.oxblood,
                        ),
                      ),
                      const TextSpan(text: ' của Tutora.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
