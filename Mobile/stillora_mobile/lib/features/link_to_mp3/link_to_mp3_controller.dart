import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'link_to_mp3_service.dart';

/// Holds the current/last link → MP3 conversion. Living in a provider (rather
/// than the screen's State) means the job keeps running when the user switches
/// tabs, and any part of the app can observe completion.
final linkToMp3ControllerProvider =
    AsyncNotifierProvider<LinkToMp3Controller, Mp3Result?>(
      LinkToMp3Controller.new,
    );

class LinkToMp3Controller extends AsyncNotifier<Mp3Result?> {
  CancelToken? _cancelToken;

  @override
  FutureOr<Mp3Result?> build() => null;

  bool get isRunning => state.isLoading;

  /// Starts a conversion. Ignores the call if one is already in flight.
  Future<void> convert(String url, {String? language}) async {
    if (state.isLoading) return;
    final token = CancelToken();
    _cancelToken = token;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(linkToMp3ServiceProvider).convert(
            url,
            language: language,
            cancelToken: token,
          ),
    );
    // A cancelled request resolves to a benign idle state, not an error.
    if (token.isCancelled) {
      state = const AsyncData(null);
      return;
    }
    state = result;
  }

  /// Aborts the in-flight conversion.
  void cancel() => _cancelToken?.cancel('cancelled-by-user');

  /// Clears the last result (e.g. when the user edits the link).
  void clear() => state = const AsyncData(null);
}
