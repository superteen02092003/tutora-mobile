import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
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
      icon: const Icon(Icons.flag_outlined, size: 16),
      label: const Text('Báo nội dung AI sai'),
      style: TextButton.styleFrom(
        foregroundColor: TutorColors.ink3,
        textStyle: TutorType.rowSub(),
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 44),
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
    backgroundColor: TutorColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(TutorSurface.radius),
      ),
    ),
    builder: (_) => _AiFeedbackSheet(recordingId: recordingId),
  );
  if ((sent ?? false) && context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Cảm ơn bạn đã báo. TopTutor sẽ xem lại nội dung này.'),
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
      TutorSurface.gutter,
      0,
      TutorSurface.gutter,
      20 + MediaQuery.of(context).viewInsets.bottom,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Báo nội dung AI sai', style: TutorType.sectionTitle()),
        const SizedBox(height: 6),
        Text(
          'TopTutor dùng báo cáo này để sửa cách AI tóm tắt. Bạn vẫn sửa được '
          'nội dung trước khi gửi phụ huynh.',
          style: TutorType.rowSub(),
        ),
        const SizedBox(height: 12),
        RadioGroup<String>(
          groupValue: _reason,
          onChanged: (v) => setState(() => _reason = v),
          child: Column(
            children: [
              for (final (i, (value, label)) in _reasons.indexed)
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      top: i == 0 ? BorderSide.none : TutorSurface.rule,
                    ),
                  ),
                  child: RadioListTile<String>(
                    value: value,
                    activeColor: TutorColors.ink,
                    title: Text(label, style: TutorType.rowTitle()),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _note,
          maxLength: 1000,
          minLines: 2,
          maxLines: 4,
          cursorColor: TutorColors.ink,
          style: TutorType.body(),
          decoration: InputDecoration(
            labelText: 'Mô tả thêm (không bắt buộc)',
            labelStyle: TutorType.rowSub(),
            floatingLabelStyle: TutorType.caption(color: TutorColors.ink3),
            counterStyle: TutorType.caption(),
            filled: true,
            fillColor: TutorColors.surfaceSunken,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TutorSurface.radiusSmall),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TutorSurface.radiusSmall),
              borderSide: const BorderSide(color: TutorColors.ink),
            ),
          ),
        ),
        if (_error != null) ...[
          Text(_error!, style: TutorType.rowSub(color: TutorColors.danger)),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 4),
        FilledButton(
          onPressed: _reason == null || _sending ? null : _send,
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 48),
            backgroundColor: TutorColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: TutorColors.surfaceSunken,
            shape: const StadiumBorder(),
            textStyle: TutorType.action().copyWith(fontSize: 15),
          ),
          child: Text(_sending ? 'Đang gửi…' : 'Gửi'),
        ),
      ],
    ),
  );
}
