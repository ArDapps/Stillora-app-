import 'dart:io';

import 'package:flutter/services.dart';
import 'package:stillora_video_engine/stillora_video_engine.dart' as engine;

import 'color_adjust.dart';

/// Runs the post-export colour-grade pass over a finished export.
///
/// Returns [base] unchanged when the grade is neutral, or when the active
/// engine doesn't implement `colorGrade` yet (the iOS/Android native engines —
/// grading ships desktop-first). On success the intermediate ungraded file is
/// deleted to avoid leaving a duplicate behind.
Future<engine.ExportResult> applyColorGrade({
  required engine.StilloraVideoEngine videoEngine,
  required engine.ExportResult base,
  required ColorAdjust color,
}) async {
  if (color.isIdentity) return base;
  try {
    final graded = await videoEngine.colorGrade(
      videoPath: base.outputPath,
      adjust: color.toSpec(),
      width: base.width,
      height: base.height,
      durationSeconds: base.durationSeconds,
    );
    try {
      File(base.outputPath).deleteSync();
    } catch (_) {
      // A leftover intermediate is harmless; never fail the export over it.
    }
    return graded;
  } on MissingPluginException {
    // Platform engine can't grade yet — hand back the ungraded export.
    return base;
  }
}
