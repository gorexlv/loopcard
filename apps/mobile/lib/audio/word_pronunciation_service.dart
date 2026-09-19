import 'package:flutter/services.dart';

class WordPronunciationService {
  const WordPronunciationService();

  static const _channel = MethodChannel('com.loopcard.loopcard/speech');

  Future<bool> speak(String word, {String region = ''}) async {
    final normalized = word.trim();
    if (normalized.isEmpty) return false;
    try {
      return await _channel.invokeMethod<bool>('speak', {
            'text': normalized,
            'region': region,
          }) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
