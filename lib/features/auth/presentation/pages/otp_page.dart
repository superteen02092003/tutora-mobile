import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/storage/secure_storage.dart';
import 'package:tutora/core/utils/jwt_utils.dart';
import 'package:tutora/features/auth/presentation/controllers/otp_controller.dart';
import 'package:tutora/features/auth/presentation/pages/login_page.dart';
import 'package:tutora/shared/services/push_token_service.dart';
import 'package:tutora/shared/widgets/app_logo.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

class OtpPage extends ConsumerStatefulWidget {
  const OtpPage({required this.phone, required this.mode, super.key});

  final String phone;
  final OtpMode mode;

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> {
  final List<TextEditingController> _ctrls = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());

  // Forgot password — bước 2: nhập mật khẩu mới
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  int _resendCd = 59;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nodes[0].requestFocus();
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_resendCd <= 0) {
        _timer?.cancel();
      } else {
        setState(() => _resendCd--);
      }
    });
  }

  void _onDigit(int i, String val) {
    final digit = val.replaceAll(RegExp(r'\D'), '');
    if (digit.isEmpty) return;
    _ctrls[i].text = digit[digit.length - 1];
    if (i < 5) _nodes[i + 1].requestFocus();
    setState(() {});
  }

  void _onKey(int i, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _ctrls[i].text.isEmpty &&
        i > 0) {
      _nodes[i - 1].requestFocus();
      _ctrls[i - 1].clear();
      setState(() {});
    }
  }

  String get _otp => _ctrls.map((c) => c.text).join();

  bool get _otpFull => _ctrls.every((c) => c.text.isNotEmpty);

  bool get _isForgot => widget.mode == OtpMode.forgotPassword;

  bool get _canSubmit {
    if (!_otpFull) return false;
    if (_isForgot) {
      return _newPassCtrl.text.length >= 8 &&
          _newPassCtrl.text == _confirmPassCtrl.text;
    }
    return true;
  }

  Future<void> _onVerify() async {
    if (_isForgot) {
      // Trước đây nhánh này gọi nhầm verify-phone nên mật khẩu mới không bao giờ
      // được lưu — màn vẫn báo "Đặt lại mật khẩu thành công".
      await ref
          .read(otpControllerProvider.notifier)
          .resetPassword(
            phone: widget.phone,
            otp: _otp,
            newPassword: _newPassCtrl.text,
          );
    } else {
      await ref
          .read(otpControllerProvider.notifier)
          .verify(
            phone: widget.phone,
            otp: _otp,
          );
    }
  }

  Future<void> _onResend() async {
    setState(() {
      _resendCd = 59;
      for (final c in _ctrls) {
        c.clear();
      }
    });
    _timer?.cancel();
    _startTimer();
    final notifier = ref.read(otpControllerProvider.notifier);
    if (_isForgot) {
      await notifier.resendForgot(phone: widget.phone);
    } else {
      await notifier.resend(phone: widget.phone);
    }
  }

  /// Xác minh SĐT xong backend trả JWT (repository đã lưu): gia sư vào thẳng
  /// app; vai trò khác bị đăng xuất như ở trang đăng nhập.
  Future<void> _enterApp() async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.getAccessToken();
    if (!mounted) return;
    final claims = token == null ? null : parseJwt(token);
    if (claims == null) {
      context.go(AppRoutes.login);
      return;
    }
    if (claims.role != UserRole.tutor) {
      await storage.clearTokens();
      if (!mounted) return;
      AppToast.show(
        context,
        message: tutorOnlyMessage,
        type: AppToastType.warning,
        duration: const Duration(seconds: 6),
      );
      context.go(AppRoutes.login);
      return;
    }
    unawaited(ref.read(pushTokenServiceProvider).registerToken());
    context.go(AppRoutes.tutorHome);
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(otpControllerProvider, (_, state) {
      if (!context.mounted) return;
      if (state is OtpSuccess) {
        AppToast.show(
          context,
          message: _isForgot
              ? 'Đặt lại mật khẩu thành công!'
              : 'Xác minh thành công!',
          type: AppToastType.success,
        );
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!context.mounted) return;
          if (_isForgot) {
            context.go(AppRoutes.login);
          } else {
            unawaited(_enterApp());
          }
        });
      } else if (state is OtpResent) {
        AppToast.show(
          context,
          message: 'Đã gửi lại mã OTP.',
          type: AppToastType.success,
        );
        ref.read(otpControllerProvider.notifier).reset();
      } else if (state is OtpError) {
        AppToast.show(
          context,
          message: state.message,
          type: AppToastType.error,
        );
        ref.read(otpControllerProvider.notifier).reset();
      }
    });

    final isLoading = ref.watch(otpControllerProvider) is OtpLoading;

    return Scaffold(
      backgroundColor: AppColors.cream2,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              color: AppColors.cream2,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
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
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.ink3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const AppLogo(),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.line),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.phone_android_rounded,
                        color: AppColors.gold,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      _isForgot ? 'Đặt lại mật khẩu' : 'Xác minh số điện thoại',
                      style: GoogleFonts.bricolageGrotesque(
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                        letterSpacing: -0.5,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.ink3,
                          height: 1.6,
                        ),
                        children: [
                          const TextSpan(text: 'Nhập mã 6 chữ số đã gửi đến\n'),
                          TextSpan(
                            text: widget.phone,
                            style: GoogleFonts.ibmPlexMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          const TextSpan(text: ' qua Zalo.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // OTP boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        6,
                        (i) => _OtpBox(
                          controller: _ctrls[i],
                          focusNode: _nodes[i],
                          onChanged: (v) => _onDigit(i, v),
                          onKey: (e) => _onKey(i, e),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Resend timer
                    Center(
                      child: _resendCd > 0
                          ? Text.rich(
                              TextSpan(
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.ink3,
                                ),
                                children: [
                                  const TextSpan(text: 'Gửi lại sau '),
                                  TextSpan(
                                    text:
                                        '0:${_resendCd.toString().padLeft(2, '0')}',
                                    style: GoogleFonts.ibmPlexMono(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : GestureDetector(
                              onTap: isLoading ? null : _onResend,
                              child: Text(
                                'Gửi lại mã →',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.oxblood,
                                ),
                              ),
                            ),
                    ),

                    // Forgot password: thêm field nhập mật khẩu mới
                    if (_isForgot) ...[
                      const SizedBox(height: 28),
                      const Divider(color: AppColors.line),
                      const SizedBox(height: 20),
                      Text(
                        'Mật khẩu mới',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _newPassCtrl,
                        obscureText: true,
                        enabled: !isLoading,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Tối thiểu 8 ký tự',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.ink3,
                          ),
                          filled: true,
                          fillColor: AppColors.paper,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            borderSide: const BorderSide(color: AppColors.line),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            borderSide: const BorderSide(color: AppColors.line),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            borderSide: const BorderSide(
                              color: AppColors.ink,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirmPassCtrl,
                        obscureText: true,
                        enabled: !isLoading,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Xác nhận mật khẩu',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.ink3,
                          ),
                          filled: true,
                          fillColor: AppColors.paper,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            borderSide: const BorderSide(color: AppColors.line),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            borderSide: const BorderSide(color: AppColors.line),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            borderSide: const BorderSide(
                              color: AppColors.ink,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

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
                      onPressed: isLoading || !_canSubmit ? null : _onVerify,
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.cream,
                              ),
                            )
                          : Text(_isForgot ? 'Đặt lại mật khẩu' : 'Xác nhận'),
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

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onKey,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<KeyEvent> onKey;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 56,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: onKey,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          onChanged: onChanged,
          style: GoogleFonts.ibmPlexMono(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: controller.text.isEmpty
                ? AppColors.cream2
                : AppColors.paper,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: controller.text.isEmpty ? AppColors.line : AppColors.ink,
                width: controller.text.isEmpty ? 1.0 : 2.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: controller.text.isEmpty ? AppColors.line : AppColors.ink,
                width: controller.text.isEmpty ? 1.0 : 2.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.ink, width: 2),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}
