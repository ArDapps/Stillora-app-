# Stillora Mobile Constitution

**Project Name:** Stillora
**Product Type:** Flutter Mobile Application
**Platforms:** iOS and Android
**Parent Brand:** Tecno Blocks
**Public Website:** `https://stillora.loopara.app/`
**Version:** 1.0.0
**Status:** Binding Constitution
**Tagline:** Turn images into videos in seconds.

---

## 1. Product Mission

Stillora is a privacy-first mobile application that turns static images into social-media-ready MP4 videos using the processing power of the user's phone.

The app must allow users to:

1. Select an image from their phone.
2. Choose a social media video format.
3. Choose a video duration.
4. Optionally attach an audio file.
5. Generate an MP4 video locally on the device.
6. Preview the generated video.
7. Save the video to the phone gallery.
8. Share the video using the native system share sheet.

The primary product promise is:

> **100% Local Processing — Your files never leave your device.**

Arabic equivalent:

> **المعالجة تتم بالكامل على جهازك — ملفاتك لا تغادر هاتفك.**

---

## 2. Non-Negotiable Principles

### Principle I — Local Processing Only

All media processing must happen locally on the user's phone.

The app must never upload any of the following files to the backend:

* Source images
* Audio files
* Generated videos
* Temporary export files
* Preview files
* Gallery files

The Next.js backend must not expose any image-upload, audio-upload, media-processing, or video-export endpoints for Stillora Mobile.

The app may communicate with the backend only for:

* Google authentication
* User profile information
* App configuration
* Feature flags
* Non-sensitive analytics events when explicitly enabled
* Subscription or entitlement data if added in a future specification

No analytics event may include file names, file paths, image contents, audio metadata, generated video contents, or media thumbnails.

---

### Principle II — Flutter Mobile Application

The mobile app must be developed using Flutter and Dart.

Required baseline:

```text
Flutter
Dart
iOS
Android
Material 3
Riverpod
GoRouter
Dio
Freezed or Equatable
SharedPreferences or Hive
Secure Storage
```

The implementation must use a feature-first clean architecture.

Recommended project structure:

```text
stillora_mobile/
├── lib/
│   ├── app/
│   │   ├── app.dart
│   │   ├── router.dart
│   │   └── theme.dart
│   │
│   ├── core/
│   │   ├── api/
│   │   ├── auth/
│   │   ├── constants/
│   │   ├── errors/
│   │   ├── storage/
│   │   ├── utils/
│   │   └── widgets/
│   │
│   ├── features/
│   │   ├── splash/
│   │   ├── onboarding/
│   │   ├── auth/
│   │   ├── home/
│   │   ├── editor/
│   │   ├── export/
│   │   ├── preview/
│   │   ├── gallery/
│   │   ├── settings/
│   │   └── profile/
│   │
│   └── main.dart
│
├── packages/
│   └── stillora_video_engine/
│       ├── lib/
│       ├── android/
│       └── ios/
│
├── assets/
│   ├── icons/
│   ├── images/
│   └── onboarding/
│
├── test/
└── integration_test/
```

The AI coding agent must not replace Flutter with React Native, Expo, Ionic, a WebView wrapper, or a Progressive Web App.

---

### Principle III — Native Local Video Engine

The application must include a reusable Flutter plugin named:

```text
stillora_video_engine
```

This plugin is responsible for video generation and export.

The Flutter UI must communicate with the plugin using a stable Dart interface.

Example interface:

```dart
abstract interface class StilloraVideoEngine {
  Stream<ExportProgress> get progressStream;

  Future<ExportResult> exportVideo({
    required String imagePath,
    String? audioPath,
    required int durationSeconds,
    required int width,
    required int height,
    required ResizeMode resizeMode,
    VideoEffect effect = VideoEffect.none,
  });

  Future<void> cancelExport();

  Future<void> clearTemporaryFiles();
}
```

The engine must use native APIs:

| Platform | Required Native Technology                                                      |
| -------- | ------------------------------------------------------------------------------- |
| iOS      | Swift with AVFoundation and AVAssetWriter                                       |
| Android  | Kotlin with Jetpack Media3 Transformer, MediaCodec, and MediaMuxer where needed |

