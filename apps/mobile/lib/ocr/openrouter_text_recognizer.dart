import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'on_device_word_capture_flow.dart';
import 'word_capture_flow.dart';

/// The mobile app sends photos to our authenticated backend, never to OpenRouter
/// with a provider key. The backend owns model selection and credentials.
class OpenRouterTextRecognizer implements LocalTextRecognizer {
  OpenRouterTextRecognizer(this.client);
  final SupabaseClient client;

  @override
  Future<List<String>> recognizeLines(String imagePath) async {
    if (client.auth.currentSession == null) {
      throw const OcrException('请先登录后使用云端识别。');
    }
    final file = File(imagePath);
    if (await file.length() > 5 * 1024 * 1024) {
      throw const OcrException('照片过大，请裁剪后重试。');
    }
    final bytes = await file.readAsBytes();
    final isPng = bytes.length > 8 && bytes[0] == 0x89 && bytes[1] == 0x50;
    final isWebp =
        bytes.length > 12 &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP';
    final mime = isPng
        ? 'image/png'
        : isWebp
        ? 'image/webp'
        : 'image/jpeg';
    final result = await client.functions
        .invoke(
          'photo-ocr',
          body: {'image': 'data:$mime;base64,${base64Encode(bytes)}'},
        )
        .timeout(const Duration(seconds: 65));
    final data = result.data;
    if (result.status != 200 || data is! Map || data['text'] is! String) {
      throw const OcrException('云端识别失败，请重试。');
    }
    return (data['text'] as String).split('\n');
  }
}
