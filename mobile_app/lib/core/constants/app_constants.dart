/// Central application configuration.
///
/// IMPORTANT (SIH integration contract):
/// - `apiBaseUrl` is the ONLY place the NestJS base URL is configured.
/// - Endpoints are NOT hard-coded here; repositories define capability
///   interfaces and `RealXxxRepository` implementations map them to the
///   final NestJS routes once Member 1 finalises the API contract.
class AppConstants {
  AppConstants._();

  /// Unified Legal Metrology Backend API base URL (FastAPI core on port 8000).
  ///
  /// Override per-environment with:
  ///   flutter run --dart-define=API_BASE_URL=http://localhost:8000/api/v1
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  /// Local development / Windows Desktop base URL
  static const String localDesktopBaseUrl = 'http://localhost:8000/api/v1';

  /// Request timeouts.
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Secure-storage keys. Tokens are never persisted in plain text.
  static const String accessTokenKey = 'lm.access_token';
  static const String refreshTokenKey = 'lm.refresh_token';
  static const String userIdKey = 'lm.user_id';

  static const String appName = 'Legal Metrology';
  static const String appTagline = 'Legal Metrology Act, 2011 — Digital Enforcement';
}
