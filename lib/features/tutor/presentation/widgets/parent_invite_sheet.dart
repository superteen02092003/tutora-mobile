import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/features/tutor/data/datasources/recorder_datasource.dart';
import 'package:tutora/features/tutor/data/models/recorder_models.dart';
import 'package:tutora/features/tutor/presentation/providers/recorder_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Tạo link mời rồi mở sheet để gia sư gửi cho phụ huynh qua Zalo cá nhân.
///
/// Phụ huynh mở link trong Zalo Mini App Tutora → quan tâm OA → đồng ý. Sau đó
/// báo cáo được gửi qua Zalo OA (UID), không cần gia sư làm gì thêm.
Future<void> inviteParentToZalo(
  BuildContext context,
  WidgetRef ref,
  RecorderStudentDto student,
) async {
  final messenger = ScaffoldMessenger.of(context);
  RecorderParentInviteDto invite;
  try {
    invite = await ref.read(recorderDatasourceProvider).createParentInvite(student.studentId);
    ref.invalidate(recorderStudentsProvider);
  } on DioException catch (e) {
    final msg = e.response?.data is Map ? (e.response!.data as Map)['message'] as String? : null;
    messenger.showSnackBar(SnackBar(content: Text(msg ?? 'Chưa tạo được link mời. Kiểm tra mạng rồi thử lại.')));
    return;
  } on Object {
    messenger.showSnackBar(const SnackBar(content: Text('Chưa tạo được link mời. Thử lại sau.')));
    return;
  }
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: TutorColors.bg,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _InviteSheet(student: student, invite: invite),
  );
}

class _InviteSheet extends StatelessWidget {
  const _InviteSheet({required this.student, required this.invite});

  final RecorderStudentDto student;
  final RecorderParentInviteDto invite;

  String? get _phone {
    final p = student.parentPhone?.replaceAll(RegExp(r'\D'), '');
    return (p == null || p.isEmpty) ? null : p;
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: invite.shareText));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã sao chép tin nhắn mời.')));
    }
  }

  /// Sao chép tin nhắn rồi mở khung chat Zalo với SĐT phụ huynh (zalo.me/{sđt}) —
  /// gia sư chỉ cần dán và gửi.
  Future<void> _openZalo(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: invite.shareText));
    final phone = _phone;
    final uri = Uri.parse(phone != null ? 'https://zalo.me/$phone' : 'https://zalo.me');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Đã sao chép tin nhắn — dán vào khung chat Zalo rồi gửi.'
          : 'Không mở được Zalo. Tin nhắn đã được sao chép.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final exp = invite.expiresAt;
    final expText = exp == null
        ? ''
        : ' Link có hạn đến ${exp.day.toString().padLeft(2, '0')}/${exp.month.toString().padLeft(2, '0')}.';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: TutorColors.line, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Mời phụ huynh nhận báo cáo qua Zalo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: TutorColors.ink)),
            const SizedBox(height: 6),
            Text(
              'Gửi tin nhắn này cho phụ huynh của ${student.fullName}. Phụ huynh bấm link, '
              'quan tâm Tutora và đồng ý là xong.$expText',
              style: const TextStyle(fontSize: 13, height: 1.4, color: TutorColors.ink3),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: TutorColors.surface,
                border: Border.all(color: TutorColors.line),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                invite.shareText,
                style: const TextStyle(fontSize: 13.5, height: 1.45, color: TutorColors.ink),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: () => _openZalo(context),
                style: FilledButton.styleFrom(
                  backgroundColor: TutorColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  _phone != null ? 'Sao chép & mở Zalo phụ huynh' : 'Sao chép & mở Zalo',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () => _copy(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: TutorColors.ink,
                  side: const BorderSide(color: TutorColors.line),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.copy_rounded, size: 17),
                label: const Text('Chỉ sao chép tin nhắn'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
