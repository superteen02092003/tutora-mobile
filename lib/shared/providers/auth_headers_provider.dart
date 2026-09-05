import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/storage/secure_storage.dart';

/// Header `Authorization` cho ảnh tải bằng `Image.network`.
final AutoDisposeFutureProvider<Map<String, String>> authImageHeadersProvider =
    FutureProvider.autoDispose<Map<String, String>>((ref) async {
      final token = await ref.read(secureStorageProvider).getAccessToken();
      return token == null ? const {} : {'Authorization': 'Bearer $token'};
    });
