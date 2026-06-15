import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_controller.dart';

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
  });

  final String? html;
  final String? url;
  final int width;
  final int height;
  final int durationMs;
  final int fps;
}

final htmlToVideoServiceProvider = Provider<HtmlToVideoService>(
  HtmlToVideoService.new,
);

/// Posts animated HTML to the shared backend's `/api/convert/html` renderer and
/// writes the returned MP4 to a temp file the UI can preview, save, or share.
class HtmlToVideoService {
  HtmlToVideoService(this._ref);

  final Ref _ref;

  Future<File> convert(HtmlToVideoRequest request) async {
    final token = _ref.read(authControllerProvider).asData?.value?.token;
    if (token == null) {
      throw HtmlToVideoException('Please sign in to convert HTML to video.');
    }

    final dio = _ref.read(dioProvider);
    try {
      final response = await dio.post<List<int>>(
        '/api/convert/html',
        data: {
          if (request.html != null) 'html': request.html,
          if (request.url != null) 'url': request.url,
          'width': request.width,
          'height': request.height,
          'durationMs': request.durationMs,
          'fps': request.fps,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          responseType: ResponseType.bytes,
          sendTimeout: const Duration(minutes: 2),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw HtmlToVideoException('The server returned an empty video.');
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
      return 'The render took too long. Try a shorter duration or lower fps.';
    }
    return 'Could not convert the HTML. Check your connection and try again.';
  }
}
