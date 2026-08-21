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
  settings(3, Icons.info_outline_rounded, Icons.info_rounded),
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
  pdfConverter(11, Icons.picture_as_pdf_outlined, Icons.picture_as_pdf_rounded),
  stilloraPro(
    12,
    Icons.workspace_premium_outlined,
    Icons.workspace_premium_rounded,
  );

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
    AppSection.stilloraPro => s.stilloraPro,
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
    AppSection.stilloraPro => s.stilloraProSubtitle,
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
  ///  • Stillora Pro is the upgrade page; it ships everywhere.
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

/// The headings the navigation is grouped under, so Stillora reads as a private
/// media *toolkit* rather than a flat list of one-off screens: what you make,
/// what you do to existing video, documents, your own output, and the app
/// itself.
enum SidebarGroup {
  create,
  videoTools,
  documentTools,
  yourContent,
  accountApp;

  String label(AppStrings s) => switch (this) {
    SidebarGroup.create => s.groupCreate,
    SidebarGroup.videoTools => s.groupVideoTools,
    SidebarGroup.documentTools => s.groupDocumentTools,
    SidebarGroup.yourContent => s.groupYourContent,
    SidebarGroup.accountApp => s.groupAccountApp,
  };
}

/// One heading plus the sections under it.
class NavGroup {
  const NavGroup(this.group, this.sections);

  final SidebarGroup group;
  final List<AppSection> sections;

  /// Sections that actually run on this platform. A group whose every member
  /// is gated away renders nothing at all — no orphan heading.
  Iterable<AppSection> get availableSections =>
      sections.where((section) => section.isAvailable);
}

/// Grouped navigation, shared by the desktop sidebar and the phone drawer so
/// the two can never drift apart.
///
/// DOCUMENT TOOLS holds only the PDF converter today and is intentionally kept
/// as its own group so further document utilities can slot in beside it.
const navGroups = <NavGroup>[
  NavGroup(SidebarGroup.create, [
    AppSection.create,
    AppSection.text,
    AppSection.loopImages,
    AppSection.html,
  ]),
  NavGroup(SidebarGroup.videoTools, [
    AppSection.watermark,
    AppSection.removeSilence,
    AppSection.speed,
    AppSection.compress,
    AppSection.convert,
  ]),
  NavGroup(SidebarGroup.documentTools, [AppSection.pdfConverter]),
  NavGroup(SidebarGroup.yourContent, [AppSection.library]),
  NavGroup(SidebarGroup.accountApp, [
    AppSection.stilloraPro,
    AppSection.settings,
  ]),
];

/// The ACCOUNT / APP group is pinned to the bottom of the sidebar rather than
/// scrolling with the tools.
final navToolGroups = navGroups
    .where((group) => group.group != SidebarGroup.accountApp)
    .toList(growable: false);

final navFooterGroup = navGroups.firstWhere(
  (group) => group.group == SidebarGroup.accountApp,
);

/// Flat display order, derived from [navGroups] so adding a section to a group
/// is the only edit needed. Kept for callers that just want the sequence.
final desktopNavOrder = <AppSection>[
  for (final group in navGroups) ...group.sections,
];

final mobileNavOrder = desktopNavOrder;
