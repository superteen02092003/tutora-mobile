import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tutora/features/tutor/data/datasources/tutor_profile_datasource.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

/// Bảng xác nhận xoá tài khoản (Google Play yêu cầu xoá được ngay trong app).
/// Design V5.6: nền giấy, góc trên bo 20, ô nhập lõm, nút viên thuốc.
Future<void> showDeleteAccountSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: TutorColors.paperTop,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(TutorSurface.radius),
      ),
    ),
    builder: (_) => const _DeleteAccountSheet(),
  );
}

class _DeleteAccountSheet extends ConsumerStatefulWidget {
  const _DeleteAccountSheet();

  @override
  ConsumerState<_DeleteAccountSheet> createState() =>
      _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends ConsumerState<_DeleteAccountSheet> {
  final TextEditingController _password = TextEditingController();
  bool _confirmed = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final password = _password.text;
    if (password.isEmpty) {
      setState(() => _error = 'Vui lòng nhập mật khẩu.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = ref.read(authControllerProvider.notifier);
    final error = await ref
        .read(tutorProfileDatasourceProvider)
        .deleteAccount(password: password);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }
    AppToast.show(
      context,
      message: 'Đã xoá tài khoản.',
      type: AppToastType.success,
    );
    Navigator.of(context).pop();
    await auth.logout();
  }

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(TutorSurface.radiusSmall),
      borderSide: BorderSide(color: c, width: w),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        TutorSurface.gutter,
        12,
        TutorSurface.gutter,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tay cầm của bảng.
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0x241F2A24),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('Xoá tài khoản', style: TutorType.display(size: 24)),
          const SizedBox(height: 10),
          Text(
            'Tài khoản sẽ bị khoá ngay và không thể khôi phục. Sau 30 ngày, '
            'TopTutor xoá vĩnh viễn thông tin cá nhân, danh sách học sinh, báo '
            'cáo và bản ghi âm của bạn. Báo cáo chưa gửi sẽ bị huỷ.',
            style: TutorType.rowSub().copyWith(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Text(
            'Mật khẩu hiện tại',
            style: TutorType.caption(color: TutorColors.ink3),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _password,
            obscureText: true,
            enabled: !_busy,
            style: TutorType.body(),
            cursorColor: TutorColors.ink,
            decoration: InputDecoration(
              errorText: _error,
              errorStyle: TutorType.caption(color: TutorColors.danger),
              errorMaxLines: 3,
              filled: true,
              fillColor: TutorColors.surfaceSunken,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              border: border(Colors.transparent),
              enabledBorder: border(Colors.transparent),
              disabledBorder: border(Colors.transparent),
              focusedBorder: border(TutorColors.ink, 1.2),
              errorBorder: border(TutorColors.danger),
              focusedErrorBorder: border(TutorColors.danger, 1.2),
            ),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _confirmed,
            onChanged: _busy
                ? null
                : (v) => setState(() => _confirmed = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: TutorColors.danger,
            side: const BorderSide(color: Color(0xFFA3A8A2), width: 1.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TutorSurface.radiusSmall),
            ),
            title: Text(
              'Tôi hiểu tài khoản và dữ liệu sẽ bị xoá vĩnh viễn.',
              style: TutorType.rowSub(color: TutorColors.ink),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _confirmed && !_busy ? _delete : null,
              style: FilledButton.styleFrom(
                backgroundColor: TutorColors.danger,
                foregroundColor: Colors.white,
                disabledBackgroundColor: TutorColors.surfaceSunken,
                disabledForegroundColor: TutorColors.ink4,
                shape: const StadiumBorder(),
                textStyle: TutorType.action().copyWith(fontSize: 15),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Xoá tài khoản'),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: TutorColors.ink3,
                shape: const StadiumBorder(),
                textStyle: TutorType.action(),
              ),
              child: const Text('Huỷ'),
            ),
          ),
        ],
      ),
    );
  }
}
