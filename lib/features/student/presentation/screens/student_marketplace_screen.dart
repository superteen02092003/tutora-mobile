import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_filter_options.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/utils/format_utils.dart';
import 'package:tutora/features/student/presentation/shell/student_shell.dart';
import 'package:tutora/features/tutor_search/data/models/tutor_search_models.dart';
import 'package:tutora/features/tutor_search/presentation/controllers/marketplace_controller.dart';
import 'package:tutora/shared/widgets/app_logo.dart';
import 'package:tutora/shared/widgets/status_chip.dart';
import 'package:tutora/shared/widgets/user_avatar.dart';
import 'package:tutora/shared/widgets/verify_pip.dart';

class StudentMarketplacePage extends ConsumerStatefulWidget {
  const StudentMarketplacePage({super.key});

  @override
  ConsumerState<StudentMarketplacePage> createState() =>
      _StudentMarketplacePageState();
}

class _StudentMarketplacePageState extends ConsumerState<StudentMarketplacePage>
    with ScrollToTopMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      listenScrollToTop(context, 1, _scrollController);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      unawaited(ref.read(marketplaceControllerProvider.notifier).loadMore());
    }
  }

  void _onSearch(String term) {
    unawaited(ref.read(marketplaceControllerProvider.notifier).search(term));
  }

  Future<void> _openFilter(MarketplaceLoaded current) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        current: current,
        onApply: (mode, city, sort, rating, budget) {
          unawaited(
            ref
                .read(marketplaceControllerProvider.notifier)
                .applyFilter(
                  teachingMode: mode,
                  city: city,
                  sortBy: sort,
                  minRating: rating,
                  budget: budget,
                ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketplaceControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopBar(
              searchController: _searchController,
              onSearch: _onSearch,
              activeFilter: state is MarketplaceLoaded && state.hasActiveFilter,
              onFilterTap: state is MarketplaceLoaded
                  ? () => _openFilter(state)
                  : null,
            ),
            if (state is MarketplaceLoaded && state.hasActiveFilter)
              _ActiveFilterChips(
                state: state,
                onClearAll: () => ref
                    .read(marketplaceControllerProvider.notifier)
                    .clearFilters(),
                onRemoveMode: () => ref
                    .read(marketplaceControllerProvider.notifier)
                    .applyFilter(teachingMode: null),
                onRemoveCity: () => ref
                    .read(marketplaceControllerProvider.notifier)
                    .applyFilter(city: null),
                onRemoveSort: () => ref
                    .read(marketplaceControllerProvider.notifier)
                    .applyFilter(sortBy: null),
                onRemoveRating: () => ref
                    .read(marketplaceControllerProvider.notifier)
                    .applyFilter(minRating: null),
                onRemoveBudget: () => ref
                    .read(marketplaceControllerProvider.notifier)
                    .applyFilter(budget: null),
              ),
            Expanded(
              child: switch (state) {
                MarketplaceLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                MarketplaceError(:final message) => _ErrorView(
                  message: message,
                  onRetry: () => ref
                      .read(marketplaceControllerProvider.notifier)
                      .load(reset: true),
                ),
                MarketplaceLoaded() => _LoadedView(
                  state: state,
                  scrollController: _scrollController,
                ),
                _ => const SizedBox.shrink(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.searchController,
    required this.onSearch,
    required this.activeFilter,
    required this.onFilterTap,
  });
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final bool activeFilter;
  final VoidCallback? onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              const AppLogo(),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push(AppRoutes.studentMessages),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.paper,
                    border: Border.all(color: AppColors.line),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    size: 18,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TÌM GIA SƯ · TUTORA MARKETPLACE',
                style: AppTextStyles.eyebrow(color: AppColors.oxblood),
              ),
              const SizedBox(height: 6),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Tìm người đồng hành ',
                      style: GoogleFonts.bricolageGrotesque(
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                        height: 1.05,
                        letterSpacing: -0.5,
                        color: AppColors.ink,
                      ),
                    ),
                    TextSpan(
                      text: 'đúng phong cách.',
                      style: GoogleFonts.ibmPlexSerif(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w400,
                        fontSize: 24,
                        color: AppColors.ink,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  onSubmitted: onSearch,
                  textInputAction: TextInputAction.search,
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink),
                  decoration: InputDecoration(
                    hintText: 'Toán · Hệ thức Vi-ét…',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.ink3,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 16,
                      color: AppColors.ink3,
                    ),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: AppColors.ink3,
                            ),
                            onPressed: () {
                              searchController.clear();
                              onSearch('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.paper,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.ink),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onFilterTap,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: activeFilter ? AppColors.ink : AppColors.paper,
                    border: Border.all(
                      color: activeFilter ? AppColors.ink : AppColors.line,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: activeFilter ? AppColors.gold : AppColors.ink3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActiveFilterChips extends StatelessWidget {
  const _ActiveFilterChips({
    required this.state,
    required this.onClearAll,
    required this.onRemoveMode,
    required this.onRemoveCity,
    required this.onRemoveSort,
    required this.onRemoveRating,
    required this.onRemoveBudget,
  });
  final MarketplaceLoaded state;
  final VoidCallback onClearAll;
  final VoidCallback onRemoveMode;
  final VoidCallback onRemoveCity;
  final VoidCallback onRemoveSort;
  final VoidCallback onRemoveRating;
  final VoidCallback onRemoveBudget;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          if (state.selectedMode != null)
            _Chip(
              label: filterLabel(teachingModeOptions, state.selectedMode),
              onRemove: onRemoveMode,
            ),
          if (state.selectedBudget != null)
            _Chip(
              label: filterLabel(budgetOptions, state.selectedBudget),
              onRemove: onRemoveBudget,
            ),
          if (state.selectedCity != null)
            _Chip(
              label: filterLabel(cityOptions, state.selectedCity),
              onRemove: onRemoveCity,
            ),
          if (state.selectedSortBy != null)
            _Chip(
              label: filterLabel(sortByOptions, state.selectedSortBy),
              onRemove: onRemoveSort,
            ),
          if (state.minRating != null)
            _Chip(
              label: '≥ ${state.minRating!.toStringAsFixed(1)}★',
              onRemove: onRemoveRating,
            ),
          GestureDetector(
            onTap: onClearAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                'Xóa tất cả',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.ink3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(right: 6),
    padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
    decoration: BoxDecoration(
      color: AppColors.ink,
      borderRadius: BorderRadius.circular(AppRadius.full),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.cream,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onRemove,
          child: const Icon(
            Icons.close_rounded,
            size: 12,
            color: AppColors.cream,
          ),
        ),
      ],
    ),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.current, required this.onApply});
  final MarketplaceLoaded current;
  final void Function(
    String? mode,
    String? city,
    String? sort,
    double? rating,
    String? budget,
  )
  onApply;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _mode;
  String? _city;
  String? _sort;
  double? _rating;
  String? _budget;

  @override
  void initState() {
    super.initState();
    _mode = widget.current.selectedMode;
    _city = widget.current.selectedCity;
    _sort = widget.current.selectedSortBy;
    _rating = widget.current.minRating;
    _budget = widget.current.selectedBudget;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Text(
                'Bộ lọc',
                style: GoogleFonts.bricolageGrotesque(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _mode = null;
                    _city = null;
                    _sort = null;
                    _rating = null;
                    _budget = null;
                  });
                },
                child: Text(
                  'Xóa tất cả',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _FilterLabel('Hình thức học'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: teachingModeOptions.map((m) {
              final sel = _mode == m.key;
              return GestureDetector(
                onTap: () => setState(() => _mode = sel ? null : m.key),
                child: _FilterOption(label: m.label, selected: sel),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const _FilterLabel('Ngân sách'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: budgetOptions.map((b) {
              final sel = _budget == b.key;
              return GestureDetector(
                onTap: () => setState(() => _budget = sel ? null : b.key),
                child: _FilterOption(label: b.label, selected: sel),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const _FilterLabel('Khu vực'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: cityOptions.map((c) {
              final sel = _city == c.key;
              return GestureDetector(
                onTap: () => setState(() => _city = sel ? null : c.key),
                child: _FilterOption(label: c.label, selected: sel),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const _FilterLabel('Đánh giá tối thiểu'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: minRatingOptions.map((r) {
              final sel = _rating == r;
              return GestureDetector(
                onTap: () => setState(() => _rating = sel ? null : r),
                child: _FilterOption(
                  label: '${r.toStringAsFixed(1)}★+',
                  selected: sel,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const _FilterLabel('Sắp xếp theo'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sortByOptions.map((s) {
              final sel = _sort == s.key;
              return GestureDetector(
                onTap: () => setState(() => _sort = sel ? null : s.key),
                child: _FilterOption(label: s.label, selected: sel),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              widget.onApply(_mode, _city, _sort, _rating, _budget);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                'Áp dụng bộ lọc',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cream,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterLabel extends StatelessWidget {
  const _FilterLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTextStyles.eyebrow());
}

class _FilterOption extends StatelessWidget {
  const _FilterOption({required this.label, required this.selected});
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: BoxDecoration(
      color: selected ? AppColors.ink : AppColors.paper,
      border: Border.all(color: selected ? AppColors.ink : AppColors.line),
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    child: Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: selected ? AppColors.gold : AppColors.ink,
      ),
    ),
  );
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({required this.state, required this.scrollController});
  final MarketplaceLoaded state;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (state.tutors.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppColors.ink4,
            ),
            const SizedBox(height: 12),
            Text(
              'Không tìm thấy gia sư phù hợp.',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink3),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            '${state.totalCount} gia sư',
            style: AppTextStyles.eyebrow(),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, AppSpacing.xxl),
            itemCount: state.tutors.length + (state.hasNext ? 1 : 0),
            itemBuilder: (context, i) {
              if (i == state.tutors.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TutorCard(tutor: state.tutors[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TutorCard extends StatelessWidget {
  const _TutorCard({required this.tutor});
  final TutorSearchResult tutor;

  ChipTone get _badgeTone => switch (tutor.subscriptionType) {
    'Senior' => ChipTone.ox,
    'New' => ChipTone.cream,
    _ => ChipTone.moss,
  };

  String get _badge =>
      tutor.subscriptionTypeLabel ?? tutor.verificationStatus ?? '';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/student/search/tutor/${tutor.tutorId}'),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserAvatar(
              name: tutor.displayName,
              size: 56,
              imageUrl: tutor.avatarUrl,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          tutor.displayName,
                          style: GoogleFonts.bricolageGrotesque(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const VerifyPip(small: true),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      tutor.subjectSummary,
                      tutor.locationSummary,
                    ].where((s) => s.isNotEmpty).join(' · '),
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppColors.ink3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: AppColors.gold,
                      ),
                      Text(
                        (tutor.averageRating ?? 0).toStringAsFixed(2),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        '· ${tutor.totalReviews ?? 0} đánh giá',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: AppColors.ink3,
                        ),
                      ),
                      if (_badge.isNotEmpty)
                        StatusChip(label: _badge, tone: _badgeTone),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatPrice(tutor.hourlyRate),
                  style: GoogleFonts.bricolageGrotesque(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  '/ giờ',
                  style: GoogleFonts.inter(fontSize: 10, color: AppColors.ink3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink3),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                'Thử lại',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.cream,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
