import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/shared/widgets/app_logo.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({required this.email, super.key});

  final String email;

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final List<TextEditingController> _ctrls = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());

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

  bool get _isFull => _ctrls.every((c) => c.text.isNotEmpty);

  void _onVerify() {
    AppToast.show(
      context,
      message: 'Tính năng xác thực đang được phát triển.',
      type: AppToastType.info,
    );
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) context.go(AppRoutes.login);
    });
  }

  void _onResend() {
    setState(() => _resendCd = 59);
    _timer?.cancel();
    _startTimer();
    AppToast.show(
      context,
      message: 'Tính năng gửi lại đang được phát triển.',
      type: AppToastType.info,
    );
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    // Icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.mail_outline_rounded,
                        color: AppColors.gold,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Xác thực email',
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
                            text: widget.email,
                            style: GoogleFonts.ibmPlexMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
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
                              onTap: _onResend,
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
                      onPressed: _isFull ? _onVerify : null,
                      child: const Text('Xác nhận'),
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
