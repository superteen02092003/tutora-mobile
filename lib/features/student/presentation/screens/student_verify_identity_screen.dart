import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tutora/core/constants/app_assets.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/features/student/data/datasources/profile_datasource.dart';
import 'package:tutora/features/student/data/models/student_access_models.dart';
import 'package:tutora/features/student/presentation/providers/student_access_provider.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

class StudentVerifyIdentityPage extends ConsumerStatefulWidget {
  const StudentVerifyIdentityPage({super.key});

  @override
  ConsumerState<StudentVerifyIdentityPage> createState() =>
      _StudentVerifyIdentityPageState();
}

class _StudentVerifyIdentityPageState
    extends ConsumerState<StudentVerifyIdentityPage> {
  final _picker = ImagePicker();
  String? _frontPath;
  String? _backPath;
  bool _submitting = false;
  String? _error;
  CccdVerifyResult? _result;

  bool get _ready => _frontPath != null && _backPath != null;

  Future<void> _pick({required bool front}) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SourceSheet(),
    );
    if (source == null) return;

    final file = await _picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 2000,
    );
    if (file == null) return;
    setState(() {
      if (front) {
        _frontPath = file.path;
      } else {
        _backPath = file.path;
      }
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (!_ready) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final res = await ref
          .read(profileDatasourceProvider)
          .verifyCccd(frontPath: _frontPath!, backPath: _backPath!);
      if (!mounted) return;
      setState(() => _result = res);
      ref.invalidate(bookingEligibilityProvider);
      AppToast.show(context, message: res.message, type: AppToastType.success);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eligibility = ref.watch(bookingEligibilityProvider);
    final verified = eligibility.maybeWhen(
      data: (e) => !e.needAgeVerification,
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.ink),
        title: Text(
          'Xác minh thông tin',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          if (verified)
            const _StatusBanner(
              icon: Icons.verified_rounded,
              color: AppColors.green,
              title: 'Đã xác minh độ tuổi',
              message: 'Bạn có thể đặt lịch học bình thường.',
            )
          else
            const _StatusBanner(
              icon: Icons.info_outline_rounded,
              color: Color(0xFFB0821B),
              title: 'Chưa xác minh độ tuổi',
              message:
                  'Tutora cần xác minh bạn đủ 16 tuổi trước khi tự đặt lịch học. '
                  'Chụp 2 mặt CCCD để xác minh.',
            ),

          if (verified) ...[
            const SizedBox(height: 12),
            Center(
              child: Image.asset(
                AppAssets.verifiedIdentity,
                width: MediaQuery.of(context).size.width * 0.78,
                fit: BoxFit.contain,
              ),
            ),
            if (_result?.fullName != null ||
                _result?.dateOfBirth != null ||
                _result?.maskedIdentity != null) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  children: [
                    if (_result?.fullName != null)
                      _InfoRow('Họ tên', _result!.fullName!),
                    if (_result?.dateOfBirth != null)
                      _InfoRow('Ngày sinh', _result!.dateOfBirth!),
                    if (_result?.maskedIdentity != null)
                      _InfoRow('Số CCCD', _result!.maskedIdentity!),
                  ],
                ),
              ),
            ],
          ] else ...[
            const SizedBox(height: 24),
            Text(
              'Ảnh CCCD',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Chụp rõ nét, đủ 4 góc, không loá sáng.',
              style: GoogleFonts.inter(fontSize: 15, color: AppColors.ink3),
            ),
            const SizedBox(height: 14),
            _PhotoTile(
              label: 'Mặt trước',
              path: _frontPath,
              onTap: () => _pick(front: true),
            ),
            const SizedBox(height: 12),
            _PhotoTile(
              label: 'Mặt sau',
              path: _backPath,
              onTap: () => _pick(front: false),
            ),
          ],

          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFDECEC),
                border: Border.all(color: const Color(0xFFF3C9C9)),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 20,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _error!,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        height: 1.5,
                        color: AppColors.ink2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (!verified && _result != null && _result!.ocrSuccess) ...[
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
                  _InfoRow('Họ tên', _result!.fullName ?? '—'),
                  _InfoRow('Ngày sinh', _result!.dateOfBirth ?? '—'),
                  _InfoRow('Số CCCD', _result!.maskedIdentity ?? '—'),
                ],
              ),
            ),
          ],

          if (!verified) ...[
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _ready && !_submitting ? _submit : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 17),
                decoration: BoxDecoration(
                  color: _ready ? AppColors.ink : AppColors.line,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  _submitting ? 'Đang xác minh...' : 'Gửi xác minh',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _ready ? AppColors.cream : AppColors.ink4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ảnh CCCD chỉ dùng để xác minh độ tuổi và được lưu trữ mã hoá.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                height: 1.5,
                color: AppColors.ink4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.07),
      border: Border.all(color: color.withValues(alpha: 0.3)),
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(width: 12),
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
              const SizedBox(height: 4),
              Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.ink2,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.label,
    required this.path,
    required this.onTap,
  });

  final String label;
  final String? path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final has = path != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 172,
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(
            color: has ? AppColors.ink : AppColors.line,
            width: has ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        clipBehavior: Clip.antiAlias,
        child: has
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(path!), fit: BoxFit.cover),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        'Chụp lại',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.cream,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_a_photo_outlined,
                    size: 30,
                    color: AppColors.ink3,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Nhấn để chụp hoặc chọn ảnh',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.ink4,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
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
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SourceSheet extends StatelessWidget {
  const _SourceSheet();

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.line,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 20),
          _SourceRow(
            icon: Icons.photo_camera_rounded,
            label: 'Chụp ảnh',
            onTap: () => Navigator.of(context).pop(ImageSource.camera),
          ),
          const SizedBox(height: 8),
          _SourceRow(
            icon: Icons.photo_library_rounded,
            label: 'Chọn từ thư viện',
            onTap: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.ink),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    ),
  );
}
