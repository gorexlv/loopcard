import 'word_capture_flow.dart';

class CapturedPhoto {
  const CapturedPhoto({
    required this.id,
    required this.path,
    required this.text,
    this.error = false,
  });
  final String id;
  final String path;
  final String text;
  final bool error;
  CapturedPhoto withText(String value) =>
      CapturedPhoto(id: id, path: path, text: value);
}

abstract interface class PhotoCaptureFlow implements WordCaptureFlow {
  Future<CapturedPhoto?> capturePhoto();
  Future<CapturedPhoto> recognizePhoto(CapturedPhoto photo);
}

class PhotoBatch {
  static const maxPhotos = 10;
  static const maxTextLength = 4000;
  final List<CapturedPhoto> photos = [];
  bool get canSubmit =>
      photos.isNotEmpty &&
      photos.every((p) => !p.error && p.text.trim().isNotEmpty) &&
      photos.fold<int>(0, (n, p) => n + p.text.trim().length) +
              photos.length -
              1 <=
          maxTextLength;
  void add(CapturedPhoto photo) {
    if (photos.length >= maxPhotos) throw StateError('photo_limit');
    photos.add(photo);
  }

  void replace(String id, CapturedPhoto photo) {
    final index = photos.indexWhere((p) => p.id == id);
    if (index >= 0) {
      photos[index] = CapturedPhoto(
        id: id,
        path: photo.path,
        text: photo.text,
        error: photo.error,
      );
    }
  }

  void remove(String id) => photos.removeWhere((p) => p.id == id);
  List<Map<String, dynamic>> get sources => [
    for (final p in photos) {'id': p.id, 'text': p.text.trim()},
  ];
}
