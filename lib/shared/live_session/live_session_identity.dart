import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/storage/secure_storage.dart';
import 'package:tutora/shared/live_session/live_session_models.dart';

final _uuidNPattern = RegExp(r'^[0-9a-f]{32}$', caseSensitive: false);

/// Tạo/đọc danh tính thiết bị cho phiên học Agora.
///
/// deviceId (UUID .NET "N", 32 hex) được lưu bền qua secure storage; participationId
/// tạo mới mỗi lần join.
class LiveSessionIdentityFactory {
  const LiveSessionIdentityFactory(this._storage);

  final SecureStorageService _storage;

  Future<LiveSessionIdentity> build() async {
    final deviceId = await _ensureDeviceId();
    return LiveSessionIdentity(
      participationId: _uuidN(),
      deviceId: deviceId,
      deviceLabel: _deviceLabel(),
    );
  }

  Future<String> _ensureDeviceId() async {
    try {
      final stored = await _storage.getLiveSessionDeviceId();
      if (stored != null && _uuidNPattern.hasMatch(stored)) return stored;
    } catch (_) {
      // Storage có thể bị chặn; tạo id trong bộ nhớ cho phiên hiện tại.
    }
    final created = _uuidN();
    try {
      await _storage.saveLiveSessionDeviceId(created);
    } catch (_) {
      // Best-effort.
    }
    return created;
  }

  /// UUID v4 dạng .NET "N" — 32 hex, không dấu gạch ngang.
  static String _uuidN() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static String _deviceLabel() {
    String platform;
    if (kIsWeb) {
      platform = 'Web';
    } else if (Platform.isAndroid) {
      platform = 'Android';
    } else if (Platform.isIOS) {
      platform = 'iOS';
    } else {
      platform = 'Mobile';
    }
    final label = 'Tutora · $platform';
    return label.length > 120 ? label.substring(0, 120) : label;
  }
}

final liveSessionIdentityFactoryProvider = Provider<LiveSessionIdentityFactory>(
  (ref) {
    return LiveSessionIdentityFactory(ref.read(secureStorageProvider));
  },
);
