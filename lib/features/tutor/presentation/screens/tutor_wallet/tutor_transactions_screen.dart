import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/datasources/tutor_finance_datasource.dart';
import 'package:tutora/features/tutor/data/models/tutor_finance_models.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_wallet/tutor_transaction_detail_screen.dart';
import 'package:tutora/features/tutor/presentation/widgets/tutor_transaction_list.dart';
import 'package:tutora/features/tutor/presentation/widgets/tutor_ui.dart';
import 'package:tutora/shared/widgets/tutor_nav_bar.dart';

const _transactionTypes = <(String, String?)>[
  ('Tất cả', null),
  ('Thu nhập buổi học', 'EscrowRelease'),
  ('Tiền giữ escrow', 'EscrowCredit'),
  ('Hoàn escrow', 'EscrowReversal'),
  ('Rút tiền', 'Withdrawal'),
  ('Hoàn tiền', 'Refund'),
  ('Điều chỉnh số dư', 'AdminCredit'),
];

class TutorTransactionsScreen extends ConsumerStatefulWidget {
  const TutorTransactionsScreen({super.key});

  @override
  ConsumerState<TutorTransactionsScreen> createState() =>
      _TutorTransactionsScreenState();
}

class _TutorTransactionsScreenState
    extends ConsumerState<TutorTransactionsScreen> {
  final _scrollController = ScrollController();
  final _transactions = <TutorTransaction>[];

  _TransactionFilter _filter = const _TransactionFilter();
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    unawaited(_load(reset: true));
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 280) {
      unawaited(_load());
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      if (mounted) {
        setState(() {
          _loading = true;
          _error = null;
        });
      }
    } else if (_loading || _loadingMore || !_hasMore) {
      return;
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final nextPage = reset ? 1 : _page + 1;
      final range = _filter.range;
      final page = await ref
          .read(tutorFinanceDatasourceProvider)
          .getTransactions(
            page: nextPage,
            type: _filter.type,
            from: range == null
                ? null
                : DateTime(
                    range.start.year,
                    range.start.month,
                    range.start.day,
                  ),
            to: range == null
                ? null
                : DateTime(
                    range.end.year,
                    range.end.month,
                    range.end.day,
                    23,
                    59,
                    59,
                    999,
                  ),
          );
      if (!mounted) return;
      setState(() {
        if (reset) _transactions.clear();
        _transactions.addAll(page.transactions);
        _page = page.page;
        _hasMore = page.hasMore;
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = 'Không tải được giao dịch. Vui lòng thử lại.';
      });
    }
  }

  Future<void> _openFilter() async {
    final selected = await showModalBottomSheet<_TransactionFilter>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: TutorColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _TransactionFilterSheet(initial: _filter),
    );
    if (selected == null || selected == _filter) return;
    setState(() => _filter = selected);
    await _load(reset: true);
  }

  void _openDetail(TutorTransaction transaction) {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => TutorTransactionDetailScreen(
            transaction: transaction,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TutorColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TutorChildHeader(
              title: 'Tất cả giao dịch',
              action: IconButton(
                onPressed: _openFilter,
                tooltip: _filter.isActive ? 'Đang lọc' : 'Bộ lọc',
                icon: Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: _filter.isActive
                      ? TutorColors.primary
                      : TutorColors.ink3,
                ),
              ),
            ),
            if (_filter.isActive) _ActiveFilterBar(filter: _filter),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: TutorColors.primary,
          strokeWidth: 2,
        ),
      );
    }
    if (_error != null && _transactions.isEmpty) {
      return _MessageView(
        icon: Icons.wifi_off_rounded,
        message: _error!,
        action: 'Thử lại',
        onTap: () => _load(reset: true),
      );
    }
    if (_transactions.isEmpty) {
      return const _MessageView(
        icon: Icons.receipt_long_outlined,
        message: 'Không có giao dịch phù hợp với bộ lọc.',
      );
    }

    return RefreshIndicator(
      color: TutorColors.primary,
      onRefresh: () => _load(reset: true),
      child: ListView(
        controller: _scrollController,
        children: [
          TutorTransactionList(
            transactions: _transactions,
            onTap: _openDetail,
          ),
          if (_loadingMore)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(
                  color: TutorColors.primary,
                  strokeWidth: 2,
                ),
              ),
            ),
          if (_error != null && _transactions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: TextButton(
                  onPressed: _load,
                  child: const Text('Không tải thêm được · Thử lại'),
                ),
              ),
            ),
          const SizedBox(height: kTutorNavTotalHeight + 16),
        ],
      ),
    );
  }
}

