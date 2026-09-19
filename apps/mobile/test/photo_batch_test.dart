import 'package:flutter_test/flutter_test.dart';
import 'package:loopcard/ocr/photo_batch.dart';
import 'package:loopcard/ocr/on_device_word_capture_flow.dart';

CapturedPhoto photo(String id, {bool error = false, String? text}) =>
    CapturedPhoto(
      id: id,
      path: '/$id.jpg',
      text: text ?? 'text $id',
      error: error,
    );
void main() {
  test('replace, delete, supplement preserve final batch and provenance', () {
    final batch = PhotoBatch()
      ..add(photo('1'))
      ..add(photo('2'))
      ..add(photo('3'));
    batch.replace('2', photo('replacement', text: 'new text'));
    batch.remove('1');
    batch.add(photo('4'));
    expect(batch.sources, [
      {'id': '2', 'text': 'new text'},
      {'id': '3', 'text': 'text 3'},
      {'id': '4', 'text': 'text 4'},
    ]);
    expect(batch.photos.first.path, '/replacement.jpg');
    expect(batch.canSubmit, isTrue);
  });
  test('empty, failed, oversized and blank batches cannot submit', () {
    final batch = PhotoBatch();
    expect(batch.canSubmit, isFalse);
    batch.add(photo('1', error: true));
    expect(batch.canSubmit, isFalse);
    batch.replace('1', photo('1', text: ''));
    expect(batch.canSubmit, isFalse);
    batch.replace('1', photo('1', text: 'x' * 4001));
    expect(batch.canSubmit, isFalse);
    batch.replace('1', photo('1'));
    expect(batch.canSubmit, isTrue);
    batch.remove('1');
    expect(batch.canSubmit, isFalse);
  });
  test(
    'recognition failures retain photo and can retry without new capture',
    () async {
      final recognizer = RetryRecognizer();
      final flow = OnDeviceWordCaptureFlow(
        camera: Camera(),
        cropper: Cropper(),
        recognizer: recognizer,
      );
      final result = await flow.capturePhoto();
      expect(result!.error, isTrue);
      expect(result.path, '/photo.jpg');
      recognizer.fail = false;
      final next = await flow.recognizePhoto(result);
      expect(next.id, result.id);
      expect(next.error, isFalse);
      expect(next.text, 'Water evaporates.\nIt becomes vapor.');
    },
  );
}

class Camera implements CameraImagePathSource {
  @override
  Future<String?> capturePath() async => '/photo.jpg';
}

class Cropper implements CapturedImageCropper {
  @override
  Future<String?> cropPath(String path) async => path;
}

class RetryRecognizer implements LocalTextRecognizer {
  bool fail = true;
  @override
  Future<List<String>> recognizeLines(String path) async {
    if (fail) throw StateError('ocr failed');
    return ['Water evaporates.', 'It becomes vapor.'];
  }
}
