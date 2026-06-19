import 'package:dio/dio.dart';

import '../models/trade_plan.dart';
import 'api_client.dart';

/// Talks to `/api/trade-plans/*` + `/api/trades/discipline/`. Plans are
/// created with their full `checks` list; updating a single check is a
/// PATCH that re-sends the whole list with one entry flipped — matching
/// the server's "replace-all" semantics.
class TradePlanService {
  TradePlanService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;
  Dio get _dio => _client.dio;

  Future<TradePlan> create({
    required String symbol,
    required String direction,
    int? strategyId,
    double? plannedEntry,
    double? plannedSl,
    double? plannedTp,
    double? plannedSize,
    String decision = 'planned',
    String overrideReason = '',
    String notes = '',
    required List<TradePlanCheck> checks,
  }) async {
    try {
      final res = await _dio.post('/trade-plans/', data: {
        if (strategyId != null) 'strategy': strategyId,
        'symbol': symbol,
        'direction': direction,
        if (plannedEntry != null) 'planned_entry': plannedEntry,
        if (plannedSl != null) 'planned_sl': plannedSl,
        if (plannedTp != null) 'planned_tp': plannedTp,
        if (plannedSize != null) 'planned_size': plannedSize,
        'decision': decision,
        'override_reason': overrideReason,
        'notes': notes,
        'checks': checks.map((c) => c.toWire()).toList(),
      });
      return TradePlan.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw toApiException(e, fallback: 'Could not save the plan.');
    }
  }

  Future<DisciplineStats> discipline() async {
    try {
      final res = await _dio.get('/trades/discipline/');
      return DisciplineStats.fromJson(
          Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  /// Pass `symbol` to scope the news-blackout check to the symbol's
  /// currencies (planning EURUSD shouldn't be blocked by JPY news).
  Future<GuardrailStatus> guardrails({String? symbol}) async {
    try {
      final res = await _dio.get(
        '/trades/guardrails/',
        queryParameters: {
          if (symbol != null && symbol.isNotEmpty)
            'symbol': symbol.toUpperCase(),
        },
      );
      return GuardrailStatus.fromJson(
          Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}
