import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_controller.dart';

/// A user-facing failure while converting a link to MP3.
class LinkToMp3Exception implements Exception {
  LinkToMp3Exception(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The extracted audio plus the source video's title (used to name the file).
class Mp3Result {
  const Mp3Result({required this.file, required this.title});
  final File file;
  final String title;
}

final linkToMp3ServiceProvider = Provider<LinkToMp3Service>(
  LinkToMp3Service.new,
);

/// Posts a YouTube/TikTok link to the shared backend's `/api/convert/audio`
/// endpoint and writes the returned MP3 to a temp file the UI can save or share.
/// Downloading from the web must happen server-side, so there is no on-device
/// path — every platform goes through the server.
class LinkToMp3Service {
  LinkToMp3Service(this._ref);

  final Ref _ref;

  Future<Mp3Result> convert(
    String url, {
    String? language,
    CancelToken? cancelToken,
  }) async {
    final token = _ref.read(authControllerProvider).asData?.value?.token;
    final dio = _ref.read(dioProvider);

    try {
      final response = await dio.post<List<int>>(
        '/api/convert/audio',
        cancelToken: cancelToken,
        data: {
          'url': url,
          'language': ?language,
        },
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
          responseType: ResponseType.bytes,
          sendTimeout: const Duration(minutes: 1),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw LinkToMp3Exception('The server returned an empty file.');
      }

      final title = _titleFromResponse(response);
      final dir = await getTemporaryDirectory();
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/${_safeFileStem(title)}_$stamp.mp3');
      await file.writeAsBytes(bytes, flush: true);
      return Mp3Result(file: file, title: title);
    } on DioException catch (error) {
      throw LinkToMp3Exception(_messageFromError(error));
    }
  }

  /// The backend sends the (url-encoded) source title in `X-Stillora-Title`.
  String _titleFromResponse(Response<List<int>> response) {
    final raw = response.headers.value('x-stillora-title');
    if (raw == null || raw.isEmpty) return 'audio';
    try {
      final decoded = Uri.decodeComponent(raw).trim();
      return decoded.isEmpty ? 'audio' : decoded;
    } catch (_) {
      return 'audio';
    }
  }

  /// Filesystem-safe stem for the temp file name.
  String _safeFileStem(String title) {
    final safe = title.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
    final trimmed = safe.replaceAll(RegExp(r'^_+|_+$'), '');
    return trimmed.isEmpty ? 'audio' : trimmed;
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
      return 'The download took too long. Try a shorter video.';
    }
    final status = error.response?.statusCode;
    if (status == 502 || status == 503 || status == 504) {
      return 'The server couldn’t fetch that link (error $status). '
          'Please try again.';
    }
    if (status != null) {
      return 'The server couldn’t convert that link (error $status). '
          'Please try again.';
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Couldn’t reach the server. Check your connection and try again.';
    }
    return 'Could not convert that link. Check your connection and try again.';
  }
}
