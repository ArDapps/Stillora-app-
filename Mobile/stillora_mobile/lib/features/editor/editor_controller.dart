import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import '../../core/platform/import_directory.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/storage/app_preferences.dart';
import '../color/color_adjust.dart';
import 'editor_duration.dart';
import 'editor_media_duration.dart';
import 'editor_media_item.dart';
import 'editor_state_model.dart';
import 'local_editor_media_store.dart';
import 'video_preset.dart';
import 'video_styles.dart';

// The Create-flow notifier: picking media, fitting durations to audio,
// persistence, and the setters the editor screens call.
// Split out of `editor_state.dart` unchanged.

final editorControllerProvider =
    NotifierProvider<EditorController, EditorState>(EditorController.new);

class EditorController extends Notifier<EditorState> {
  final _mediaStore = LocalEditorMediaStore();

  @override
  EditorState build() {
    final prefs = ref.read(appPreferencesProvider);
    return _restoreSession(prefs) ?? const EditorState();
  }

  /// Restores the last saved session. Returns null if nothing was saved or
  /// if the saved data is unreadable. Media items whose files no longer exist
  /// on disk are silently dropped (handles cleaned-up mobile temp paths).
  EditorState? _restoreSession(AppPreferences prefs) {
    final data = prefs.savedEditorSession;
    if (data == null) return null;
    try {
      final rawMedia =
          (data['media'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final media = [
        for (final item in rawMedia)
          if (File(item['path'] as String).existsSync())
            MediaItem.fromPath(
              item['path'] as String,
              durationSeconds: (item['d'] as int?) ?? defaultDurationSeconds,
              volume: (item['vol'] as num?)?.toDouble() ?? defaultClipVolume,
            ),
      ];
      final audioPath = data['audioPath'] as String?;
      final validAudio = audioPath != null && File(audioPath).existsSync()
          ? audioPath
          : null;
      return EditorState(
        media: media,
        selectedIndex: 0,
        audioPath: validAudio,
        audioDurationSeconds: validAudio != null
            ? data['audioDurationSeconds'] as int?
            : null,
        audioIsNarration:
            validAudio != null && (data['audioIsNarration'] as bool? ?? false),
        preset: presetById(data['presetId'] as String? ?? 'reels'),
        durationSeconds: normalizeDurationSeconds(
          (data['durationSeconds'] as int?) ?? defaultDurationSeconds,
        ),
        resizeMode: data['resizeMode'] == 'fill'
            ? ResizeMode.fill
            : ResizeMode.fit,
        exportQuality: exportQualityByName(
          data['exportQuality'] as String? ?? defaultExportQuality.name,
        ),
        effect: clipEffectByName(data['effect'] as String?),
        transition: frameTransitionByName(data['transition'] as String?),
      );
    } catch (_) {
      return null;
    }
  }

  /// Saves the current state to SharedPreferences asynchronously.
  void _persist() {
    final prefs = ref.read(appPreferencesProvider);
    unawaited(
      prefs.saveEditorSession({
        'media': [
          for (final item in state.media)
            {'path': item.path, 'd': item.durationSeconds, 'vol': item.volume},
        ],
        'audioPath': state.audioPath,
        'audioDurationSeconds': state.audioDurationSeconds,
        'audioIsNarration': state.audioIsNarration,
        'presetId': state.preset.id,
        'durationSeconds': state.durationSeconds,
        'resizeMode': state.resizeMode == ResizeMode.fill ? 'fill' : 'fit',
        'exportQuality': state.exportQuality.name,
        'effect': state.effect.name,
        'transition': state.transition.name,
      }),
    );
  }

  /// Lets the user pick multiple images, videos, or a mix of both.
  Future<void> pickMedia() async {
    final paths = await _pickMediaPaths();
    if (paths.isEmpty) {
      return;
    }
    // Spread the baseline duration evenly so the initial timeline keeps the
    // familiar total (e.g. 10s split across the chosen clips).
    final durations = _distributeEvenly(paths.length, state.durationSeconds);
    final items = [
      for (var i = 0; i < paths.length; i++)
        MediaItem.fromPath(paths[i], durationSeconds: durations[i]),
    ];
    state = state.copyWith(media: items, selectedIndex: 0);
    _persist();
    // A video clip should default to its own length (images keep the baseline).
    // Measured off the main path; patches durations in as each one resolves.
    unawaited(_applyNaturalVideoDurations(paths));
  }

  /// Appends more media to the current selection.
  Future<void> addMedia() async {
    final paths = await _pickMediaPaths();
    if (paths.isEmpty) {
      return;
    }
    final existing = {for (final item in state.media) item.path};
    // New clips adopt the current average clip length so the timeline grows
    // predictably; the user can fine-tune each one afterwards.
    final defaultClip = _defaultClipSeconds(state.media);
    final additions = [
      for (final path in paths)
        if (!existing.contains(path))
          MediaItem.fromPath(path, durationSeconds: defaultClip),
    ];
    if (additions.isEmpty) {
      return;
    }
    state = state.copyWith(media: [...state.media, ...additions]);
    _refitMediaToAudio();
    _persist();
    // Default each newly added video to its own length (no-op under audio fit).
    unawaited(_applyNaturalVideoDurations([for (final a in additions) a.path]));
  }

  /// Sets each *video* clip's duration to the source file's real length so a
  /// clip defaults to how long the video actually is (images keep their
  /// placeholder duration, having no intrinsic length). The user can still
  /// change any clip afterwards via [setClipDuration].
  ///
  /// Skipped entirely while a soundtrack/narration is fitting the timeline — in
  /// that case [_refitMediaToAudio] deliberately spreads the audio length across
  /// clips and should win. Measures off the main path and patches each clip by
  /// its path, so it survives reordering/removal during the async probe.
  Future<void> _applyNaturalVideoDurations(List<String> paths) async {
    for (final path in paths) {
      if (mediaKindForPath(path) != MediaKind.video) continue;
      if (state.audioDurationSeconds != null) return; // audio fit wins
      final seconds = await readMediaDurationSeconds(path);
      if (seconds == null) continue;
      // Bail if audio was attached while we were probing.
      if (state.audioDurationSeconds != null) return;
      // Rebuilt from the *current* media, so a clip removed mid-probe is simply
      // absent here and stays untouched.
      final next = [
        for (final item in state.media)
          (item.path == path && item.kind == MediaKind.video)
              ? item.copyWith(durationSeconds: seconds)
              : item,
      ];
      state = state.copyWith(
        media: next,
        durationSeconds: next.fold<int>(
          0,
          (sum, item) => sum + item.durationSeconds,
        ),
      );
    }
    _persist();
  }

  /// When a soundtrack/narration is attached, keep the exported video the same
  /// length as the audio by spreading the audio duration evenly across every
  /// clip. No-op when there's no audio or no media. Called whenever the media
  /// set changes so the fit survives adding/removing clips.
  void _refitMediaToAudio() {
    final audioDuration = state.audioDurationSeconds;
    if (audioDuration == null || state.media.isEmpty) return;
    final durations = _distributeEvenly(state.media.length, audioDuration);
    final next = [
      for (var i = 0; i < state.media.length; i++)
        state.media[i].copyWith(durationSeconds: durations[i]),
    ];
    state = state.copyWith(media: next, durationSeconds: audioDuration);
  }

  Future<List<String>> _pickMediaPaths() async {
    final paths = await _pickRawMediaPaths();
    return _mediaStore.materializeMediaPaths(paths);
  }

  Future<List<String>> _pickRawMediaPaths() async {
    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      final result = await pickImportFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: desktopMediaExtensions,
      );
      return [
        for (final file in result?.files ?? const <PlatformFile>[])
          if (file.path != null) file.path!,
      ];
    }

    final picker = ImagePicker();
    final files = await picker.pickMultipleMedia();
    return [for (final file in files) file.path];
  }

