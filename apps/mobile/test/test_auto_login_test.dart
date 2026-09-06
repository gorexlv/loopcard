import 'package:flutter_test/flutter_test.dart';
import 'package:loopcard/auth/auth_service.dart';
import 'package:loopcard/auth/test_auto_login.dart';

void main() {
  test('signs in only when an explicit debug test build enables it', () async {
    final auth = MemoryAuthService();

    final signedIn = await TestAutoLogin.run(
      auth,
      debugBuild: true,
      enabledOverride: true,
      emailOverride: 'apk-test@loopcard.app',
      passwordOverride: 'password123',
    );

    expect(signedIn, isTrue);
    expect(auth.currentUser?.email, 'apk-test@loopcard.app');
  });

  test('never signs in when the build is not debug', () async {
    final auth = MemoryAuthService();

    final signedIn = await TestAutoLogin.run(
      auth,
      debugBuild: false,
      enabledOverride: true,
      emailOverride: 'apk-test@loopcard.app',
      passwordOverride: 'password123',
    );

    expect(signedIn, isFalse);
    expect(auth.currentUser, isNull);
  });
}
