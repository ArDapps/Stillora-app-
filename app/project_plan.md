# Stillora Constitution

## Project Identity

**Product Name:** Stillora
**Parent Company:** Tecno Blocks
**Product Type:** Image-to-video web application
**Primary Domain Recommendation:** `stillora.com` or a suitable available alternative
**Tagline:** Turn images into videos in seconds.
**Constitution Version:** 1.0.0
**Ratified:** 2026-06-05

---

# 1. Product Mission

Stillora is a fast, simple, and polished web application that converts a static image into a ready-to-share MP4 video.

The user uploads one image, selects an output format, chooses a duration, optionally adds audio, previews the result, and exports an MP4 video.

The product should feel like a lightweight creative editor inspired by the ease of use of modern design tools. It must not become a complex professional video-editing application.

Stillora must support:

* Instagram Reels
* Facebook Reels
* TikTok videos
* Instagram Stories
* YouTube Shorts
* Standard horizontal YouTube videos
* Square social-media videos
* Videos that preserve the original uploaded image dimensions

The initial application must include a public editor and a protected admin dashboard.

---

# 2. Core Product Principles

## Principle 1: Fast Creation Flow

A user should be able to create a video with minimal effort.

The core workflow is:

1. Upload an image.
2. Select an output preset.
3. Select a duration.
4. Optionally upload audio.
5. Preview the video composition.
6. Export an MP4 file.
7. Download the generated result.

The product must avoid unnecessary screens, forms, or steps.

The public editor should open immediately when a visitor enters the application.

---

## Principle 2: No Image Distortion

The original image must never be stretched or distorted.

When the uploaded image does not match the selected video aspect ratio, the user must choose between:

* **Fit:** Show the entire image and fill the unused space with a background.
* **Fill:** Scale the image until it fills the video frame and crop the excess edges.

The preview must accurately display the final result before video generation begins.

---

## Principle 3: Server-Side Persistence

Stillora must not be treated as a browser-only converter.

The production architecture must support server-side storage, database records, conversion-job tracking, and admin management.

Uploaded files and generated files must be saved on the server or VPS using organized directories.

Application metadata must be saved in PostgreSQL.

Browser-side preview is allowed and encouraged for speed, but the authoritative media files and conversion records must be stored on the server.

---

## Principle 4: Simple, Canva-Inspired Editing Experience

The user interface should feel intuitive and visual.

The layout may be inspired by the usability patterns of visual-editor applications, but Stillora must use its own original design, colors, icons, spacing, and branding.

Do not copy another platform pixel-for-pixel.

The editor must prioritize:

* Drag-and-drop upload
* Large central preview canvas
* Clear output presets
* Simple settings panels
* Visible duration controls
* Optional audio upload
* Clear export action
* Conversion progress
* Downloadable result

---

## Principle 5: Maintainable Architecture

Code must be easy to understand, test, and extend.

Every feature must use clear boundaries:

* UI components
* Business logic
* Validation
* Database access
* Storage services
* FFmpeg processing
* Authentication
* Admin actions
* API responses
* Background jobs

Do not place conversion logic directly inside React components.

---

# 3. Brand Identity

## Brand Name

Use:

```text
Stillora
```

The name combines the idea of a still image with a modern creative-tool identity.

## Product Positioning

```text
Stillora turns images into ready-to-share social videos.
Upload an image, add optional audio, choose a format, and export an MP4 in seconds.
```

## Brand Relationship

Stillora is a product built by Tecno Blocks.

Use this footer text:

```text
Built by Tecno Blocks
```

Add a link to the Tecno Blocks website for custom-development requests.

## Recommended Brand Style

Use a clean creative-SaaS appearance.

Suggested palette:

```text
Primary:        #7C3AED
Primary Dark:   #5B21B6
Accent:         #2563EB
Background:     #F5F7FB
Surface:        #FFFFFF
Canvas Area:    #E5E7EB
Text Primary:   #111827
Text Secondary: #6B7280
Success:        #16A34A
Warning:        #D97706
Error:          #DC2626
```

Use:

* Rounded cards
* Soft shadows
* Clear spacing
* Modern icons
* Compact controls
* Visible selected states
* Smooth transitions
* Accessible focus states

