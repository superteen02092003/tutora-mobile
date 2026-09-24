import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/features/tutor/data/datasources/app_recording_datasource.dart';

/// Nút "Báo nội dung AI sai" — Google Play yêu cầu app có AI tạo nội dung phải
/// cho người dùng báo nội dung sai / không phù hợp. Đặt dưới nội dung AI viết.
class AiFeedbackButton extends StatelessWidget {
  const AiFeedbackButton({required this.recordingId, super.key});

  final String recordingId;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      onPressed: () => showAiFeedbackSheet(context, recordingId),
      icon: const Icon(Icons.flag_outlined, size: 18),
      label: const Text('Báo nội dung AI sai'),
      style: TextButton.styleFrom(
        foregroundColor: TutorColors.ink3,
        padding: EdgeInsets.zero,
      ),
    ),
  );
}

/// Mở sheet chọn lý do + ghi chú rồi gửi. Trả true khi đã gửi thành công.
Future<bool> showAiFeedbackSheet(
  BuildContext context,
  String recordingId,
) async {
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _AiFeedbackSheet(recordingId: recordingId),
  );
  if ((sent ?? false) && context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Cảm ơn bạn đã báo. Tutora sẽ xem lại nội dung này.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
  return sent ?? false;
}

class _AiFeedbackSheet extends ConsumerStatefulWidget {
  const _AiFeedbackSheet({required this.recordingId});

  final String recordingId;

  @override
  ConsumerState<_AiFeedbackSheet> createState() => _AiFeedbackSheetState();
}

class _AiFeedbackSheetState extends ConsumerState<_AiFeedbackSheet> {
  static const _reasons = <(String, String)>[
    ('wrong_content', 'Nội dung không đúng với buổi học'),
    ('wrong_student', 'Nhầm học sinh / thông tin của người khác'),
    ('inappropriate', 'Lời lẽ không phù hợp'),
    ('other', 'Lý do khác'),
  ];

  String? _reason;
  final _note = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final reason = _reason;
    if (reason == null) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref
          .read(appRecordingDatasourceProvider)
          .reportAiFeedback(
            widget.recordingId,
            reason: reason,
            note: _note.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on Object {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = 'Chưa gửi được. Kiểm tra mạng rồi thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      0,
      20,
      20 + MediaQuery.of(context).viewInsets.bottom,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Báo nội dung AI sai',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: TutorColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tutora dùng báo cáo này để sửa cách AI tóm tắt. Bạn vẫn sửa được '
          'nội dung trước khi gửi phụ huynh.',
          style: TextStyle(fontSize: 13, color: TutorColors.ink3, height: 1.35),
        ),
        const SizedBox(height: 12),
        RadioGroup<String>(
          groupValue: _reason,
          onChanged: (v) => setState(() => _reason = v),
          child: Column(
            children: [
              for (final (value, label) in _reasons)
                RadioListTile<String>(
                  value: value,
                  title: Text(label, style: const TextStyle(fontSize: 14)),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _note,
          maxLength: 1000,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Mô tả thêm (không bắt buộc)',
            border: OutlineInputBorder(),
          ),
        ),
        if (_error != null) ...[
          Text(_error!, style: const TextStyle(color: TutorColors.primary)),
          const SizedBox(height: 8),
        ],
        FilledButton(
          onPressed: _reason == null || _sending ? null : _send,
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 48),
            backgroundColor: TutorColors.primary,
          ),
          child: Text(_sending ? 'Đang gửi…' : 'Gửi'),
        ),
      ],
    ),
  );
}
