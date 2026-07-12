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
import 'package:tutora/features/parent/presentation/shell/parent_shell.dart';
import 'package:tutora/features/tutor_search/data/models/tutor_search_models.dart';
import 'package:tutora/features/tutor_search/presentation/controllers/marketplace_controller.dart';
import 'package:tutora/shared/data/lookup_datasource.dart';
import 'package:tutora/shared/widgets/skeletons.dart';
import 'package:tutora/shared/widgets/user_avatar.dart';
import 'package:tutora/shared/widgets/verify_pip.dart';

class ParentMarketplacePage extends ConsumerStatefulWidget {
  const ParentMarketplacePage({super.key});

  @override
  ConsumerState<ParentMarketplacePage> createState() =>
      _ParentMarketplacePageState();
}

class _ParentMarketplacePageState extends ConsumerState<ParentMarketplacePage>
    with ParentScrollToTopMixin {
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

  List<FilterOption> _subjectOptions() => ref
      .watch(subjectsProvider)
      .maybeWhen(
        data: (list) => list
            .map((s) => (key: s.subjectId.toString(), label: s.subjectName))
            .toList(),
        orElse: () => const <FilterOption>[],
      );

  List<FilterOption> _gradeOptions() => ref
      .watch(gradeLevelsProvider)
      .maybeWhen(
        data: (list) =>
            list.map((g) => (key: g.gradeName, label: g.gradeName)).toList(),
        orElse: () => const <FilterOption>[],
      );

  Future<void> _openFilter(
    MarketplaceLoaded current,
    List<FilterOption> subjectOptions,
    List<FilterOption> gradeOptions,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        current: current,
        subjectOptions: subjectOptions,
        gradeOptions: gradeOptions,
        onApply: (subjectId, grade, city, sort, rating, budget) {
          unawaited(
            ref
                .read(marketplaceControllerProvider.notifier)
                .applyFilter(
                  subjectId: subjectId,
                  gradeLevel: grade,
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

  Future<void> _openSubjectPicker(
    int? current,
    List<FilterOption> subjectOptions,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubjectPickerSheet(
        selectedSubjectId: current,
        subjectOptions: subjectOptions,
        onPick: (subjectId) {
          unawaited(
            ref
                .read(marketplaceControllerProvider.notifier)
                .applyFilter(subjectId: subjectId),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketplaceControllerProvider);
    final subjectId = state is MarketplaceLoaded
        ? state.selectedSubjectId
        : null;
    final subjectOpts = _subjectOptions();
    final gradeOpts = _gradeOptions();

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopBar(
              searchController: _searchController,
              onSearch: _onSearch,
              activeFilter: state is MarketplaceLoaded && state.hasActiveFilter,
              onFilterTap: state is MarketplaceLoaded
                  ? () => _openFilter(state, subjectOpts, gradeOpts)
                  : null,
              selectedSubjectId: subjectId,
              subjectOptions: subjectOpts,
              onSubjectTap: () => _openSubjectPicker(subjectId, subjectOpts),
            ),
            if (state is MarketplaceLoaded && state.hasActiveFilter)
              _ActiveFilterChips(
                state: state,
                subjectOptions: subjectOpts,
                gradeOptions: gradeOpts,
                onClearAll: () => ref
                    .read(marketplaceControllerProvider.notifier)
                    .clearFilters(),
                onRemoveSubject: () => ref
                    .read(marketplaceControllerProvider.notifier)
                    .applyFilter(subjectId: null),
                onRemoveGrade: () => ref
                    .read(marketplaceControllerProvider.notifier)
                    .applyFilter(gradeLevel: null),
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
                MarketplaceLoading() => const TutorSearchSkeleton(),
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
    required this.selectedSubjectId,
    required this.subjectOptions,
    required this.onSubjectTap,
  });
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final bool activeFilter;
  final VoidCallback? onFilterTap;
  final int? selectedSubjectId;
  final List<FilterOption> subjectOptions;
  final VoidCallback? onSubjectTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onSubjectTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.menu_book_rounded,
                          size: 18,
                          color: AppColors.oxblood,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedSubjectId == null
                                ? 'Tất cả môn học'
                                : filterLabel(
                                    subjectOptions,
                                    selectedSubjectId.toString(),
                                  ),
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: AppColors.ink3,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => context.push(AppRoutes.parentMessages),
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  onSubmitted: onSearch,
                  textInputAction: TextInputAction.search,
                  style: GoogleFonts.inter(fontSize: 15, color: AppColors.ink),
                  decoration: InputDecoration(
                    hintText: 'Tìm gia sư, môn học…',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppColors.ink3,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 20,
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
    required this.subjectOptions,
    required this.gradeOptions,
    required this.onClearAll,
    required this.onRemoveSubject,
    required this.onRemoveGrade,
    required this.onRemoveCity,
    required this.onRemoveSort,
    required this.onRemoveRating,
    required this.onRemoveBudget,
  });
  final MarketplaceLoaded state;
  final List<FilterOption> subjectOptions;
  final List<FilterOption> gradeOptions;
  final VoidCallback onClearAll;
  final VoidCallback onRemoveSubject;
  final VoidCallback onRemoveGrade;
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
          if (state.selectedSubjectId != null)
            _Chip(
              label: filterLabel(
                subjectOptions,
                state.selectedSubjectId.toString(),
              ),
              onRemove: onRemoveSubject,
            ),
          if (state.selectedGrade != null)
            _Chip(
              label: filterLabel(gradeOptions, state.selectedGrade),
              onRemove: onRemoveGrade,
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
  const _FilterSheet({
    required this.current,
    required this.subjectOptions,
    required this.gradeOptions,
    required this.onApply,
  });
  final MarketplaceLoaded current;
  final List<FilterOption> subjectOptions;
  final List<FilterOption> gradeOptions;
  final void Function(
    int? subjectId,
    String? grade,
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
  int? _subjectId;
  String? _grade;
  String? _city;
  String? _sort;
  double? _rating;
  String? _budget;

  @override
  void initState() {
    super.initState();
    _subjectId = widget.current.selectedSubjectId;
    _grade = widget.current.selectedGrade;
    _city = widget.current.selectedCity;
    _sort = widget.current.selectedSortBy;
    _rating = widget.current.minRating;
    _budget = widget.current.selectedBudget;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.85;
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
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
                    _grade = null;
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
          const SizedBox(height: 12),
          // Subject filter lives in the top bar now — sheet holds the rest.
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FilterLabel('Cấp học'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.gradeOptions.map((g) {
                      final sel = _grade == g.key;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _grade = sel ? null : g.key),
                        child: _FilterOption(label: g.label, selected: sel),
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
                        onTap: () =>
                            setState(() => _budget = sel ? null : b.key),
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              widget.onApply(
                _subjectId,
                _grade,
                _city,
                _sort,
                _rating,
                _budget,
              );
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
            padding: EdgeInsets.fromLTRB(
              16,
              4,
              16,
              16 + MediaQuery.of(context).padding.bottom,
            ),
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

  String get _priceText {
    final p = tutor.hourlyRate ?? 0;
    if (p <= 0) return 'Thương lượng';
    if (p >= 1000) return 'Từ ${(p / 1000).round()}.000đ';
    return 'Từ ${p.toStringAsFixed(0)}đ';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          context.push('${AppRoutes.parentSearch}/tutor/${tutor.tutorId}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: UserAvatar(
                    name: tutor.displayName,
                    size: 84,
                    imageUrl: tutor.avatarUrl,
                    square: true,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              tutor.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.bricolageGrotesque(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const VerifyPip(small: true),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _priceText,
                        style: GoogleFonts.bricolageGrotesque(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: AppColors.oxblood,
                        ),
                      ),
                      if (tutor.subjectSummary.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          tutor.subjectSummary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.ink3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (tutor.headline?.isNotEmpty ?? false) ...[
              const SizedBox(height: 10),
              Text(
                tutor.headline!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 15, color: AppColors.gold),
                const SizedBox(width: 3),
                Text(
                  (tutor.averageRating ?? 0).toStringAsFixed(1),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  ' (${tutor.totalReviews ?? 0})',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.ink3,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${tutor.totalClassSessions ?? 0} buổi học',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.ink3,
                  ),
                ),
                const Spacer(),
                Text(
                  'Xem hồ sơ →',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.oxblood,
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

// Subject picker — bottom sheet, applies immediately (mirrors student).
class _SubjectPickerSheet extends StatelessWidget {
  const _SubjectPickerSheet({
    required this.selectedSubjectId,
    required this.subjectOptions,
    required this.onPick,
  });
  final int? selectedSubjectId;
  final List<FilterOption> subjectOptions;
  final ValueChanged<int?> onPick;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.7;
    final items = <({int? id, String label})>[
      (id: null, label: 'Tất cả môn học'),
      ...subjectOptions.map((s) => (id: int.parse(s.key), label: s.label)),
    ];

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
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
          Text(
            'Chọn môn học',
            style: GoogleFonts.bricolageGrotesque(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: items.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: AppColors.line),
              itemBuilder: (context, index) {
                final item = items[index];
                final sel = item.id == selectedSubjectId;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Navigator.pop(context);
                    onPick(item.id);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.label,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: sel
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        if (sel)
                          const Icon(
                            Icons.check_rounded,
                            size: 20,
                            color: AppColors.oxblood,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
