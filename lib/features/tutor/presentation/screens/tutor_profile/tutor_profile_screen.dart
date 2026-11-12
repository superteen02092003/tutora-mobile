import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tutora/core/constants/legal_links.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_profile_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_profile/tutor_change_password_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_profile/tutor_delete_account_sheet.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_profile/tutor_edit_personal_info_screen.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

/// T8 Cài đặt ("You") theo canvas: nhãn nhỏ, tiêu đề "Bạn", các nhóm hàng kẻ mực.
/// Giữ đủ mục Google Play yêu cầu: điều khoản, quyền riêng tư, xoá dữ liệu,
/// xoá tài khoản.
class TutorProfileScreen extends ConsumerStatefulWidget {
  const TutorProfileScreen({super.key});

  @override
  ConsumerState<TutorProfileScreen> createState() => _TutorProfileScreenState();
}

class _TutorProfileScreenState extends ConsumerState<TutorProfileScreen> {
  void _openLink(String url) => unawaited(_launchLink(url));

  Future<void> _launchLink(String url) async {
    final opened = await openExternalUrl(url);
    if (!opened && mounted) {
      AppToast.show(
        context,
        message: 'Không mở được liên kết.',
        type: AppToastType.error,
      );
    }
  }

  void _push(Widget screen) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tutorProfileProvider);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    if (state.isLoading && state.user == null) {
      return const Scaffold(
        backgroundColor: TutorColors.bg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.user == null) {
      return Scaffold(
        backgroundColor: TutorColors.bg,
        body: Center(
          child: TextButton.icon(
            onPressed: () => ref.read(tutorProfileProvider.notifier).load(),
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ),
      );
    }

    final user = state.user!;
    final given = _givenName(user.fullName);

    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.only(bottom: bottomPad + 40),
          children: [
            CanvasHeader(
              title: 'Bạn',
              onBack: () => Navigator.of(context).maybePop(),
              right: given.isEmpty ? 'Cài đặt' : 'Gia sư $given',
            ),
            const SizedBox(height: 20),
            const _ProfileRow(),
            _Group(
              label: 'Thông báo',
              children: [
                _Row(
                  label: 'Báo cáo sẵn sàng để duyệt, nhắc buổi học',
                  trailing: Switch(
                    value: state.notifOn,
                    onChanged: (v) {
                      ref
                          .read(tutorProfileProvider.notifier)
                          .setNotif(value: v);
                      AppToast.show(
                        context,
                        message: v ? 'Đã bật thông báo' : 'Đã tắt thông báo',
                        type: AppToastType.success,
                      );
                    },
                    activeThumbColor: TutorColors.bg,
                    activeTrackColor: TutorColors.ink,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            _Group(
              label: 'Ghi âm',
              children: [
                _Row(
                  label: 'Mẹo ghi âm',
                  onTap: () =>
                      unawaited(context.push(AppRoutes.tutorRecordingTips)),
                ),
              ],
            ),
            _Group(
              label: 'Quyền riêng tư',
              children: [
                const _Row(
                  label: 'Đồng ý của phụ huynh',
                  value: 'Theo từng học sinh',
                ),
                _Row(
                  label: 'Bản ghi âm được dùng thế nào',
                  value: 'Đọc',
                  onTap: () => _openLink(LegalLinks.privacy),
                ),
                _Row(
                  label: 'Điều khoản sử dụng',
                  onTap: () => _openLink(LegalLinks.terms),
                ),
                _Row(
                  label: 'Yêu cầu xoá dữ liệu',
                  onTap: () => _openLink(LegalLinks.dataDeletion),
                ),
              ],
            ),
            _Group(
              label: 'Tài khoản',
              children: [
                _Row(
                  label: 'Thông tin cá nhân',
                  value: user.email,
                  onTap: () => _push(const TutorEditPersonalInfoScreen()),
                ),
                _Row(
                  label: 'Đổi mật khẩu',
                  onTap: () => _push(const TutorChangePasswordScreen()),
                ),
                _Row(
                  label: 'Đăng xuất',
                  danger: true,
                  onTap: () =>
                      ref.read(authControllerProvider.notifier).logout(),
                ),
                _Row(
                  label: 'Xoá tài khoản',
                  danger: true,
                  last: true,
                  onTap: () => unawaited(showDeleteAccountSheet(context)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: TutorSurface.screenPadding,
              child: CanvasGhostLink(
                label: 'Xem lại màn chào mừng ›',
                onTap: () => unawaited(context.push(AppRoutes.tutorWelcome)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tên gọi (từ cuối của họ tên tiếng Việt): "Nguyễn Thu Hà" → "Hà".
String _givenName(String? full) {
  final parts = (full ?? '').trim().split(RegExp(r'\s+'));
  return parts.isEmpty ? '' : parts.last;
}

class _Group extends StatelessWidget {
  const _Group({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      TutorSurface.gutter,
      TutorSurface.sectionGap,
      TutorSurface.gutter,
      0,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CanvasKicker(label),
        const SizedBox(height: 8),
        ...children,
      ],
    ),
  );
}

/// Hàng cài đặt: chữ 16 đậm vừa, giá trị xám bên phải hoặc mũi tên.
class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
    this.danger = false,
    this.last = false,
  });

  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;
  final bool last;

  @override
  Widget build(BuildContext context) => CanvasRow(
    onTap: onTap,
    lastRule: last,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 28),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: danger ? TutorColors.danger : TutorColors.ink,
              ),
            ),
          ),
          if (value != null && value!.trim().isNotEmpty) ...[
            const SizedBox(width: 12),
            // Không dùng Flexible: nó chia đôi hàng với nhãn và đẩy mũi tên
            // vào giữa. Giá trị có bề rộng tối đa, nhãn lấy phần còn lại.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(
                value!,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TutorType.rowSub().copyWith(fontSize: 14),
              ),
            ),
          ],
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          if (trailing == null && onTap != null && !danger) ...[
            const SizedBox(width: 8),
            const CanvasChevron(),
          ],
        ],
      ),
    ),
  );
}

