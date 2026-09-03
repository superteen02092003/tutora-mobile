import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/features/tutor/data/datasources/tutor_finance_datasource.dart';
import 'package:tutora/features/tutor/data/models/transaction_type_labels.dart';

/// Ngưỡng rút tối thiểu do admin cấu hình. Lấy từ API, không hardcode:
/// mức thật đang là 50.000 nên số cứng 10.000 trước đây cho form qua rồi mới
/// bị backend chặn — người dùng chỉ thấy lỗi sau khi bấm xác nhận.
final AutoDisposeFutureProvider<double> _minWithdrawalProvider =
    FutureProvider.autoDispose<double>((ref) {
      return ref.read(tutorFinanceDatasourceProvider).getMinWithdrawalAmount();
    });

/// Mở bottom sheet rút tiền.
Future<bool?> showWithdrawSheet(
  BuildContext context, {
  required double available,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    // Phủ lên cả bottom bar của shell, không mở trong nested navigator.
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _WithdrawSheet(available: available),
  );
}

class _WithdrawSheet extends ConsumerStatefulWidget {
  const _WithdrawSheet({required this.available});
  final double available;

  @override
  ConsumerState<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends ConsumerState<_WithdrawSheet> {
  final _controller = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _amount {
    final digits = _controller.text.replaceAll(RegExp('[^0-9]'), '');
    return double.tryParse(digits) ?? 0;
  }

  String? _validate(double minWithdrawal) {
    final amount = _amount;
    if (amount < minWithdrawal) {
      return 'Số tiền rút tối thiểu là ${fmtMoney(minWithdrawal)}.';
    }
    if (amount > widget.available) {
      return 'Vượt quá số dư khả dụng (${fmtMoney(widget.available)}).';
    }
    return null;
  }

  Future<void> _submit(double minWithdrawal) async {
    final err = _validate(minWithdrawal);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(tutorFinanceDatasourceProvider).createWithdrawal(_amount);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on TutorFinanceException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Không tạo được yêu cầu rút tiền. Vui lòng thử lại.';
      });
    }
  }

  void _setPreset(double v) {
    _controller.text = _vndInput(v);
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    // Chưa tải xong thì tạm dùng mức mặc định — chặn cuối vẫn là backend.
    final minWithdrawal =
        ref.watch(_minWithdrawalProvider).valueOrNull ??
        TutorFinanceDatasource.defaultMinWithdrawal;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Rút tiền',
              style: GoogleFonts.ibmPlexSerif(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Số dư khả dụng: ${fmtMoney(widget.available)} · '
              'tối thiểu ${fmtMoney(minWithdrawal)}',
              style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.ink4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _error != null ? AppColors.error : AppColors.line,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [_ThousandsFormatter()],
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '0',
                        hintStyle: GoogleFonts.ibmPlexMono(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink4,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'đ',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                _PresetChip(label: '500K', onTap: () => _setPreset(500000)),
                _PresetChip(label: '1TR', onTap: () => _setPreset(1000000)),
                _PresetChip(label: '2TR', onTap: () => _setPreset(2000000)),
                _PresetChip(
                  label: 'Toàn bộ',
                  onTap: () => _setPreset(widget.available),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.error),
              ),
            ],
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: Color(0xFF7A5900),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tiền được trừ ngay khỏi số dư và chuyển về tài khoản đã lưu sau khi admin duyệt (trong ~24 giờ).',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF7A5900),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _submitting ? null : () => _submit(minWithdrawal),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.cream,
                        ),
                      )
                    : Text(
                        'Xác nhận rút tiền',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.cream,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.line),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}

String _vndInput(double v) {
  final s = v.round().toString();
  return s.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]}.',
  );
}

/// Định dạng nhóm nghìn khi gõ: 1000000 -> 1.000.000
class _ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp('[^0-9]'), '');
    if (digits.isEmpty) {
      return TextEditingValue.empty;
    }
    final formatted = digits.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]}.',
    );
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
