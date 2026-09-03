import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/core/utils/format_utils.dart';
import 'package:tutora/features/tutor/data/datasources/tutor_dispute_datasource.dart';
import 'package:tutora/features/tutor/data/models/tutor_dispute_models.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_dispute_provider.dart';
import 'package:tutora/features/tutor/presentation/widgets/tutor_ui.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

/// Chi tiết khiếu nại: nội dung, phản hồi gia sư, trao đổi với admin.
class TutorDisputeDetailScreen extends ConsumerStatefulWidget {
  const TutorDisputeDetailScreen({required this.classSessionId, super.key});

  final int classSessionId;

  @override
  ConsumerState<TutorDisputeDetailScreen> createState() =>
      _TutorDisputeDetailScreenState();
}

class _TutorDisputeDetailScreenState
    extends ConsumerState<TutorDisputeDetailScreen> {
  bool _submitting = false;
  bool _uploading = false;

  /// Nộp ảnh bằng chứng — để riêng vì ảnh nặng ký hơn lời giải trình.
  Future<void> _uploadEvidence() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      await ref
          .read(tutorDisputeDatasourceProvider)
          .uploadEvidence(
            classSessionId: widget.classSessionId,
            filePath: picked.path,
          );
      if (!mounted) return;
      ref.invalidate(tutorDisputeDetailProvider(widget.classSessionId));
      AppToast.show(
        context,
        message: 'Đã nộp bằng chứng.',
        type: AppToastType.success,
      );
    } on TutorDisputeException catch (e) {
      if (mounted) {
        AppToast.show(context, message: e.message, type: AppToastType.error);
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _openResponseSheet(TutorDisputeDetailDto dispute) async {
    final text = await showModalBottomSheet<String>(
      context: context,
      // Phủ lên cả bottom bar của shell, không mở trong nested navigator.
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ResponseSheet(initial: dispute.tutorResponse ?? ''),
    );
    if (text == null || text.trim().isEmpty || !mounted) return;

    setState(() => _submitting = true);
    try {
      await ref
          .read(tutorDisputeDatasourceProvider)
          .submitResponse(
            classSessionId: widget.classSessionId,
            response: text.trim(),
          );
      if (!mounted) return;
      ref
        ..invalidate(tutorDisputeDetailProvider(widget.classSessionId))
        ..invalidate(tutorDisputesProvider);
      AppToast.show(
        context,
        message: 'Đã gửi phản hồi tới quản trị viên.',
        type: AppToastType.success,
      );
    } on TutorDisputeException catch (e) {
      if (mounted) {
        AppToast.show(context, message: e.message, type: AppToastType.error);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(tutorDisputeDetailProvider(widget.classSessionId));

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const TutorChildHeader(title: 'Chi tiết khiếu nại'),
            Expanded(
              child: async.when(
                loading: () => const _DetailSkeleton(),
                error: (e, _) => TutorEmptyState(
                  icon: Icons.cloud_off_rounded,
                  message: 'Không tải được khiếu nại.\n$e',
                  actionLabel: 'Thử lại',
                  onAction: () => ref.invalidate(
                    tutorDisputeDetailProvider(widget.classSessionId),
                  ),
                ),
                data: (dispute) => dispute == null
                    ? const TutorEmptyState(
                        icon: Icons.inbox_outlined,
                        message: 'Buổi học này không có khiếu nại.',
                      )
                    : _DetailBody(
                        dispute: dispute,
                        classSessionId: widget.classSessionId,
                        submitting: _submitting,
                        uploading: _uploading,
                        onRespond: () => _openResponseSheet(dispute),
                        onUploadEvidence: _uploadEvidence,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({
    required this.dispute,
    required this.classSessionId,
    required this.submitting,
    required this.uploading,
    required this.onRespond,
    required this.onUploadEvidence,
  });

  final TutorDisputeDetailDto dispute;
  final int classSessionId;
  final bool submitting;
  final bool uploading;
  final VoidCallback onRespond;
  final VoidCallback onUploadEvidence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thread = ref.watch(disputeThreadProvider(classSessionId));

    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        Padding(
          padding: TutorSurface.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryCard(dispute: dispute),
              const SizedBox(height: TutorSurface.sectionGap),
            ],
          ),
        ),

        // Phản hồi của gia sư — khối quan trọng nhất, đặt ngay dưới tóm tắt.
        TutorSectionHeader(
          title: dispute.hasResponded
              ? 'Phản hồi của bạn'
              : 'Bạn chưa phản hồi',
        ),
        Padding(
          padding: TutorSurface.screenPadding,
          child: _ResponseCard(
            dispute: dispute,
            submitting: submitting,
            uploading: uploading,
            onRespond: onRespond,
            onUploadEvidence: onUploadEvidence,
          ),
        ),

        if (dispute.myEvidence.isNotEmpty) ...[
          const SizedBox(height: TutorSurface.sectionGap),
          TutorSectionHeader(
            title: 'Bằng chứng bạn đã nộp · ${dispute.myEvidence.length}',
          ),
          _EvidenceStrip(
            urls: dispute.myEvidence.map((e) => e.fileUrl).toList(),
          ),
        ],

        if (dispute.evidence.isNotEmpty) ...[
          const SizedBox(height: TutorSurface.sectionGap),
          TutorSectionHeader(
            title: 'Bằng chứng người học nộp · ${dispute.evidence.length}',
          ),
          _EvidenceStrip(urls: dispute.evidence),
        ],

        const SizedBox(height: TutorSurface.sectionGap),
        const TutorSectionHeader(title: 'Trao đổi với quản trị viên'),
        Padding(
          padding: TutorSurface.screenPadding,
          child: thread.when(
            loading: () => const TutorSkeleton(
              height: 90,
              radius: TutorSurface.radius,
            ),
            error: (_, _) => const TutorCard(
              padding: EdgeInsets.zero,
              child: TutorEmptyState(
                icon: Icons.forum_outlined,
                message: 'Chưa tải được trao đổi.',
              ),
            ),
            data: (messages) => messages.isEmpty
                ? const TutorCard(
                    padding: EdgeInsets.zero,
                    child: TutorEmptyState(
                      icon: Icons.forum_outlined,
                      message:
                          'Chưa có trao đổi nào.\nQuản trị viên sẽ liên hệ nếu cần thêm thông tin.',
                    ),
                  )
                : Column(
                    children: [
                      for (final m in messages) ...[
                        _ThreadBubble(message: m),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.dispute});

  final TutorDisputeDetailDto dispute;

  @override
  Widget build(BuildContext context) {
    return TutorCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (dispute.status.isOpen)
                TutorStatusChip.attention(dispute.status.label)
              else
                TutorStatusChip.done(dispute.status.label),
              const SizedBox(width: 6),
              TutorStatusChip.neutral(dispute.type.label),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            dispute.reason.isEmpty ? 'Không có mô tả' : dispute.reason,
            style: TutorType.rowSub(color: AppColors.ink).copyWith(height: 1.5),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: AppColors.line),
          const SizedBox(height: 12),
          _MetaRow(label: 'Người gửi', value: dispute.createdByName),
          if (dispute.sessionStart != null)
            _MetaRow(
              label: 'Buổi học',
              value: _fmtDateTime(dispute.sessionStart!),
            ),
          if (dispute.sessionPrice != null)
            _MetaRow(
              label: 'Giá buổi',
              value: fmtVnd(dispute.sessionPrice!.round()),
            ),
          if (dispute.refundAmount != null)
            _MetaRow(
              label: 'Số tiền hoàn',
              value: fmtVnd(dispute.refundAmount!.round()),
            ),
          if (dispute.resolutionNote != null &&
              dispute.resolutionNote!.isNotEmpty)
            _MetaRow(label: 'Kết luận', value: dispute.resolutionNote!),
        ],
      ),
    );
  }

  static String _fmtDateTime(DateTime t) =>
      '${t.day}/${t.month}/${t.year} · '
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: TutorType.caption()),
          ),
          Expanded(
            child: Text(
              value,
              style: TutorType.rowSub(color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponseCard extends StatelessWidget {
  const _ResponseCard({
    required this.dispute,
    required this.submitting,
    required this.uploading,
    required this.onRespond,
    required this.onUploadEvidence,
  });

  final TutorDisputeDetailDto dispute;
  final bool submitting;
  final bool uploading;
  final VoidCallback onRespond;
  final VoidCallback onUploadEvidence;

  @override
  Widget build(BuildContext context) {
    final deadline = dispute.responseDeadline;
    final overdue = deadline != null && DateTime.now().isAfter(deadline);

    return TutorCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (dispute.hasResponded) ...[
            Text(
              dispute.tutorResponse!,
              style: TutorType.rowSub(
                color: AppColors.ink,
              ).copyWith(height: 1.5),
            ),
            if (dispute.tutorRespondedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Đã gửi ${_fmtDate(dispute.tutorRespondedAt!)}',
                style: TutorType.caption(),
              ),
            ],
          ] else
            Text(
              deadline == null
                  ? 'Gửi giải trình để quản trị viên có đủ hai phía trước khi kết luận.'
                  : overdue
                  ? 'Đã quá hạn phản hồi. Bạn vẫn có thể gửi nếu vụ việc chưa khép lại.'
                  : 'Hạn phản hồi: ${_fmtDate(deadline)}. Gửi giải trình để quản trị viên có đủ hai phía trước khi kết luận.',
              style: TutorType.rowSub().copyWith(height: 1.5),
            ),

          if (dispute.canRespond) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TutorButton(
                    label: submitting
                        ? 'Đang gửi…'
                        : dispute.hasResponded
                        ? 'Sửa phản hồi'
                        : 'Gửi phản hồi',
                    icon: dispute.hasResponded ? Icons.edit_outlined : null,
                    onTap: submitting ? null : onRespond,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TutorButton(
                    label: uploading ? 'Đang tải…' : 'Bằng chứng',
                    icon: Icons.image_outlined,
                    filled: false,
                    onTap: uploading ? null : onUploadEvidence,
                  ),
                ),
              ],
            ),
          ] else if (dispute.status.isOpen) ...[
            // Từ `investigating` trở đi backend khoá hồ sơ; chỉ còn kênh chat.
            const SizedBox(height: 12),
            Text(
              'Khiếu nại đã chuyển sang giai đoạn điều tra nên không nộp thêm '
              'được vào hồ sơ. Trao đổi tiếp với quản trị viên ở phần dưới.',
              style: TutorType.caption(color: TutorStatusTone.pending),
            ),
          ],
        ],
      ),
    );
  }

  static String _fmtDate(DateTime t) =>
      '${t.day}/${t.month}, ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