The app must not depend on Expo Go.

The app must not use the discontinued original FFmpegKit package as a core dependency.

A future specification may add a maintained FFmpeg build only when a feature cannot be implemented reliably with native APIs. That decision must be documented separately.

---

## 3. Video Export Requirements

### Supported Input

The MVP supports:

* One source image
* One optional audio file
* Local files only

Supported source image formats:

```text
JPG
JPEG
PNG
WEBP when supported by the platform
```

Supported optional audio formats:

```text
MP3
M4A
AAC
WAV when supported by the platform
```

### Supported Output

The MVP output format must be:

```text
Container: MP4
Video Codec: H.264
Pixel Format: Compatible with iOS and Android gallery playback
Audio Codec: AAC when audio is provided
```

### Export Durations

The user must be able to select:

```text
10 seconds
30 seconds
```

The architecture must allow adding more durations later without rewriting the export engine.

### Video Presets

The MVP must include:

| Preset            |                Resolution |    Ratio |
| ----------------- | ------------------------: | -------: |
| Reels             |               1080 × 1920 |     9:16 |
| TikTok            |               1080 × 1920 |     9:16 |
| Stories           |               1080 × 1920 |     9:16 |
| YouTube Shorts    |               1080 × 1920 |     9:16 |
| Square Post       |               1080 × 1080 |      1:1 |
| YouTube Landscape |               1920 × 1080 |     16:9 |
| Original Size     | Derived from source image | Original |

### Resize Modes

The editor must provide:

```text
Fit
Fill
```

Definitions:

* **Fit:** Show the entire image. Empty areas may use a background color.
* **Fill:** Fill the entire frame. The image may be cropped while preserving its aspect ratio.

The implementation must never stretch or distort the image.

### Audio Behavior

Audio is optional.

When audio is selected:

* Trim the audio if it is longer than the video duration.
* Loop the audio if it is shorter than the video duration.
* Export the video successfully even when no audio is selected.
* Allow the user to remove or replace the selected audio before exporting.

---

## 4. Authentication

### Google Authentication Only

Stillora Mobile must support Google authentication only.

The mobile application must not include:

* Email and password registration
* Email and password login
* Forgot-password screens
* Password-reset endpoints
* Apple authentication unless added in a future platform-compliance specification
* Facebook authentication
* X authentication
* Guest accounts unless added in a future specification

The login screen must contain one primary authentication action:

```text
Continue with Google
```

### Shared Next.js API

Stillora Mobile must reuse the same Next.js API and authentication infrastructure used by Riskira.

The coding agent must inspect the existing Next.js API before creating new authentication logic.

Do not create a second authentication backend.

Do not duplicate user tables unless the current API architecture explicitly requires a related Stillora profile table.

Recommended flow:

```text
Flutter App
   ↓
Google Sign-In SDK
   ↓
Receive Google ID Token
   ↓
POST ID Token to shared Next.js API
   ↓
Backend verifies token with Google
   ↓
Backend creates or retrieves the user
   ↓
Backend returns application access token and refresh token
   ↓
Flutter stores tokens securely
```

Required Flutter package:

```text
google_sign_in
```

Required secure token storage:

```text
flutter_secure_storage
```

Tokens must never be stored in plain text using `SharedPreferences`.

### Suggested API Contract

Before implementing these routes, inspect the existing Riskira API. Reuse matching routes when available.

Suggested authentication endpoint:

```http
POST /api/auth/google
Content-Type: application/json
```

Request:

```json
{
  "idToken": "GOOGLE_ID_TOKEN",
  "app": "stillora",
  "platform": "ios"
}
```

Example success response:

```json
{
  "success": true,
  "data": {
    "accessToken": "JWT_ACCESS_TOKEN",
    "refreshToken": "JWT_REFRESH_TOKEN",
    "user": {
      "id": "USER_ID",
      "name": "Bahaa",
      "email": "user@example.com",
      "avatarUrl": "https://example.com/avatar.png"
    }
  }
}
```

Suggested refresh endpoint:

```http
POST /api/auth/refresh
Content-Type: application/json
```

Suggested logout endpoint:

```http
POST /api/auth/logout
Authorization: Bearer ACCESS_TOKEN
```

