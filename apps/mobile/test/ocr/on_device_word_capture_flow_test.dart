import 'package:flutter_test/flutter_test.dart';
import 'package:loopcard/ocr/on_device_word_capture_flow.dart';

void main() {
  test('extracts English words from locally recognized lines', () async {
    final flow = OnDeviceWordCaptureFlow(
      camera: _FakeCamera('/tmp/card.jpg'),
      recognizer: _FakeRecognizer(['Borrow a charger', 'lend money']),
    );

    expect(await flow.captureWords(), ['Borrow', 'charger', 'lend', 'money']);
  });

  test('returns null when camera capture is cancelled', () async {
    final flow = OnDeviceWordCaptureFlow(
      camera: _FakeCamera(null),
      recognizer: _FakeRecognizer(const []),
    );

    expect(await flow.captureWords(), isNull);
  });
}

class _FakeCamera implements CameraImagePathSource {
  const _FakeCamera(this.path);

  final String? path;

  @override
  Future<String?> capturePath() async => path;
}

class _FakeRecognizer implements LocalTextRecognizer {
  const _FakeRecognizer(this.lines);

  final List<String> lines;

  @override
  Future<List<String>> recognizeLines(String imagePath) async => lines;
}