/// Dải ảnh bằng chứng cuộn ngang.
class _EvidenceStrip extends StatelessWidget {
  const _EvidenceStrip({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: TutorSurface.screenPadding,
        itemCount: urls.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => _EvidenceThumb(url: urls[i]),
      ),
    );
  }
}

class _EvidenceThumb extends StatelessWidget {
  const _EvidenceThumb({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(TutorSurface.radiusSmall),
      child: Container(
        width: 96,
        height: 96,
        color: AppColors.cream2,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Icon(
            Icons.insert_drive_file_outlined,
            color: AppColors.ink4,
          ),
        ),
      ),
    );
  }
}

class _ThreadBubble extends StatelessWidget {
  const _ThreadBubble({required this.message});

  final DisputeMessageDto message;

  @override
  Widget build(BuildContext context) {
    final mine = message.isFromTutor;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? AppColors.ink : AppColors.paper,
          borderRadius: BorderRadius.circular(TutorSurface.radius),
          border: mine ? null : Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mine)
              Text(
                message.senderName.isEmpty
                    ? 'Quản trị viên'
                    : message.senderName,
                style: TutorType.caption(color: AppColors.ink3).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (!mine) const SizedBox(height: 3),
            Text(
              message.message,
              style: TutorType.rowSub(
                color: mine ? AppColors.cream : AppColors.ink,
              ).copyWith(height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ô nhập phản hồi dạng bottom sheet — tránh đẩy sang màn riêng cho một ô text.
class _ResponseSheet extends StatefulWidget {
  const _ResponseSheet({required this.initial});

  final String initial;

  @override
  State<_ResponseSheet> createState() => _ResponseSheetState();
}

class _ResponseSheetState extends State<_ResponseSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
            Text('Phản hồi khiếu nại', style: TutorType.sectionTitle()),
            const SizedBox(height: 4),
            Text(
              'Mô tả điều đã xảy ra trong buổi học. Chỉ quản trị viên đọc nội dung này.',
              style: TutorType.rowSub(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              maxLines: 6,
              minLines: 4,
              autofocus: true,
              style: TutorType.rowSub(color: AppColors.ink),
              decoration: InputDecoration(
                hintText: 'Ví dụ: Buổi học diễn ra đủ 90 phút, em Minh…',
                hintStyle: TutorType.rowSub(color: AppColors.ink4),
                filled: true,
                fillColor: AppColors.paper,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TutorSurface.radius),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TutorSurface.radius),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TutorSurface.radius),
                  borderSide: const BorderSide(
                    color: AppColors.ink,
                    width: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: TutorButton(
                label: 'Gửi phản hồi',
                onTap: () => Navigator.of(context).pop(_controller.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: TutorSurface.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TutorSkeleton(height: 170, radius: TutorSurface.radius),
          SizedBox(height: TutorSurface.sectionGap),
          TutorSkeleton(height: 15, width: 130),
          SizedBox(height: 12),
          TutorSkeleton(height: 120, radius: TutorSurface.radius),
        ],
      ),
    );
  }
}
