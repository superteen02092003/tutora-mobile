import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/features/student/data/datasources/booking_datasource.dart';

class BookingListState {
  const BookingListState({
    this.items = const [],
    this.totalCount = 0,
    this.page = 1,
    this.isLoading = false,
    this.error,
  });

  final List<StudentBookingDto> items;
  final int totalCount;
  final int page;
  final bool isLoading;
  final String? error;

  static const pageSize = 20;

  int get totalPages => (totalCount / pageSize).ceil().clamp(1, 9999);
  bool get hasMore => page < totalPages;

  BookingListState copyWith({
    List<StudentBookingDto>? items,
    int? totalCount,
    int? page,
    bool? isLoading,
    String? error,
  }) => BookingListState(
    items: items ?? this.items,
    totalCount: totalCount ?? this.totalCount,
    page: page ?? this.page,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

// status is baked in at construction — notifier always uses its own key
class BookingListNotifier extends StateNotifier<BookingListState> {
  BookingListNotifier(this._datasource, this._status)
    : super(const BookingListState());

  final BookingDatasource _datasource;
  final String _status; // '' = all tabs

  Future<void> load({bool reset = false}) async {
    if (reset) {
      state = const BookingListState(isLoading: true);
    } else {
      state = state.copyWith(isLoading: true);
    }
    try {
      final result = await _datasource.getStudentBookings(
        page: reset ? 1 : state.page,
        status: _status.isEmpty ? null : _status,
      );
      state = state.copyWith(
        items: reset ? result.items : [...state.items, ...result.items],
        totalCount: result.totalCount,
        page: reset ? 1 : state.page,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> nextPage() async {
    if (!state.hasMore || state.isLoading) return;
    state = state.copyWith(page: state.page + 1);
    await load();
  }

  Future<void> refresh() => load(reset: true);
}

// Family keyed by status string ('' = all)
final bookingListProvider =
    StateNotifierProviderFamily<BookingListNotifier, BookingListState, String>((
      ref,
      status,
    ) {
      return BookingListNotifier(ref.read(bookingDatasourceProvider), status);
    });
