import 'package:dio/dio.dart';

import '../../core/error/admin_error_codes.dart';
import '../../core/error/app_exception.dart';
import '../../domain/entities/admin_content.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

/// Wire-format DTO for an admin_content row from Supabase REST.
class AdminContentModel {
  const AdminContentModel({
    required this.contentId,
    required this.type,
    required this.title,
    required this.body,
    required this.isPublished,
    required this.createdAt,
    this.publishedAt,
    this.imageUrl,
  });

  final String contentId;
  final AdminContentType type;
  final String title;
  final String body;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime? publishedAt;
  final String? imageUrl;

  factory AdminContentModel.fromJson(Map<String, dynamic> json) {
    return AdminContentModel(
      contentId: json['id'] as String,
      type: _typeFromJson(json['type'] as String? ?? 'announcement'),
      title: json['title'] as String,
      body: json['body'] as String,
      isPublished: json['is_published'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'] as String)
          : null,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': contentId,
        'type': _typeToJson(type),
        'title': title,
        'body': body,
        'is_published': isPublished,
        'created_at': createdAt.toIso8601String(),
        if (publishedAt != null)
          'published_at': publishedAt!.toIso8601String(),
        if (imageUrl != null) 'image_url': imageUrl,
      };

  AdminContent toEntity() => AdminContent(
        contentId: contentId,
        type: type,
        title: title,
        body: body,
        isPublished: isPublished,
        createdAt: createdAt,
        publishedAt: publishedAt,
        imageUrl: imageUrl,
      );

  static AdminContentType _typeFromJson(String raw) {
    switch (raw) {
      case 'banner':
        return AdminContentType.banner;
      case 'lesson':
        return AdminContentType.lesson;
      case 'faq':
        return AdminContentType.faq;
      default:
        return AdminContentType.announcement;
    }
  }

  static String _typeToJson(AdminContentType t) {
    switch (t) {
      case AdminContentType.banner:
        return 'banner';
      case AdminContentType.lesson:
        return 'lesson';
      case AdminContentType.faq:
        return 'faq';
      case AdminContentType.announcement:
        return 'announcement';
    }
  }
}

// ── Abstract interface ────────────────────────────────────────────────────────

abstract class AdminRemoteDataSource {
  Future<List<AdminContentModel>> getContent({AdminContentType? type});
  Future<AdminContentModel> getContentById({required String contentId});
  Future<AdminContentModel> createContent({
    required AdminContentType type,
    required String title,
    required String body,
    String? imageUrl,
  });
  Future<AdminContentModel> updateContent({
    required String contentId,
    required AdminContentType type,
    required String title,
    required String body,
    String? imageUrl,
  });
  Future<void> deleteContent({required String contentId});
  Future<AdminContentModel> publishContent({required String contentId});
  Future<AdminContentModel> unpublishContent({required String contentId});
}

// ── Implementation ────────────────────────────────────────────────────────────

/// PostgREST-backed implementation.
///
/// Table: `admin_content`
/// Columns: id, type, title, body, is_published, published_at, image_url,
///          created_at, updated_at
class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  const AdminRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  static const String _base = '/admin_content';
  static final Options _returnRepresentation = Options(
    headers: <String, String>{'Prefer': 'return=representation'},
  );

  // ── Read ──────────────────────────────────────────────────────────────────

  @override
  Future<List<AdminContentModel>> getContent({
    AdminContentType? type,
  }) async {
    try {
      final Map<String, dynamic> params = <String, dynamic>{
        'select': '*',
        'order': 'created_at.desc',
      };
      if (type != null) {
        params['type'] = 'eq.${AdminContentModel._typeToJson(type)}';
      }
      final Response<dynamic> res =
          await _dio.get<dynamic>(_base, queryParameters: params);
      final List<dynamic> list = res.data as List<dynamic>;
      return list
          .map((dynamic e) =>
              AdminContentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<AdminContentModel> getContentById({
    required String contentId,
  }) async {
    try {
      final Response<dynamic> res = await _dio.get<dynamic>(
        _base,
        queryParameters: <String, dynamic>{
          'id': 'eq.$contentId',
          'select': '*',
        },
      );
      final List<dynamic> list = res.data as List<dynamic>;
      if (list.isEmpty) {
        throw ServerException('Content not found', AdminErrorCodes.notFound);
      }
      return AdminContentModel.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e, notFoundCode: AdminErrorCodes.notFound);
    }
  }

  // ── Create ────────────────────────────────────────────────────────────────

  @override
  Future<AdminContentModel> createContent({
    required AdminContentType type,
    required String title,
    required String body,
    String? imageUrl,
  }) async {
    try {
      final Map<String, dynamic> payload = <String, dynamic>{
        'type': AdminContentModel._typeToJson(type),
        'title': title,
        'body': body,
        if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
      };
      final Response<dynamic> res = await _dio.post<dynamic>(
        _base,
        data: payload,
        options: _returnRepresentation,
      );
      final List<dynamic> list = res.data as List<dynamic>;
      if (list.isEmpty) {
        throw ServerException(
            'Create content returned empty response', AdminErrorCodes.operationFailed);
      }
      return AdminContentModel.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Update ────────────────────────────────────────────────────────────────

  @override
  Future<AdminContentModel> updateContent({
    required String contentId,
    required AdminContentType type,
    required String title,
    required String body,
    String? imageUrl,
  }) async {
    try {
      final Map<String, dynamic> payload = <String, dynamic>{
        'type': AdminContentModel._typeToJson(type),
        'title': title,
        'body': body,
        // Explicitly set to null to clear an existing image.
        'image_url': (imageUrl != null && imageUrl.isNotEmpty) ? imageUrl : null,
      };
      final Response<dynamic> res = await _dio.patch<dynamic>(
        _base,
        queryParameters: <String, dynamic>{'id': 'eq.$contentId'},
        data: payload,
        options: _returnRepresentation,
      );
      final List<dynamic> list = res.data as List<dynamic>;
      if (list.isEmpty) {
        throw ServerException('Content not found', AdminErrorCodes.notFound);
      }
      return AdminContentModel.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e, notFoundCode: AdminErrorCodes.notFound);
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  @override
  Future<void> deleteContent({required String contentId}) async {
    try {
      await _dio.delete<dynamic>(
        _base,
        queryParameters: <String, dynamic>{'id': 'eq.$contentId'},
      );
    } on DioException catch (e) {
      throw _mapError(e, notFoundCode: AdminErrorCodes.notFound);
    }
  }

  // ── Publish toggles ───────────────────────────────────────────────────────

  @override
  Future<AdminContentModel> publishContent({
    required String contentId,
  }) async {
    try {
      final Response<dynamic> res = await _dio.patch<dynamic>(
        _base,
        queryParameters: <String, dynamic>{'id': 'eq.$contentId'},
        data: <String, dynamic>{
          'is_published': true,
          'published_at': DateTime.now().toUtc().toIso8601String(),
        },
        options: _returnRepresentation,
      );
      final List<dynamic> list = res.data as List<dynamic>;
      if (list.isEmpty) {
        throw ServerException('Content not found', AdminErrorCodes.notFound);
      }
      return AdminContentModel.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e, notFoundCode: AdminErrorCodes.notFound);
    }
  }

  @override
  Future<AdminContentModel> unpublishContent({
    required String contentId,
  }) async {
    try {
      final Response<dynamic> res = await _dio.patch<dynamic>(
        _base,
        queryParameters: <String, dynamic>{'id': 'eq.$contentId'},
        data: <String, dynamic>{
          'is_published': false,
          'published_at': null,
        },
        options: _returnRepresentation,
      );
      final List<dynamic> list = res.data as List<dynamic>;
      if (list.isEmpty) {
        throw ServerException('Content not found', AdminErrorCodes.notFound);
      }
      return AdminContentModel.fromJson(list.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e, notFoundCode: AdminErrorCodes.notFound);
    }
  }

  // ── Error mapping ──────────────────────────────────────────────────────────

  AppException _mapError(DioException e, {String? notFoundCode}) {
    final bool isTransport = e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError;

    if (isTransport) {
      return const NetworkException(
          'Unable to reach the server. Check your connection.');
    }

    final int? status = e.response?.statusCode;
    if (status == 404 && notFoundCode != null) {
      return ServerException('Resource not found', notFoundCode, e);
    }
    if (status == 401 || status == 403) {
      return const UnauthorizedException('Unauthorized');
    }
    return ServerException(
      'Admin content operation failed',
      AdminErrorCodes.operationFailed,
      e,
    );
  }
}
