// Driver for integration_test/as_built_screens_test.dart: saves every
// screenshot the test takes into $AS_BUILT_OUT (default build/as_built/screens)
// and the run summary next to them.
import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final out = Directory(
    Platform.environment['AS_BUILT_OUT'] ?? 'build/as_built/screens',
  )..createSync(recursive: true);

  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      File('${out.path}/$name.png').writeAsBytesSync(bytes);
      return true;
    },
    responseDataCallback: (data) async {
      if (data == null) return;
      File('${out.path}/_run-summary.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(data),
      );
    },
  );
}
