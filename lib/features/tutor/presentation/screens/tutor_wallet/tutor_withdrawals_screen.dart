import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/features/tutor/data/datasources/tutor_finance_datasource.dart';
import 'package:tutora/features/tutor/data/models/transaction_type_labels.dart';
import 'package:tutora/features/tutor/data/models/tutor_finance_models.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_finance_provider.dart';
import 'package:tutora/features/tutor/presentation/widgets/tutor_ui.dart';
import 'package:tutora/shared/providers/auth_headers_provider.dart';

class TutorWithdrawalsScreen extends ConsumerWidget {
  const TutorWithdrawalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tutorWithdrawalsProvider);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      body: SafeArea(
        child: Column(
          children: [
            const TutorChildHeader(title: 'Lịch sử rút tiền'),
            Expanded(
              child: async.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.oxblood,
                    strokeWidth: 2,
                  ),
                ),
                error: (_, _) => Center(
                  child: Text(
                    'Không tải được lịch sử.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.ink3,
                    ),
                  ),
                ),
                data: (page) {
                  if (page.items.isEmpty) {
                    return _EmptyState();
                  }
                  return RefreshIndicator(
                    color: AppColors.oxblood,
                    onRefresh: () async =>
                        ref.invalidate(tutorWithdrawalsProvider),
                    // Danh sách liền mạch, tách dòng bằng VIỀN thay vì thẻ
                    // rời nhau: các dòng chỉ khác nhau vài con số nên xé
                    // thành từng khối trông rối và tốn chiều dọc.
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(0, 6, 0, bottomPad + 24),
                      itemCount: page.items.length,
                      separatorBuilder: (_, _) => const Divider(
                        height: 1,
                        thickness: 0.8,
                        color: AppColors.line,
                        indent: 16,
                        endIndent: 16,
                      ),
                      itemBuilder: (_, i) => _WithdrawalCard(
                        item: page.items[i],
                        onTap: () => _openDetail(context, page.items[i]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, TutorWithdrawal item) {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) =>
              _WithdrawalDetailScreen(withdrawalId: item.withdrawalId),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 40,
            color: AppColors.ink4,
          ),
          const SizedBox(height: 10),
          Text(
            'Chưa có yêu cầu rút tiền nào.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink3),
          ),
        ],
      ),
    );
  }
}

