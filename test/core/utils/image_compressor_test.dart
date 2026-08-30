import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inventory/core/utils/image_compressor.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('image_compressor_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('creates target directory and saves file when source exists', () async {
    final source = File('${tempDir.path}/source.jpg');
    await source.writeAsBytes(List.filled(1024, 0));

    final destinationPath = '${tempDir.path}/nested/dir/destination.jpg';

    final resultPath = await AppImageCompressor.compressAndSave(
      sourceFile: source,
      destinationPath: destinationPath,
    );

    expect(resultPath, destinationPath);
    expect(await File(destinationPath).exists(), isTrue);
    expect(await File(destinationPath).length(), 1024);
  });

  test('preserves constants for optimal dimensions and quality', () {
    expect(AppImageCompressor.defaultMaxDimension, 1200);
    expect(AppImageCompressor.memoMaxDimension, 1600);
    expect(AppImageCompressor.defaultQuality, 80);
  });
}
