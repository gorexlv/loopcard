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

abstract interface class AutomaticAvatarService {
  Future<AppUser?> ensureAvatar(AppUser user);
}

class SupabaseAuthService implements AuthService, AutomaticAvatarService {
  SupabaseAuthService(this._client);

  final SupabaseClient _client;
  final Map<String, String> _avatarUrls = {};
  final Map<String, Future<AppUser?>> _avatarRequests = {};

  @override
  Future<AppUser?> ensureAvatar(AppUser user) {
    if (user.avatarUrl?.trim().isNotEmpty ?? false) {
      return Future.value(user);
    }
    return _avatarRequests.putIfAbsent(user.id, () async {
      try {
        final result = await _client.functions.invoke('generate-avatar');
        final url = result.data is Map ? result.data['avatar_url'] : null;
        if (url is String && url.trim().isNotEmpty) {
          // Edge Functions may use an internal Docker host locally. Resolve
          // generated storage objects using the mobile client's public host.
          const prefix = '/storage/v1/object/public/generated-avatars/';
          final path = Uri.tryParse(url)?.path;
          _avatarUrls[user.id] = path != null && path.startsWith(prefix)
              ? _client.storage
                    .from('generated-avatars')
                    .getPublicUrl(path.substring(prefix.length))
              : url;
        }
        return _client.auth.currentUser?.id == user.id ? currentUser : null;
      } catch (_) {
        // Avatar availability must never prevent sign-in or onboarding.
        return null;
      } finally {
        _avatarRequests.remove(user.id);
      }
    });
  }

  String? _nonEmpty(dynamic value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;

  AppUser? _mapUser(User? user) => user == null
      ? null
      : AppUser(
          id: user.id,
          email: user.email,
          displayName:
              user.userMetadata?['full_name'] as String? ??
              user.userMetadata?['name'] as String?,
          avatarUrl:
              _nonEmpty(user.userMetadata?['avatar_url']) ??
              _nonEmpty(user.userMetadata?['picture']) ??
              _avatarUrls[user.id],
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
