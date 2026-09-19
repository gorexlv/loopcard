import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import 'english_word_extractor.dart';
import 'word_capture_flow.dart';
import 'photo_batch.dart';

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

abstract interface class CapturedImageCropper {
  Future<String?> cropPath(String imagePath);
}

class SystemCapturedImageCropper implements CapturedImageCropper {
  SystemCapturedImageCropper({ImageCropper? cropper})
    : _cropper = cropper ?? ImageCropper();

  final ImageCropper _cropper;

  @override
  Future<String?> cropPath(String imagePath) async {
    final isChinese = PlatformDispatcher.instance.locale.languageCode == 'zh';
    final cropped = await _cropper.cropImage(
      sourcePath: imagePath,
      maxWidth: 2048,
      maxHeight: 2048,
      compressQuality: 92,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: isChinese ? '选择识别区域' : 'Select text area',
          lockAspectRatio: false,
          showCropGrid: true,
        ),
        IOSUiSettings(
          title: isChinese ? '选择识别区域' : 'Select text area',
          doneButtonTitle: isChinese ? '识别选区' : 'Use selection',
          cancelButtonTitle: isChinese ? '取消' : 'Cancel',
          aspectRatioLockEnabled: false,
          resetAspectRatioEnabled: true,
        ),
      ],
    );
    return cropped?.path;
  }
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

class OnDeviceWordCaptureFlow implements PhotoCaptureFlow {
  const OnDeviceWordCaptureFlow({
    required CameraImagePathSource camera,
    required CapturedImageCropper cropper,
    required LocalTextRecognizer recognizer,
  }) : _camera = camera,
       _cropper = cropper,
       _recognizer = recognizer;

  factory OnDeviceWordCaptureFlow.standard() => OnDeviceWordCaptureFlow(
    camera: SystemCameraImagePathSource(),
    cropper: SystemCapturedImageCropper(),
    recognizer: MlKitLocalTextRecognizer(),
  );

  final CameraImagePathSource _camera;
  final CapturedImageCropper _cropper;
  final LocalTextRecognizer _recognizer;

  @override
  Future<CapturedPhoto?> capturePhoto() async {
    final path = await _camera.capturePath();
    if (path == null) return null;
    final cropped = await _cropper.cropPath(path);
    if (cropped == null) return null;
    return recognizePhoto(
      CapturedPhoto(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        path: cropped,
        text: '',
      ),
    );
  }

  @override
  Future<CapturedPhoto> recognizePhoto(CapturedPhoto photo) async {
    try {
      final lines = await _recognizer.recognizeLines(photo.path);
      final text = lines.join('\n').trim();
      return CapturedPhoto(
        id: photo.id,
        path: photo.path,
        text: text,
        error: text.isEmpty,
      );
    } catch (_) {
      return CapturedPhoto(
        id: photo.id,
        path: photo.path,
        text: photo.text,
        error: true,
      );
    }
  }

  @override
  Future<List<String>?> captureWords() async {
    try {
      final imagePath = await _camera.capturePath();
      if (imagePath == null) return null;
      final croppedPath = await _cropper.cropPath(imagePath);
      if (croppedPath == null) return null;
      final lines = await _recognizer.recognizeLines(croppedPath);
      return EnglishWordExtractor.extract(lines);
    } catch (_) {
      throw const OcrException('On-device recognition failed');
    }
  }
}