## Logo Direction

Use a minimal logo mark:

* Rounded square or rounded rectangle
* Static image-frame icon
* Small play triangle
* Modern and simple appearance
* Suitable for favicon and mobile display

---

# 4. Required Technology Stack

Use the following stack unless a future specification explicitly changes it.

## Frontend

```text
Next.js App Router
TypeScript
Tailwind CSS
shadcn/ui
React Hook Form
Zod
Lucide icons
```

## Backend

```text
Next.js Route Handlers or Server Actions where appropriate
Node.js
Prisma ORM
PostgreSQL
Native FFmpeg installed in the application container
```

## Authentication

```text
Email and password authentication
JWT-based admin sessions or a secure session-based equivalent
bcrypt or Argon2 password hashing
Role-based authorization
```

## Deployment

```text
Coolify
Docker Compose
Application container
PostgreSQL container
Persistent VPS volumes
```

## Storage

```text
Server-side local file storage on the VPS
Organized directories
Database records for all saved files
Persistent Docker volumes
```

Native FFmpeg must perform the final production conversion on the server.

Do not depend exclusively on `ffmpeg.wasm` for production exports.

---

# 5. Public User Experience

## Main Editor Route

```text
/
```

The public editor must be available without login unless a future business requirement changes this.

## Core User Flow

1. The user opens Stillora.
2. The user drags an image into the upload area or chooses a file.
3. The app uploads the image to the server.
4. The app displays an immediate preview and image metadata.
5. The user chooses an output preset.
6. The user selects **Fit** or **Fill**.
7. The user selects 10 seconds or 30 seconds.
8. The user optionally uploads an audio file.
9. The app displays a realistic preview.
10. The user clicks **Export MP4**.
11. The server creates a conversion job.
12. Native FFmpeg generates the MP4.
13. The interface displays progress.
14. The user previews the final MP4.
15. The user downloads the MP4.

---

# 6. Supported Output Presets

The editor must support the following output formats.

## Original Image Size

```text
Preset ID: original
Dimensions: Preserve uploaded image dimensions
Aspect Ratio: Preserve original aspect ratio
```

Use minimal padding only when FFmpeg or the selected codec requires even-numbered dimensions.

Example:

```text
Uploaded image: 1001 × 1501
Encoded video:  1002 × 1502
```

Never stretch the image.

## Reels, TikTok, and Stories

```text
Preset ID: reels
Dimensions: 1080 × 1920
Aspect Ratio: 9:16
Orientation: Vertical
```

Display label:

```text
Reels / TikTok / Stories
1080 × 1920 · 9:16 Vertical
```

This is the default selected preset.

## YouTube Shorts

```text
Preset ID: youtube-shorts
Dimensions: 1080 × 1920
Aspect Ratio: 9:16
Orientation: Vertical
```

Display label:

```text
YouTube Shorts
1080 × 1920 · 9:16 Vertical
```

## YouTube Long Video

```text
Preset ID: youtube-long
Dimensions: 1920 × 1080
Aspect Ratio: 16:9
Orientation: Horizontal
```

Display label:

```text
YouTube Long Video
1920 × 1080 · 16:9 Landscape
```

## Square Post

```text
Preset ID: square
Dimensions: 1080 × 1080
Aspect Ratio: 1:1
Orientation: Square
```

Display label:

```text
Square Post
1080 × 1080 · 1:1 Square
```

---

# 7. Image Upload Requirements

## Supported Formats

Accept:

```text
.jpg
.jpeg
.png
.webp
```

## Recommended File Limit

```text
Maximum image size: 20 MB
```

## Required Behavior

The image uploader must:

* Support drag and drop.
* Support file-picker selection.
* Accept one image at a time.
* Upload the selected image to the server.
* Display a preview immediately.
* Show the original filename.
* Show image width and height.
* Show file size.
* Show image format.
* Allow replacement.
* Allow removal.
* Validate the file before conversion.
* Show a clear message for unsupported formats.
* Handle corrupted images gracefully.

Use safe generated filenames on the server. Do not trust original filenames for storage paths.

---

# 8. Audio Upload Requirements

Audio is optional.

## Supported Formats

Accept:

```text
.mp3
.wav
.m4a
.aac
.ogg
```

