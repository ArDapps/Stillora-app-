import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stillora_mobile/features/gallery/gallery_download.dart';
import 'package:stillora_mobile/features/gallery/local_export_record.dart';
import 'package:stillora_mobile/features/gallery/widgets/gallery_cards.dart';

void main() {
  final record = LocalExportRecord(
    id: 'r1',
    outputPath: '/tmp/stillora/out.mp4',
    preset: 'Reels / Shorts',
    width: 1080,
    height: 1920,
    durationSeconds: 12,
    createdAt: DateTime(2026, 7, 19),
  );

  Widget harness(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('the save dialog gets a descriptive filename', (tester) async {
    // Preset text is slugged so the name is filesystem-safe.
    expect(suggestedFileNameFor(record), 'stillora-reels-shorts-1080x1920.mp4');
  });

  testWidgets('every grid card carries a download button', (tester) async {
    await tester.pumpWidget(
      harness(
        GalleryCard(
          record: record,
          selecting: false,
          selected: false,
          onTap: () {},
          onLongPress: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(GalleryDownloadButton), findsOneWidget);
    expect(find.byIcon(Icons.download_rounded), findsOneWidget);
  });

  testWidgets('every list row carries a download button', (tester) async {
    await tester.pumpWidget(
      harness(
        GalleryTile(
          record: record,
          selecting: false,
          selected: false,
          onTap: () {},
          onLongPress: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(GalleryDownloadButton), findsOneWidget);
  });

  testWidgets('download is hidden while selecting videos to delete', (
    tester,
  ) async {
    // A download button inside a multi-select is a mis-tap waiting to happen.
    await tester.pumpWidget(
      harness(
        GalleryCard(
          record: record,
          selecting: true,
          selected: false,
          onTap: () {},
          onLongPress: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(GalleryDownloadButton), findsNothing);
  });
}
