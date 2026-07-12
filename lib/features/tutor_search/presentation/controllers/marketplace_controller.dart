import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/features/tutor_search/data/datasources/tutor_search_datasource.dart';
import 'package:tutora/features/tutor_search/data/models/tutor_search_models.dart';

sealed class MarketplaceState {}

final class MarketplaceIdle extends MarketplaceState {}

final class MarketplaceLoading extends MarketplaceState {}

final class MarketplaceLoaded extends MarketplaceState {
  MarketplaceLoaded({
    required this.tutors,
    required this.hasNext,
    required this.totalCount,
    this.searchTerm = '',
    this.selectedCity,
    this.selectedGrade,
    this.selectedSubjectId,
    this.selectedSortBy,
    this.minRating,
    this.selectedBudget,
  });

  final List<TutorSearchResult> tutors;
  final bool hasNext;
  final int totalCount;
  final String searchTerm;
  final String? selectedCity;
  final String? selectedGrade;
  final int? selectedSubjectId;
  final String? selectedSortBy;
  final double? minRating;
  final String? selectedBudget; // e.g. 'under_50', '50_100', etc.

  bool get hasActiveFilter =>
      selectedCity != null ||
      selectedGrade != null ||
      selectedSubjectId != null ||
      selectedSortBy != null ||
      minRating != null ||
      selectedBudget != null;

  MarketplaceLoaded copyWith({
    List<TutorSearchResult>? tutors,
    bool? hasNext,
    int? totalCount,
    String? searchTerm,
    Object? selectedCity = _sentinel,
    Object? selectedGrade = _sentinel,
    Object? selectedSubjectId = _sentinel,
    Object? selectedSortBy = _sentinel,
    Object? minRating = _sentinel,
    Object? selectedBudget = _sentinel,
  }) {
    return MarketplaceLoaded(
      tutors: tutors ?? this.tutors,
      hasNext: hasNext ?? this.hasNext,
      totalCount: totalCount ?? this.totalCount,
      searchTerm: searchTerm ?? this.searchTerm,
      selectedCity: selectedCity == _sentinel
          ? this.selectedCity
          : selectedCity as String?,
      selectedGrade: selectedGrade == _sentinel
          ? this.selectedGrade
          : selectedGrade as String?,
      selectedSubjectId: selectedSubjectId == _sentinel
          ? this.selectedSubjectId
          : selectedSubjectId as int?,
      selectedSortBy: selectedSortBy == _sentinel
          ? this.selectedSortBy
          : selectedSortBy as String?,
      minRating: minRating == _sentinel ? this.minRating : minRating as double?,
      selectedBudget: selectedBudget == _sentinel
          ? this.selectedBudget
          : selectedBudget as String?,
    );
  }

  static const _sentinel = Object();
}

final class MarketplaceError extends MarketplaceState {
  MarketplaceError(this.message);
  final String message;
}

({double? min, double? max}) _budgetToRate(String? budget) => switch (budget) {
  'under_50' => (min: null, max: 50000),
  '50_100' => (min: 50000, max: 100000),
  '100_200' => (min: 100000, max: 200000),
  '200_500' => (min: 200000, max: 500000),
  'over_500' => (min: 500000, max: null),
  _ => (min: null, max: null),
};

class MarketplaceController extends StateNotifier<MarketplaceState> {
  MarketplaceController(this._datasource) : super(MarketplaceIdle()) {
    unawaited(load());
  }

  final TutorSearchDatasource _datasource;
  int _page = 1;

  MarketplaceLoaded get _currentOrEmpty => state is MarketplaceLoaded
      ? state as MarketplaceLoaded
      : MarketplaceLoaded(tutors: [], hasNext: false, totalCount: 0);

  Future<void> load({bool reset = false}) async {
    if (reset) _page = 1;
    final current = _currentOrEmpty;
    final rate = _budgetToRate(current.selectedBudget);
    state = MarketplaceLoading();
    try {
      final result = await _datasource.search(
        searchTerm: current.searchTerm,
        gradeLevel: current.selectedGrade,
        subjectIds: current.selectedSubjectId == null
            ? null
            : [current.selectedSubjectId!],
        teachingAreaCity: current.selectedCity,
        sortBy: current.selectedSortBy,
        minRating: current.minRating,
        minHourlyRate: rate.min,
        maxHourlyRate: rate.max,
        pageNumber: _page,
      );
      state = current.copyWith(
        tutors: result.items,
        hasNext: result.hasNext,
        totalCount: result.totalCount,
      );
    } catch (e) {
      state = MarketplaceError('Không tải được danh sách gia sư.');
    }
  }

