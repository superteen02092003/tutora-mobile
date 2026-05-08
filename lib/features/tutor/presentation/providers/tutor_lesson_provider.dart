import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/features/tutor/data/datasources/tutor_lesson_datasource.dart';
import 'package:tutora/features/tutor/data/models/tutor_lesson_models.dart';

// ── Schedule (calendar + list) ─────────────────────────────────────────────

class TutorScheduleState {
  const TutorScheduleState({
    this.lessons = const [],
    this.isLoading = false,
    this.error,
  });

  final List<TutorLessonDto> lessons;
  final bool isLoading;
  final String? error;

  TutorScheduleState copyWith({
    List<TutorLessonDto>? lessons,
    bool? isLoading,
    String? error,
  }) => TutorScheduleState(
    lessons: lessons ?? this.lessons,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

class TutorScheduleNotifier extends StateNotifier<TutorScheduleState> {
  TutorScheduleNotifier(this._ds) : super(const TutorScheduleState()) {
    unawaited(loadCurrentMonth());
  }

  final TutorLessonDatasource _ds;

  Future<void> loadCurrentMonth() async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month).toIso8601String();
    final to = DateTime(now.year, now.month + 1, 0).toIso8601String();
    await loadRange(from: from, to: to);
  }

  Future<void> loadRange({required String from, required String to}) async {
    state = state.copyWith(isLoading: true);
    try {
      final lessons = await _ds.getCalendar(from: from, to: to);
      state = state.copyWith(isLoading: false, lessons: lessons);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final tutorScheduleProvider =
    StateNotifierProvider<TutorScheduleNotifier, TutorScheduleState>(
      (ref) => TutorScheduleNotifier(ref.read(tutorLessonDatasourceProvider)),
    );

// ── Lesson list (FE13) ─────────────────────────────────────────────────────

class TutorLessonListState {
  const TutorLessonListState({
    this.lessons = const [],
    this.isLoading = false,
    this.error,
  });

  final List<TutorLessonDto> lessons;
  final bool isLoading;
  final String? error;

  TutorLessonListState copyWith({
    List<TutorLessonDto>? lessons,
    bool? isLoading,
    String? error,
  }) => TutorLessonListState(
    lessons: lessons ?? this.lessons,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

class TutorLessonListNotifier extends StateNotifier<TutorLessonListState> {
  TutorLessonListNotifier(this._ds) : super(const TutorLessonListState()) {
    unawaited(load());
  }

  final TutorLessonDatasource _ds;

  Future<void> load({String? status, String? from, String? to}) async {
    state = state.copyWith(isLoading: true);
    try {
      final lessons = await _ds.getLessons(
        status: status,
        from: from,
        to: to,
      );
      state = state.copyWith(isLoading: false, lessons: lessons);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final tutorLessonListProvider =
    StateNotifierProvider<TutorLessonListNotifier, TutorLessonListState>(
      (ref) => TutorLessonListNotifier(ref.read(tutorLessonDatasourceProvider)),
    );

// ── Availability (FE14) ────────────────────────────────────────────────────

class TutorAvailabilityState {
  const TutorAvailabilityState({
    this.slots = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  final List<TutorAvailabilityDto> slots;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  TutorAvailabilityState copyWith({
    List<TutorAvailabilityDto>? slots,
    bool? isLoading,
    bool? isSaving,
    String? error,
  }) => TutorAvailabilityState(
    slots: slots ?? this.slots,
    isLoading: isLoading ?? this.isLoading,
    isSaving: isSaving ?? this.isSaving,
    error: error,
  );
}

class TutorAvailabilityNotifier extends StateNotifier<TutorAvailabilityState> {
  TutorAvailabilityNotifier(this._ds) : super(const TutorAvailabilityState()) {
    unawaited(load());
  }

  final TutorLessonDatasource _ds;

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final slots = await _ds.getAvailability();
      state = state.copyWith(isLoading: false, slots: slots);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> addSlot(CreateAvailabilityRequest request) async {
    state = state.copyWith(isSaving: true);
    try {
      await _ds.createAvailability(request);
      await load();
      return true;
    } catch (_) {
      state = state.copyWith(isSaving: false);
      return false;
    }
  }

  Future<bool> removeSlot(int availabilityId) async {
    try {
      await _ds.deleteAvailability(availabilityId);
      state = state.copyWith(
        slots: state.slots
            .where((s) => s.availabilityId != availabilityId)
            .toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

final tutorAvailabilityProvider =
    StateNotifierProvider<TutorAvailabilityNotifier, TutorAvailabilityState>(
      (ref) =>
          TutorAvailabilityNotifier(ref.read(tutorLessonDatasourceProvider)),
    );
