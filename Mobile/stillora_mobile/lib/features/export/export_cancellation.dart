import 'package:flutter/services.dart';

/// Whether an error thrown from an export is a user-initiated cancellation
/// rather than a real failure. Every engine backend signals cancel differently
/// (ffmpeg: `export_cancelled`; native iOS/macOS/Android: `cancelled`), so match
/// on the code/message containing "cancel".
bool isExportCancellation(Object error) {
  if (error is PlatformException) {
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();
    return code.contains('cancel') || message.contains('cancel');
  }
  return error.toString().toLowerCase().contains('cancel');
}