@immutable
class _TransactionFilter {
  const _TransactionFilter({this.type, this.range});

  final String? type;
  final DateTimeRange? range;

  bool get isActive => type != null || range != null;

  @override
  bool operator ==(Object other) =>
      other is _TransactionFilter &&
      other.type == type &&
      other.range?.start == range?.start &&
      other.range?.end == range?.end;

  @override
  int get hashCode => Object.hash(type, range?.start, range?.end);
}

class _TransactionFilterSheet extends StatefulWidget {
  const _TransactionFilterSheet({required this.initial});

  final _TransactionFilter initial;

  @override
  State<_TransactionFilterSheet> createState() =>
      _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends State<_TransactionFilterSheet> {
  late String? _type = widget.initial.type;
  late DateTimeRange? _range = widget.initial.range;

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final selected = await showDateRangePicker(
      context: context,
      initialDateRange: _range,
      firstDate: DateTime(2024),
      lastDate: DateTime(now.year + 1, 12, 31),
      helpText: 'Chọn khoảng giao dịch',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
      saveText: 'Chọn',
    );
    if (selected != null) setState(() => _range = selected);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: TutorColors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Bộ lọc giao dịch',
                    style: TutorType.sectionTitle(),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _type = null;
                    _range = null;
                  }),
                  child: const Text('Xóa tất cả'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'LOẠI GIAO DỊCH',
              style: TutorType.caption(),
            ),
            const SizedBox(height: 6),
            for (final item in _transactionTypes)
              _FilterOption(
                label: item.$1,
                selected: _type == item.$2,
                onTap: () => setState(() => _type = item.$2),
              ),
            const Divider(height: 24, color: TutorColors.line),
            Text(
              'THỜI GIAN',
              style: TutorType.caption(),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickRange,
              borderRadius: BorderRadius.circular(TutorSurface.radiusSmall),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: TutorColors.line),
                  borderRadius: BorderRadius.circular(TutorSurface.radiusSmall),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.date_range_rounded,
                      size: 19,
                      color: TutorColors.ink3,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _range == null
                            ? 'Tất cả thời gian'
                            : _rangeLabel(_range!),
                        style: TutorType.action(),
                      ),
                    ),
                    if (_range != null)
                      IconButton(
                        onPressed: () => setState(() => _range = null),
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close_rounded, size: 18),
                      )
                    else
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: TutorColors.ink4,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(
                  _TransactionFilter(type: _type, range: _range),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: TutorColors.ink,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Áp dụng bộ lọc'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterOption extends StatelessWidget {
  const _FilterOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 46,
        child: Row(
          children: [
            Expanded(child: Text(label, style: TutorType.rowTitle())),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? TutorColors.primary : TutorColors.ink4,
              size: 21,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveFilterBar extends StatelessWidget {
  const _ActiveFilterBar({required this.filter});

  final _TransactionFilter filter;

  @override
  Widget build(BuildContext context) {
    final type = _transactionTypes
        .where((item) => item.$2 == filter.type)
        .map((item) => item.$1)
        .firstOrNull;
    return Container(
      width: double.infinity,
      color: TutorColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 9, 20, 10),
      child: Text(
        [
          ?type,
          if (filter.range != null) _rangeLabel(filter.range!),
        ].join(' · '),
        style: TutorType.caption(color: TutorColors.primary),
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.message,
    this.action,
    this.onTap,
  });

  final IconData icon;
  final String message;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 38, color: TutorColors.ink4),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TutorType.rowSub(),
            ),
            if (action != null) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onTap, child: Text(action!)),
            ],
          ],
        ),
      ),
    );
  }
}

String _rangeLabel(DateTimeRange range) =>
    '${range.start.day}/${range.start.month}/${range.start.year} – '
    '${range.end.day}/${range.end.month}/${range.end.year}';
