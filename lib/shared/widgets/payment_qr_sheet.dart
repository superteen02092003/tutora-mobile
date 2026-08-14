import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/features/student/data/models/payment_models.dart';
import 'package:tutora/features/student/presentation/widgets/booking_constants.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

/// QR chuyển khoản trong app. Trả `true` khi đối soát thấy tiền về.
Future<bool?> showPaymentQrSheet(
  BuildContext context, {
  required PaymentInfoDto info,
  required Future<bool> Function() onCheck,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PaymentQrSheet(info: info, onCheck: onCheck),
  );
}

class _PaymentQrSheet extends StatefulWidget {
  const _PaymentQrSheet({required this.info, required this.onCheck});

  final PaymentInfoDto info;
  final Future<bool> Function() onCheck;

  @override
  State<_PaymentQrSheet> createState() => _PaymentQrSheetState();
}

class _PaymentQrSheetState extends State<_PaymentQrSheet> {
  bool _checking = false;

  Future<void> _check() async {
    setState(() => _checking = true);
    try {
      final paid = await widget.onCheck();
      if (!mounted) return;
      if (paid) {
        Navigator.of(context).pop(true);
      } else {
        AppToast.show(
          context,
          message:
              'Chưa nhận được tiền. Nếu bạn vừa chuyển, đợi một lát rồi thử lại.',
          type: AppToastType.warning,
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: e.toString().replaceFirst('Exception: ', ''),
        type: AppToastType.error,
      );
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final qr = info.vietQrImageUrl;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Quét mã để thanh toán',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(false),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.paper,
                        border: Border.all(color: AppColors.line),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: qr == null
                          ? const SizedBox(
                              width: 220,
                              height: 220,
                              child: Center(
                                child: Text('Không tạo được mã QR'),
                              ),
                            )
                          : Image.network(
                              qr,
                              width: 220,
                              height: 220,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const SizedBox(
                                width: 220,
                                height: 220,
                                child: Center(
                                  child: Text('Không tải được mã QR'),
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      children: [
                        _CopyRow(
                          label: 'Số tiền',
                          value: formatPrice(info.amount),
                        ),
                        if (info.accountNumber != null) ...[
                          const Divider(height: 20, color: AppColors.line),
                          _CopyRow(
                            label: 'Số tài khoản',
                            value: info.accountNumber!,
                          ),
                        ],
                        if (info.accountName != null) ...[
                          const Divider(height: 20, color: AppColors.line),
                          _CopyRow(
                            label: 'Chủ tài khoản',
                            value: info.accountName!,
                          ),
                        ],
                        if (info.description != null) ...[
                          const Divider(height: 20, color: AppColors.line),
                          _CopyRow(
                            label: 'Nội dung',
                            value: info.description!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Nhập ĐÚNG số tiền và nội dung, nếu sai hệ thống sẽ không '
                    'tự nhận được.',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      height: 1.5,
                      color: AppColors.ink3,
                    ),
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: _checking ? null : _check,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _checking ? AppColors.line : AppColors.ink,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        _checking ? 'Đang kiểm tra...' : 'Tôi đã chuyển khoản',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _checking ? AppColors.ink4 : AppColors.cream,
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
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 104,
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink3),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ),
      GestureDetector(
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: value));
          if (context.mounted) {
            AppToast.show(
              context,
              message: 'Đã sao chép $label',
              type: AppToastType.success,
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.cream2,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: AppColors.line),
          ),
          child: Text(
            'Sao chép',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
    ],
  );
}
