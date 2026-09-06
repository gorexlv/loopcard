import 'package:flutter/foundation.dart';

import 'auth_service.dart';

/// Enables a credentialed test build without changing release authentication.
///
/// Credentials are compile-time values and are ignored unless the app is both
/// a debug build and explicitly built with TEST_AUTO_LOGIN=true.
class TestAutoLogin {
  const TestAutoLogin._();

  static const enabled = bool.fromEnvironment('TEST_AUTO_LOGIN');
  static const email = String.fromEnvironment('TEST_ACCOUNT_EMAIL');
  static const password = String.fromEnvironment('TEST_ACCOUNT_PASSWORD');

  static Future<bool> run(
    AuthService authService, {
    bool debugBuild = kDebugMode,
    bool? enabledOverride,
    String? emailOverride,
    String? passwordOverride,
  }) async {
    final shouldRun = enabledOverride ?? enabled;
    final resolvedEmail = emailOverride ?? email;
    final resolvedPassword = passwordOverride ?? password;
    if (!debugBuild ||
        !shouldRun ||
        authService.currentUser != null ||
        resolvedEmail.isEmpty ||
        resolvedPassword.isEmpty) {
      return false;
    }

    try {
      await authService.signInWithEmail(
        email: resolvedEmail,
        password: resolvedPassword,
      );
      return authService.currentUser != null;
    } catch (_) {
      // A test backend can be offline. Falling back to the normal login screen
      // keeps the build usable without weakening release authentication.
      return false;
    }
  }
}