## Recommended File Limit

```text
Maximum audio size: 50 MB
```

## Required Behavior

The audio uploader must:

* Support drag and drop.
* Support file-picker selection.
* Upload the selected file to the server.
* Show filename.
* Show file size.
* Show duration when available.
* Provide play and pause controls.
* Allow replacement.
* Allow removal.
* Validate format and size.
* Display clear errors.

## Audio Duration Rules

When audio is longer than the selected video duration:

```text
Trim the audio to match the video duration.
```

When audio is shorter than the selected video duration:

```text
Keep the remaining video duration silent.
```

Do not loop short audio by default.

An optional future toggle may allow:

```text
Loop short audio
```

---

# 9. Video Duration Rules

The MVP supports two durations:

```text
10 seconds
30 seconds
```

The default duration is:

```text
10 seconds
```

Changing the duration must update:

* Preview timeline
* Conversion settings
* Audio trimming
* Output filename
* Export modal summary
* Database record

Do not add custom duration input in the MVP.

---

# 10. Image Fit and Background Modes

## Fit Mode

Display the complete image inside the video frame.

Use a background when the image aspect ratio does not match the selected output ratio.

This is the default mode.

## Fill Mode

Scale the image until the full video frame is covered.

Crop any excess edges.

The preview must show the crop result before export.

## Background Options

When Fit mode is selected, provide:

```text
Black
White
Custom color
Blurred image background
```

Default:

```text
Blurred image background
```

The selected background option must be stored in the conversion record.

---

# 11. Editor Interface

## Overall Desktop Layout

Use a full-height creative-editor interface.

```text
┌─────────────────────────────────────────────────────────────────────┐
│ Logo  Project Name   Undo  Redo   Preset   Duration      Export MP4 │
├──────────┬──────────────────────────────────────────────────────────┤
│ Uploads  │                                                          │
│ Format   │                  CENTRAL CANVAS                          │
│ Audio    │                  Video Preview                           │
│ Bg       │                                                          │
│ Settings │                                                          │
├──────────┴──────────────────────────────────────────────────────────┤
│ Play  00:00 / 00:10   ━━━━━━━━━ Timeline ━━━━━━━  Volume  Zoom    │
└─────────────────────────────────────────────────────────────────────┘
```

## Top Toolbar

Display:

* Stillora logo
* Editable project name
* Undo button
* Redo button
* Active preset
* Video dimensions
* Duration
* Preview button
* Export MP4 button

Use a prominent primary button:

```text
Export MP4
```

## Left Sidebar Tabs

Display:

```text
Uploads
Output Format
Audio
Background
Settings
```

Use icons and text labels.

## Central Canvas

The canvas must:

* Occupy most of the available space.
* Use a neutral workspace background.
* Center the preview frame.
* Display the selected output ratio accurately.
* Reflect Fit and Fill changes immediately.
* Reflect background changes immediately.
* Never exceed the viewport height.
* Support zoom controls.
* Support fit-to-screen.
* Support fullscreen preview.

## Timeline Bar

Display:

* Play
* Pause
* Restart
* Current playback time
* Total duration
* Seek bar
* Volume
* Zoom percentage

The MVP timeline does not need multi-clip editing.

---

# 12. Mobile Experience

On mobile devices:

* Use a compact top bar.
* Keep the Export MP4 button visible.
* Display the canvas in the center.
* Move editor tabs into bottom navigation.
* Open settings as bottom sheets.
* Place timeline controls above bottom navigation.
* Use large touch targets.
* Ensure file-picker support.
* Do not depend only on drag-and-drop interaction.

Mobile navigation:

```text
Uploads
Format
Audio
Background
Settings
```

---

# 13. Export Flow

When the user clicks **Export MP4**, open a summary modal.

Example:

```text
Export your MP4 video

Format: MP4
Video size: 1080 × 1920
Preset: Reels / TikTok / Stories
Duration: 10 seconds
Audio: Included
Fit mode: Fit
Background: Blurred image

[ Cancel ]   [ Generate MP4 ]
```

After confirmation:

