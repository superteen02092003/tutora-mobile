import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/features/tutor_search/data/datasources/tutor_detail_datasource.dart';
import 'package:tutora/features/tutor_search/data/models/tutor_detail_models.dart';

sealed class TutorDetailState {}

final class TutorDetailLoading extends TutorDetailState {}

final class TutorDetailLoaded extends TutorDetailState {
  TutorDetailLoaded(this.profile);
  final TutorFullProfileDto profile;
}

final class TutorDetailError extends TutorDetailState {
  TutorDetailError(this.message);
  final String message;
}

class TutorDetailController extends StateNotifier<TutorDetailState> {
  TutorDetailController(this._datasource, this._tutorId)
    : super(TutorDetailLoading()) {
    unawaited(_load());
  }

  final TutorDetailDatasource _datasource;
  final String _tutorId;

  Future<void> _load() async {
    state = TutorDetailLoading();
    try {
      final profile = await _datasource.getFullProfile(_tutorId);
      state = TutorDetailLoaded(profile);
    } catch (_) {
      state = TutorDetailError('Không tải được thông tin gia sư.');
    }
  }

  void retry() => unawaited(_load());
}

final AutoDisposeStateNotifierProviderFamily<
  TutorDetailController,
  TutorDetailState,
  String
>
tutorDetailControllerProvider = StateNotifierProvider.autoDispose
    .family<TutorDetailController, TutorDetailState, String>((ref, tutorId) {
      return TutorDetailController(
        ref.read(tutorDetailDatasourceProvider),
        tutorId,
      );
    });