Suggested current-user endpoint:

```http
GET /api/auth/me
Authorization: Bearer ACCESS_TOKEN
```

### Backend Security Rules

The Next.js API must:

* Verify Google ID tokens server-side.
* Never trust the email sent directly by the mobile app.
* Use the verified Google subject identifier as the identity source.
* Issue short-lived access tokens.
* Support refresh-token rotation when the existing backend supports it.
* Store secrets in environment variables.
* Reject invalid, expired, or incorrectly scoped Google tokens.
* Associate the authenticated user with the source app using `app: "stillora"` when supported by the shared API.

---

## 5. Onboarding

### Onboarding Goal

The onboarding experience must explain the value of Stillora clearly before the user opens the editor.

Onboarding must appear on first launch only.

Its completion state must be stored locally.

Users must be able to replay onboarding from Settings.

### Required Onboarding Screens

#### Screen 1 — Welcome

Title:

```text
Turn images into videos
```

Subtitle:

```text
Create social-media-ready MP4 videos from your photos in seconds.
```

Arabic-ready equivalent:

```text
حوّل صورك إلى فيديوهات
أنشئ فيديوهات MP4 جاهزة للنشر على منصات التواصل خلال ثوانٍ.
```

#### Screen 2 — Choose the Perfect Format

Title:

```text
Made for every platform
```

Subtitle:

```text
Create videos for Reels, TikTok, Stories, YouTube Shorts, square posts, and landscape videos.
```

#### Screen 3 — Add Your Sound

Title:

```text
Bring your image to life
```

Subtitle:

```text
Add optional audio and generate a video ready to save or share.
```

#### Screen 4 — Privacy First

Title:

```text
100% local processing
```

Subtitle:

```text
Your images, audio files, and videos never leave your phone.
```

Arabic-ready equivalent:

```text
معالجة محلية بالكامل
صورك وملفات الصوت والفيديوهات لا تغادر هاتفك.
```

#### Screen 5 — Get Started

Title:

```text
Create your first video
```

Subtitle:

```text
Select an image and turn it into a video in a few simple steps.
```

Primary action:

```text
Get Started
```

Secondary action:

```text
Continue with Google
```

### Onboarding Rules

* Use smooth animations without reducing performance.
* Include Skip, Next, and Back actions where appropriate.
* Use a visible progress indicator.
* Keep the interface minimal.
* Do not request gallery or notification permissions before they are needed.
* Ask for permissions contextually when the user selects, saves, or shares a file.

---

## 6. Required Screens

### 6.1 Splash Screen

Purpose:

* Display Stillora logo.
* Restore local onboarding state.
* Restore secure authentication session.
* Route the user correctly.

Routing logic:

```text
First launch → Onboarding
Returning unauthenticated user → Login
Returning authenticated user → Home
```

### 6.2 Login Screen

Required elements:

* Stillora logo
* Product tagline
* Privacy-first message
* Continue with Google button
* Terms of Service link
* Privacy Policy link

No email or password fields.

### 6.3 Home Screen

Required elements:

* Welcome header
* Create New Video action
* Recent local exports
* Preset shortcuts
* Privacy-first badge
* Settings access

Recent exports must come from the phone's local storage records, not the backend.

### 6.4 Editor Screen

Required steps:

```text
1. Select image
2. Choose preset
3. Choose duration
4. Choose Fit or Fill
5. Add optional audio
6. Preview settings
7. Generate video
```

The editor must show:

* Image preview
* Preset selector
* Duration selector
* Resize mode selector
* Optional audio picker
* Remove-audio action
* Generate button

### 6.5 Export Progress Screen

Required states:

```text
Preparing image...
Generating video...
Merging audio...
Saving video...
Done
```

Requirements:

* Show progress percentage when native APIs provide it.
* Show a cancel button while export is running.
* Prevent starting duplicate export tasks.
* Keep the screen responsive.
* Handle app lifecycle changes safely.
* Clean temporary files after success, cancellation, or failure.

### 6.6 Preview Screen

Required actions:

```text
Play
Pause
Save to Gallery
Share
Create Another Video
Delete Local Export
```

### 6.7 Local Gallery Screen