1. Create a conversion-job database record.
2. Queue or start the server-side FFmpeg conversion.
3. Show conversion progress.
4. Save the generated MP4 file on the VPS.
5. Save the generated video metadata in PostgreSQL.
6. Return the generated video URL.
7. Display preview and download controls.

## Progress Steps

Display meaningful progress states:

```text
Uploading media
Preparing files
Processing image
Processing audio
Encoding MP4
Finalizing video
Video ready
```

## Success State

Display:

```text
Your video is ready

[ Preview Video ]
[ Download MP4 ]
[ Create Another Video ]
```

---

# 14. FFmpeg Encoding Rules

Use native FFmpeg inside the application container or a dedicated worker container.

## Video Settings

Preferred encoding:

```text
Container: MP4
Video codec: H.264
Pixel format: yuv420p
Frame rate: 30 FPS
Fast-start metadata: Enabled
```

## Audio Settings

When audio exists:

```text
Audio codec: AAC
Audio duration: Limited to selected video duration
```

When audio does not exist:

```text
Generate a valid silent MP4 video.
```

## Output Filename

Use a safe readable format:

```text
stillora-{project-id}-{preset}-{duration}s.mp4
```

Example:

```text
stillora-cm123-reels-10s.mp4
```

## Output Validation

After FFmpeg completes:

* Confirm that the output file exists.
* Confirm that the file size is greater than zero.
* Save file size.
* Save output width and height.
* Save duration.
* Save processing completion time.
* Save job status.
* Save error details when processing fails.

---

# 15. Server Storage Architecture

Store application files on the VPS using persistent mounted volumes.

## Recommended Storage Structure

```text
/storage
├── uploads
│   ├── images
│   │   └── {year}/{month}/{project-id}/
│   └── audio
│       └── {year}/{month}/{project-id}/
├── generated
│   └── videos
│       └── {year}/{month}/{project-id}/
├── temp
│   └── {job-id}/
└── logs
    └── conversions/
```

## Example Paths

```text
/storage/uploads/images/2026/06/cmb123/source-image.webp
/storage/uploads/audio/2026/06/cmb123/background-audio.mp3
/storage/generated/videos/2026/06/cmb123/stillora-cmb123-reels-10s.mp4
/storage/temp/job-456/
```

## Storage Rules

* Never save uploaded files using unsafe raw filenames.
* Generate unique filenames.
* Save original filename separately in the database.
* Save MIME type.
* Save file size.
* Save disk path.
* Save a public or protected URL where appropriate.
* Save creation timestamp.
* Delete temporary conversion files after completion or failure.
* Use Docker volumes so media remains available after deployments.
* Prevent path traversal.
* Restrict executable uploads.
* Validate MIME type and extension.
* Do not expose sensitive internal paths in API responses.

---

# 16. PostgreSQL Data Model

Use Prisma ORM.

The exact schema may evolve, but it must include the following entities.

## AdminUser

```text
id
email
passwordHash
name
role
isActive
lastLoginAt
createdAt
updatedAt
```

## Project

```text
id
publicId
name
status
selectedPreset
fitMode
backgroundType
backgroundColor
durationSeconds
createdAt
updatedAt
```

## MediaAsset

```text
id
projectId
type
originalFilename
storedFilename
mimeType
extension
sizeBytes
width
height
durationSeconds
storagePath
publicUrl
createdAt
updatedAt
```

Supported asset types:

```text
IMAGE
AUDIO
VIDEO
```

## ConversionJob

```text
id
projectId
status
progressPercent
currentStep
preset
fitMode
backgroundType
backgroundColor
durationSeconds
inputImageAssetId
inputAudioAssetId
outputVideoAssetId
errorMessage
startedAt
completedAt
createdAt
updatedAt
```

Supported job statuses:

```text
PENDING
UPLOADING
QUEUED
PROCESSING
COMPLETED
FAILED
CANCELLED
```

## AuditLog

```text
id
adminUserId
action
entityType
entityId
metadata
createdAt
```

## AppSetting

```text
id
key
value
updatedAt
```

Suggested settings:

```text
MAX_IMAGE_SIZE_MB
MAX_AUDIO_SIZE_MB
MAX_DURATION_SECONDS
DEFAULT_PRESET
DEFAULT_DURATION_SECONDS
STORAGE_ROOT_PATH
TEMP_FILE_RETENTION_HOURS
GENERATED_VIDEO_RETENTION_DAYS
ALLOW_PUBLIC_DOWNLOADS
```

