import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/tutor/data/datasources/tutor_finance_datasource.dart';
import 'package:tutora/features/tutor/data/models/tutor_finance_models.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_finance_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_wallet/bank_picker_sheet.dart';
import 'package:tutora/features/tutor/presentation/widgets/tutor_ui.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

/// Tài khoản nhận giải ngân — pop `true` khi có thay đổi để ví refresh.
class TutorBankAccountScreen extends ConsumerStatefulWidget {
  const TutorBankAccountScreen({super.key});

  @override
  ConsumerState<TutorBankAccountScreen> createState() =>
      _TutorBankAccountScreenState();
}

class _TutorBankAccountScreenState
    extends ConsumerState<TutorBankAccountScreen> {
  final _accountNumber = TextEditingController();
  final _holderName = TextEditingController();
  BankOption? _selectedBank;
  String? _initialBankName;

  bool _saving = false;
  bool _deleting = false;
  bool _prefilled = false;
  String? _accountError;
  String? _holderError;
  String? _bankError;

  @override
  void dispose() {
    _accountNumber.dispose();
    _holderName.dispose();
    super.dispose();
  }

  void _prefill(TutorBankInfo bank, List<BankOption> banks) {
    if (_prefilled) return;
    _prefilled = true;
    if (!bank.isComplete) return;
    _accountNumber.text = bank.accountNumber ?? '';
    _holderName.text = bank.accountHolderName ?? '';
    _initialBankName = bank.bankName;
    _selectedBank = banks.where((b) => b.shortName == bank.bankName).isNotEmpty
        ? banks.firstWhere((b) => b.shortName == bank.bankName)
        : null;
  }

  bool _validate() {
    final acc = _accountNumber.text.trim();
    final holder = _holderName.text.trim();
    var ok = true;
    setState(() {
      _bankError = null;
      _accountError = null;
      _holderError = null;
    });
    if (_selectedBank == null && (_initialBankName?.isEmpty ?? true)) {
      setState(() => _bankError = 'Vui lòng chọn ngân hàng.');
      ok = false;
    }
    if (!RegExp(r'^\d{8,19}$').hasMatch(acc)) {
      setState(() => _accountError = 'Số tài khoản gồm 8–19 chữ số.');
      ok = false;
    }
    if (holder.isEmpty || !RegExp(r'^[A-Z\s]+$').hasMatch(holder)) {
      setState(
        () => _holderError =
            'Tên chủ TK viết IN HOA không dấu (VD: NGUYEN VAN A).',
      );
      ok = false;
    }
    return ok;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(tutorFinanceDatasourceProvider)
          .updateBankInfo(
            bankName: _selectedBank?.shortName ?? _initialBankName ?? '',
            accountNumber: _accountNumber.text.trim(),
            accountHolderName: _holderName.text.trim(),
          );
      if (!mounted) return;
      ref.invalidate(tutorBankInfoProvider);
      AppToast.show(
        context,
        message: 'Đã lưu tài khoản ngân hàng.',
        type: AppToastType.success,
      );
      Navigator.of(context).pop(true);
    } on TutorFinanceException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppToast.show(context, message: e.message, type: AppToastType.error);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppToast.show(
        context,
        message: 'Không lưu được tài khoản.',
        type: AppToastType.error,
      );
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: Text('Xóa tài khoản?', style: AppTextStyles.h3()),
        content: Text(
          'Bạn sẽ không thể rút tiền cho đến khi thêm tài khoản mới.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink3),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _deleting = true);
    try {
      await ref.read(tutorFinanceDatasourceProvider).deleteBankInfo();
      if (!mounted) return;
      ref.invalidate(tutorBankInfoProvider);
      AppToast.show(
        context,
        message: 'Đã xóa tài khoản ngân hàng.',
        type: AppToastType.success,
      );
      Navigator.of(context).pop(true);
    } on TutorFinanceException catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      AppToast.show(context, message: e.message, type: AppToastType.error);
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleting = false);
      AppToast.show(
        context,
        message: 'Không xóa được tài khoản.',
        type: AppToastType.error,
      );
    }
  }

  Future<void> _pickBank(List<BankOption> banks) async {
    final picked = await showBankPickerSheet(context, banks);
    if (picked != null) {
      setState(() {
        _selectedBank = picked;
        _initialBankName = picked.shortName;
        _bankError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bankInfoAsync = ref.watch(tutorBankInfoProvider);
    final banksAsync = ref.watch(bankListProvider);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      body: SafeArea(
        child: Column(
          children: [
            TutorChildHeader(
              title: 'Tài khoản ngân hàng',
              action: bankInfoAsync.valueOrNull?.isComplete ?? false
                  ? IconButton(
                      onPressed: _deleting ? null : _delete,
                      tooltip: 'Xóa tài khoản',
                      icon: const Icon(Icons.delete_outline_rounded, size: 21),
                      color: AppColors.error,
                    )
                  : null,
            ),
            Expanded(
              child: bankInfoAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.oxblood,
                    strokeWidth: 2,
                  ),
                ),
                error: (_, _) => Center(
                  child: Text(
                    'Không tải được thông tin.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.ink3,
                    ),
                  ),
                ),
                data: (bank) {
                  final banks = banksAsync.valueOrNull ?? const <BankOption>[];
                  _prefill(bank, banks);
                  return ListView(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad + 24),
                    children: [
                      _label('NGÂN HÀNG'),
                      const SizedBox(height: 6),
                      _BankField(
                        selected: _selectedBank,
                        fallbackName: _initialBankName,
                        loading: banksAsync.isLoading,
                        error: _bankError,
                        onTap: banks.isEmpty ? null : () => _pickBank(banks),
                      ),
                      const SizedBox(height: 16),
                      _label('SỐ TÀI KHOẢN'),
                      const SizedBox(height: 6),
                      _InputField(
                        controller: _accountNumber,
                        hint: 'VD: 0123456789',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(19),
                        ],
                        error: _accountError,
                        mono: true,
                      ),
                      const SizedBox(height: 16),
                      _label('TÊN CHỦ TÀI KHOẢN'),
                      const SizedBox(height: 6),
                      _InputField(
                        controller: _holderName,
                        hint: 'VD: NGUYEN VAN A',
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [_UpperCaseFormatter()],
                        error: _holderError,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Viết IN HOA không dấu, đúng tên trên tài khoản ngân hàng.',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: AppColors.ink4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: _saving ? null : _save,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.ink,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          alignment: Alignment.center,
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.cream,
                                  ),
                                )
                              : Text(
                                  'Lưu tài khoản',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.cream,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: GoogleFonts.inter(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.08,
      color: AppColors.ink4,
    ),
  );
}

class _BankField extends StatelessWidget {
  const _BankField({
    required this.selected,
    required this.fallbackName,
    required this.loading,
    required this.error,
    required this.onTap,
  });
  final BankOption? selected;
  final String? fallbackName;
  final bool loading;
  final String? error;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final name = selected?.shortName ?? fallbackName;
    final hasValue = name != null && name.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: error != null ? AppColors.error : AppColors.line,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    loading
                        ? 'Đang tải danh sách ngân hàng…'
                        : hasValue
                        ? name
                        : 'Chọn ngân hàng',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                      color: hasValue ? AppColors.ink : AppColors.ink4,
                    ),
                  ),
                ),
                const Icon(
                  Icons.expand_more_rounded,
                  size: 20,
                  color: AppColors.ink4,
                ),
              ],
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 5),
          Text(
            error!,
            style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.error),
          ),
        ],
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.error,
    this.mono = false,
  });
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final String? error;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final style = mono
        ? GoogleFonts.ibmPlexMono(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          )
        : GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: error != null ? AppColors.error : AppColors.line,
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textCapitalization: textCapitalization,
            style: style,
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.ink4,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 5),
          Text(
            error!,
            style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.error),
          ),
        ],
      ],
    );
  }
}

/// Ép IN HOA khi gõ tên chủ TK (backend chỉ nhận [A-Z\s]).
class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
