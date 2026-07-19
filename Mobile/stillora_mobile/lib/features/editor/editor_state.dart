/// Entry point for the Create-flow editor state. The implementation was split
/// by responsibility; everything that used to live here is re-exported so every
/// existing `import '.../editor/editor_state.dart'` keeps working unchanged.
library;

export 'editor_controller.dart' show EditorController, editorControllerProvider;
export 'editor_duration.dart';
export 'editor_export_estimate.dart';
export 'editor_media_item.dart';
export 'editor_state_model.dart' show EditorState;