  Future<void> search(String term) async {
    _page = 1;
    final current = _currentOrEmpty;
    final rate = _budgetToRate(current.selectedBudget);
    state = MarketplaceLoading();
    try {
      final result = await _datasource.search(
        searchTerm: term,
        gradeLevel: current.selectedGrade,
        subjectIds: current.selectedSubjectId == null
            ? null
            : [current.selectedSubjectId!],
        teachingAreaCity: current.selectedCity,
        sortBy: current.selectedSortBy,
        minRating: current.minRating,
        minHourlyRate: rate.min,
        maxHourlyRate: rate.max,
        pageNumber: _page,
      );
      state = current.copyWith(
        tutors: result.items,
        hasNext: result.hasNext,
        totalCount: result.totalCount,
        searchTerm: term,
      );
    } catch (e) {
      state = MarketplaceError('Không tải được danh sách gia sư.');
    }
  }

  Future<void> applyFilter({
    Object? gradeLevel = _MarketplaceSentinel.value,
    Object? subjectId = _MarketplaceSentinel.value,
    Object? city = _MarketplaceSentinel.value,
    Object? sortBy = _MarketplaceSentinel.value,
    Object? minRating = _MarketplaceSentinel.value,
    Object? budget = _MarketplaceSentinel.value,
  }) async {
    _page = 1;
    final current = _currentOrEmpty;
    final newGrade = gradeLevel == _MarketplaceSentinel.value
        ? current.selectedGrade
        : gradeLevel as String?;
    final newSubject = subjectId == _MarketplaceSentinel.value
        ? current.selectedSubjectId
        : subjectId as int?;
    final newCity = city == _MarketplaceSentinel.value
        ? current.selectedCity
        : city as String?;
    final newSort = sortBy == _MarketplaceSentinel.value
        ? current.selectedSortBy
        : sortBy as String?;
    final newRating = minRating == _MarketplaceSentinel.value
        ? current.minRating
        : minRating as double?;
    final newBudget = budget == _MarketplaceSentinel.value
        ? current.selectedBudget
        : budget as String?;
    final rate = _budgetToRate(newBudget);

    state = MarketplaceLoading();
    try {
      final result = await _datasource.search(
        searchTerm: current.searchTerm,
        gradeLevel: newGrade,
        subjectIds: newSubject == null ? null : [newSubject],
        teachingAreaCity: newCity,
        sortBy: newSort,
        minRating: newRating,
        minHourlyRate: rate.min,
        maxHourlyRate: rate.max,
        pageNumber: _page,
      );
      state = MarketplaceLoaded(
        tutors: result.items,
        hasNext: result.hasNext,
        totalCount: result.totalCount,
        searchTerm: current.searchTerm,
        selectedGrade: newGrade,
        selectedSubjectId: newSubject,
        selectedCity: newCity,
        selectedSortBy: newSort,
        minRating: newRating,
        selectedBudget: newBudget,
      );
    } catch (e) {
      state = MarketplaceError('Không tải được danh sách gia sư.');
    }
  }

  Future<void> clearFilters() => applyFilter(
    gradeLevel: null,
    subjectId: null,
    city: null,
    sortBy: null,
    minRating: null,
    budget: null,
  );

  Future<void> loadMore() async {
    final current = state;
    if (current is! MarketplaceLoaded || !current.hasNext) return;
    _page++;
    final rate = _budgetToRate(current.selectedBudget);
    try {
      final result = await _datasource.search(
        searchTerm: current.searchTerm,
        gradeLevel: current.selectedGrade,
        subjectIds: current.selectedSubjectId == null
            ? null
            : [current.selectedSubjectId!],
        teachingAreaCity: current.selectedCity,
        sortBy: current.selectedSortBy,
        minRating: current.minRating,
        minHourlyRate: rate.min,
        maxHourlyRate: rate.max,
        pageNumber: _page,
      );
      state = current.copyWith(
        tutors: [...current.tutors, ...result.items],
        hasNext: result.hasNext,
      );
    } catch (_) {
      _page--;
    }
  }
}

class _MarketplaceSentinel {
  const _MarketplaceSentinel._();
  static const value = _MarketplaceSentinel._();
}

final AutoDisposeStateNotifierProvider<MarketplaceController, MarketplaceState>
marketplaceControllerProvider =
    StateNotifierProvider.autoDispose<MarketplaceController, MarketplaceState>(
      (ref) => MarketplaceController(ref.read(tutorSearchDatasourceProvider)),
    );
