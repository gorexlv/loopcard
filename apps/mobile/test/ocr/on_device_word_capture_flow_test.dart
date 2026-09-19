import 'package:flutter_test/flutter_test.dart';
import 'package:loopcard/ocr/on_device_word_capture_flow.dart';

void main() {
  test('extracts English words from locally recognized lines', () async {
    final recognizer = _FakeRecognizer(['Borrow a charger', 'lend money']);
    final flow = OnDeviceWordCaptureFlow(
      camera: _FakeCamera('/tmp/card.jpg'),
      cropper: const _FakeCropper('/tmp/cropped.jpg'),
      recognizer: recognizer,
    );

    expect(await flow.captureWords(), ['Borrow', 'charger', 'lend', 'money']);
    expect(recognizer.lastImagePath, '/tmp/cropped.jpg');
  });

  test('returns null when camera capture is cancelled', () async {
    final flow = OnDeviceWordCaptureFlow(
      camera: _FakeCamera(null),
      cropper: const _FakeCropper('/tmp/cropped.jpg'),
      recognizer: _FakeRecognizer(const []),
    );

    expect(await flow.captureWords(), isNull);
  });

  test('returns null when region selection is cancelled', () async {
    final recognizer = _FakeRecognizer(const []);
    final flow = OnDeviceWordCaptureFlow(
      camera: _FakeCamera('/tmp/card.jpg'),
      cropper: const _FakeCropper(null),
      recognizer: recognizer,
    );

    expect(await flow.captureWords(), isNull);
    expect(recognizer.lastImagePath, isNull);
  });
}

class _FakeCamera implements CameraImagePathSource {
  const _FakeCamera(this.path);

  final String? path;

  @override
  Future<String?> capturePath() async => path;
}

class _FakeRecognizer implements LocalTextRecognizer {
  _FakeRecognizer(this.lines);

  final List<String> lines;
  String? lastImagePath;

  @override
  Future<List<String>> recognizeLines(String imagePath) async {
    lastImagePath = imagePath;
    return lines;
  }
}

class _FakeCropper implements CapturedImageCropper {
  const _FakeCropper(this.path);

  final String? path;

  @override
  Future<String?> cropPath(String imagePath) async => path;
}
