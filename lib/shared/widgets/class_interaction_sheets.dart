import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/shared/datasources/class_interaction_datasource.dart';

/// Mở sheet đánh giá gia sư. Trả về `true` nếu gửi thành công.
Future<bool?> showFeedbackSheet(BuildContext context, int classSessionId) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FeedbackSheet(classSessionId: classSessionId),
  );
}

/// Mở sheet khiếu nại buổi học. Trả về `true` nếu gửi thành công.
Future<bool?> showDisputeSheet(BuildContext context, int classSessionId) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DisputeSheet(classSessionId: classSessionId),
  );
}

class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.ibmPlexSerif(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.busy,
    required this.onTap,
  });
  final String label;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.cream,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cream,
                ),
              ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);
  final String? text;
  @override
  Widget build(BuildContext context) {
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(
        text!,
        style: GoogleFonts.inter(fontSize: 12, color: AppColors.error),
      ),
    );
  }
}

// Feedback

class _FeedbackSheet extends ConsumerStatefulWidget {
  const _FeedbackSheet({required this.classSessionId});
  final int classSessionId;

  @override
  ConsumerState<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends ConsumerState<_FeedbackSheet> {
  final _comment = TextEditingController();
  int _rating = 5;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(classInteractionDatasourceProvider)
          .submitFeedback(
            classSessionId: widget.classSessionId,
            rating: _rating,
            comment: _comment.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ClassInteractionException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Không gửi được đánh giá. Vui lòng thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Đánh giá gia sư',
      children: [
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 1; i <= 5; i++)
                GestureDetector(
                  onTap: () => setState(() => _rating = i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      i <= _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 40,
                      color: i <= _rating ? AppColors.gold : AppColors.ink4,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          child: TextField(
            controller: _comment,
            maxLines: 4,
            maxLength: 1000,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Nhận xét về buổi học (không bắt buộc)…',
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.ink4,
              ),
            ),
          ),
        ),
        _ErrorText(_error),
        const SizedBox(height: 14),
        _SubmitButton(label: 'Gửi đánh giá', busy: _busy, onTap: _submit),
      ],
    );
  }
}

// Dispute

const _disputeTypes = <(String, String)>[
  ('no_show', 'Gia sư không có mặt'),
  ('quality', 'Chất lượng buổi học'),
  ('payment', 'Vấn đề thanh toán'),
  ('other', 'Khác'),
];

class _DisputeSheet extends ConsumerStatefulWidget {
  const _DisputeSheet({required this.classSessionId});
  final int classSessionId;

  @override
  ConsumerState<_DisputeSheet> createState() => _DisputeSheetState();
}

class _DisputeSheetState extends ConsumerState<_DisputeSheet> {
  final _reason = TextEditingController();
  String _type = _disputeTypes.first.$1;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason.text.trim();
    if (reason.length < 10) {
      setState(() => _error = 'Lý do phải từ 10 ký tự trở lên.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(classInteractionDatasourceProvider)
          .submitDispute(
            classSessionId: widget.classSessionId,
            disputeType: _type,
            reason: reason,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ClassInteractionException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Không gửi được khiếu nại. Vui lòng thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Khiếu nại buổi học',
      children: [
        Text(
          'LOẠI KHIẾU NẠI',
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.08,
            color: AppColors.ink4,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (value, label) in _disputeTypes)
              GestureDetector(
                onTap: () => setState(() => _type = value),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: _type == value ? AppColors.ink : AppColors.paper,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _type == value ? AppColors.ink : AppColors.line,
                    ),
                  ),
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _type == value ? AppColors.cream : AppColors.ink,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'MÔ TẢ CHI TIẾT',
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.08,
            color: AppColors.ink4,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          child: TextField(
            controller: _reason,
            maxLines: 4,
            maxLength: 2000,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Mô tả vấn đề bạn gặp phải (tối thiểu 10 ký tự)…',
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.ink4,
              ),
            ),
          ),
        ),
        _ErrorText(_error),
        const SizedBox(height: 14),
        _SubmitButton(label: 'Gửi khiếu nại', busy: _busy, onTap: _submit),
      ],
    );
  }
}
