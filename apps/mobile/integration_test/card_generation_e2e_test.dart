import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:loopcard/ai/card_agent.dart';
import 'package:loopcard/l10n/app_localizations.dart';
import 'package:loopcard/screens/card_agent_screen.dart';
import 'package:loopcard/theme/loop_theme.dart';

// Records the real transport unchanged; no generated content is mocked.
class RecordingAgent implements CardAgent {
  RecordingAgent(this.delegate, this.calls);
  final CardAgent delegate;
  final List<Map<String, dynamic>> calls;
  @override
  String get owner => delegate.owner;
  @override
  Future<Map<String, dynamic>> send(Map<String, dynamic> request) async {
    final clock = Stopwatch()..start();
    final record = <String, dynamic>{'request': cloneAgentJson(request)};
    calls.add(record);
    try {
      final response = await delegate.send(request);
      record['response'] = cloneAgentJson(response);
      record['status'] = 'success';
      return response;
    } catch (error) {
      record['status'] = 'failed';
      record['error'] = error.toString();
      rethrow;
    } finally {
      record['seconds'] = clock.elapsedMilliseconds / 1000;
    }
  }
}

const cases = [
  {
    'id': 'L01',
    'source': '静夜思',
    'message':
        '补齐李白这首诗，生成一张全篇卡。正面题目、作者、朝代独立分行，不要标签。背面原文、释义、字词注释分别一页，有可靠背景则另加背景页。诗句分行。',
    'generate': true,
  },
  {
    'id': 'L02',
    'source': '陋室铭',
    'message':
        '补齐全文，生成一张古文全篇卡。正面题目、作者、朝代独立分行。背面四页：原文、完整白话释义、重点词和单字的释义（含读音）、可靠背景介绍。没有可靠背景不要编造。',
    'generate': true,
  },

  {
    'id': 'W01',
    'source': 'borrow\nlend\napple',
    'message': '为这三个单词各做一张卡，补齐词性、音标、中文释义和例句。正面仅单词，不显示其他提示。背面先中文释义，再英文例句和中文翻译。',
    'generate': true,
  },
  {
    'id': 'P01',
    'source': '静夜思\n春晓',
    'message': '请根据题目列表补齐作者、完整原诗和白话释义。每首一张卡，正面题目和作者，背面完整原文、逐句白话释义。',
    'generate': true,
  },
  {
    'id': 'P02',
    'source': '登鹳雀楼',
    'message': '根据题目补齐王之涣这首诗，做两张接句背诵卡。正面上一句不泄露答案，背面下一句原文和释义。',
    'generate': true,
  },
  {
    'id': 'C01',
    'source': '陋室铭\n爱莲说',
    'message': '请根据篇目列表补齐作者、完整原文和翻译。每篇一张卡，正面题目和作者，背面完整原文、白话翻译、重点字词。不要截断原文。',
    'generate': true,
  },
  {
    'id': 'C02',
    'source': '论语·学而第一则',
    'message': '补齐学而时习之这一则的完整原文，做三张逐句卡。正面原句，背面白话翻译、重点字词、句意。说的读音请给出。',
    'generate': true,
  },
  {
    'id': 'A01',
    'source': '送别',
    'message': '根据这个题目补齐整首原文并制作诗词卡。',
    'generate': false,
  },
];

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'post OCR real CardAgent generation and card faces',
    (tester) async {
      final client = SupabaseClient(
        const String.fromEnvironment('SUPABASE_URL'),
        const String.fromEnvironment('SUPABASE_ANON_KEY'),
      );
      await client.auth.signInWithPassword(
        email: const String.fromEnvironment('TEST_ACCOUNT_EMAIL'),
        password: const String.fromEnvironment('TEST_ACCOUNT_PASSWORD'),
      );
      final results = <Map<String, dynamic>>[];
      binding.reportData = {
        'cases': results,
        'mocked': false,
        'starts_after_ocr': true,
      };
      Future<void> waitForRequest() async {
        final deadline = DateTime.now().add(const Duration(seconds: 90));
        await tester.pump();
        while (find.byType(LinearProgressIndicator).evaluate().isNotEmpty &&
            DateTime.now().isBefore(deadline)) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        await tester.pumpAndSettle();
        expect(find.byType(LinearProgressIndicator), findsNothing);
        expect(tester.takeException(), isNull);
      }

      Future<void> reveal(Finder finder) async {
        final outer = tester.state<ScrollableState>(
          find.byType(Scrollable).first,
        );
        outer.position.jumpTo(outer.position.maxScrollExtent);
        await tester.pumpAndSettle();
        for (var i = 0; finder.evaluate().isEmpty && i < 50; i++) {
          outer.position.jumpTo(
            (outer.position.pixels - 180).clamp(
              0,
              outer.position.maxScrollExtent,
            ),
          );
          await tester.pumpAndSettle();
        }
        expect(finder, findsOneWidget);
        await Scrollable.ensureVisible(tester.element(finder), alignment: 0.05);
        await tester.pumpAndSettle();
      }

      try {
        const only = String.fromEnvironment('TEST_CASES');
        for (final scenario in cases.where(
          (c) => only.isEmpty || only.split(',').contains(c['id']),
        )) {
          final id = scenario['id']! as String;
          final calls = <Map<String, dynamic>>[];
          final result = <String, dynamic>{
            'id': id,
            'source': scenario['source'],
            'calls': calls,
            'screenshots': <String>[],
          };
          results.add(result);
          final store = AgentSessionStore(
            'e2e-$id-${client.auth.currentUser!.id}',
          );
          await store.clear();
          await tester.pumpWidget(
            MaterialApp(
              key: ValueKey(id),
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
              home: CardAgentScreen(
                agent: RecordingAgent(SupabaseCardAgent(client), calls),
                store: store,
                sources: [
                  {'id': '$id-photo-1', 'text': scenario['source']},
                ],
                onSave: (_, _, _) async =>
                    throw StateError('Generation test does not save decks'),
              ),
            ),
          );
          await tester.pumpAndSettle();
          const selectPreset = bool.fromEnvironment('SELECT_PRESET');
          if (selectPreset) {
            final preset = switch (id) {
              'W01' => '简洁单词',
              'P01' || 'A01' || 'L01' => '诗词全篇',
              'P02' => '诗词接句',
              _ => '古文研读',
            };
            final choice = find.textContaining(preset).first;
            await reveal(choice);
            await tester.tap(choice);
            await tester.pumpAndSettle();
            result['selected_preset'] = preset;
          }
          await tester.enterText(
            find.byType(TextField).last,
            scenario['message']! as String,
          );
          await tester.tap(find.byTooltip('发送'));
          await waitForRequest();
          Future<void> screenshot(String name) async {
            await binding.takeScreenshot(name);
            (result['screenshots'] as List).add('$name.png');
          }

          await screenshot('$id-chat');
          if (calls.last['status'] == 'success' &&
              scenario['generate'] == true) {
            await reveal(find.text('生成卡片').last);
            await tester.tap(find.text('生成卡片').last);
            await waitForRequest();
            if (calls.last['status'] == 'success') {
              final state = (await store.load())!;
              final messages = state['messages'] as List;
              final cards = messages.last['cards'] as List;
              result['card_count'] = cards.length;
              if (cards.isNotEmpty) {
                final carousel = find.byKey(
                  ValueKey('${messages.length - 1}-${cards.length}'),
                );
                await reveal(carousel);
                for (var index = 0; index < cards.length; index++) {
                  final flip = find.descendant(
                    of: carousel,
                    matching: find.text('查看背面'),
                  );
                  await screenshot('$id-${index + 1}-front');
                  await tester.tap(flip);
                  await tester.pumpAndSettle();

                  final pager = find.descendant(
                    of: carousel,
                    matching: find.byKey(const ValueKey('literary-back-pages')),
                  );
                  final pageCount = pager.evaluate().isEmpty
                      ? 1
                      : (cards[index]['sections'] as List).length;
                  for (var page = 0; page < pageCount; page++) {
                    await screenshot('$id-${index + 1}-back-page-${page + 1}');
                    final pageScope = pager.evaluate().isEmpty
                        ? carousel
                        : find.descendant(
                            of: carousel,
                            matching: find.byKey(
                              PageStorageKey('literary-page-$page'),
                            ),
                          );
                    for (final element
                        in find
                            .descendant(
                              of: pageScope,
                              matching: find.byType(Scrollable),
                            )
                            .evaluate()) {
                      final scroll =
                          (element as StatefulElement).state as ScrollableState;
                      if (scroll.position.axis == Axis.vertical &&
                          scroll.position.maxScrollExtent > 0) {
                        scroll.position.jumpTo(scroll.position.maxScrollExtent);
                        await tester.pumpAndSettle();
                        await screenshot(
                          '$id-${index + 1}-back-page-${page + 1}-bottom',
                        );
                      }
                    }
                    if (page + 1 < pageCount) {
                      await tester.drag(pager, const Offset(-280, 0));
                      await tester.pumpAndSettle();
                    }
                  }
                  if (index + 1 < cards.length) {
                    await tester.tap(
                      find.descendant(
                        of: carousel,
                        matching: find.byTooltip('下一张'),
                      ),
                    );
                    await tester.pumpAndSettle();
                  }
                }
              } else {
                await screenshot('$id-empty-generation');
              }
            } else {
              await screenshot('$id-generation-error');
            }
          }
          result['session'] = await store.load();
          await store.clear();
          // Progress is deliberately limited to non-sensitive case metadata.
          debugPrint(
            'E2E $id: ${jsonEncode({'calls': calls.map((c) => c['status']).toList(), 'cards': result['card_count']})}',
          );
        }
      } finally {
        await client.auth.signOut();
        await client.dispose();
      }
    },
    timeout: const Timeout(Duration(minutes: 20)),
  );
}