---

# 17. Admin Dashboard

## Admin Route

```text
/admin
```

The dashboard must require authentication.

## Authentication Pages

```text
/admin/login
/admin/logout
```

## Dashboard Overview

Display:

* Total projects
* Total uploaded images
* Total uploaded audio files
* Total generated videos
* Successful conversions
* Failed conversions
* Active conversion jobs
* Storage usage
* Recent activity
* Recent failed jobs

## Projects Management

Route:

```text
/admin/projects
```

Admin users must be able to:

* View all projects.
* Search projects.
* Filter by status.
* Open project details.
* View uploaded image.
* View uploaded audio metadata.
* Preview generated MP4.
* Download generated MP4.
* View project creation time.
* View selected preset.
* View duration.
* View Fit or Fill mode.
* Delete project files.
* Delete project records safely.

## Conversion Jobs

Route:

```text
/admin/jobs
```

Display:

* Job ID
* Project
* Status
* Progress
* Current step
* Preset
* Duration
* Start time
* Completion time
* Processing duration
* Error message
* Retry count

Admin users must be able to:

* View job details.
* Retry failed jobs.
* Cancel queued jobs when technically possible.
* Inspect failure information.
* Remove stale temporary files.

## Media Library

Route:

```text
/admin/media
```

Display:

* Media thumbnail or icon
* Media type
* Original filename
* Stored filename
* File size
* Dimensions
* Duration
* Project
* Creation date
* Storage path summary

Admin users must be able to:

* Preview supported media.
* Download files.
* Remove unused assets.
* Filter by media type.
* Search by filename or project ID.

## Storage Monitoring

Route:

```text
/admin/storage
```

Display:

* Total storage usage
* Uploaded-image usage
* Uploaded-audio usage
* Generated-video usage
* Temporary-file usage
* Old files eligible for cleanup

Provide safe cleanup actions.

## Settings

Route:

```text
/admin/settings
```

Allow administrators to manage:

* Upload limits
* Maximum duration
* Default preset
* Default background
* Retention period
* Public-download behavior
* Application name
* Support link
* Tecno Blocks link

## Admin Users

Route:

```text
/admin/users
```

Support roles:

```text
SUPER_ADMIN
ADMIN
VIEWER
```

Permissions:

### SUPER_ADMIN

* Full access
* Manage admin users
* Change settings
* Delete files
* Delete records
* Retry jobs
* View audit logs

### ADMIN

* Manage projects
* View media
* Retry jobs
* View storage
* Update safe settings

### VIEWER

* Read-only access

---

# 18. API Requirements

Use secure and consistent API routes.

Suggested routes:

```text
POST   /api/uploads/image
POST   /api/uploads/audio
POST   /api/projects
GET    /api/projects/:id
PATCH  /api/projects/:id
POST   /api/projects/:id/export
GET    /api/jobs/:id
POST   /api/jobs/:id/retry
GET    /api/videos/:id/download
DELETE /api/projects/:id
```

Admin routes:

```text
POST   /api/admin/auth/login
POST   /api/admin/auth/logout
GET    /api/admin/dashboard
GET    /api/admin/projects
GET    /api/admin/projects/:id
GET    /api/admin/jobs
POST   /api/admin/jobs/:id/retry
POST   /api/admin/jobs/:id/cancel
GET    /api/admin/media
DELETE /api/admin/media/:id
GET    /api/admin/storage
POST   /api/admin/storage/cleanup
GET    /api/admin/settings
PATCH  /api/admin/settings
GET    /api/admin/users
POST   /api/admin/users
PATCH  /api/admin/users/:id
DELETE /api/admin/users/:id
```

## API Response Shape

Use a consistent format.

Success:

```json
{
  "success": true,
  "data": {}
}
```

Failure:

```json
{
  "success": false,
  "error": {
    "code": "INVALID_FILE_TYPE",
    "message": "Please upload a JPG, PNG, or WebP image."
  }
}
```

---

# 19. Docker Compose Architecture

Deploy using Coolify with Docker Compose.

Required services:

