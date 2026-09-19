import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:loopcard/ai/card_agent.dart';
import 'package:loopcard/l10n/app_localizations.dart';
import 'package:loopcard/ocr/on_device_word_capture_flow.dart';
import 'package:loopcard/ocr/openrouter_text_recognizer.dart';
import 'package:loopcard/screens/photo_batch_screen.dart';
import 'package:loopcard/screens/card_agent_screen.dart';
import 'package:loopcard/theme/loop_theme.dart';
import 'ocr_fixtures.dart';

class FixtureCamera implements CameraImagePathSource {
  FixtureCamera(this.paths);
  final List<String> paths;
  int index = 0;
  @override
  Future<String?> capturePath() async => paths[index++];
}

class FixtureCropper implements CapturedImageCropper {
  @override
  Future<String?> cropPath(String path) async => path;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'iOS real cloud OCR, photo management and literary previews',
    (tester) async {
      final client = SupabaseClient(
        const String.fromEnvironment('SUPABASE_URL'),
        const String.fromEnvironment('SUPABASE_ANON_KEY'),
      );
      await client.auth.signInWithPassword(
        email: const String.fromEnvironment('TEST_ACCOUNT_EMAIL'),
        password: const String.fromEnvironment('TEST_ACCOUNT_PASSWORD'),
      );
      final dir = await Directory.systemTemp.createTemp('loopcard-ocr-');
      final paths = <String>[];
      for (final item in ocrImages.entries) {
        final file = File('${dir.path}/${item.key}.png');
        await file.writeAsBytes(base64Decode(item.value));
        paths.add(file.path);
      }
      final store = AgentSessionStore('ios-ocr-${client.auth.currentUser!.id}');
      final flow = OnDeviceWordCaptureFlow(
        camera: FixtureCamera([...paths, paths[1]]),
        cropper: FixtureCropper(),
        recognizer: OpenRouterTextRecognizer(client),
      );
      List<Map<String, dynamic>>? submitted;
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: LoopTheme.light,
          locale: const Locale('zh'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async {
                    submitted =
                        await Navigator.push<List<Map<String, dynamic>>>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PhotoBatchScreen(flow: flow),
                          ),
                        );
                    if (submitted != null && context.mounted) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CardAgentScreen(
                            agent: SupabaseCardAgent(client),
                            store: store,
                            sources: submitted!,
                            onSave: (_, _, _) async =>
                                throw StateError('This test never saves decks'),
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('开始 OCR 自动化测试'),
                ),
              ),
            ),
          ),
        ),
      );
      Future<void> settleNetwork() async {
        final until = DateTime.now().add(const Duration(seconds: 75));
        while (find.byType(LinearProgressIndicator).evaluate().isNotEmpty &&
            DateTime.now().isBefore(until)) {
          await tester.pump(const Duration(milliseconds: 200));
        }
        await tester.pumpAndSettle();
        expect(find.byType(LinearProgressIndicator), findsNothing);
        expect(tester.takeException(), isNull);
      }

      Future<void> tapVisible(Finder finder) async {
        await Scrollable.ensureVisible(tester.element(finder), alignment: 0.4);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pump();
      }

      try {
        await tester.pumpAndSettle();
        await tester.tap(find.text('开始 OCR 自动化测试'));
        await tester.pumpAndSettle();
        await binding.takeScreenshot('01-empty-upload-notice');
        for (var i = 0; i < 3; i++) {
          await tester.tap(find.text(i == 0 ? '拍照' : '补拍'));
          await tester.pump();
          await settleNetwork();
          expect(find.textContaining('识别失败 ·'), findsNothing);
        }
        expect(find.text('拍照素材 · 3/10'), findsOneWidget);
        await binding.takeScreenshot('02-three-photos-real-ocr');
        await tapVisible(find.text('校对 / 删减').first);
        await tester.pumpAndSettle();
        expect(
          find.widgetWithText(
            TextField,
            'borrow: 借入\nlend: 借出\nMay I borrow your pen?',
          ),
          findsOneWidget,
        );
        await binding.takeScreenshot('03-edit-ocr');
        await tester.enterText(find.byType(TextField), 'borrow: 借入\nlend: 借出');
        await tester.tap(find.text('完成'));
        await tester.pumpAndSettle();
        await tapVisible(find.text('删除').first);
        await tester.pumpAndSettle();
        expect(find.text('拍照素材 · 2/10'), findsOneWidget);
        await tapVisible(find.text('重拍').first);
        await settleNetwork();
        await binding.takeScreenshot('04-retake-two-photos');
        await tester.tap(find.text('提交并定制卡片'));
        await tester.pumpAndSettle();
        expect(submitted, hasLength(2));
        expect(submitted![0]['text'], contains('床前明月光'));
        expect(submitted![1]['text'], contains('學而時習之'));
        await binding.takeScreenshot('05-chat-source-handoff');
        for (final name in ['诗词全篇', '诗词接句', '古文逐句', '古文字词']) {
          if (name != '诗词全篇') {
            // Move the outer chat list, not a scrollable long card face.
            final chat = tester.state<ScrollableState>(
              find.byType(Scrollable).first,
            );
            for (
              var n = 0;
              n < 10 && find.text('常用正反面排版').evaluate().isEmpty;
              n++
            ) {
              chat.position.jumpTo(chat.position.maxScrollExtent);
              await tester.pumpAndSettle();
            }
            await tapVisible(find.text('常用正反面排版'));
            await tester.pumpAndSettle();
          }
          await tapVisible(find.textContaining(name).first);
          await tester.pumpAndSettle();
          await Scrollable.ensureVisible(
            tester.element(find.text('查看背面').last),
            alignment: 0.3,
          );
          await tester.pumpAndSettle();
          await binding.takeScreenshot('06-preview-$name-front');
          await tapVisible(find.text('查看背面').last);
          await tester.pumpAndSettle();
          await binding.takeScreenshot('06-preview-$name-back');
          expect(tester.takeException(), isNull);
          final state = (await store.load())!;
          expect(state['messages'].last['example'], isTrue);
        }
      } finally {
        await client.auth.signOut();
        await client.dispose();
        await dir.delete(recursive: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