Purpose:

* Display exported videos created locally by Stillora.
* Allow preview, share, save, and delete actions.
* Display video duration, preset, and creation date.

The gallery must not depend on backend connectivity.

### 6.8 Profile Screen

Required elements:

* Google profile avatar
* Name
* Email
* Logout
* Privacy Policy
* Terms of Service

### 6.9 Settings Screen

Required options:

```text
Language
Theme
Default video duration
Default video preset
Default resize mode
Replay onboarding
Clear temporary files
Privacy Policy
Terms of Service
Logout
```

---

## 7. Offline-First Behavior

After authentication, video creation must work without an internet connection.

Internet connectivity must not be required for:

* Selecting images
* Selecting audio
* Editing video settings
* Generating videos
* Previewing videos
* Saving videos
* Sharing videos
* Viewing local exports
* Deleting local exports

When authentication refresh fails because the device is offline:

* Preserve the existing session locally when safe.
* Do not block local video generation unnecessarily.
* Retry profile synchronization when connectivity returns.
* Avoid showing repeated disruptive error dialogs.

---

## 8. Local Storage Rules

### Temporary Files

Temporary files must be stored in the operating system cache or application temporary directory.

The app must:

* Generate unique temporary file names.
* Remove temporary files after export completion.
* Remove temporary files after cancellation.
* Remove stale temporary files during app startup.
* Provide a Settings action to clear temporary files manually.

### Generated Videos

Generated videos must be stored locally.

Store lightweight metadata locally:

```dart
class LocalExportRecord {
  final String id;
  final String outputPath;
  final String? thumbnailPath;
  final String preset;
  final int width;
  final int height;
  final int durationSeconds;
  final DateTime createdAt;
}
```

Do not send this record to the backend.

### Permissions

Permissions must be requested only when needed.

Required contextual permission flows:

```text
Select image → Request media picker permission only when required
Select audio → Request file or media permission only when required
Save video → Request gallery permission only when required
Share video → Use native share sheet
```

---

## 9. UI and Brand Direction

Stillora should feel modern, lightweight, trustworthy, and creative.

Visual direction:

```text
Canva-inspired simplicity
Clear spacing
Rounded cards
Large visual previews
Minimal technical wording
Fast editor workflow
Privacy-first messaging
```

Brand hierarchy:

```text
Stillora
Turn images into videos in seconds.
Built by Tecno Blocks
```

The user must never feel that Stillora is a complex professional video editor.

The MVP must focus on one simple promise:

```text
Image → MP4 Video → Save or Share
```

---

## 10. Error Handling

The app must show user-friendly messages for:

* Unsupported image format
* Unsupported audio format
* Missing media permission
* Not enough device storage
* Video export failure
* User cancellation
* Native encoder failure
* Google authentication cancellation
* Google authentication failure
* Expired session
* Offline API access

Example messages:

```text
We couldn't create your video. Please try again.
```

```text
Your files stay on your phone. Nothing was uploaded.
```

```text
There isn't enough free space to export this video.
```

Do not show raw native exceptions or stack traces to users.

Log technical errors locally in debug builds.

Never log access tokens, refresh tokens, image paths, audio paths, or video paths in production logs.

---

## 11. MVP Scope

### Included in MVP

* Flutter iOS and Android application
* Splash screen
* Five-screen onboarding
* Google authentication only
* Shared Riskira Next.js API authentication
* Home screen
* Select one local image
* Select optional local audio
* 10-second and 30-second durations
* Social media presets
* Original-size preset
* Fit and Fill modes
* Local MP4 generation
* H.264 video export
* AAC audio output when audio exists
* Progress states
* Cancel export
* Preview generated video
* Save to gallery
* Native sharing
* Local export history
* Profile
* Settings
* Replay onboarding
* Clear temporary files
* Privacy Policy and Terms of Service links
* English structure with Arabic-ready localization architecture

### Excluded from MVP

* Server-side media processing
* Uploading media files
* Cloud gallery
* Cloud backup
* React Native
* Expo
* Expo Go
* Email and password authentication
* Multiple images in one video
* Text overlays
* Templates marketplace
* Advanced transitions
* AI image generation
* AI video generation
* Social media publishing
* Admin dashboard inside the Flutter app
* Web editor
* Desktop app