```text
app
postgres
```

Optional recommended service for heavier workloads:

```text
worker
```

## Suggested Compose Structure

```yaml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    restart: unless-stopped
    environment:
      DATABASE_URL: ${DATABASE_URL}
      JWT_SECRET: ${JWT_SECRET}
      STORAGE_ROOT_PATH: /app/storage
      NODE_ENV: production
    volumes:
      - stillora_storage:/app/storage
    depends_on:
      - postgres

  postgres:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - stillora_postgres_data:/var/lib/postgresql/data

volumes:
  stillora_storage:
  stillora_postgres_data:
```

When job volume grows, add a dedicated worker service and a queue system.

Potential future queue stack:

```text
Redis
BullMQ
Dedicated FFmpeg worker container
```

Do not add Redis before the MVP needs it unless the first implementation requires reliable asynchronous jobs.

---

# 20. Environment Variables

Use environment variables.

Minimum required variables:

```text
DATABASE_URL
POSTGRES_DB
POSTGRES_USER
POSTGRES_PASSWORD
JWT_SECRET
ADMIN_EMAIL
ADMIN_INITIAL_PASSWORD
STORAGE_ROOT_PATH
NEXT_PUBLIC_APP_URL
NEXT_PUBLIC_APP_NAME
TECNO_BLOCKS_URL
MAX_IMAGE_SIZE_MB
MAX_AUDIO_SIZE_MB
TEMP_FILE_RETENTION_HOURS
GENERATED_VIDEO_RETENTION_DAYS
```

Never commit secrets into the repository.

Provide:

```text
.env.example
```

---

# 21. Security Requirements

The application must:

* Hash passwords with bcrypt or Argon2.
* Use secure admin sessions.
* Validate all uploads.
* Validate file signatures where practical.
* Limit upload file sizes.
* Reject unsupported files.
* Generate unique server-side filenames.
* Protect against path traversal.
* Escape user-provided text.
* Use role-based access control.
* Protect admin APIs.
* Rate-limit sensitive endpoints.
* Log admin actions.
* Avoid exposing internal storage paths.
* Delete temporary files.
* Use environment variables for secrets.
* Use HTTPS through Coolify configuration.
* Prevent unauthorized deletion.
* Confirm destructive admin actions with a modal.

---

# 22. Error Handling

Handle errors clearly.

Required error cases:

```text
Unsupported image type
Unsupported audio type
Image too large
Audio too large
Corrupted image
Corrupted audio
Upload failed
Database unavailable
Storage unavailable
FFmpeg unavailable
Conversion failed
Generated file missing
Download unavailable
Unauthorized admin access
Insufficient admin permission
```

Errors must:

* Explain the problem.
* Tell the user what action to take.
* Avoid exposing stack traces.
* Save useful technical details for admins.
* Create a failed job record when conversion fails.

---

# 23. Performance Requirements

The application must feel responsive.

Requirements:

* Show image preview quickly.
* Upload files with progress feedback.
* Disable duplicate export requests.
* Use efficient FFmpeg commands.
* Clean temporary files.
* Avoid unnecessary React renders.
* Use optimized image thumbnails in admin pages.
* Paginate project and media lists.
* Load heavy admin content only when needed.
* Add indexes to commonly filtered database columns.
* Avoid blocking the browser during conversion.
* Keep server conversion logic separate from request handlers when possible.

---

# 24. Accessibility Requirements

The public editor and admin dashboard must:

* Support keyboard navigation.
* Use visible focus states.
* Use accessible labels.
* Use readable contrast.
* Avoid relying only on color.
* Show validation messages close to inputs.
* Use status text for conversion progress.
* Support screen-reader-friendly buttons.
* Use appropriate semantic HTML.

---

# 25. Suggested Component Structure

## Public Editor Components

```text
EditorShell
TopToolbar
LeftSidebar
SidebarTabButton
UploadsPanel
ImageDropzone
AudioPanel
AudioDropzone
OutputFormatPanel
PresetCard
BackgroundPanel
SettingsPanel
CanvasWorkspace
VideoCanvas
ZoomControls
TimelineBar
PlaybackControls
ExportModal
ConversionProgress
DownloadResult
ErrorAlert
MobileBottomNavigation
```

