import 'package:dio/dio.dart';

import '../models/csv_import_result.dart';
import '../models/trade.dart';
import 'api_client.dart';

/// Raised when the server reports row-level CSV problems (HTTP 400 with
/// an `errors` array). UI shows the per-row messages in a list so the
/// user can fix the file and retry.
class CsvImportException extends ApiException {
  CsvImportException(super.message, this.errors);
  final List<String> errors;
}

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

  /// Sync trades from an MT4 / MT5 broker CSV. The server matches rows
  /// by Ticket ID — new tickets are inserted, open ones get updated,
  /// closed ones are skipped. Returns a [CsvImportResult] with the
  /// counts the UI shows on the success screen.
  Future<CsvImportResult> importCsv({
    required String path,
    required String filename,
  }) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(path, filename: filename),
      });
      final res = await _dio.post(
        '/trades/import_csv/',
        data: form,
        // Let dio compute the multipart boundary itself — don't override
        // Content-Type or the request body becomes unparseable on the
        // server side.
        options: Options(
          headers: {Headers.contentTypeHeader: null},
          contentType: 'multipart/form-data',
        ),
      );
      return CsvImportResult.fromJson(
          Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      // The server signals row-level problems with
      // { detail: "CSV contains errors.", errors: ["Row 2: …", …] }
      // — bubble those up as a typed exception so the UI can render
      // the per-row list.
      final data = e.response?.data;
      if (data is Map && data['errors'] is List) {
        final message = (data['detail'] as String?) ??
            'CSV contains errors. Fix the rows below and try again.';
        final errors = (data['errors'] as List)
            .map((row) => row.toString())
            .toList(growable: false);
        throw CsvImportException(message, errors);
      }
      throw toApiException(e, fallback: 'Could not import the CSV.');
    }
  }
}
