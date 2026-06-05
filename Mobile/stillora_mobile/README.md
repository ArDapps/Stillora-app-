# Stillora Mobile

Flutter mobile app for Stillora: turn one local image into an MP4 video for social platforms.

## Status

This scaffold implements the MVP app shell, feature-first structure, onboarding, Google-only auth client wiring, editor state, local export metadata, settings/profile/gallery surfaces, and the typed `stillora_video_engine` plugin boundary.

Native H.264/AAC export is intentionally still inside the plugin package and must be implemented in:

- `packages/stillora_video_engine/android`
- `packages/stillora_video_engine/ios`

The Flutter UI does not call the existing web media upload/export routes.

## Architecture

```text
lib/
├── app/
├── core/
│   ├── api/
│   ├── auth/
│   ├── constants/
│   ├── storage/
│   └── widgets/
├── features/
│   ├── splash/
│   ├── onboarding/
│   ├── auth/
│   ├── home/
│   ├── editor/
│   ├── export/
│   ├── preview/
│   ├── gallery/
│   ├── settings/
│   └── profile/
└── main.dart
```

The local plugin exposes:

```dart
abstract interface class StilloraVideoEngine {
  Stream<ExportProgress> get progressStream;

  Future<ExportResult> exportVideo({
    required String imagePath,
    String? audioPath,
    required int durationSeconds,
    required int width,
    required int height,
    ResizeMode resizeMode = ResizeMode.fit,
    VideoEffect effect = VideoEffect.none,
  });

  Future<void> cancelExport();
  Future<void> clearTemporaryFiles();
}
```

## Auth

The mobile app uses Google Sign-In on device, then posts the Google access token to the existing shared Next.js endpoint:

```http
POST /api/auth/mobile
```

The returned Stillora JWT is stored in `flutter_secure_storage`. Media files, local export records, thumbnails, and temporary paths must never be uploaded or sent in analytics.

Set a different API origin at build time with:

```bash
flutter run --dart-define=STILLORA_API_BASE_URL=http://localhost:3000
```

## Development

```bash
flutter pub get
flutter analyze
flutter test
```

Plugin tests:

```bash
cd packages/stillora_video_engine
flutter pub get
flutter test
```

## Native Export TODO

Android should implement export in Kotlin with Jetpack Media3 Transformer, MediaCodec, and MediaMuxer where needed.

iOS should implement export in Swift with AVFoundation and AVAssetWriter.

Required behavior:

- Export MP4 with H.264 video.
- Export AAC audio when audio is provided.
- Support Fit and Fill without stretching.
- Support 10-second and 30-second durations.
- Trim or loop selected audio to duration.
- Emit progress stages.
- Support cancellation.
- Clear temporary files after success, cancellation, or failure.