  /// Sets the duration of a single clip without touching the others.
  void setClipDuration(int index, int seconds) {
    if (index < 0 || index >= state.media.length) {
      return;
    }
    final next = [...state.media];
    next[index] = next[index].copyWith(
      durationSeconds: normalizeDurationSeconds(seconds),
    );
    state = state.copyWith(media: next);
    _persist();
  }

  /// Sets a single video clip's audio volume (0..1; 0 mutes it).
  void setClipVolume(int index, double volume) {
    if (index < 0 || index >= state.media.length) {
      return;
    }
    final next = [...state.media];
    next[index] = next[index].copyWith(volume: normalizeClipVolume(volume));
    state = state.copyWith(media: next);
    _persist();
  }

  int _defaultClipSeconds(List<MediaItem> media) {
    if (media.isEmpty) {
      return state.durationSeconds;
    }
    final total = media.fold(0, (sum, item) => sum + item.durationSeconds);
    return normalizeDurationSeconds((total / media.length).round());
  }

  /// Splits [total] seconds across [count] clips as evenly as possible, handing
  /// the remainder to the earliest clips so the parts sum back to [total].
  List<int> _distributeEvenly(int count, int total) {
    if (count <= 0) {
      return const [];
    }
    final clamped = normalizeDurationSeconds(total);
    final base = clamped ~/ count;
    final remainder = clamped - base * count;
    return [
      for (var i = 0; i < count; i++)
        normalizeDurationSeconds(base + (i < remainder ? 1 : 0)),
    ];
  }

