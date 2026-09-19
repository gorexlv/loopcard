import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopcard/auth/auth_service.dart';
import 'package:loopcard/widgets/user_avatar.dart';

void main() {
  testWidgets('new accounts and invalid URLs show bundled portrait', (
    tester,
  ) async {
    for (final url in <String?>[
      null,
      '',
      ' ',
      'not-a-url',
      'file:///private',
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: UserAvatar(
            user: AppUser(id: 'new-user', avatarUrl: url),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as AssetImage).assetName, UserAvatar.defaultAsset);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('remote failure keeps default portrait without an error', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: UserAvatar(
          user: AppUser(
            id: 'existing',
            avatarUrl: 'https://example.test/avatar.png',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    final asset = tester.widgetList<Image>(find.byType(Image)).first;
    expect((asset.image as AssetImage).assetName, UserAvatar.defaultAsset);
  });
}
