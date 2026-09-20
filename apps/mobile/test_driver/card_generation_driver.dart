import 'dart:convert';
import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
  onScreenshot: (name, bytes, [args]) async {
    final file = File(
      '${Platform.environment['CARD_GENERATION_OUTPUT'] ?? '../../docs/testing/card-generation-e2e'}/$name.png',
    );
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    return true;
  },
  responseDataCallback: (data) async {
    final file = File(
      '${Platform.environment['CARD_GENERATION_OUTPUT'] ?? '../../docs/testing/card-generation-e2e'}/results.json',
    );
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        for (final entry in (data ?? {}).entries)
          if (entry.key != 'screenshots') entry.key: entry.value,
      }),
    );
  },
);
