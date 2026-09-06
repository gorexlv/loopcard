import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import 'english_word_extractor.dart';
import 'word_capture_flow.dart';

abstract interface class CameraImagePathSource {
  Future<String?> capturePath();
}

class SystemCameraImagePathSource implements CameraImagePathSource {
  SystemCameraImagePathSource({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<String?> capturePath() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 2048,
      requestFullMetadata: false,
    );
    return image?.path;
  }
}

abstract interface class LocalTextRecognizer {
  Future<List<String>> recognizeLines(String imagePath);
}

class MlKitLocalTextRecognizer implements LocalTextRecognizer {
  MlKitLocalTextRecognizer({TextRecognizer? recognizer})
    : _recognizer =
          recognizer ?? TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;

  @override
  Future<List<String>> recognizeLines(String imagePath) async {
    final input = InputImage.fromFilePath(imagePath);
    final recognized = await _recognizer.processImage(input);
    return recognized.blocks
        .expand((block) => block.lines)
        .map((line) => line.text)
        .toList(growable: false);
  }
}

class OnDeviceWordCaptureFlow implements WordCaptureFlow {
  const OnDeviceWordCaptureFlow({
    required CameraImagePathSource camera,
    required LocalTextRecognizer recognizer,
  }) : _camera = camera,
       _recognizer = recognizer;

  factory OnDeviceWordCaptureFlow.standard() => OnDeviceWordCaptureFlow(
    camera: SystemCameraImagePathSource(),
    recognizer: MlKitLocalTextRecognizer(),
  );

  final CameraImagePathSource _camera;
  final LocalTextRecognizer _recognizer;

  @override
  Future<List<String>?> captureWords() async {
    final imagePath = await _camera.capturePath();
    if (imagePath == null) return null;
    try {
      final lines = await _recognizer.recognizeLines(imagePath);
      return EnglishWordExtractor.extract(lines);
    } catch (_) {
      throw const OcrException('On-device recognition failed');
    }
  }
}