  void selectMedia(int index) {
    if (index < 0 || index >= state.media.length) {
      return;
    }
    state = state.copyWith(selectedIndex: index);
  }

  void removeMediaAt(int index) {
    if (index < 0 || index >= state.media.length) {
      return;
    }
    final next = [...state.media]..removeAt(index);
    var selected = state.selectedIndex;
    if (selected >= next.length) {
      selected = next.isEmpty ? 0 : next.length - 1;
    } else if (index < selected) {
      selected -= 1;
    }
    state = state.copyWith(media: next, selectedIndex: selected);
    _refitMediaToAudio();
    _persist();
  }

  void reorderMedia(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.media.length) {
      return;
    }
    var targetIndex = newIndex;
    if (targetIndex > oldIndex) {
      targetIndex -= 1;
    }
    if (targetIndex < 0 || targetIndex >= state.media.length) {
      return;
    }
    final next = [...state.media];
    final moved = next.removeAt(oldIndex);
    next.insert(targetIndex, moved);
    state = state.copyWith(media: next, selectedIndex: targetIndex);
    _persist();
  }

  void clearMedia() {
    state = state.copyWith(media: const [], selectedIndex: 0);
    _persist();
  }

  /// Clears every input back to a blank editor: media, audio, preset, duration,
  /// and resize mode. Also wipes the saved session so nothing is restored.
  void reset() {
    state = const EditorState();
    final prefs = ref.read(appPreferencesProvider);
    unawaited(prefs.clearEditorSession());
  }

  /// Attaches a Voice Narration recording. Same pipeline as [setAudioPath] but
  /// flagged so the editor labels it as narration rather than a soundtrack.
  Future<void> setNarration(String path) =>
      setAudioPath(path, isNarration: true);

  Future<void> setAudioPath(String path, {bool isNarration = false}) async {
    final localPath = await _mediaStore.materializePath(
      path,
      kind: EditorMediaStoreKind.audio,
    );
    if (localPath == null) {
      return;
    }
    state = state.copyWith(
      audioPath: localPath,
      audioDurationSeconds: null,
      audioIsNarration: isNarration,
    );
    final duration = await readMediaDurationSeconds(localPath);
    if (state.audioPath != localPath || duration == null) {
      _persist();
      return;
    }
    final durations = _distributeEvenly(state.media.length, duration);
    final next = state.media.isEmpty
        ? state.media
        : [
            for (var i = 0; i < state.media.length; i++)
              state.media[i].copyWith(durationSeconds: durations[i]),
          ];
    state = state.copyWith(
      media: next,
      audioDurationSeconds: duration,
      durationSeconds: duration,
    );
    _persist();
  }

  Future<EditorState> prepareForExport() async {
    final mediaPaths = await _mediaStore.materializeMediaPaths(
      state.mediaPaths,
    );
    final audioPath = await _mediaStore.materializeAudioPath(state.audioPath);
    if (mediaPaths.length != state.media.length) {
      throw const FileSystemException(
        'Stillora could not read the selected media. Please choose the file again.',
      );
    }

    final nextMedia = [
      for (var i = 0; i < state.media.length; i++)
        MediaItem.fromPath(
          mediaPaths[i],
          durationSeconds: state.media[i].durationSeconds,
          volume: state.media[i].volume,
        ),
    ];
    state = state.copyWith(media: nextMedia, audioPath: audioPath);
    _persist();
    return state;
  }

  void removeAudio() {
    state = state.copyWith(clearAudio: true);
    _persist();
  }

  void setPreset(VideoPreset preset) {
    state = state.copyWith(preset: preset);
    _persist();
  }

  /// Sets the overall target duration and re-splits it evenly across every
  /// clip. Use [setClipDuration] to bias an individual clip afterwards.
  void setDuration(int seconds) {
    final normalized = normalizeDurationSeconds(seconds);
    if (state.media.isEmpty) {
      state = state.copyWith(durationSeconds: normalized);
      _persist();
      return;
    }
    final durations = _distributeEvenly(state.media.length, normalized);
    final next = [
      for (var i = 0; i < state.media.length; i++)
        state.media[i].copyWith(durationSeconds: durations[i]),
    ];
    state = state.copyWith(media: next, durationSeconds: normalized);
    _persist();
  }

  void setResizeMode(ResizeMode resizeMode) {
    state = state.copyWith(resizeMode: resizeMode);
    _persist();
  }

  void setExportQuality(ExportQuality quality) {
    state = state.copyWith(exportQuality: quality);
    _persist();
  }

  void setEffect(ClipEffect effect) {
    state = state.copyWith(effect: effect);
    _persist();
  }

  void setColor(ColorAdjust color) {
    state = state.copyWith(color: color);
  }

  void setTransition(FrameTransition transition) {
    state = state.copyWith(transition: transition);
    _persist();
  }
}
