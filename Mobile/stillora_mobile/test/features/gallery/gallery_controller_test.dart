import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stillora_mobile/features/gallery/gallery_controller.dart';
import 'package:stillora_mobile/features/gallery/local_export_record.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('library restores local video path after provider restart', () async {
    final directory = await Directory.systemTemp.createTemp(
      'stillora-gallery-',
    );
    addTearDown(() => directory.deleteSync(recursive: true));
    final video = File('${directory.path}/export.mp4')
      ..writeAsBytesSync([1, 2]);
    final record = LocalExportRecord(
      id: 'export-1',
      outputPath: video.path,
      preset: 'Reels',
      width: 1080,
      height: 1920,
      durationSeconds: 30,
      createdAt: DateTime.utc(2026, 6, 6),
    );

    final firstContainer = ProviderContainer();
    addTearDown(firstContainer.dispose);
    await firstContainer.read(galleryControllerProvider.future);
    await firstContainer
        .read(galleryControllerProvider.notifier)
        .addRecord(record);

    final restartedContainer = ProviderContainer();
    addTearDown(restartedContainer.dispose);
    final restored = await restartedContainer.read(
      galleryControllerProvider.future,
    );

    expect(restored, [record]);
  });

  test('removeRecord deletes local file and removes persisted path', () async {
    final directory = await Directory.systemTemp.createTemp(
      'stillora-gallery-',
    );
    addTearDown(() => directory.deleteSync(recursive: true));
    final video = File('${directory.path}/export.mp4')
      ..writeAsBytesSync([1, 2]);
    final record = LocalExportRecord(
      id: 'export-1',
      outputPath: video.path,
      preset: 'Reels',
      width: 1080,
      height: 1920,
      durationSeconds: 30,
      createdAt: DateTime.utc(2026, 6, 6),
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(galleryControllerProvider.future);

    await container.read(galleryControllerProvider.notifier).addRecord(record);
    await container
        .read(galleryControllerProvider.notifier)
        .removeRecord(record.id);

    expect(video.existsSync(), isFalse);

    final restartedContainer = ProviderContainer();
    addTearDown(restartedContainer.dispose);
    final restored = await restartedContainer.read(
      galleryControllerProvider.future,
    );
    expect(restored, isEmpty);
  });
}
