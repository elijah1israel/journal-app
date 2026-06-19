import 'package:dio/dio.dart';

import '../models/strategy.dart';
import 'api_client.dart';

class StrategyService {
  StrategyService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;
  Dio get _dio => _client.dio;

  Future<List<Strategy>> list() async {
    try {
      final res = await _dio.get('/strategies/');
      final data = res.data;
      final raw = data is List ? data : (data['results'] as List? ?? const []);
      return raw
          .map((e) => Strategy.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<Strategy> create({
    required String name,
    String description = '',
    String rules = '',
    String timeframes = '',
    String markets = '',
  }) async {
    try {
      final res = await _dio.post('/strategies/', data: {
        'name': name,
        'description': description,
        'rules': rules,
        'timeframes': timeframes,
        'markets': markets,
      });
      return Strategy.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw toApiException(e, fallback: 'Could not save the strategy.');
    }
  }

  Future<Strategy> update(int id, Map<String, dynamic> payload) async {
    try {
      final res = await _dio.patch('/strategies/$id/', data: payload);
      return Strategy.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw toApiException(e, fallback: 'Could not update the strategy.');
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/strategies/$id/');
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  // ── Checklist rules ────────────────────────────────────────────

  Future<StrategyRule> createRule(
    int strategyId, {
    required String text,
    bool isRequired = true,
  }) async {
    try {
      final res = await _dio.post(
        '/strategies/$strategyId/rules/',
        data: {'text': text, 'is_required': isRequired},
      );
      return StrategyRule.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw toApiException(e, fallback: 'Could not save the rule.');
    }
  }

  Future<StrategyRule> updateRule(
    int strategyId,
    int ruleId, {
    String? text,
    bool? isRequired,
    int? order,
  }) async {
    final payload = <String, dynamic>{
      if (text != null) 'text': text,
      if (isRequired != null) 'is_required': isRequired,
      if (order != null) 'order': order,
    };
    try {
      final res = await _dio.patch(
        '/strategies/$strategyId/rules/$ruleId/',
        data: payload,
      );
      return StrategyRule.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> deleteRule(int strategyId, int ruleId) async {
    try {
      await _dio.delete('/strategies/$strategyId/rules/$ruleId/');
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}
