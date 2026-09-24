import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tutora/features/tutor/data/datasources/tutor_profile_datasource.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

/// Bảng xác nhận xoá tài khoản (Google Play yêu cầu xoá được ngay trong app).
Future<void> showDeleteAccountSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Xoá tài khoản', style: AppTextStyles.h2()),
          const SizedBox(height: 12),
          Text(
            'Tài khoản sẽ bị khoá ngay và không thể khôi phục. Sau 30 ngày, '
            'Tutora xoá vĩnh viễn thông tin cá nhân, danh sách học sinh, báo '
            'cáo và bản ghi âm của bạn. Báo cáo chưa gửi sẽ bị huỷ.',
            style: AppTextStyles.body(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            obscureText: true,
            enabled: !_busy,
            decoration: InputDecoration(
              labelText: 'Mật khẩu hiện tại',
              errorText: _error,
              border: const OutlineInputBorder(),
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
            activeColor: AppColors.oxblood,
            title: Text(
              'Tôi hiểu tài khoản và dữ liệu sẽ bị xoá vĩnh viễn.',
              style: AppTextStyles.bodySmall(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _confirmed && !_busy ? _delete : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.paper,
              ),
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.paper,
                      ),
                    )
                  : const Text('Xoá tài khoản'),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(),
              child: const Text('Huỷ'),
            ),
          ),
        ],
      ),
    );
  }
}