## Admin Components

```text
AdminShell
AdminSidebar
AdminTopbar
DashboardStats
RecentJobsTable
ProjectsTable
ProjectDetails
JobsTable
JobDetails
MediaTable
StorageOverview
SettingsForm
AdminUsersTable
AuditLogsTable
ConfirmDeleteDialog
```

## Hooks and Services

```text
useVideoEditor
useMediaUpload
useConversionJob
useVideoPreview
useAdminSession
usePagination
storageService
ffmpegService
projectService
mediaService
conversionService
auditLogService
```

---

# 26. Suggested Application Routes

```text
app/
├── page.tsx
├── layout.tsx
├── globals.css
├── api/
│   ├── uploads/
│   ├── projects/
│   ├── jobs/
│   ├── videos/
│   └── admin/
└── admin/
    ├── login/
    ├── page.tsx
    ├── projects/
    ├── jobs/
    ├── media/
    ├── storage/
    ├── settings/
    └── users/
```

---

# 27. Testing Requirements

## Unit Tests

Test:

* Image validation
* Audio validation
* File-size validation
* Safe filename generation
* Output preset dimensions
* Odd-dimension padding
* Fit calculations
* Fill calculations
* Audio trimming
* Output filename generation
* Admin permission checks
* Storage path generation

## Component Tests

Test:

* Image drag and drop
* Audio drag and drop
* File replacement
* File removal
* Preset selection
* Fit and Fill changes
* Background selection
* Duration selection
* Preview rendering
* Export modal
* Upload progress
* Conversion progress
* Download button
* Admin login
* Admin filters
* Admin delete confirmation

## Integration Tests

Test:

* Upload image and create project.
* Upload optional audio.
* Start FFmpeg conversion.
* Save generated MP4.
* Save metadata in PostgreSQL.
* Retrieve conversion-job progress.
* Preview and download generated video.
* Retry failed job.
* Delete project and associated files safely.
* Confirm admin permission boundaries.

## End-to-End Tests

Test:

1. Create a 10-second Reels video without audio.
2. Create a 30-second Reels video with audio.
3. Create a YouTube Shorts video.
4. Create a standard horizontal YouTube video.
5. Create a square social video.
6. Preserve original image dimensions.
7. Use Fit mode with blurred background.
8. Use Fill mode with visible crop.
9. Upload long audio and confirm trimming.
10. Upload short audio and confirm silence at the end.
11. Reject unsupported files.
12. Access the admin dashboard.
13. Search projects.
14. Retry a failed job.
15. Preview generated video in the media library.
16. Confirm persistent files survive application restart.
17. Confirm PostgreSQL data survives container restart.
18. Use the editor on a mobile viewport.

---

# 28. MVP Scope

## Required for MVP

The first release must include:

* Stillora branding
* Public editor
* Drag-and-drop image upload
* Image preview
* Optional drag-and-drop audio upload
* Audio preview
* 10-second duration
* 30-second duration
* Reels preset
* YouTube Shorts preset
* YouTube long-video preset
* Square preset
* Original-size preset
* Fit mode
* Fill mode
* Background options
* Accurate preview
* Server-side FFmpeg conversion
* Generated MP4 download
* Coolify deployment
* Docker Compose
* PostgreSQL container
* Persistent VPS storage
* Admin authentication
* Admin dashboard
* Projects list
* Conversion-job list
* Media library
* Storage overview
* Settings page
* Failed-job retry
* Safe deletion
* Audit logs for important admin actions

## Out of Scope for MVP

Do not implement:

* Multi-image slideshows
* Timeline clip editing
* Text overlays
* Stickers
* Templates marketplace
* Team collaboration
* Public user accounts
* Subscription billing
* AI image generation
* Complex animation effects
* Transitions
* Cloud-object storage
* Social-media publishing
* Custom video lengths
* Mobile native apps
* Advanced audio editing
* Multiple audio tracks
* Layer management
* Video filters
* Real-time collaboration

---

# 29. Future Enhancements

Potential later additions:

```text
Custom durations
Audio looping
Fade-in and fade-out
Multiple-image slideshows
Transitions
Text overlays
Logo watermarking
Template presets
AI captions
Image animation
Ken Burns effect
Server-side job queue
Redis
BullMQ
Dedicated worker containers
User accounts
Freemium usage limits
Subscriptions
Cloud-object storage
Social-media publishing
Batch processing
API access
White-label mode
```

---

# 30. Definition of Done

The MVP is complete only when:

* The user can open Stillora without login.
* The user can upload one image.
* The image is saved on the VPS.
* The image metadata is saved in PostgreSQL.
* The preview appears correctly.
* The user can select a platform preset.
* The user can choose Fit or Fill.
* The user can select a background.
* The user can select 10 or 30 seconds.
* The user can optionally upload audio.
* The audio file is saved on the VPS.
* The audio metadata is saved in PostgreSQL.
* The user can preview the composition.
* The user can request MP4 export.
* The server generates the MP4 using native FFmpeg.
* The conversion job is tracked in PostgreSQL.
* The generated MP4 is saved on the VPS.
* The generated-video metadata is saved in PostgreSQL.
* The user can preview the real output.
* The user can download the MP4.
* A protected admin dashboard exists.
* Admin users can view projects.
* Admin users can view jobs.
* Admin users can retry failed jobs.
* Admin users can view media.
* Admin users can view storage usage.
* Admin users can change safe application settings.
* Admin users can safely remove files and projects.
* Docker Compose runs the app and PostgreSQL.
* Coolify can deploy the project.
* Persistent Docker volumes preserve PostgreSQL and media files across restarts.
* Desktop and mobile layouts work correctly.
* Critical flows have automated tests.

---

# 31. Governance

This constitution is the primary source of truth for the Stillora project.

All future specifications, plans, tasks, and implementation decisions must respect this constitution.

When a proposed feature conflicts with this constitution:

1. Identify the conflict.
2. Explain the reason for the change.
3. Update the constitution version.
4. Record the amendment date.
5. Update related specifications and tasks.

## Versioning Rules

Use semantic versioning:

```text
MAJOR.MINOR.PATCH
```

Increment:

* **MAJOR** for significant architecture or product-direction changes.
* **MINOR** for new principles, major sections, or expanded product requirements.
* **PATCH** for clarifications and wording improvements.

## Mandatory Review Checklist

Before approving a feature, confirm:

* Does it keep the editor simple?
* Does it preserve image quality?
* Does it avoid image distortion?
* Does it save required data in PostgreSQL?
* Does it save media safely on the VPS?
* Does it support Coolify deployment?
* Does it maintain admin visibility?
* Does it preserve security boundaries?
* Does it include validation?
* Does it include test coverage?
* Is it required for the MVP or should it be deferred?

---

# 32. First Spec Kit Commands

After saving this constitution, create the initial project specification with:

```text
/speckit.specify
Build Stillora, a Canva-inspired image-to-MP4 web application under Tecno Blocks. Users upload one image, choose Reels, YouTube Shorts, YouTube long-video, square, or original-size output, select Fit or Fill, choose a background, select 10 or 30 seconds, optionally upload audio, preview the result, and export an MP4. Use Next.js App Router, TypeScript, Tailwind CSS, shadcn/ui, Prisma, PostgreSQL in Docker Compose, native FFmpeg server-side conversion, Coolify deployment, persistent VPS storage, and a protected admin dashboard for projects, jobs, media, storage, settings, users, audit logs, failed-job retry, and safe deletion.
```

Then generate the plan:

```text
/speckit.plan
Use a maintainable Next.js App Router architecture with a public editor, protected admin dashboard, Prisma PostgreSQL data layer, local VPS storage service, native FFmpeg conversion service, Docker Compose deployment for Coolify, persistent volumes, secure admin authentication, role-based permissions, clear API boundaries, validation, automated tests, and an MVP-first implementation sequence.
```

Then generate tasks:

```text
/speckit.tasks
Break implementation into dependency-ordered tasks. Start with project setup, Docker Compose, PostgreSQL, Prisma schema, storage volumes, environment variables, admin auth, and shared validation. Then implement uploads, projects, presets, preview, audio, FFmpeg export, job tracking, download, admin projects, admin jobs, media library, storage dashboard, settings, audit logs, testing, and Coolify deployment documentation.
```