/// Ảnh đại diện + tên + môn; chạm ảnh để đổi (chỉ thư viện ảnh, không cần
/// quyền CAMERA).
class _ProfileRow extends ConsumerWidget {
  const _ProfileRow();

  Future<void> _pickAndUpload(BuildContext context, WidgetRef ref) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (file == null || !context.mounted) return;
    final ok = await ref
        .read(tutorProfileProvider.notifier)
        .uploadAvatar(file.path);
    if (!context.mounted) return;
    AppToast.show(
      context,
      message: ok
          ? 'Cập nhật ảnh đại diện thành công'
          : 'Cập nhật thất bại, thử lại sau',
      type: ok ? AppToastType.success : AppToastType.error,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tutorProfileProvider);
    final user = state.user;
    final uploading = state.isUploadingAvatar;
    final subjects =
        state.progress?.basicInfo.subjects
            .map((s) => s.subjectName)
            .join(' · ') ??
        '';

    return Padding(
      padding: TutorSurface.screenPadding,
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Đổi ảnh đại diện',
            child: GestureDetector(
              onTap: uploading
                  ? null
                  : () => unawaited(_pickAndUpload(context, ref)),
              child: Stack(
                children: [
                  _Avatar(
                    name: user?.fullName ?? '',
                    avatarUrl: user?.avatarUrl,
                  ),
                  if (uploading)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          TutorSurface.radius,
                        ),
                        child: const ColoredBox(
                          color: Color(0x73000000),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? '',
                  style: TutorType.display(size: 22),
                ),
                if (subjects.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subjects,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TutorType.rowSub(),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  uploading ? 'Đang tải ảnh…' : 'Chạm ảnh để đổi',
                  style: TutorType.caption(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.avatarUrl});

  static const double _size = 56;
  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final fallback = _Initials(name: name);
    if (avatarUrl == null || avatarUrl!.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(TutorSurface.radius),
      child: Image.network(
        avatarUrl!,
        width: _size,
        height: _size,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : fallback,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    // Chữ đầu của tên gọi, như avatar ở Trang chủ ("Lê Quốc Khánh" → "K").
    final given = _givenName(name);
    final initials = given.isEmpty ? '' : given[0].toUpperCase();
    return Container(
      width: _Avatar._size,
      height: _Avatar._size,
      decoration: TutorSurface.card(color: TutorColors.accentBg),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: TutorColors.ink,
        ),
      ),
    );
  }
}
