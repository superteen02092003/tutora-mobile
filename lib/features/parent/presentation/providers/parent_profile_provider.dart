import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/features/parent/data/datasources/parent_profile_datasource.dart';

class ParentProfileState {
  const ParentProfileState({
    this.profile,
    this.isLoading = false,
    this.isUploadingAvatar = false,
    this.error,
  });

  final StudentProfileDto? profile;
  final bool isLoading;
  final bool isUploadingAvatar;
  final String? error;

  ParentProfileState copyWith({
    StudentProfileDto? profile,
    bool? isLoading,
    bool? isUploadingAvatar,
    String? error,
  }) => ParentProfileState(
    profile: profile ?? this.profile,
    isLoading: isLoading ?? this.isLoading,
    isUploadingAvatar: isUploadingAvatar ?? this.isUploadingAvatar,
    error: error,
  );
}

class ParentProfileNotifier extends StateNotifier<ParentProfileState> {
  ParentProfileNotifier(this._ds) : super(const ParentProfileState()) {
    unawaited(load());
  }

  final ParentProfileDatasource _ds;

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final profile = await _ds.getProfile();
      state = state.copyWith(isLoading: false, profile: profile);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> updateProfile(UpdateProfileRequest request) async {
    try {
      await _ds.updateProfile(request);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> changePassword(ChangePasswordRequest request) async {
    try {
      await _ds.changePassword(request);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deactivateAccount() async {
    try {
      await _ds.deactivateAccount();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> uploadAvatar(String filePath) async {
    state = state.copyWith(isUploadingAvatar: true);
    try {
      final newUrl = await _ds.uploadAvatar(filePath);
      if (newUrl.isNotEmpty && state.profile != null) {
        final p = state.profile!;
        state = state.copyWith(
          isUploadingAvatar: false,
          profile: StudentProfileDto(
            userId: p.userId,
            fullName: p.fullName,
            email: p.email,
            phone: p.phone,
            birthdate: p.birthdate,
            address: p.address,
            gender: p.gender,
            avatarUrl: newUrl,
            createdAt: p.createdAt,
          ),
        );
      }
      return true;
    } catch (_) {
      state = state.copyWith(isUploadingAvatar: false);
      return false;
    }
  }
}

final parentProfileProvider =
    StateNotifierProvider<ParentProfileNotifier, ParentProfileState>(
      (ref) => ParentProfileNotifier(ref.read(parentProfileDatasourceProvider)),
    );