class _WithdrawalCard extends StatelessWidget {
  const _WithdrawalCard({required this.item, required this.onTap});
  final TutorWithdrawal item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
        color: AppColors.paper,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    fmtMoney(item.amount),
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                _StatusBadge(status: item.status),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                // `GET /tutor/withdrawals` trả bankName/accountNumber RỖNG
                // (chỉ endpoint chi tiết mới có), nên nối chuỗi vô điều kiện
                // sẽ đẻ ra dòng " · " trơ trọi. Chỉ vẽ khi thật sự có dữ liệu.
                if (item.bankLine != null) ...[
                  const Icon(
                    Icons.account_balance_outlined,
                    size: 13,
                    color: AppColors.ink4,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.bankLine!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.ink4,
                      ),
                    ),
                  ),
                ] else
                  const Spacer(),
                Text(
                  _date(item.requestedAt),
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 11,
                    color: AppColors.ink4,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WithdrawalDetailScreen extends ConsumerWidget {
  const _WithdrawalDetailScreen({required this.withdrawalId});
  final int withdrawalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_withdrawalDetailProvider(withdrawalId));
    final authHeaders =
        ref.watch(authImageHeadersProvider).valueOrNull ??
        const <String, String>{};
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      body: SafeArea(
        child: Column(
          children: [
            const TutorChildHeader(title: 'Chi tiết rút tiền'),
            Expanded(
              child: async.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.oxblood,
                    strokeWidth: 2,
                  ),
                ),
                error: (_, _) => Center(
                  child: Text(
                    'Không tải được chi tiết.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.ink3,
                    ),
                  ),
                ),
                data: (w) => ListView(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad + 24),
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Text(
                            fmtMoney(w.amount),
                            style: GoogleFonts.ibmPlexMono(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _StatusBadge(status: w.status),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _Section(
                      children: [
                        // `?? '—'` không đủ: BE trả CHUỖI RỖNG chứ không phải
                        // null khi thiếu thông tin, lọt qua thì ô giá trị
                        // trống trơn.
                        _Row(label: 'Ngân hàng', value: _orDash(w.bankName)),
                        _Row(
                          label: 'Số tài khoản',
                          value: _orDash(w.accountNumber),
                          mono: true,
                        ),
                        _Row(
                          label: 'Chủ tài khoản',
                          value: _orDash(w.accountHolderName),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _Section(
                      children: [
                        _Row(
                          label: 'Ngày yêu cầu',
                          value: _dateTime(w.requestedAt),
                          mono: true,
                        ),
                        if (w.processedAt != null)
                          _Row(
                            label: 'Ngày xử lý',
                            value: _dateTime(w.processedAt),
                            mono: true,
                          ),
                        if (w.transactionId != null &&
                            w.transactionId!.isNotEmpty)
                          _Row(
                            label: 'Mã giao dịch',
                            value: w.transactionId!,
                            mono: true,
                          ),
                        if (w.paidAt != null)
                          _Row(
                            label: 'Ngày chi trả',
                            value: _dateTime(w.paidAt),
                            mono: true,
                          ),
                      ],
                    ),
                    if (w.rejectionReason != null &&
                        w.rejectionReason!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _NoteBox(
                        title: 'Lý do từ chối',
                        text: w.rejectionReason!,
                        error: true,
                      ),
                    ],
                    if (w.completionNote != null &&
                        w.completionNote!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _NoteBox(title: 'Ghi chú', text: w.completionNote!),
                    ],
                    if (w.proofImageUrl != null &&
                        w.proofImageUrl!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _label('CHỨNG TỪ CHI TRẢ'),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        // Ảnh nằm sau `/api/files/private`, endpoint này có
                        // [Authorize] nên phải gửi kèm JWT — Image.network
                        // trần không đính header, luôn ăn 401.
                        child: Image.network(
                          w.proofImageUrl!,
                          headers: authHeaders,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            height: 120,
                            color: AppColors.cream2,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.ink4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: GoogleFonts.inter(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.08,
      color: AppColors.ink4,
    ),
  );
}

String _orDash(String? v) => (v == null || v.trim().isEmpty) ? '—' : v;

/// Chi tiết một yêu cầu rút tiền theo id.
final AutoDisposeFutureProviderFamily<TutorWithdrawal, int>
_withdrawalDetailProvider = FutureProvider.autoDispose
    .family<TutorWithdrawal, int>((ref, id) {
      return ref.read(tutorFinanceDatasourceProvider).getWithdrawalDetail(id);
    });

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final tone = withdrawalStatusTone(status);
    final (bg, fg) = switch (tone) {
      1 => (const Color(0xFFD5EDD9), const Color(0xFF1D5C2D)),
      2 => (const Color(0xFFF6D9D9), AppColors.error),
      _ => (const Color(0xFFFFF3CD), const Color(0xFF7A5900)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        withdrawalStatusLabel(status),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(children: children),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.mono = false});
  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink4),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: mono
                  ? GoogleFonts.ibmPlexMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    )
                  : GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteBox extends StatelessWidget {
  const _NoteBox({
    required this.title,
    required this.text,
    this.error = false,
  });
  final String title;
  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final bg = error ? const Color(0xFFF6D9D9) : AppColors.cream2;
    final fg = error ? AppColors.error : AppColors.ink3;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: error ? AppColors.error : AppColors.ink2,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

String _date(DateTime? d) {
  if (d == null) return '';
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

String _dateTime(DateTime? d) {
  if (d == null) return '—';
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '${_date(d)} $hh:$mm';
}
