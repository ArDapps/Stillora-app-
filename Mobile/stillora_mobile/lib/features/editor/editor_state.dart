import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'video_preset.dart';

enum ResizeMode { fit, fill }

class EditorState extends Equatable {
  const EditorState({
    this.imagePath,
    this.audioPath,
    this.preset = defaultVideoPreset,
    this.durationSeconds = 10,
    this.resizeMode = ResizeMode.fit,
  });

  final String? imagePath;
  final String? audioPath;
  final VideoPreset preset;
  final int durationSeconds;
  final ResizeMode resizeMode;

  bool get canExport => imagePath != null;

  EditorState copyWith({
    String? imagePath,
    String? audioPath,
    bool clearAudio = false,
    VideoPreset? preset,
    int? durationSeconds,
    ResizeMode? resizeMode,
  }) {
    return EditorState(
      imagePath: imagePath ?? this.imagePath,
      audioPath: clearAudio ? null : audioPath ?? this.audioPath,
      preset: preset ?? this.preset,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      resizeMode: resizeMode ?? this.resizeMode,
    );
  }

  @override
  List<Object?> get props => [
    imagePath,
    audioPath,
    preset,
    durationSeconds,
    resizeMode,
  ];
}

final editorControllerProvider =
    NotifierProvider<EditorController, EditorState>(EditorController.new);

class EditorController extends Notifier<EditorState> {
  @override
  EditorState build() => const EditorState();

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      state = state.copyWith(imagePath: image.path);
    }
  }

  void setAudioPath(String path) => state = state.copyWith(audioPath: path);

  void removeAudio() => state = state.copyWith(clearAudio: true);

  void setPreset(VideoPreset preset) => state = state.copyWith(preset: preset);

  void setDuration(int seconds) =>
      state = state.copyWith(durationSeconds: seconds);

  void setResizeMode(ResizeMode resizeMode) {
    state = state.copyWith(resizeMode: resizeMode);
  }
}
