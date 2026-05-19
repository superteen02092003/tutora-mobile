import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._ref);

  final Ref _ref;

  bool _isRefreshing = false;
  final List<_PendingRequest> _queue = [];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _ref.read(secureStorageProvider).getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    final storage = _ref.read(secureStorageProvider);
    final refreshToken = await storage.getRefreshToken();

    if (refreshToken == null) {
      await _handleAuthFailure(storage, handler, err);
      return;
    }

    // Single-flight
    if (_isRefreshing) {
      final completer = _PendingRequest(err.requestOptions);
      _queue.add(completer);
      final result = await completer.future;
      if (result == null) {
        handler.next(err);
      } else {
        handler.resolve(result);
      }
      return;
    }

    _isRefreshing = true;

    try {
      // Dùng Dio riêng để tránh interceptor loop
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: err.requestOptions.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: const {'Content-Type': 'application/json'},
        ),
      );

      final response = await refreshDio.post<Map<String, dynamic>>(
        '/api/token/refresh',
        data: {'refreshToken': refreshToken},
      );

      final content = response.data?['content'] as Map<String, dynamic>?;
      final newAccess = content?['token'] as String?;
      final newRefresh = content?['refreshToken'] as String?;

      if (newAccess == null || newRefresh == null) {
        throw Exception('Invalid refresh response');
      }

      await storage.saveTokens(access: newAccess, refresh: newRefresh);

      // Retry request gốc với token mới
      final retried = await _retry(err.requestOptions, newAccess);
      _resolveQueue(newAccess);
      handler.resolve(retried);
    } catch (_) {
      _rejectQueue();
      await _handleAuthFailure(storage, handler, err);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<Response<dynamic>> _retry(
    RequestOptions options,
    String token,
  ) async {
    final retryDio = Dio(BaseOptions(baseUrl: options.baseUrl));
    return retryDio.request<dynamic>(
      options.path,
      data: options.data,
      queryParameters: options.queryParameters,
      options: Options(
        method: options.method,
        headers: {
          ...options.headers,
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  void _resolveQueue(String token) {
    for (final pending in _queue) {
      unawaited(
        _retry(
          pending.options,
          token,
        ).then(pending.resolve).catchError((Object _) => pending.resolve(null)),
      );
    }
    _queue.clear();
  }

  void _rejectQueue() {
    for (final pending in _queue) {
      pending.resolve(null);
    }
    _queue.clear();
  }

  Future<void> _handleAuthFailure(
    SecureStorageService storage,
    ErrorInterceptorHandler handler,
    DioException err,
  ) async {
    await storage.clearTokens();
    final ctx = _ref.read(_navigatorKeyProvider).currentContext;
    if (ctx != null && ctx.mounted) {
      ctx.go(AppRoutes.login);
    }
    handler.next(err);
  }
}

final _navigatorKeyProvider = Provider<GlobalKey<NavigatorState>>(
  (_) => throw UnimplementedError('navigatorKeyProvider must be overridden'),
);

// Provider public để app_router / main.dart override
final Provider<GlobalKey<NavigatorState>> navigatorKeyProvider =
    _navigatorKeyProvider;

class _PendingRequest {
  _PendingRequest(this.options);

  final RequestOptions options;
  final Completer<Response<dynamic>?> _completer = Completer();

  Future<Response<dynamic>?> get future => _completer.future;

  void resolve(Response<dynamic>? response) {
    if (!_completer.isCompleted) _completer.complete(response);
  }
}
