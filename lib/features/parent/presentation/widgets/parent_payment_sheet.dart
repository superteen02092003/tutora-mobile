import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/features/parent/data/models/parent_models.dart';
import 'package:tutora/features/parent/presentation/widgets/parent_booking_widgets.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

/// Sheet chuyển khoản: QR + số tài khoản để phụ huynh trả đợt đang chờ.
/// Trả `true` khi đối soát thấy đã nhận tiền.
Future<bool?> showParentPaymentSheet(
  BuildContext context, {
  required ParentPaymentInfo info,
  required Future<bool> Function() onCheck,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PaymentSheet(info: info, onCheck: onCheck),
  );
}

class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet({required this.info, required this.onCheck});

  final ParentPaymentInfo info;
  final Future<bool> Function() onCheck;

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  bool _checking = false;

  Future<void> _check() async {
    setState(() => _checking = true);
    try {
      final paid = await widget.onCheck();
      if (!mounted) return;
      if (paid) {
        Navigator.of(context).pop(true);
        return;
      }
      AppToast.show(
        context,
        message:
            'Chưa nhận được tiền. Nếu bạn vừa chuyển, đợi một lát rồi '
            'kiểm tra lại.',
        type: AppToastType.warning,
      );
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
    final qr = info.vietQrImageUrl ?? info.qrCode;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      info.isDeposit
                          ? 'Trả phí buổi học đầu'
                          : 'Trả phần còn lại',
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
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.line),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Quét mã bằng app ngân hàng, hoặc chuyển khoản theo thông tin '
                'bên dưới.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.45,
                  color: AppColors.ink3,
                ),
              ),
              const SizedBox(height: 16),
              if (qr != null)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Image.network(
                      qr,
                      width: 220,
                      height: 220,
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
              _CopyRow(label: 'Số tiền', value: parentMoney(info.amount)),
              if (info.accountNumber?.isNotEmpty ?? false)
                _CopyRow(label: 'Số tài khoản', value: info.accountNumber!),
              if (info.accountName?.isNotEmpty ?? false)
                _CopyRow(label: 'Chủ tài khoản', value: info.accountName!),
              if (info.description?.isNotEmpty ?? false)
                _CopyRow(label: 'Nội dung', value: info.description!),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: const Color(0xFFF3D9BC)),
                ),
                child: Text(
                  'Chuyển đúng số tiền và giữ nguyên nội dung, nếu không hệ '
                  'thống sẽ không tự đối soát được.',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    height: 1.45,
                    color: const Color(0xFF9A3412),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _checking ? null : () => unawaited(_check()),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _checking ? AppColors.ink3 : AppColors.oxblood,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    _checking ? 'Đang kiểm tra…' : 'Tôi đã chuyển khoản',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 116,
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
            onTap: () {
              unawaited(Clipboard.setData(ClipboardData(text: value)));
              AppToast.show(
                context,
                message: 'Đã copy $label',
                type: AppToastType.success,
              );
            },
            child: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(
                Icons.copy_rounded,
                size: 18,
                color: AppColors.ink3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
