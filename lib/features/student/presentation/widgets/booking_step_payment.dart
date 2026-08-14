import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/features/student/data/models/payment_models.dart';
import 'package:tutora/features/student/presentation/widgets/booking_constants.dart';
import 'package:tutora/features/student/presentation/widgets/booking_shared.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

/// Phương thức trả phí buổi đầu.
enum PayMethod { wallet, transfer }

/// Bước 5 — trả phí buổi đầu; phần còn lại trả sau khi buổi 1 kết thúc.
class BookingStepPayment extends StatelessWidget {
  const BookingStepPayment({
    required this.summary,
    required this.loading,
    required this.method,
    required this.onMethodChanged,
    required this.error,
    required this.onRetry,
    required this.info,
    super.key,
  });

  final PaymentSummaryDto? summary;
  final bool loading;
  final PayMethod method;
  final ValueChanged<PayMethod> onMethodChanged;
  final String? error;
  final VoidCallback onRetry;

  /// Có giá trị khi đã tạo link — chuyển sang màn QR.
  final PaymentInfoDto? info;

  @override
  Widget build(BuildContext context) {
    if (info != null) return _QrView(info: info!);

    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            error!,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.5,
              color: AppColors.ink3,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.cream2,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(color: AppColors.line),
              ),
              child: Text(
                'Thử lại',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
        ],
      );
    }

    final s = summary;
    if (s == null) return const SizedBox.shrink();

    final isDeposit = s.paymentPhase == 'deposit';
    final walletEnough = s.walletBalance >= s.amount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BookingSectionTitle('Cần thanh toán'),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isDeposit ? 'Đợt 1 — buổi học đầu tiên' : 'Các buổi còn lại',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formatPrice(s.amount),
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  color: AppColors.cream,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            children: [
              BookingPriceRow('Tổng hợp đồng', formatPrice(s.totalAmount)),
              const SizedBox(height: 8),
              BookingPriceRow('Trả bây giờ', formatPrice(s.depositAmount)),
              const SizedBox(height: 8),
              BookingPriceRow(
                'Trả sau buổi đầu',
                formatPrice(s.remainingAmount),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        const BookingSectionTitle('Phương thức'),
        const SizedBox(height: 10),
        _MethodCard(
          icon: Icons.account_balance_wallet_rounded,
          title: 'Ví Tutora',
          subtitle: walletEnough
              ? 'Số dư ${formatPrice(s.walletBalance)}'
              : 'Số dư ${formatPrice(s.walletBalance)} — không đủ',
          selected: method == PayMethod.wallet,
          disabled: !walletEnough,
          onTap: walletEnough ? () => onMethodChanged(PayMethod.wallet) : null,
        ),
        const SizedBox(height: 10),
        _MethodCard(
          icon: Icons.qr_code_rounded,
          title: 'Chuyển khoản ngân hàng',
          subtitle: 'Quét QR hoặc chuyển khoản qua PayOS',
          selected: method == PayMethod.transfer,
          onTap: () => onMethodChanged(PayMethod.transfer),
        ),

        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.08),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Text(
            'Tiền được giữ tại Tutora Escrow và chỉ chuyển cho gia sư sau khi '
            'buổi học hoàn tất.',
            style: GoogleFonts.inter(
              fontSize: 13.5,
              color: AppColors.ink2,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

/// Màn QR chuyển khoản — dựng ảnh VietQR từ bin + số tài khoản như web.
class _QrView extends StatelessWidget {
  const _QrView({required this.info});
  final PaymentInfoDto info;

  @override
  Widget build(BuildContext context) {
    final qr = info.vietQrImageUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BookingSectionTitle('Quét mã để thanh toán'),
        const SizedBox(height: 4),
        Text(
          'Mở app ngân hàng bất kỳ, quét mã VietQR bên dưới.',
          style: GoogleFonts.inter(
            fontSize: 15,
            height: 1.5,
            color: AppColors.ink3,
          ),
        ),
        const SizedBox(height: 16),
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
                    width: 240,
                    height: 240,
                    child: Center(child: Text('Không tạo được mã QR')),
                  )
                : Image.network(
                    qr,
                    width: 240,
                    height: 240,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox(
                      width: 240,
                      height: 240,
                      child: Center(child: Text('Không tải được mã QR')),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            children: [
              _CopyRow(label: 'Số tiền', value: formatPrice(info.amount)),
              if (info.accountNumber != null) ...[
                const Divider(height: 20, color: AppColors.line),
                _CopyRow(label: 'Số tài khoản', value: info.accountNumber!),
              ],
              if (info.accountName != null) ...[
                const Divider(height: 20, color: AppColors.line),
                _CopyRow(label: 'Chủ tài khoản', value: info.accountName!),
              ],
              if (info.description != null) ...[
                const Divider(height: 20, color: AppColors.line),
                _CopyRow(label: 'Nội dung', value: info.description!),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.08),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Text(
            'Nhập ĐÚNG số tiền và nội dung chuyển khoản, nếu sai hệ thống sẽ '
            'không tự nhận được.',
            style: GoogleFonts.inter(
              fontSize: 13.5,
              height: 1.5,
              color: AppColors.ink2,
            ),
          ),
        ),
      ],
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
        width: 110,
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

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.disabled = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: disabled ? 0.55 : 1,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.ink.withValues(alpha: 0.04)
                : Colors.white,
            border: Border.all(
              color: selected ? AppColors.ink : AppColors.line,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected ? AppColors.ink : AppColors.cream2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: selected ? AppColors.gold : AppColors.ink3,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.ink3,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 10),
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 15,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
