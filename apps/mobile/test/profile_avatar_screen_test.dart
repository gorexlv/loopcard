import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopcard/auth/auth_service.dart';
import 'package:loopcard/l10n/app_localizations.dart';
import 'package:loopcard/screens/profile_screen.dart';
import 'package:loopcard/theme/loop_theme.dart';
import 'package:loopcard/widgets/user_avatar.dart';

void main() {
  testWidgets('profile shows generated default portrait for a new account', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final font in ['Inter', 'NotoSansSC']) {
      await (FontLoader(
        font,
      )..addFont(rootBundle.load('assets/fonts/$font-Variable.ttf'))).load();
    }
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hans',
        ),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: LoopTheme.dark,
        home: ProfileScreen(
          decks: const [],
          user: const AppUser(id: 'new-user', email: 'reader@example.com'),
          onSignOut: () async {},
          locale: null,
          themeMode: ThemeMode.dark,
          onLocaleChanged: (_) {},
          onThemeModeChanged: (_) {},
        ),
      ),
    );
    await tester.runAsync(
      () => precacheImage(
        const AssetImage(UserAvatar.defaultAsset),
        tester.element(find.byType(UserAvatar)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(UserAvatar), findsOneWidget);
    expect(tester.getSize(find.byType(UserAvatar)), const Size(72, 72));
    expect(find.text('L'), findsNothing);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('design-canvas')),
      matchesGoldenFile('goldens/profile-auto-avatar.png'),
    );
  });
}
