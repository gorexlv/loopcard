import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

enum AppAuthProvider { google, apple }

class AppUser {
  const AppUser({
    required this.id,
    this.email,
    this.displayName,
    this.avatarUrl,
  });

  final String id;
  final String? email;
  final String? displayName;
  final String? avatarUrl;
}

abstract interface class AuthService {
  AppUser? get currentUser;
  Stream<AppUser?> get userChanges;
  Future<void> signInWithEmail({
    required String email,
    required String password,
  });
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  });
  Future<void> signInWithProvider(AppAuthProvider provider);
  Future<void> signOut();
}

class SupabaseAuthService implements AuthService {
  SupabaseAuthService(this._client);

  final SupabaseClient _client;

  AppUser? _mapUser(User? user) => user == null
      ? null
      : AppUser(
          id: user.id,
          email: user.email,
          displayName:
              user.userMetadata?['full_name'] as String? ??
              user.userMetadata?['name'] as String?,
          avatarUrl:
              user.userMetadata?['avatar_url'] as String? ??
              user.userMetadata?['picture'] as String?,
        );

  @override
  AppUser? get currentUser => _mapUser(_client.auth.currentUser);

  @override
  Stream<AppUser?> get userChanges => _client.auth.onAuthStateChange.map(
    (event) => _mapUser(event.session?.user),
  );

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    await _client.auth.signUp(email: email, password: password);
  }

  @override
  Future<void> signInWithProvider(AppAuthProvider provider) async {
    await _client.auth.signInWithOAuth(
      provider == AppAuthProvider.google
          ? OAuthProvider.google
          : OAuthProvider.apple,
      redirectTo: 'io.loopcard.app://login-callback/',
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  @override
  Future<void> signOut() => _client.auth.signOut();
}

class MemoryAuthService implements AuthService {
  MemoryAuthService({AppUser? user}) : _user = user;

  factory MemoryAuthService.authenticated() => MemoryAuthService(
    user: const AppUser(id: 'local-test-user', email: 'user@loopcard.test'),
  );

  AppUser? _user;
  final _controller = StreamController<AppUser?>.broadcast();

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> get userChanges => _controller.stream;

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _user = AppUser(id: 'memory-user', email: email);
    _controller.add(_user);
  }

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) => signInWithEmail(email: email, password: password);

  @override
  Future<void> signInWithProvider(AppAuthProvider provider) async {
    _user = AppUser(
      id: 'memory-${provider.name}',
      email: '${provider.name}@loopcard.test',
    );
    _controller.add(_user);
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }
}
