import '../../core/i18n/app_strings.dart';
import '../../core/i18n/language_controller.dart';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/api/api_client.dart';
import '../export/export_controller.dart' show videoEngineProvider;

/// A user-facing failure while converting HTML to video.
class HtmlToVideoException implements Exception {
  HtmlToVideoException(this.message);
  final String message;
  @override
  String toString() => message;
}

class HtmlToVideoRequest {
  const HtmlToVideoRequest({
    this.html,
    this.url,
    required this.width,
    required this.height,
    required this.durationMs,
    required this.fps,
    this.audioPath,
  });

  final String? html;
  final String? url;
  final int width;
  final int height;
  final int durationMs;
  final int fps;

  /// Optional soundtrack / voice-over file muxed onto the rendered video.
  final String? audioPath;
}

final htmlToVideoServiceProvider = Provider<HtmlToVideoService>(
  HtmlToVideoService.new,
);

/// Posts animated HTML to the shared backend's `/api/convert/html` renderer and
/// writes the returned MP4 to a temp file the UI can preview, save, or share.
class HtmlToVideoService {
  HtmlToVideoService(this._ref);

  final Ref _ref;

  /// The active translation — service errors surface straight in a snack bar,
  /// so they have to speak the user's language too.
  AppStrings get _strings =>
      AppStrings.of(_ref.read(languageControllerProvider));

  Future<File> convert(
    HtmlToVideoRequest request, {
    CancelToken? cancelToken,
  }) async {
    // macOS renders locally with the native engine — no server round-trip.
    if (Platform.isMacOS) {
      return _convertLocally(request);
    }
    return _convertViaServer(request, cancelToken: cancelToken);
  }

  /// On-device render (desktop). Returns the written MP4 file.
  Future<File> _convertLocally(HtmlToVideoRequest request) async {
    try {
      final result = await _ref
          .read(videoEngineProvider)
          .renderHtml(
            html: request.html,
            url: request.url,
            width: request.width,
            height: request.height,
            durationMs: request.durationMs,
            fps: request.fps,
            audioPath: request.audioPath,
          );
      return File(result.outputPath);
    } on PlatformException catch (error) {
      throw HtmlToVideoException(error.message ?? _strings.htmlErrLocalRender);
    }
  }

  Future<File> _convertViaServer(
    HtmlToVideoRequest request, {
    CancelToken? cancelToken,
  }) async {
    final dio = _ref.read(dioProvider);

    // Read + base64-encode the optional soundtrack so it rides in the JSON body.
    String? audioBase64;
    if (request.audioPath != null) {
      final bytes = await File(request.audioPath!).readAsBytes();
      if (bytes.isNotEmpty) audioBase64 = base64Encode(bytes);
    }

    try {
      final response = await dio.post<List<int>>(
        '/api/convert/html',
        cancelToken: cancelToken,
        data: {
          if (request.html != null) 'html': request.html,
          if (request.url != null) 'url': request.url,
          'width': request.width,
          'height': request.height,
          'durationMs': request.durationMs,
          'fps': request.fps,
          'audio': ?audioBase64,
        },
        options: Options(
          responseType: ResponseType.bytes,
          sendTimeout: const Duration(minutes: 2),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw HtmlToVideoException(_strings.htmlErrEmptyVideo);
      }

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/stillora_html_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } on DioException catch (error) {
      throw HtmlToVideoException(_messageFromError(error));
    }
  }

  /// Error responses carry a JSON `{ error }` body, but the request asked for
  /// bytes — so decode the body manually to surface the server's message.
  String _messageFromError(DioException error) {
    final data = error.response?.data;
    if (data is List<int>) {
      try {
        final decoded = jsonDecode(utf8.decode(data));
        if (decoded is Map && decoded['error'] is String) {
          return decoded['error'] as String;
        }
      } catch (_) {
        // Fall through to a generic message.
      }
    } else if (data is Map && data['error'] is String) {
      return data['error'] as String;
    }

    if (error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return _strings.htmlErrTimeout;
    }

    // No usable JSON body: surface the real HTTP status so gateway timeouts
    // (502/503/504 → an HTML error page, common for heavy pages behind a
    // reverse proxy) are distinguishable from an unreachable server.
    final status = error.response?.statusCode;
    if (status == 502 || status == 503 || status == 504) {
      return '${_strings.htmlErrGateway} ($status)';
    }
    if (status != null) {
      return '${_strings.htmlErrStatus} ($status)';
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return _strings.htmlErrUnreachable;
    }
    return _strings.htmlErrGeneric;
  }
}
