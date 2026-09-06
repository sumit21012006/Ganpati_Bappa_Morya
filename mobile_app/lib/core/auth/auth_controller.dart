import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart' show TokenStorage, tokenStorageProvider;
import '../../di/providers.dart';
import '../../models/user.dart';
import '../../repositories/auth_repository.dart';

/// Auth status used by the router to gate protected routes.
enum AuthStatus { initial, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.isRestoring = true,
  });

  final AuthStatus status;
  final User? user;

  /// True while the session is being restored from secure storage at
  /// startup (drives the splash screen).
  final bool isRestoring;

  AuthState copyWith({AuthStatus? status, User? user, bool? isRestoring}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isRestoring: isRestoring ?? this.isRestoring,
    );
  }

  bool get isInspector => user?.isInspector ?? false;
  bool get isBusiness => user?.isBusiness ?? false;
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._authRepository, this._tokenStorage) : super(const AuthState()) {
    _restoreSession();
  }

  final AuthRepository _authRepository;
  final TokenStorage _tokenStorage;

  /// Restores the persisted session at startup (splash phase).
  Future<void> _restoreSession() async {
    try {
      final accessToken = await _tokenStorage.readAccessToken();
      final userId = await _tokenStorage.readUserId();
      User? user;

      if (accessToken != null && accessToken.isNotEmpty) {
        user = await _authRepository.currentUser();
        // Fallback to cached user id when /me is unavailable (mock mode).
        user ??= userId == null ? null : User(id: userId, name: '', role: UserRole.business);
      }

      if (user != null) {
        state = AuthState(status: AuthStatus.authenticated, user: user, isRestoring: false);
      } else {
        state = AuthState(status: AuthStatus.unauthenticated, isRestoring: false);
      }
    } catch (_) {
      state = AuthState(status: AuthStatus.unauthenticated, isRestoring: false);
    }
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(status: AuthStatus.initial);
    final result = await _authRepository.login(username: username, password: password);
    await _tokenStorage.saveTokens(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    );
    await _tokenStorage.saveUserId(result.user.id);
    state = AuthState(status: AuthStatus.authenticated, user: result.user, isRestoring: false);
  }

  Future<void> registerBusinessAccount({
    required String username,
    required String password,
    required String fullName,
    required String email,
    required String phone,
  }) async {
    final user = await _authRepository.registerBusinessAccount(
      username: username,
      password: password,
      fullName: fullName,
      email: email,
      phone: phone,
    );
    // Mock backend returns session tokens via login semantics.
    final result = await _authRepository.login(username: email, password: password);
    await _tokenStorage.saveTokens(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    );
    await _tokenStorage.saveUserId(result.user.id);
    state = AuthState(status: AuthStatus.authenticated, user: user, isRestoring: false);
  }

  Future<void> logout() async {
    try {
      await _authRepository.logout();
    } finally {
      await _tokenStorage.clear();
      state = const AuthState(status: AuthStatus.unauthenticated, isRestoring: false);
    }
  }

  /// Handles a global 401: clears session so the router redirects to login.
  Future<void> handleUnauthorized() async {
    await _tokenStorage.clear();
    state = AuthState(status: AuthStatus.unauthenticated, isRestoring: false);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    ref.watch(authRepositoryProvider),
    ref.watch(tokenStorageProvider),
  );
});

/// Convenience stream for go_router refresh listening.
final authStatusProvider = Provider<AuthStatus>(
  (ref) => ref.watch(authControllerProvider.select((s) => s.status)),
);
