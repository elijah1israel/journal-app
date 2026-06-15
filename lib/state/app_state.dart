import 'package:flutter/foundation.dart';

import '../models/auth_user.dart';
import '../models/csv_import_result.dart';
import '../models/strategy.dart';
import '../models/trade.dart';
import '../services/auth_service.dart';
import '../services/strategy_service.dart';
import '../services/trade_service.dart';

/// App store for Journal. Single ChangeNotifier so every screen can
/// `context.watch<AppState>()` without juggling providers — mirrors
/// the Pable pattern so devs hopping between the two apps see the
/// same shape.
///
/// Lifecycle:
///   1. [bootstrap] reads the saved JWT (auto-login) and pulls the
///      signed-in user + first page of trades/strategies.
///   2. [login] / [register] do the same after a fresh sign-in.
///   3. Trade + strategy mutations refresh through the same lists.
class AppState extends ChangeNotifier {
  AppState({
    AuthService? auth,
    TradeService? trades,
    StrategyService? strategies,
  })  : _auth = auth ?? AuthService(),
        _trades = trades ?? TradeService(),
        _strategies = strategies ?? StrategyService();

  final AuthService _auth;
  final TradeService _trades;
  final StrategyService _strategies;

  bool _bootstrapped = false;
  bool _signedIn = false;
  AuthUser? _user;

  final List<Trade> _tradeList = [];
  final List<Strategy> _strategyList = [];
  bool _loadingTrades = false;
  bool _loadingStrategies = false;

  bool get bootstrapped => _bootstrapped;
  bool get signedIn => _signedIn;
  AuthUser? get user => _user;
  List<Trade> get trades => List.unmodifiable(_tradeList);
  List<Strategy> get strategies => List.unmodifiable(_strategyList);
  bool get loadingTrades => _loadingTrades;
  bool get loadingStrategies => _loadingStrategies;

  // ── Derived stats (drives the dashboard) ──────────────────────

  int get totalTrades => _tradeList.length;
  int get closedTrades =>
      _tradeList.where((t) => t.status == TradeStatus.closed).length;
  int get openTrades =>
      _tradeList.where((t) => t.status == TradeStatus.open).length;
  int get winners => _tradeList.where((t) => t.isWinner).length;
  int get losers => _tradeList.where((t) => t.isLoser).length;

  double get winRate {
    final closed = closedTrades;
    if (closed == 0) return 0;
    return winners * 100 / closed;
  }

  double get totalPnl =>
      _tradeList.fold(0, (sum, t) => sum + (t.pnl ?? 0));

  double get bestTradePnl {
    double best = 0;
    for (final t in _tradeList) {
      final p = t.pnl ?? 0;
      if (p > best) best = p;
    }
    return best;
  }

  double get avgRiskReward {
    final rrs =
        _tradeList.map((t) => t.riskReward).whereType<double>().toList();
    if (rrs.isEmpty) return 0;
    return rrs.reduce((a, b) => a + b) / rrs.length;
  }

  // ── Auth + bootstrap ───────────────────────────────────────────

  Future<void> bootstrap() async {
    try {
      if (await _auth.tokens.hasTokens) {
        _user = await _auth.me();
        _signedIn = true;
        await _loadAfterAuth();
      }
    } catch (_) {
      await _auth.logout();
      _resetSession();
    } finally {
      _bootstrapped = true;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _user = await _auth.login(email, password);
    _signedIn = true;
    await _loadAfterAuth();
    notifyListeners();
  }

  Future<void> register({
    required String email,
    required String firstName,
    required String lastName,
    required String password,
    required String confirmPassword,
    String? experienceLevel,
  }) async {
    _user = await _auth.register(
      email: email,
      firstName: firstName,
      lastName: lastName,
      password: password,
      confirmPassword: confirmPassword,
      experienceLevel: experienceLevel,
    );
    _signedIn = true;
    await _loadAfterAuth();
    notifyListeners();
  }

  Future<void> signOut() async {
    await _auth.logout();
    _resetSession();
    notifyListeners();
  }

  void _resetSession() {
    _signedIn = false;
    _user = null;
    _tradeList.clear();
    _strategyList.clear();
  }

  Future<void> _loadAfterAuth() async {
    // Best-effort — surface real errors only on explicit refreshes.
    try {
      await Future.wait([refreshTrades(), refreshStrategies()]);
    } catch (_) {
      // empty lists are fine — the screens render an EmptyState
    }
  }

  // ── Trades ─────────────────────────────────────────────────────

  Future<void> refreshTrades({
    String? symbol,
    String? status,
    String? direction,
    int? strategy,
  }) async {
    _loadingTrades = true;
    notifyListeners();
    try {
      final list = await _trades.list(
        symbol: symbol,
        status: status,
        direction: direction,
        strategy: strategy,
      );
      _tradeList
        ..clear()
        ..addAll(list);
    } finally {
      _loadingTrades = false;
      notifyListeners();
    }
  }

  Future<Trade> createTrade(Map<String, dynamic> payload) async {
    final created = await _trades.create(payload);
    _tradeList.insert(0, created);
    notifyListeners();
    return created;
  }

  Future<Trade> updateTrade(int id, Map<String, dynamic> payload) async {
    final updated = await _trades.update(id, payload);
    final i = _tradeList.indexWhere((t) => t.id == id);
    if (i != -1) {
      _tradeList[i] = updated;
    } else {
      _tradeList.insert(0, updated);
    }
    notifyListeners();
    return updated;
  }

  Future<void> deleteTrade(int id) async {
    await _trades.delete(id);
    _tradeList.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  /// Sync trades from a broker CSV. The server returns
  /// (created, updated, skipped, total_in_file) so the import sheet
  /// can show a success summary. We refresh the trade list after a
  /// successful import — the new rows + updated ones land in one
  /// canonical pull rather than being merged piecemeal.
  Future<CsvImportResult> importTradesCsv({
    required String path,
    required String filename,
  }) async {
    final result = await _trades.importCsv(path: path, filename: filename);
    // Only refresh if the file actually changed anything; "all skipped"
    // doesn't need a round-trip.
    if (result.created > 0 || result.updated > 0) {
      await refreshTrades();
    }
    return result;
  }

  // ── Strategies ─────────────────────────────────────────────────

  Future<void> refreshStrategies() async {
    _loadingStrategies = true;
    notifyListeners();
    try {
      final list = await _strategies.list();
      _strategyList
        ..clear()
        ..addAll(list);
    } finally {
      _loadingStrategies = false;
      notifyListeners();
    }
  }

  Future<Strategy> createStrategy({
    required String name,
    String description = '',
    String rules = '',
    String timeframes = '',
    String markets = '',
  }) async {
    final created = await _strategies.create(
      name: name,
      description: description,
      rules: rules,
      timeframes: timeframes,
      markets: markets,
    );
    _strategyList.insert(0, created);
    notifyListeners();
    return created;
  }

  Future<Strategy> updateStrategy(
      int id, Map<String, dynamic> payload) async {
    final updated = await _strategies.update(id, payload);
    final i = _strategyList.indexWhere((s) => s.id == id);
    if (i != -1) {
      _strategyList[i] = updated;
    } else {
      _strategyList.insert(0, updated);
    }
    notifyListeners();
    return updated;
  }

  Future<void> deleteStrategy(int id) async {
    await _strategies.delete(id);
    _strategyList.removeWhere((s) => s.id == id);
    notifyListeners();
  }
}
