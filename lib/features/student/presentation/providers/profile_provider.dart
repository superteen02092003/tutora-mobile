import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/features/student/data/datasources/profile_datasource.dart';
import 'package:tutora/features/student/data/models/profile_models.dart';

class ProfileState {
  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.isUploadingAvatar = false,
    this.error,
    this.notifOn = true,
  });

  final StudentProfileDto? profile;
  final bool isLoading;
  final bool isUploadingAvatar;
  final String? error;
  final bool notifOn;

  ProfileState copyWith({
    StudentProfileDto? profile,
    bool? isLoading,
    bool? isUploadingAvatar,
    String? error,
    bool? notifOn,
  }) => ProfileState(
    profile: profile ?? this.profile,
    isLoading: isLoading ?? this.isLoading,
    isUploadingAvatar: isUploadingAvatar ?? this.isUploadingAvatar,
    error: error,
    notifOn: notifOn ?? this.notifOn,
  );
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(this._ds) : super(const ProfileState()) {
    unawaited(load());
  }

  final ProfileDatasource _ds;

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

  Future<bool> uploadAvatar(String filePath) async {
    state = state.copyWith(isUploadingAvatar: true);
    try {
      final newUrl = await _ds.uploadAvatar(filePath);
      if (newUrl.isNotEmpty && state.profile != null) {
        state = state.copyWith(
          isUploadingAvatar: false,
          profile: StudentProfileDto(
            userId: state.profile!.userId,
            fullName: state.profile!.fullName,
            email: state.profile!.email,
            phone: state.profile!.phone,
            birthdate: state.profile!.birthdate,
            address: state.profile!.address,
            gender: state.profile!.gender,
            avatarUrl: newUrl,
            createdAt: state.profile!.createdAt,
          ),
        );
      }
      return true;
    } catch (_) {
      state = state.copyWith(isUploadingAvatar: false);
      return false;
    }
  }

  void setNotif({required bool value}) =>
      state = state.copyWith(notifOn: value);
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>(
  (ref) => ProfileNotifier(ref.read(profileDatasourceProvider)),
);
