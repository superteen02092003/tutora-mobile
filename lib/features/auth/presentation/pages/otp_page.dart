import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/storage/secure_storage.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/core/utils/input_validators.dart';
import 'package:tutora/core/utils/jwt_utils.dart';
import 'package:tutora/features/auth/presentation/controllers/otp_controller.dart';
import 'package:tutora/features/auth/presentation/pages/login_page.dart';
import 'package:tutora/features/auth/presentation/widgets/auth_input.dart';
import 'package:tutora/features/auth/presentation/widgets/auth_top_deco.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';
import 'package:tutora/shared/services/push_token_service.dart';
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
      return _newPassCtrl.text.length >= passwordMinLength &&
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
      backgroundColor: TutorColors.bg,
      body: DecoratedBox(
        decoration: TutorSurface.paper,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthTopDeco(
                  onBack: () => context.pop(),
                  hand: 'Sắp xong rồi',
                  title: _isForgot
                      ? 'Đặt lại mật khẩu'
                      : 'Xác minh số điện thoại',
                  lead: Text.rich(
                    TextSpan(
                      style: const TextStyle(height: 1.55),
                      children: [
                        const TextSpan(text: 'Nhập mã 6 chữ số đã gửi đến\n'),
                        TextSpan(
                          text: widget.phone,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: TutorColors.ink,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const TextSpan(text: ' qua Zalo.'),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TutorSurface.gutter,
                    28,
                    TutorSurface.gutter,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                      const SizedBox(height: 14),

                      // Resend timer
                      Center(
                        child: _resendCd > 0
                            ? ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 44,
                                ),
                                child: Center(
                                  widthFactor: 1,
                                  child: Text.rich(
                                    TextSpan(
                                      style: TutorType.rowSub().copyWith(
                                        fontSize: 14,
                                      ),
                                      children: [
                                        const TextSpan(text: 'Gửi lại sau '),
                                        TextSpan(
                                          text:
                                              '0:${_resendCd.toString().padLeft(2, '0')}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: TutorColors.ink,
                                            fontFeatures: [
                                              FontFeature.tabularFigures(),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : InkWell(
                                onTap: isLoading ? null : _onResend,
                                borderRadius: BorderRadius.circular(22),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minHeight: 44,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: Center(
                                      widthFactor: 1,
                                      child: Text(
                                        'Gửi lại mã →',
                                        style: TutorType.action().copyWith(
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                          decorationColor: TutorColors.ink,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ),

                      // Forgot password: thêm field nhập mật khẩu mới
                      if (_isForgot) ...[
                        const SizedBox(height: 20),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: TutorColors.line,
                        ),
                        const SizedBox(height: 20),
                        AuthInput(
                          label: 'Mật khẩu mới',
                          controller: _newPassCtrl,
                          obscureText: true,
                          hint: 'Tối thiểu $passwordMinLength ký tự',
                          textInputAction: TextInputAction.next,
                          enabled: !isLoading,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        AuthInput(
                          label: 'Xác nhận mật khẩu',
                          controller: _confirmPassCtrl,
                          obscureText: true,
                          hint: 'Nhập lại mật khẩu',
                          textInputAction: TextInputAction.done,
                          enabled: !isLoading,
                          onChanged: (_) => setState(() {}),
                        ),
                      ],

                      const SizedBox(height: 28),

                      CanvasCta(
                        label: _isForgot ? 'Đặt lại mật khẩu' : 'Xác nhận',
                        onPressed: isLoading || !_canSubmit ? null : _onVerify,
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

/// Ô một chữ số — ô lõm sáng, viền mực 8%; đã nhập thì viền xanh rêu.
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
    final empty = controller.text.isEmpty;
    final side = BorderSide(
      color: empty ? AuthInput.border : TutorColors.ink,
      width: empty ? 1.0 : 1.5,
    );
    final radius = BorderRadius.circular(AuthInput.radius);
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
          cursorColor: TutorColors.ink,
          style: TutorType.display(size: 22, height: 1.2),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: AuthInput.fill,
            border: OutlineInputBorder(borderRadius: radius, borderSide: side),
            enabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: side,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(color: TutorColors.ink, width: 1.5),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}
