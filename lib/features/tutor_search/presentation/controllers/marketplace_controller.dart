import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/tutor_search_datasource.dart';
import '../../data/models/tutor_search_models.dart';

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
  });

  final List<TutorSearchResult> tutors;
  final bool hasNext;
  final int totalCount;
  final String searchTerm;
  final String? selectedCity;
  final String? selectedMode;

  MarketplaceLoaded copyWith({
    List<TutorSearchResult>? tutors,
    bool? hasNext,
    int? totalCount,
    String? searchTerm,
    Object? selectedCity = _sentinel,
    Object? selectedMode = _sentinel,
  }) {
    return MarketplaceLoaded(
      tutors: tutors ?? this.tutors,
      hasNext: hasNext ?? this.hasNext,
      totalCount: totalCount ?? this.totalCount,
      searchTerm: searchTerm ?? this.searchTerm,
      selectedCity: selectedCity == _sentinel ? this.selectedCity : selectedCity as String?,
      selectedMode: selectedMode == _sentinel ? this.selectedMode : selectedMode as String?,
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
    load();
  }

  final TutorSearchDatasource _datasource;

  int _page = 1;
  static const _pageSize = 10;

  Future<void> load({bool reset = false}) async {
    if (reset) _page = 1;
    state = MarketplaceLoading();
    try {
      final current = state is MarketplaceLoaded ? state as MarketplaceLoaded : null;
      final result = await _datasource.search(
        searchTerm: current?.searchTerm,
        teachingMode: current?.selectedMode,
        teachingAreaCity: current?.selectedCity,
        pageNumber: _page,
        pageSize: _pageSize,
      );
      state = MarketplaceLoaded(
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
    state = MarketplaceLoading();
    try {
      final result = await _datasource.search(
        searchTerm: term,
        pageNumber: _page,
        pageSize: _pageSize,
      );
      state = MarketplaceLoaded(
        tutors: result.items,
        hasNext: result.hasNext,
        totalCount: result.totalCount,
        searchTerm: term,
      );
    } catch (e) {
      state = MarketplaceError('Không tải được danh sách gia sư.');
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! MarketplaceLoaded || !current.hasNext) return;
    _page++;
    try {
      final result = await _datasource.search(
        searchTerm: current.searchTerm,
        teachingMode: current.selectedMode,
        teachingAreaCity: current.selectedCity,
        pageNumber: _page,
        pageSize: _pageSize,
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

final marketplaceControllerProvider =
    StateNotifierProvider.autoDispose<MarketplaceController, MarketplaceState>((ref) {
  return MarketplaceController(ref.read(tutorSearchDatasourceProvider));
});
