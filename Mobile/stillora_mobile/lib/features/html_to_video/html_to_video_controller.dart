import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'html_to_video_service.dart';

/// Holds the current/last HTML → MP4 render. Living in a provider (rather than
/// the screen's State) means the job keeps running when the user switches tabs,
/// and any part of the app can observe completion to show a toast.
final htmlToVideoControllerProvider =
    AsyncNotifierProvider<HtmlToVideoController, File?>(
      HtmlToVideoController.new,
    );

class HtmlToVideoController extends AsyncNotifier<File?> {
  CancelToken? _cancelToken;

  @override
  FutureOr<File?> build() => null;

  bool get isRunning => state.isLoading;

  /// Starts a render. Ignores the call if one is already in flight so the user
  /// can't kick off a second conversion until the first finishes.
  Future<void> convert(HtmlToVideoRequest request) async {
    if (state.isLoading) return;
    final token = CancelToken();
    _cancelToken = token;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(htmlToVideoServiceProvider)
          .convert(request, cancelToken: token),
    );
    // A cancelled request resolves to a benign idle state, not an error.
    if (token.isCancelled) {
      state = const AsyncData(null);
      return;
    }
    state = result;
  }

  /// Aborts the in-flight render so the user can stop a mistaken conversion.
  void cancel() {
    _cancelToken?.cancel('cancelled-by-user');
  }

  /// Clears the last result (e.g. when the user changes inputs).
  void clear() => state = const AsyncData(null);
}
