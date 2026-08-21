import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/platform/platform_info.dart';

/// Every navigable section of the app, with its name, icons and platform gate
/// in one place so the phone drawer and the desktop sidebar can't drift apart.
///
/// [viewIndex] is the historical home-tab index persisted in `homeTabProvider` and
/// used to index the view list in `AppTabsScreen` — do not renumber these.
enum AppSection {
  create(
    0,
    Icons.add_photo_alternate_outlined,
    Icons.add_photo_alternate_rounded,
  ),
  library(1, Icons.video_library_outlined, Icons.video_library_rounded),
  html(2, Icons.public_outlined, Icons.public_rounded),
  settings(3, Icons.settings_outlined, Icons.settings_rounded),
  loopImages(4, Icons.repeat_rounded, Icons.repeat_on_rounded),
  removeSilence(5, Icons.content_cut_outlined, Icons.content_cut_rounded),
  watermark(
    6,
    Icons.branding_watermark_outlined,
    Icons.branding_watermark_rounded,
  ),
  speed(7, Icons.fast_forward_outlined, Icons.fast_forward_rounded),
  convert(8, Icons.swap_horiz_outlined, Icons.swap_horiz_rounded),
  text(9, Icons.text_fields_outlined, Icons.text_fields_rounded),
  compress(10, Icons.compress_outlined, Icons.compress_rounded),
  pdfConverter(11, Icons.picture_as_pdf_outlined, Icons.picture_as_pdf_rounded);

  const AppSection(this.viewIndex, this.icon, this.selectedIcon);

  final int viewIndex;
  final IconData icon;
  final IconData selectedIcon;

  String title(AppStrings s) => switch (this) {
    AppSection.create => s.create,
    AppSection.library => s.library,
    AppSection.html => s.html,
    AppSection.settings => s.settings,
    AppSection.loopImages => s.loopImages,
    AppSection.removeSilence => s.removeSilence,
    AppSection.watermark => s.watermark,
    AppSection.speed => s.speed,
    AppSection.convert => s.convert,
    AppSection.text => s.text,
    AppSection.compress => s.compress,
    AppSection.pdfConverter => s.pdfConverter,
  };

  String subtitle(AppStrings s) => switch (this) {
    AppSection.create => s.createSubtitle,
    AppSection.library => s.librarySubtitle,
    AppSection.html => s.htmlSubtitle,
    AppSection.settings => s.settingsSubtitle,
    AppSection.loopImages => s.loopImagesSubtitle,
    AppSection.removeSilence => s.removeSilenceSubtitle,
    AppSection.watermark => s.watermarkSubtitle,
    AppSection.speed => s.speedSubtitle,
    AppSection.convert => s.convertSubtitle,
    AppSection.text => s.textSubtitle,
    AppSection.compress => s.compressSubtitle,
    AppSection.pdfConverter => s.pdfConverterSubtitle,
  };

  /// Per-section platform visibility:
  ///  • Silence/Watermark/Speed/Text run on iOS's native engine, so desktop +
  ///    iOS show them; Android hides them.
  ///  • Compress re-encodes under a size cap. macOS/iOS use the native engine
  ///    (AVFoundation's fileLengthLimit *is* honored); Windows/Linux use
  ///    bundled ffmpeg. Android reuses the removeSilence pipeline it lacks, so
  ///    it stays hidden there.
  ///  • PDF Converter is pure Dart plus the printing plugin's rasteriser, both
  ///    of which ship on every platform — no gate.
  bool get isAvailable => switch (this) {
    AppSection.removeSilence ||
    AppSection.watermark ||
    AppSection.speed ||
    AppSection.text ||
    AppSection.compress => isDesktopPlatform || isIosPlatform,
    _ => true,
  };

  static AppSection fromIndex(int index) =>
      values.firstWhere((section) => section.viewIndex == index);
}

/// Display order for the phone navigation drawer: creation tools first, then
/// the library, then settings.
const mobileNavOrder = <AppSection>[
  AppSection.create,
  AppSection.text,
  AppSection.watermark,
  AppSection.removeSilence,
  AppSection.speed,
  AppSection.compress,
  AppSection.convert,
  AppSection.pdfConverter,
  AppSection.html,
  AppSection.loopImages,
  AppSection.library,
  AppSection.settings,
];

/// Display order for the desktop sidebar.
const desktopNavOrder = <AppSection>[
  AppSection.create,
  AppSection.text,
  AppSection.watermark,
  AppSection.removeSilence,
  AppSection.speed,
  AppSection.compress,
  AppSection.convert,
  AppSection.loopImages,
  AppSection.pdfConverter,
  AppSection.html,
  AppSection.library,
  AppSection.settings,
];
