import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/features/tutor/data/models/tutor_profile_models.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_profile_provider.dart';
import 'package:tutora/features/tutor/presentation/widgets/tutor_form_widgets.dart';
import 'package:tutora/features/tutor/presentation/widgets/tutor_ui.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

class TutorEditPricingScreen extends ConsumerStatefulWidget {
  const TutorEditPricingScreen({super.key});

  @override
  ConsumerState<TutorEditPricingScreen> createState() =>
      _TutorEditPricingScreenState();
}

class _TutorEditPricingScreenState
    extends ConsumerState<TutorEditPricingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _hourlyRateCtrl;
  late final TextEditingController _trialPriceCtrl;
  late bool _allowNegotiation;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final pricing = ref.read(tutorProfileProvider).progress?.pricing;
    _hourlyRateCtrl = TextEditingController(
      text: pricing?.hourlyRate != null && pricing!.hourlyRate > 0
          ? pricing.hourlyRate.toString()
          : '',
    );
    _trialPriceCtrl = TextEditingController(
      text: pricing?.trialLessonPrice?.toString() ?? '',
    );
    _allowNegotiation = pricing?.allowPriceNegotiation ?? false;
  }

  @override
  void dispose() {
    _hourlyRateCtrl.dispose();
    _trialPriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final hourlyRate = int.tryParse(_hourlyRateCtrl.text.trim()) ?? 0;
    final trialPrice = int.tryParse(_trialPriceCtrl.text.trim());

    final ok = await ref
        .read(tutorProfileProvider.notifier)
        .updatePricing(
          UpdatePricingRequest(
            hourlyRate: hourlyRate,
            allowPriceNegotiation: _allowNegotiation,
            trialLessonPrice: trialPrice,
          ),
        );

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      Navigator.of(context).pop();
      AppToast.show(
        context,
        message: 'Cập nhật giá dạy thành công',
        type: AppToastType.success,
      );
    } else {
      AppToast.show(
        context,
        message: 'Cập nhật thất bại, thử lại sau',
        type: AppToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            TutorChildHeader(
              title: 'Giá dạy',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, bottomPad + 40),
                  children: [
                    TutorFormField(
                      label: 'Giá mỗi giờ (VNĐ)',
                      controller: _hourlyRateCtrl,
                      hint: 'VD: 200000',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Không được để trống';
                        }
                        final n = int.tryParse(v.trim());
                        if (n == null || n <= 0) return 'Giá không hợp lệ';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nhập số nguyên, không dấu chấm/phẩy',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.ink4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TutorFormField(
                      label: 'Giá buổi thử (VNĐ) — tuỳ chọn',
                      controller: _trialPriceCtrl,
                      hint: 'Để trống nếu không có',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    _NegotiationToggle(
                      value: _allowNegotiation,
                      onChanged: (v) => setState(() => _allowNegotiation = v),
                    ),
                    const SizedBox(height: 32),
                    TutorSaveButton(saving: _saving, onSave: _save),
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

class _NegotiationToggle extends StatelessWidget {
  const _NegotiationToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cho phép thương lượng giá',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Phụ huynh có thể đề xuất mức giá khác',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppColors.ink4,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.ink,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}
