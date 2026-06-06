# Stillora Mobile

Flutter mobile app for Stillora: turn one local image into an MP4 video for social platforms.

The app also includes Flutter desktop runners for macOS, Windows, and Linux.
Desktop builds use a wider Stillora workspace UI. macOS exports locally through
native Swift AVFoundation, while Windows and Linux use the desktop FFmpeg
engine.

## Status

This scaffold implements the MVP app shell, feature-first structure, onboarding, Google-only auth client wiring, editor state, local export metadata, settings/profile/gallery surfaces, and the typed `stillora_video_engine` plugin boundary.

Native H.264/AAC export is implemented in the plugin package for:

- `packages/stillora_video_engine/ios`
- `packages/stillora_video_engine/macos`

Android native export still needs to be implemented in:

- `packages/stillora_video_engine/android`

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

The mobile app uses Google Sign-In on device, then posts Google auth tokens to
the existing shared Next.js endpoint:

```http
POST /api/auth/mobile
```

The app sends `accessToken` for the current deployed API and `idToken` for the
newer server-side ID-token verification path. The returned Stillora JWT is
stored in `flutter_secure_storage`. Media files, local export records,
thumbnails, and temporary paths must never be uploaded or sent in analytics.

Local storage:

- Login/session token: `flutter_secure_storage` on mobile and desktop.
- App preferences: `shared_preferences`.
- Local video library paths and export metadata: Hive box
  `stillora_library_exports`, with automatic migration from the old
  `SharedPreferences` key `stillora.exports`.

Google sign-in is implemented for iOS, Android, and macOS. macOS uses the same
Darwin/iOS-style client setup as the plugin docs; Desktop OAuth credentials are
for the future custom Linux/Windows flow. The current `google_sign_in` plugin
is not registered on Linux or Windows desktop, so those targets show a clear
unsupported message until that desktop OAuth flow is added.

Optional Google client overrides:

```bash
flutter run \
  --dart-define=GOOGLE_IOS_CLIENT_ID=... \
  --dart-define=GOOGLE_MACOS_CLIENT_ID=... \
  --dart-define=GOOGLE_WEB_CLIENT_ID=...
```

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

Desktop builds:

```bash
flutter build macos
flutter build windows
flutter build linux
```

Run the desktop app on the current host OS:

```bash
flutter run -d macos
flutter run -d windows
flutter run -d linux
```

macOS desktop export uses the native Swift AVFoundation engine from
`packages/stillora_video_engine/macos`, so Mac App Store builds do not need a
bundled FFmpeg executable. Windows and Linux use the desktop FFmpeg engine; add
the matching platform binary to those desktop bundles before shipping those
installers, or make sure `ffmpeg` is available on `PATH` during development.

```bash
ffmpeg -version
```

Plugin tests:

```bash
cd packages/stillora_video_engine
flutter pub get
flutter test
```

## Native Export TODO

Android should implement export in Kotlin with Jetpack Media3 Transformer, MediaCodec, and MediaMuxer where needed.

Required behavior:

- Export MP4 with H.264 video.
- Export AAC audio when audio is provided.
- Support Fit and Fill without stretching.
- Support 10-second and 30-second durations.
- Trim or loop selected audio to duration.
- Emit progress stages.
- Support cancellation.
- Clear temporary files after success, cancellation, or failure.
