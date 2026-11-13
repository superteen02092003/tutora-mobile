import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tutora/core/constants/legal_links.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tutora/features/tutor/data/models/recorder_insights_models.dart';
import 'package:tutora/features/tutor/presentation/providers/recorder_insights_provider.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_profile_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_profile/tutor_change_password_screen.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_profile/tutor_delete_account_sheet.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_profile/tutor_edit_personal_info_screen.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

/// T8 Cài đặt (design V5.6, board V56-Settings): nút tròn quay lại, ảnh đại
/// diện tròn + "Cài đặt", các nhóm hàng trong thẻ bo 20, công tắc màu rêu.
/// Giữ đủ mục Google Play yêu cầu: điều khoản, quyền riêng tư, xoá dữ liệu,
/// xoá tài khoản.
///
/// "Nhắc trước buổi học" và "Thông báo khi báo cáo sẵn sàng" lưu lên server
/// (`/recorder/settings`). Board có thêm "Kiểm tra âm thanh trước khi ghi" —
/// chưa có cài đặt tương ứng nên không vẽ. Hàng "Thu nhập" để sau.
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

  /// Giá trị đang lưu — hiện ngay trên màn, lỗi thì bỏ (về giá trị server).
  RecorderSettingsDto? _pendingSettings;

  Future<void> _saveSettings(RecorderSettingsDto next) async {
    setState(() => _pendingSettings = next);
    try {
      await ref.read(recorderSettingsProvider.notifier).save(next);
    } on Object {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Chưa lưu được cài đặt. Kiểm tra mạng rồi thử lại.',
          type: AppToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _pendingSettings = null);
    }
  }

  Future<void> _pickReminder(RecorderSettingsDto current) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: TutorColors.paperTop,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(TutorSurface.radius),
        ),
      ),
      builder: (_) =>
          _ReminderSheet(selected: current.lessonReminderMinutes ?? 0),
    );
    if (picked == null || !mounted) return;
    if (picked == (current.lessonReminderMinutes ?? 0)) return;
    await _saveSettings(
      picked == 0
          ? current.copyWith(clearReminder: true)
          : current.copyWith(lessonReminderMinutes: picked),
    );
  }

  /// Hai hàng cài đặt server: nhắc trước buổi học và đẩy thông báo báo cáo.
  List<Widget> _recorderSettingsRows() {
    final async = ref.watch(recorderSettingsProvider);
    final settings = _pendingSettings ?? async.valueOrNull;
    if (settings == null) {
      final failed = async.hasError;
      return [
        _Row(
          label: 'Nhắc trước buổi học',
          value: failed ? 'Không tải được · thử lại' : '…',
          onTap: failed ? () => ref.invalidate(recorderSettingsProvider) : null,
        ),
      ];
    }
    final busy = _pendingSettings != null;
    final minutes = settings.lessonReminderMinutes;
    return [
      _Row(
        label: 'Nhắc trước buổi học',
        value: minutes == null ? 'Tắt' : '$minutes phút',
        onTap: busy ? null : () => unawaited(_pickReminder(settings)),
      ),
      _Row(
        label: 'Thông báo khi báo cáo sẵn sàng',
        trailing: _MossSwitch(
          value: settings.reportReadyPush,
          onChanged: busy
              ? null
              : (v) => unawaited(
                  _saveSettings(settings.copyWith(reportReadyPush: v)),
                ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tutorProfileProvider);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    if (state.isLoading && state.user == null) {
      return const Scaffold(
        backgroundColor: TutorColors.bg,
        body: DecoratedBox(
          decoration: TutorSurface.paper,
          child: Center(
            child: CircularProgressIndicator(color: TutorColors.primary),
          ),
        ),
      );
    }

    if (state.user == null) {
      return Scaffold(
        backgroundColor: TutorColors.bg,
        body: DecoratedBox(
          decoration: TutorSurface.paper,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TutorSurface.gutter,
                    20,
                    TutorSurface.gutter,
                    0,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: CanvasBackButton(
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: TutorSurface.screenPadding,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Không tải được cài đặt',
                            style: TutorType.body(),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: 160,
                            child: CanvasCta(
                              label: 'Thử lại',
                              secondary: true,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              onPressed: () => ref
                                  .read(tutorProfileProvider.notifier)
                                  .load(),
                            ),
                          ),
                        ],
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

    final user = state.user!;

    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: DecoratedBox(
        decoration: TutorSurface.paper,
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.only(bottom: bottomPad + 40),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TutorSurface.gutter,
                  20,
                  TutorSurface.gutter,
                  0,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: CanvasBackButton(
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const _ProfileRow(),
              _Group(
                label: 'Thông báo',
                // Hai dòng thật (lưu ở backend) thay công tắc cũ chỉ đổi biến cục bộ.
                children: [..._recorderSettingsRows()],
              ),
              _Group(
                label: 'Ghi âm',
                children: [
                  _Row(
                    label: 'Mẹo ghi âm',
                    leading: Icons.lightbulb_outline_rounded,
                    onTap: () =>
                        unawaited(context.push(AppRoutes.tutorRecordingTips)),
                  ),
                ],
              ),
              _Group(
                label: 'Quyền riêng tư',
                children: [
                  const _Row(
                    label: 'Phụ huynh đồng ý',
                    value: 'Theo từng học sinh',
                  ),
                  _Row(
                    label: 'Bản ghi được dùng thế nào',
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
              const SizedBox(height: 18),
              const Padding(
                padding: EdgeInsets.only(right: 30),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: CanvasHand(
                    'Mọi thứ trong tầm tay',
                    size: 17,
                    swash: false,
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

/// Tên gọi (từ cuối của họ tên tiếng Việt): "Nguyễn Thu Hà" → "Hà".
String _givenName(String? full) {
  final parts = (full ?? '').trim().split(RegExp(r'\s+'));
  return parts.isEmpty ? '' : parts.last;
}

/// Nhóm cài đặt: nhãn nhỏ thường + thẻ bo 20, các hàng cách nhau đường kẻ mảnh.
class _Group extends StatelessWidget {
  const _Group({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      TutorSurface.gutter,
      18,
      TutorSurface.gutter,
      0,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: TutorType.caption(color: TutorColors.ink3)),
        const SizedBox(height: 6),
        DecoratedBox(
          decoration: TutorSurface.card(),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(TutorSurface.radius),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: TutorColors.line,
                      ),
                    ),
                  children[i],
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// Hàng cài đặt: chữ 15, giá trị xám bên phải hoặc mũi tên.
class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    this.value,
    this.trailing,
    this.leading,
    this.onTap,
    this.danger = false,
  });

  final String label;
  final String? value;
  final Widget? trailing;
  final IconData? leading;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final body = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 50),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (leading != null) ...[
              Icon(leading, size: 18, color: TutorColors.ink),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                label,
                style: TutorType.body(
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
                  style: TutorType.rowSub(),
                ),
              ),
            ],
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            if (trailing == null && onTap != null && !danger) ...[
              const SizedBox(width: 6),
              const CanvasChevron(),
            ],
          ],
        ),
      ),
    );
    if (onTap == null) return body;
    return InkWell(onTap: onTap, child: body);
  }
}

/// Công tắc màu rêu của màn Cài đặt.
class _MossSwitch extends StatelessWidget {
  const _MossSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => Switch(
    value: value,
    onChanged: onChanged,
    activeThumbColor: Colors.white,
    activeTrackColor: TutorColors.primary,
    inactiveThumbColor: Colors.white,
    inactiveTrackColor: const Color(0x2E1F2A24),
    trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}

/// Bảng chọn "Nhắc trước buổi học": Tắt (0) hoặc số phút.
class _ReminderSheet extends StatelessWidget {
  const _ReminderSheet({required this.selected});

  /// 0 = tắt.
  final int selected;

  static const _choices = [0, 10, 15, 30, 60, 120];

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        TutorSurface.gutter,
        18,
        TutorSurface.gutter,
        12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Nhắc trước buổi học', style: TutorType.sectionTitle()),
          const SizedBox(height: 4),
          Text(
            'Gửi thông báo để bạn nhớ bấm ghi âm.',
            style: TutorType.rowSub(),
          ),
          const SizedBox(height: 8),
          for (final m in _choices)
            InkWell(
              onTap: () => Navigator.of(context).pop(m),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                decoration: BoxDecoration(
                  border: Border(
                    top: m == _choices.first
                        ? BorderSide.none
                        : TutorSurface.rule,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        m == 0 ? 'Tắt' : '$m phút',
                        style: TutorType.body(),
                      ),
                    ),
                    if (m == selected)
                      const Icon(
                        Icons.check_rounded,
                        size: 20,
                        color: TutorColors.ink,
                        semanticLabel: 'Đang chọn',
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

/// Ảnh đại diện tròn + "Cài đặt" + "Gia sư …"; chạm ảnh để đổi (chỉ thư viện
/// ảnh, không cần quyền CAMERA).
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
    final given = _givenName(user?.fullName);
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
                    const Positioned.fill(
                      child: ClipOval(
                        child: ColoredBox(
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
                Text('Cài đặt', style: TutorType.display(size: 24)),
                const SizedBox(height: 2),
                Text(
                  [
                    if (given.isNotEmpty) 'Gia sư $given',
                    if (subjects.isNotEmpty) subjects,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TutorType.rowSub(),
                ),
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

  static const double _size = 52;
  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final fallback = _Initials(name: name);
    if (avatarUrl == null || avatarUrl!.isEmpty) return fallback;
    return ClipOval(
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
      decoration: const BoxDecoration(
        color: TutorColors.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TutorType.body(color: Colors.white).copyWith(fontSize: 18),
      ),
    );
  }
}
