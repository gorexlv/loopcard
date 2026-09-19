import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopcard/ocr/photo_batch.dart';
import 'package:loopcard/screens/photo_batch_screen.dart';

void main() {
  testWidgets(
    'retake, cancel, remove and supplement submit exactly the visible photos',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final flow = FakePhotoFlow();
      List<Map<String, dynamic>>? submitted;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  submitted = await Navigator.push<List<Map<String, dynamic>>>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PhotoBatchScreen(flow: flow),
                    ),
                  );
                },
                child: const Text('开始'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('开始'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('拍照'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('补拍'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('补拍'));
      await tester.pumpAndSettle();
      expect(find.text('拍照素材 · 3/10'), findsOneWidget);
      await tester.tap(find.text('重拍').at(1));
      await tester.pumpAndSettle();
      flow.cancel = true;
      await tester.tap(find.text('补拍'));
      await tester.pumpAndSettle();
      expect(find.text('拍照素材 · 3/10'), findsOneWidget);
      flow.cancel = false;
      await tester.tap(find.text('删除').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('补拍'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('提交并定制卡片'));
      await tester.pumpAndSettle();
      expect(submitted, [
        {'id': '2', 'text': 'material 4'},
        {'id': '3', 'text': 'material 3'},
        {'id': '5', 'text': 'material 5'},
      ]);
      expect(tester.takeException(), isNull);
    },
  );
}

class FakePhotoFlow implements PhotoCaptureFlow {
  int counter = 0;
  bool cancel = false;
  @override
  Future<CapturedPhoto?> capturePhoto() async {
    if (cancel) return null;
    counter++;
    return CapturedPhoto(
      id: '$counter',
      path: '/missing-photo-$counter.jpg',
      text: 'material $counter',
    );
  }

  @override
  Future<CapturedPhoto> recognizePhoto(CapturedPhoto photo) async => photo;
  @override
  Future<List<String>?> captureWords() async => [];
}
