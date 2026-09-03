import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/features/tutor/data/datasources/tutor_profile_datasource.dart';
import 'package:tutora/features/tutor/data/models/tutor_profile_models.dart';

class TutorProfileState {
  const TutorProfileState({
    this.user,
    this.progress,
    this.certificates = const [],
    this.isLoading = false,
    this.isUploadingAvatar = false,
    this.isSaving = false,
    this.notifOn = true,
    this.error,
  });

  final TutorUserDto? user;
  final TutorVerificationProgressDto? progress;
  final List<CertificateDto> certificates;
  final bool isLoading;
  final bool isUploadingAvatar;
  final bool isSaving;
  final bool notifOn;
  final String? error;

  TutorProfileState copyWith({
    TutorUserDto? user,
    TutorVerificationProgressDto? progress,
    List<CertificateDto>? certificates,
    bool? isLoading,
    bool? isUploadingAvatar,
    bool? isSaving,
    bool? notifOn,
    String? error,
  }) => TutorProfileState(
    user: user ?? this.user,
    progress: progress ?? this.progress,
    certificates: certificates ?? this.certificates,
    isLoading: isLoading ?? this.isLoading,
    isUploadingAvatar: isUploadingAvatar ?? this.isUploadingAvatar,
    isSaving: isSaving ?? this.isSaving,
    notifOn: notifOn ?? this.notifOn,
    error: error,
  );
}

class TutorProfileNotifier extends StateNotifier<TutorProfileState> {
  TutorProfileNotifier(this._ds) : super(const TutorProfileState()) {
    unawaited(load());
  }

  final TutorProfileDatasource _ds;

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final results = await Future.wait([
        _ds.getUser(),
        _ds.getVerificationProgress(),
      ]);
      state = state.copyWith(
        isLoading: false,
        user: results[0] as TutorUserDto,
        progress: results[1] as TutorVerificationProgressDto,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> updateUser(UpdateTutorUserRequest request) async {
    state = state.copyWith(isSaving: true);
    try {
      await _ds.updateUser(request);
      await load();
      return true;
    } catch (_) {
      state = state.copyWith(isSaving: false);
      return false;
    }
  }

  Future<bool> uploadAvatar(String filePath) async {
    state = state.copyWith(isUploadingAvatar: true);
    try {
      final newUrl = await _ds.uploadAvatar(filePath);
      if (newUrl.isNotEmpty && state.user != null) {
        final u = state.user!;
        state = state.copyWith(
          isUploadingAvatar: false,
          user: TutorUserDto(
            userId: u.userId,
            fullName: u.fullName,
            email: u.email,
            phone: u.phone,
            birthdate: u.birthdate,
            address: u.address,
            gender: u.gender,
            avatarUrl: newUrl,
            createdAt: u.createdAt,
          ),
        );
      } else {
        state = state.copyWith(isUploadingAvatar: false);
      }
      return true;
    } catch (_) {
      state = state.copyWith(isUploadingAvatar: false);
      return false;
    }
  }

  Future<bool> changePassword(TutorChangePasswordRequest request) async {
    try {
      await _ds.changePassword(request);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// `pendingApproval` = hồ sơ đã duyệt trước đó nên sửa đổi phải chờ Admin
  /// xác nhận lại; `ok` = false là lỗi mạng/validate.
  Future<({bool ok, bool pendingApproval})> updateIntroduction(
    UpdateIntroductionRequest request,
  ) => _saveProfilePart(() => _ds.updateIntroduction(request));

  Future<({bool ok, bool pendingApproval})> updatePricing(
    UpdatePricingRequest request,
  ) => _saveProfilePart(() => _ds.updatePricing(request));

  Future<({bool ok, bool pendingApproval})> _saveProfilePart(
    Future<bool> Function() save,
  ) async {
    state = state.copyWith(isSaving: true);
    try {
      final pending = await save();
      final progress = await _ds.getVerificationProgress();
      state = state.copyWith(isSaving: false, progress: progress);
      return (ok: true, pendingApproval: pending);
    } catch (_) {
      state = state.copyWith(isSaving: false);
      return (ok: false, pendingApproval: false);
    }
  }

  Future<bool> submitForReview() async {
    state = state.copyWith(isSaving: true);
    try {
      await _ds.submitForReview();
      state = state.copyWith(isSaving: false);
      return true;
    } catch (_) {
      state = state.copyWith(isSaving: false);
      return false;
    }
  }

  Future<void> loadCertificates() async {
    try {
      final certs = await _ds.getCertificates();
      state = state.copyWith(certificates: certs);
    } catch (_) {}
  }

  Future<bool> deleteCertificate(String certId) async {
    try {
      await _ds.deleteCertificate(certId);
      state = state.copyWith(
        certificates: state.certificates
            .where((c) => c.certificateId != certId)
            .toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> uploadCertificate({
    required String filePath,
    required String certificateName,
    required String certificateType,
    required String issuingOrganization,
    int? yearIssued,
  }) async {
    state = state.copyWith(isSaving: true);
    try {
      await _ds.uploadCertificate(
        filePath: filePath,
        certificateName: certificateName,
        certificateType: certificateType,
        issuingOrganization: issuingOrganization,
        yearIssued: yearIssued,
      );
      await loadCertificates();
      state = state.copyWith(isSaving: false);
      return true;
    } catch (_) {
      state = state.copyWith(isSaving: false);
      return false;
    }
  }

  void setNotif({required bool value}) =>
      state = state.copyWith(notifOn: value);
}

final tutorProfileProvider =
    StateNotifierProvider<TutorProfileNotifier, TutorProfileState>(
      (ref) => TutorProfileNotifier(
        ref.read(tutorProfileDatasourceProvider),
      ),
    );

/// Hồ sơ nghề nghiệp gia sư (headline, bio, hình thức dạy).
final AutoDisposeFutureProvider<TutorSelfProfileDto> tutorSelfProfileProvider =
    FutureProvider.autoDispose<TutorSelfProfileDto>((ref) {
      return ref.read(tutorProfileDatasourceProvider).getSelfProfile();
    });

/// Cờ "đang nhận yêu cầu đặt lịch" — endpoint riêng, không nằm trong hồ sơ.
final AutoDisposeFutureProvider<bool> tutorAcceptingBookingsProvider =
    FutureProvider.autoDispose<bool>((ref) {
      return ref.read(tutorProfileDatasourceProvider).getAcceptingBookings();
    });
