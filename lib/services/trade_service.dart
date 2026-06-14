import 'package:dio/dio.dart';

import '../models/trade.dart';
import 'api_client.dart';

class TradeService {
  TradeService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;
  Dio get _dio => _client.dio;

  Future<List<Trade>> list({
    String? symbol,
    String? status,
    String? direction,
    int? strategy,
  }) async {
    try {
      final res = await _dio.get('/trades/', queryParameters: {
        if (symbol != null && symbol.isNotEmpty) 'symbol': symbol,
        if (status != null && status.isNotEmpty) 'status': status,
        if (direction != null && direction.isNotEmpty) 'direction': direction,
        if (strategy != null) 'strategy': strategy,
      });
      final data = res.data;
      final raw = data is List ? data : (data['results'] as List? ?? const []);
      return raw
          .map((e) => Trade.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<Trade> create(Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post('/trades/', data: payload);
      return Trade.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw toApiException(e, fallback: 'Could not save the trade.');
    }
  }

  Future<Trade> update(int id, Map<String, dynamic> payload) async {
    try {
      final res = await _dio.patch('/trades/$id/', data: payload);
      return Trade.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw toApiException(e, fallback: 'Could not update the trade.');
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/trades/$id/');
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}
