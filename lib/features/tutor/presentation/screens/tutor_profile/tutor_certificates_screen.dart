import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/features/tutor/data/models/tutor_profile_models.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_profile_provider.dart';
import 'package:tutora/features/tutor/presentation/widgets/tutor_form_widgets.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

class TutorCertificatesScreen extends ConsumerStatefulWidget {
  const TutorCertificatesScreen({super.key});

  @override
  ConsumerState<TutorCertificatesScreen> createState() =>
      _TutorCertificatesScreenState();
}

class _TutorCertificatesScreenState
    extends ConsumerState<TutorCertificatesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(tutorProfileProvider.notifier).loadCertificates());
    });
  }

  void _showAddSheet() {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.paper,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => const _AddCertificateSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tutorProfileProvider);
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          SizedBox(height: topPad),
          TutorScreenHeader(
            title: 'Chứng chỉ & bằng cấp',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: state.isLoading && state.certificates.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.certificates.isEmpty
                ? _EmptyState(onAdd: _showAddSheet)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    children: state.certificates
                        .map((cert) => _CertItem(cert: cert))
                        .toList(),
                  ),
          ),
          // Add button pinned above safe area — always visible regardless of nav bar height
          Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad + 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _showAddSheet,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                label: Text(
                  'Thêm chứng chỉ',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CertItem extends StatelessWidget {
  const _CertItem({required this.cert});

  final CertificateDto cert;

  Color get _statusColor {
    if (cert.isVerified) return AppColors.green;
    if (cert.isRejected) return AppColors.oxblood;
    return AppColors.gold;
  }

  String get _statusLabel {
    if (cert.isVerified) return 'Đã xác minh';
    if (cert.isRejected) return 'Bị từ chối';
    return 'Chờ xét duyệt';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.cream2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.workspace_premium_outlined,
              size: 20,
              color: AppColors.ink3,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cert.certificateName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cert.issuingOrganization,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink4),
                ),
                if (cert.yearIssued != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Năm ${cert.yearIssued}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.ink4,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _statusLabel,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _statusColor,
                    ),
                  ),
                ),
                if (cert.isRejected && cert.verificationNote != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Lý do: ${cert.verificationNote}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.oxblood,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.workspace_premium_outlined,
              size: 48,
              color: AppColors.line,
            ),
            const SizedBox(height: 12),
            Text(
              'Chưa có chứng chỉ nào',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.ink3,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Thêm bằng cấp, chứng chỉ để tăng độ tin cậy',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Add Certificate Bottom Sheet
class _AddCertificateSheet extends ConsumerStatefulWidget {
  const _AddCertificateSheet();

  @override
  ConsumerState<_AddCertificateSheet> createState() =>
      _AddCertificateSheetState();
}

class _AddCertificateSheetState extends ConsumerState<_AddCertificateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _orgCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  String _selectedType = 'Degree';
  String? _filePath;
  bool _saving = false;

  static const _certTypes = [
    ('Degree', 'Bằng cấp'),
    ('Certificate', 'Chứng chỉ'),
    ('Award', 'Giải thưởng'),
    ('Other', 'Khác'),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _orgCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _filePath = file.path);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_filePath == null) {
      AppToast.show(
        context,
        message: 'Vui lòng chọn file chứng chỉ',
        type: AppToastType.error,
      );
      return;
    }
    setState(() => _saving = true);

    final ok = await ref
        .read(tutorProfileProvider.notifier)
        .uploadCertificate(
          filePath: _filePath!,
          certificateName: _nameCtrl.text.trim(),
          certificateType: _selectedType,
          issuingOrganization: _orgCtrl.text.trim(),
          yearIssued: int.tryParse(_yearCtrl.text.trim()),
        );

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      Navigator.of(context).pop();
      AppToast.show(
        context,
        message: 'Đã tải lên chứng chỉ',
        type: AppToastType.success,
      );
    } else {
      AppToast.show(
        context,
        message: 'Tải lên thất bại, thử lại sau',
        type: AppToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final keyboardPad = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPad + keyboardPad + 16),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
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
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Thêm chứng chỉ',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Loại chứng chỉ',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink3,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _certTypes.map((t) {
                  final selected = _selectedType == t.$1;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedType = t.$1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.ink : AppColors.paper,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: selected ? AppColors.ink : AppColors.line,
                        ),
                      ),
                      child: Text(
                        t.$2,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: selected ? Colors.white : AppColors.ink3,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TutorFormField(
                label: 'Tên chứng chỉ',
                controller: _nameCtrl,
                hint: 'VD: IELTS 7.5',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Không được để trống'
                    : null,
              ),
              const SizedBox(height: 14),
              TutorFormField(
                label: 'Tổ chức cấp',
                controller: _orgCtrl,
                hint: 'VD: British Council',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Không được để trống'
                    : null,
              ),
              const SizedBox(height: 14),
              TutorFormField(
                label: 'Năm cấp (tuỳ chọn)',
                controller: _yearCtrl,
                hint: 'VD: 2023',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cream2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _filePath != null
                          ? AppColors.green
                          : AppColors.line,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _filePath != null
                            ? Icons.check_circle_outline_rounded
                            : Icons.upload_file_outlined,
                        size: 18,
                        color: _filePath != null
                            ? AppColors.green
                            : AppColors.ink3,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _filePath != null
                              ? _filePath!.split('/').last
                              : 'Chọn file ảnh chứng chỉ',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: _filePath != null
                                ? AppColors.ink
                                : AppColors.ink4,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TutorSaveButton(
                saving: _saving,
                onSave: _submit,
                label: 'Tải lên',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
