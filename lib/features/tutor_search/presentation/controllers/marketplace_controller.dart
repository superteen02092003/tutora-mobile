import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/features/tutor_search/data/datasources/tutor_search_datasource.dart';
import 'package:tutora/features/tutor_search/data/models/tutor_search_models.dart';

// ── State ──────────────────────────────────────────────────────────────

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
    this.selectedMode,
    this.selectedSortBy,
    this.minRating,
  });

  final List<TutorSearchResult> tutors;
  final bool hasNext;
  final int totalCount;
  final String searchTerm;
  final String? selectedCity;
  final String? selectedMode;
  final String? selectedSortBy;
  final double? minRating;

  bool get hasActiveFilter =>
      selectedCity != null ||
      selectedMode != null ||
      selectedSortBy != null ||
      minRating != null;

  MarketplaceLoaded copyWith({
    List<TutorSearchResult>? tutors,
    bool? hasNext,
    int? totalCount,
    String? searchTerm,
    Object? selectedCity = _sentinel,
    Object? selectedMode = _sentinel,
    Object? selectedSortBy = _sentinel,
    Object? minRating = _sentinel,
  }) {
    return MarketplaceLoaded(
      tutors: tutors ?? this.tutors,
      hasNext: hasNext ?? this.hasNext,
      totalCount: totalCount ?? this.totalCount,
      searchTerm: searchTerm ?? this.searchTerm,
      selectedCity: selectedCity == _sentinel
          ? this.selectedCity
          : selectedCity as String?,
      selectedMode: selectedMode == _sentinel
          ? this.selectedMode
          : selectedMode as String?,
      selectedSortBy: selectedSortBy == _sentinel
          ? this.selectedSortBy
          : selectedSortBy as String?,
      minRating: minRating == _sentinel ? this.minRating : minRating as double?,
    );
  }

  static const _sentinel = Object();
}

final class MarketplaceError extends MarketplaceState {
  MarketplaceError(this.message);
  final String message;
}

// ── Controller ─────────────────────────────────────────────────────────

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
    state = MarketplaceLoading();
    try {
      final result = await _datasource.search(
        searchTerm: current.searchTerm,
        teachingMode: current.selectedMode,
        teachingAreaCity: current.selectedCity,
        sortBy: current.selectedSortBy,
        minRating: current.minRating,
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
    state = MarketplaceLoading();
    try {
      final result = await _datasource.search(
        searchTerm: term,
        teachingMode: current.selectedMode,
        teachingAreaCity: current.selectedCity,
        sortBy: current.selectedSortBy,
        minRating: current.minRating,
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
    Object? teachingMode = _MarketplaceSentinel.value,
    Object? city = _MarketplaceSentinel.value,
    Object? sortBy = _MarketplaceSentinel.value,
    Object? minRating = _MarketplaceSentinel.value,
  }) async {
    _page = 1;
    final current = _currentOrEmpty;
    final newMode = teachingMode == _MarketplaceSentinel.value
        ? current.selectedMode
        : teachingMode as String?;
    final newCity = city == _MarketplaceSentinel.value
        ? current.selectedCity
        : city as String?;
    final newSort = sortBy == _MarketplaceSentinel.value
        ? current.selectedSortBy
        : sortBy as String?;
    final newRating = minRating == _MarketplaceSentinel.value
        ? current.minRating
        : minRating as double?;

    state = MarketplaceLoading();
    try {
      final result = await _datasource.search(
        searchTerm: current.searchTerm,
        teachingMode: newMode,
        teachingAreaCity: newCity,
        sortBy: newSort,
        minRating: newRating,
        pageNumber: _page,
      );
      state = MarketplaceLoaded(
        tutors: result.items,
        hasNext: result.hasNext,
        totalCount: result.totalCount,
        searchTerm: current.searchTerm,
        selectedMode: newMode,
        selectedCity: newCity,
        selectedSortBy: newSort,
        minRating: newRating,
      );
    } catch (e) {
      state = MarketplaceError('Không tải được danh sách gia sư.');
    }
  }

  Future<void> clearFilters() => applyFilter(
    teachingMode: null,
    city: null,
    sortBy: null,
    minRating: null,
  );

  Future<void> loadMore() async {
    final current = state;
    if (current is! MarketplaceLoaded || !current.hasNext) return;
    _page++;
    try {
      final result = await _datasource.search(
        searchTerm: current.searchTerm,
        teachingMode: current.selectedMode,
        teachingAreaCity: current.selectedCity,
        sortBy: current.selectedSortBy,
        minRating: current.minRating,
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
