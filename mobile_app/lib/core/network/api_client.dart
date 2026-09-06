import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';
import '../errors/app_exception.dart';

/// Contract for secure token persistence (Keycloak-compatible).
///
/// Real implementation: flutter_secure_storage (Android Keystore-backed).
/// This abstraction exists so a future OIDC/Keycloak client can replace
/// the storage + refresh flow without touching UI or repositories.
abstract class TokenStorage {
  Future<void> saveTokens({required String accessToken, required String refreshToken});
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> saveUserId(String userId);
  Future<String?> readUserId();
  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: AppConstants.accessTokenKey, value: accessToken);
    await _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken);
  }

  @override
  Future<String?> readAccessToken() =>
      _storage.read(key: AppConstants.accessTokenKey);

  @override
  Future<String?> readRefreshToken() =>
      _storage.read(key: AppConstants.refreshTokenKey);

  @override
  Future<void> saveUserId(String userId) =>
      _storage.write(key: AppConstants.userIdKey, value: userId);

  @override
  Future<String?> readUserId() => _storage.read(key: AppConstants.userIdKey);

  @override
  Future<void> clear() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    await _storage.delete(key: AppConstants.userIdKey);
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => SecureTokenStorage());

/// Dio-based API client with JWT bearer injection and 401 refresh-once logic.
///
/// In DEMO mode the mock repositories never construct this client, so no
/// network calls happen at all. When NestJS goes live, `apiClientProvider`
/// is consumed by the `RealXxxRepository` implementations only.
class ApiClient {
  ApiClient(this._tokenStorage);

  final TokenStorage _tokenStorage;

  Dio? _dio;
  Dio get dio => _dio ??= _build();

  Dio _build() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        contentType: 'application/json',
      ),
    );

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokenStorage.readAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Single-attempt refresh on 401: never loop.
        if (error.response?.statusCode == 401) {
          final refreshed = await _tryRefresh();
          if (refreshed) {
            final retry = await _retry(error.requestOptions);
            return handler.resolve(retry);
          }
        }
        handler.next(error);
      },
    ));

    return dio;
  }

  /// TODO(backend-integration): replace with the real Keycloak token endpoint
  /// once Member 1 finalises OIDC configuration. Returns false in demo mode.
  Future<bool> _tryRefresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: AppConstants.apiBaseUrl,
          connectTimeout: AppConstants.connectTimeout,
          receiveTimeout: AppConstants.receiveTimeout,
          contentType: 'application/json',
        ),
      );
      final response = await refreshDio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = response.data;
      if (data is Map && data['accessToken'] is String) {
        await _tokenStorage.saveTokens(
          accessToken: data['accessToken'] as String,
          refreshToken: (data['refreshToken'] as String?) ?? refreshToken,
        );
        return true;
      }
      return false;
    } catch (_) {
      await _tokenStorage.clear();
      throw const UnauthorizedException();
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final token = await _tokenStorage.readAccessToken();
    final options = Options(
      method: requestOptions.method,
      headers: <String, dynamic>{...requestOptions.headers}
        ..['Authorization'] = 'Bearer $token',
    );
    return dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(tokenStorageProvider)),
);
