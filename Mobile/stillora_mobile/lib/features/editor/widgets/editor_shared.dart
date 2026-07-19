import 'dart:io';

import '../editor_state.dart';
import '../video_preset.dart';

const _standardAudioExtensions = ['mp3', 'm4a', 'aac', 'wav'];
const _androidAudioExtensions = ['m4a', 'aac'];

List<String> get supportedAudioExtensions =>
    Platform.isAndroid ? _androidAudioExtensions : _standardAudioExtensions;

String get supportedAudioLabel =>
    Platform.isAndroid ? 'M4A or AAC' : 'MP3, M4A, AAC, or WAV';

/// Whether the editor holds anything worth clearing (media, audio, or a
/// non-default preset/duration/resize choice).
bool canReset(EditorState editor) =>
    editor.hasMedia ||
    editor.audioPath != null ||
    editor.preset != defaultVideoPreset ||
    editor.durationSeconds != defaultDurationSeconds ||
    editor.resizeMode != ResizeMode.fit;
