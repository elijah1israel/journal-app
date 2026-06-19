import 'package:dio/dio.dart';

import '../models/community.dart';
import 'api_client.dart';

/// Talks to `/api/communities/*`. Mirrors the conventions in
/// [StrategyService] and [TradeService] — each method maps to one REST
/// call, every error becomes an [ApiException].
class CommunityService {
  CommunityService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;
  Dio get _dio => _client.dio;

  // ── Communities ──────────────────────────────────────────────────

  /// Discovery feed — every published community.
  Future<List<Community>> listAll() => _getList('/communities/');

  /// Communities the signed-in user is a member of.
  Future<List<Community>> listMine() => _getList('/communities/mine/');

  /// Communities the signed-in user owns (the "creator" tab).
  Future<List<Community>> listOwned() => _getList('/communities/owned/');

  Future<List<Community>> _getList(String path) async {
    try {
      final res = await _dio.get(path);
      final data = res.data;
      final raw = data is List ? data : (data['results'] as List? ?? const []);
      return raw
          .map((e) => Community.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<Community> get(int id) async {
    try {
      final res = await _dio.get('/communities/$id/');
      return Community.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<Community> create({
    required String name,
    String tagline = '',
    String description = '',
    String currency = 'UGX',
  }) async {
    try {
      final res = await _dio.post('/communities/', data: {
        'name': name,
        'tagline': tagline,
        'description': description,
        'currency': currency,
      });
      return Community.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw toApiException(e, fallback: 'Could not create the community.');
    }
  }

  /// Join a community. Phase 1: only free tiers are accepted server-side.
  Future<Community> subscribe(int communityId, {int? tierId}) async {
    try {
      final res = await _dio.post(
        '/communities/$communityId/subscribe/',
        data: tierId == null ? <String, dynamic>{} : {'tier_id': tierId},
      );
      return Community.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw toApiException(e, fallback: 'Could not join the community.');
    }
  }

  Future<void> leave(int communityId) async {
    try {
      await _dio.post('/communities/$communityId/leave/');
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  // ── Posts ────────────────────────────────────────────────────────

  Future<List<CommunityPost>> listPosts(int communityId) async {
    try {
      final res = await _dio.get('/communities/$communityId/posts/');
      final data = res.data;
      final raw = data is List ? data : (data['results'] as List? ?? const []);
      return raw
          .map((e) =>
              CommunityPost.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<CommunityPost> createPost(
    int communityId, {
    required String body,
    String title = '',
    String kind = 'text',
    int? minTierId,
  }) async {
    try {
      final res = await _dio.post(
        '/communities/$communityId/posts/',
        data: {
          'title': title,
          'body': body,
          'kind': kind,
          if (minTierId != null) 'min_tier': minTierId,
        },
      );
      return CommunityPost.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw toApiException(e, fallback: 'Could not publish the post.');
    }
  }

  Future<void> deletePost(int communityId, int postId) async {
    try {
      await _dio.delete('/communities/$communityId/posts/$postId/');
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  // ── Comments ─────────────────────────────────────────────────────

  Future<List<CommunityComment>> listComments(int communityId, int postId) async {
    try {
      final res = await _dio.get(
        '/communities/$communityId/posts/$postId/comments/',
      );
      final data = res.data;
      final raw = data is List ? data : (data['results'] as List? ?? const []);
      return raw
          .map((e) =>
              CommunityComment.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<CommunityComment> createComment(
    int communityId,
    int postId, {
    required String body,
  }) async {
    try {
      final res = await _dio.post(
        '/communities/$communityId/posts/$postId/comments/',
        data: {'body': body},
      );
      return CommunityComment.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw toApiException(e, fallback: 'Could not post the comment.');
    }
  }
}
