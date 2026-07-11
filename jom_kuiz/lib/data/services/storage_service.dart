import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import 'token_manager.dart';

/// Uploads files to Supabase Storage via the Storage REST API.
///
/// Uses `PUT /storage/v1/object/{bucket}/{path}` with the user's JWT
/// so Supabase RLS policies are enforced on uploads.
///
/// The buckets (`question-media`, `content-media`) must be created by the
/// SQL migration before uploads are attempted.
class StorageService {
  const StorageService({
    required Dio dio,
    required TokenManager tokenManager,
  })  : _dio = dio,
        _tokenManager = tokenManager;

  final Dio _dio;
  final TokenManager _tokenManager;

  /// Uploads [bytes] to `{supabaseUrl}/storage/v1/object/{bucket}/{path}`.
  ///
  /// Returns the public URL for the object (bucket must be public).
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required Uint8List bytes,
    String mimeType = 'image/jpeg',
  }) async {
    final String storageUrl =
        '${AppConfig.supabaseUrl}/storage/v1/object/$bucket/$path';

    final String? accessToken = await _tokenManager.readAccessToken();

    final Map<String, String> headers = <String, String>{
      'Content-Type': mimeType,
      // x-upsert overwrites an existing object at the same path.
      'x-upsert': 'true',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
      if (AppConfig.supabaseAnonKey.isNotEmpty)
        'apikey': AppConfig.supabaseAnonKey,
    };

    await _dio.put<dynamic>(
      storageUrl,
      data: Stream<List<int>>.fromIterable(<List<int>>[bytes]),
      options: Options(
        headers: headers,
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    return '${AppConfig.supabaseUrl}/storage/v1/object/public/$bucket/$path';
  }

  /// Convenience: uploads an image, generating a timestamped path.
  Future<String> uploadImage({
    required String bucket,
    required Uint8List bytes,
    required String fileName,
  }) {
    final String ext = _ext(fileName, fallback: 'jpg');
    final String path =
        'images/${DateTime.now().millisecondsSinceEpoch}.$ext';
    return uploadFile(
      bucket: bucket,
      path: path,
      bytes: bytes,
      mimeType: _imageMime(ext),
    );
  }

  /// Convenience: uploads a video, generating a timestamped path.
  Future<String> uploadVideo({
    required String bucket,
    required Uint8List bytes,
    required String fileName,
  }) {
    final String ext = _ext(fileName, fallback: 'mp4');
    final String path =
        'videos/${DateTime.now().millisecondsSinceEpoch}.$ext';
    return uploadFile(
      bucket: bucket,
      path: path,
      bytes: bytes,
      mimeType: _videoMime(ext),
    );
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  String _ext(String fileName, {required String fallback}) {
    final int dot = fileName.lastIndexOf('.');
    if (dot < 0 || dot == fileName.length - 1) return fallback;
    return fileName.substring(dot + 1).toLowerCase();
  }

  String _imageMime(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  String _videoMime(String ext) {
    switch (ext) {
      case 'mov':
        return 'video/quicktime';
      default:
        return 'video/mp4';
    }
  }
}
