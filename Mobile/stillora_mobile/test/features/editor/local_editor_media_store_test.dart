import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stillora_mobile/features/editor/local_editor_media_store.dart';

void main() {
  test('copies picked media into the local source media folder', () async {
    final temp = await Directory.systemTemp.createTemp('stillora-media-store-');
    addTearDown(() => temp.deleteSync(recursive: true));
    final source = File('${temp.path}/photo one.jpg')..writeAsBytesSync([1, 2]);
    final store = LocalEditorMediaStore(baseDirectory: temp);

    final copied = await store.materializeMediaPaths([source.path]);

    expect(copied, hasLength(1));
    expect(copied.single, isNot(source.path));
    expect(File(copied.single).readAsBytesSync(), [1, 2]);
    expect(copied.single.contains('Stillora Source Media'), isTrue);
  });

  test(
    'does not duplicate files already in the local source media folder',
    () async {
      final temp = await Directory.systemTemp.createTemp(
        'stillora-media-store-',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      final localDirectory = Directory(
        '${temp.path}${Platform.pathSeparator}Stillora Source Media',
      )..createSync(recursive: true);
      final localFile = File('${localDirectory.path}/photo.jpg')
        ..writeAsBytesSync([1, 2]);
      final store = LocalEditorMediaStore(baseDirectory: temp);

      final copied = await store.materializeMediaPaths([localFile.path]);

      expect(copied, [localFile.path]);
    },
  );
}
