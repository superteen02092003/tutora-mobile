import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/datasources/tutor_finance_datasource.dart';
import 'package:tutora/features/tutor/presentation/widgets/tutor_ui.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

/// Nhập OTP để xác nhận đổi tài khoản ngân hàng. Trả `true` khi xác thực xong.
Future<bool?> showBankOtpSheet(BuildContext context, {required String phone}) {
  return showModalBottomSheet<bool>(
    context: context,
    // Phủ lên cả bottom bar của shell, không mở trong nested navigator.
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BankOtpSheet(phone: phone),
  );
}

class _BankOtpSheet extends ConsumerStatefulWidget {
  const _BankOtpSheet({required this.phone});

  final String phone;

  @override
  ConsumerState<_BankOtpSheet> createState() => _BankOtpSheetState();
}

class _BankOtpSheetState extends ConsumerState<_BankOtpSheet> {
  final _ctrl = TextEditingController();
  Timer? _timer;
  int _cooldown = 0;
  bool _sending = false;
  bool _verifying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _send());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _startCooldown(int seconds) {
    _timer?.cancel();
    setState(() => _cooldown = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  Future<void> _send() async {
    if (_sending || _cooldown > 0) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(tutorFinanceDatasourceProvider).sendBankOtp();
      if (!mounted) return;
      _startCooldown(60);
    } on TutorFinanceException catch (e) {
      if (!mounted) return;
      // Cooldown chưa hết thì hiện đồng hồ thay vì báo lỗi đỏ.
      if (e.errorCode == 'OTP_COOLDOWN_ACTIVE') {
        _startCooldown(60);
      } else {
        setState(() => _error = e.message);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _verify() async {
    final code = _ctrl.text.trim();
    if (code.length < 4) return;
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      await ref.read(tutorFinanceDatasourceProvider).verifyBankOtp(code);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on TutorFinanceException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
      if (e.errorCode == 'OTP_TOO_MANY_ATTEMPTS') {
        AppToast.show(
          context,
          message: 'Nhập sai quá nhiều lần, hãy gửi lại mã.',
          type: AppToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: Container(
        decoration: const BoxDecoration(
          color: TutorColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: TutorColors.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('Xác nhận đổi tài khoản', style: TutorType.screenTitle()),
            const SizedBox(height: 6),
            Text(
              widget.phone.isEmpty
                  ? 'Nhập mã 6 số vừa gửi tới điện thoại của bạn.'
                  : 'Nhập mã 6 số vừa gửi tới ${_mask(widget.phone)}.',
              style: TutorType.rowSub(),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TutorType.numeralLarge().copyWith(letterSpacing: 8),
              decoration: InputDecoration(
                counterText: '',
                hintText: '••••••',
                hintStyle: TutorType.numeralLarge(
                  color: TutorColors.ink4,
                ).copyWith(letterSpacing: 8),
                filled: true,
                fillColor: TutorColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TutorSurface.radius),
                  borderSide: const BorderSide(color: TutorColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TutorSurface.radius),
                  borderSide: BorderSide(
                    color: _error == null
                        ? TutorColors.line
                        : TutorColors.danger,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TutorSurface.radius),
                  borderSide: const BorderSide(color: TutorColors.primary),
                ),
              ),
              onChanged: (v) {
                if (_error != null) setState(() => _error = null);
                if (v.length == 6) unawaited(_verify());
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TutorType.caption(color: TutorColors.danger),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Text('Chưa nhận được mã?', style: TutorType.caption()),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _cooldown > 0 || _sending ? null : _send,
                  child: Text(
                    _cooldown > 0 ? 'Gửi lại sau ${_cooldown}s' : 'Gửi lại',
                    style: TutorType.action(
                      color: _cooldown > 0
                          ? TutorColors.ink4
                          : TutorColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TutorButton(
              label: _verifying ? 'Đang xác nhận…' : 'Xác nhận',
              onTap: _verifying ? null : _verify,
            ),
          ],
        ),
      ),
    );
  }

  /// '0912345678' → '0912***678'.
  static String _mask(String phone) {
    if (phone.length < 7) return phone;
    return '${phone.substring(0, 4)}***${phone.substring(phone.length - 3)}';
  }
}
