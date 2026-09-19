import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:loopcard/ocr/openrouter_text_recognizer.dart';
import 'package:loopcard/ocr/word_capture_flow.dart';

void main() {
  test('requires a user session before reading or uploading a photo', () async {
    final client = SupabaseClient('http://127.0.0.1:1', 'public-test-key');
    addTearDown(client.dispose);
    await expectLater(
      OpenRouterTextRecognizer(client).recognizeLines('/does-not-exist.jpg'),
      throwsA(isA<OcrException>()),
    );
  });
}
