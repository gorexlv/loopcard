abstract interface class WordCaptureFlow {
  Future<List<String>?> captureWords();
}

class OcrException implements Exception {
  const OcrException(this.message);

  final String message;

  @override
  String toString() => message;
}
