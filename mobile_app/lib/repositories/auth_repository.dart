import '../models/user.dart';

/// Authentication capability contract.
///
/// Designed to be backed by Keycloak (OIDC) through NestJS. The mock
/// implementation authenticates against a seeded demo user list; the real
/// implementation will perform OIDC authorization-code + PKCE flows via
/// Member 1's token endpoint. UI never talks to Keycloak directly.
abstract class AuthRepository {
  /// Authenticates and returns the user with roles from the backend.
  /// Throws [UnauthorizedException] on invalid credentials.
  Future<AuthResult> login({required String username, required String password});

  /// Exchanges a refresh token for a new access token.
  Future<AuthResult> refresh({required String refreshToken});

  /// Currently authenticated user (null when signed out).
  Future<User?> currentUser();

  /// Revokes tokens server-side and clears local secure storage.
  Future<void> logout();

  /// Business self-registration. Returns the created account's user.
  /// Inspector accounts CANNOT be created here — they are provisioned by
  /// the administration/backend (Member 1). This method only ever yields
  /// BUSINESS-role users.
  Future<User> registerBusinessAccount({
    required String username,
    required String password,
    required String fullName,
    required String email,
    required String phone,
  });
}

class AuthResult {
  const AuthResult({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    this.expiresInSeconds,
  });

  final User user;
  final String accessToken;
  final String refreshToken;

  /// OIDC `expires_in` when the backend provides it.
  final int? expiresInSeconds;
}
