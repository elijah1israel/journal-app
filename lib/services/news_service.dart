import 'package:dio/dio.dart';

import '../models/news_event.dart';
import 'api_client.dart';

/// Talks to `/api/news/`. Returns events sorted by `when`, filtered by
/// currency + minimum impact on the server.
class NewsService {
  NewsService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;
  Dio get _dio => _client.dio;

  /// `currencies` defaults to empty (server-side: all). Cap on
  /// `withinHours` is 168 server-side; values above are clamped there.
  Future<List<NewsEvent>> list({
    Set<String> currencies = const {},
    int withinHours = 24,
    String minImpact = 'low',
  }) async {
    try {
      final res = await _dio.get('/news/', queryParameters: {
        if (currencies.isNotEmpty) 'currencies': currencies.join(','),
        'within_hours': withinHours,
        'min_impact': minImpact,
      });
      final data = res.data;
      final raw = data is List ? data : (data['results'] as List? ?? const []);
      return raw
          .map((e) =>
              NewsEvent.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}