Do not add excluded features unless a future approved specification explicitly introduces them.

---

## 12. Future-Ready Architecture

The architecture must allow future specifications to add:

* Zoom In effect
* Zoom Out effect
* Pan effect
* Fade In and Fade Out
* Background colors
* Blur backgrounds
* Text overlays
* Multiple images
* Slideshow mode
* More durations
* More export resolutions
* Subscription plans
* Feature limits
* Remote configuration
* Optional anonymous analytics
* Admin-managed app announcements

Future features must not break the core privacy guarantee.

Media files must remain local unless the user explicitly chooses a future cloud feature and gives informed consent.

---

## 13. Testing Requirements

### Unit Tests

Required unit tests:

* Preset-to-resolution mapping
* Duration selection
* Fit and Fill configuration
* Local export metadata
* Onboarding completion state
* Session persistence
* Token storage behavior
* Offline behavior
* Temporary file cleanup

### Widget Tests

Required widget tests:

* Onboarding navigation
* Google login button state
* Home navigation
* Editor validation
* Export progress states
* Preview actions
* Settings actions

### Integration Tests

Required integration tests:

```text
First launch → Onboarding → Google login → Home
Home → Select image → Choose preset → Export → Preview
Preview → Save to gallery
Preview → Share
Settings → Replay onboarding
Settings → Clear temporary files
Offline mode → Create local video successfully
Export cancellation → Temporary files removed
```

### Native Plugin Tests

Required native plugin coverage:

* Export without audio
* Export with audio
* Audio trim
* Audio loop
* Fit mode
* Fill mode
* Cancellation
* Invalid file input
* Low-storage error
* Temporary-file cleanup

---

## 14. Security and Privacy Rules

The implementation must:

* Use HTTPS for API communication.
* Verify Google authentication server-side.
* Store tokens using secure storage.
* Avoid plain-text token storage.
* Avoid media uploads.
* Avoid production logs containing sensitive information.
* Avoid storing unnecessary user data.
* Provide Privacy Policy and Terms of Service links.
* Explain local processing visibly during onboarding and inside the editor.

The coding agent must treat any accidental media upload as a critical bug.

---

## 15. AI Coding Agent Rules

When generating or modifying the project, the AI agent must:

1. Read this constitution before implementing any feature.
2. Preserve Flutter as the mobile framework.
3. Preserve local-only media processing.
4. Reuse the existing Riskira Next.js API authentication infrastructure.
5. Implement Google authentication only.
6. Inspect existing API routes before adding new routes.
7. Avoid duplicated authentication logic.
8. Keep video-engine logic outside UI widgets.
9. Keep platform-specific code inside `stillora_video_engine`.
10. Keep feature modules isolated.
11. Add tests with each feature.
12. Handle errors explicitly.
13. Remove temporary files safely.
14. Avoid adding dependencies unless necessary.
15. Document any native setup steps for iOS and Android.
16. Never use Expo Go or React Native assumptions.
17. Never create media-upload endpoints.
18. Never move media processing to the server.
19. Never expose raw stack traces in production UI.
20. Update the README after architectural changes.

---

## 16. Definition of Done

A feature is complete only when:

* It respects local-only processing.
* It works on both iOS and Android or is explicitly marked as platform-specific.
* It includes loading, success, failure, and cancellation states where relevant.
* It does not introduce media uploads.
* It includes tests.
* It does not expose secrets or raw exceptions.
* It follows the feature-first architecture.
* It works with the shared Next.js authentication API where authentication is required.
* It includes documentation for any native configuration changes.

---

## 17. Governance

This constitution is the highest-priority engineering document for Stillora Mobile.

Any specification, implementation plan, task list, pull request, generated code, or AI coding instruction that conflicts with this constitution must be rejected or revised.

The following rules require an explicit constitution amendment before they can change:

* Flutter as the mobile framework
* Local-only media processing
* Google authentication only
* Reuse of the shared Next.js authentication API
* No media upload to the backend
* Native local video-engine architecture

**Ratified:** 2026-06-05
**Last Amended:** 2026-06-05
**Constitution Version:** 1.0.0
