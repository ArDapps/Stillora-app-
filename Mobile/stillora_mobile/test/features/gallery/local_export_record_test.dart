import 'package:flutter_test/flutter_test.dart';
import 'package:stillora_mobile/features/gallery/local_export_record.dart';

void main() {
  test('local export metadata round-trips without backend fields', () {
    final createdAt = DateTime.utc(2026, 6, 5, 12);
    final record = LocalExportRecord(
      id: 'export-1',
      outputPath: '/local/export.mp4',
      preset: 'Reels',
      width: 1080,
      height: 1920,
      durationSeconds: 10,
      createdAt: createdAt,
    );

    final json = record.toJson();
    final restored = LocalExportRecord.fromJson(json);

    expect(restored, record);
    expect(json.containsKey('uploadUrl'), isFalse);
  });
}
