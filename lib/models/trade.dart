/// Wire enum: long vs short.
enum TradeDirection {
  buy('buy'),
  sell('sell');

  const TradeDirection(this.wire);
  final String wire;

  static TradeDirection fromWire(String? value) {
    for (final d in TradeDirection.values) {
      if (d.wire == value) return d;
    }
    return TradeDirection.buy;
  }

  String get label => this == TradeDirection.buy ? 'Long' : 'Short';
}

/// Open / closed (server-derived from [result]).
enum TradeStatus {
  open('open'),
  closed('closed');

  const TradeStatus(this.wire);
  final String wire;

  static TradeStatus fromWire(String? value) {
    if (value == 'closed') return TradeStatus.closed;
    return TradeStatus.open;
  }
}

/// "" = still open, "tp" = take-profit hit, "sl" = stop-loss hit.
enum TradeResult {
  none(''),
  tp('tp'),
  sl('sl');

  const TradeResult(this.wire);
  final String wire;

  static TradeResult fromWire(String? value) {
    for (final r in TradeResult.values) {
      if (r.wire == value) return r;
    }
    return TradeResult.none;
  }

  String get label => switch (this) {
        TradeResult.tp => 'TP',
        TradeResult.sl => 'SL',
        TradeResult.none => 'Open',
      };
}

/// A single trade journal entry. The backend computes P&L, P&L %, and
/// risk/reward server-side, so [pnl] / [pnlPct] / [riskReward] are
/// read-only here — the form never sends them.
class Trade {
  const Trade({
    required this.id,
    required this.strategy,
    required this.strategyName,
    required this.symbol,
    required this.direction,
    required this.status,
    required this.result,
    required this.positionSize,
    required this.contractSize,
    required this.entryPrice,
    required this.exitPrice,
    required this.stopLoss,
    required this.takeProfit,
    required this.entryDate,
    required this.exitDate,
    required this.pnl,
    required this.pnlPct,
    required this.riskReward,
    required this.notes,
    required this.tags,
  });

  final int id;
  final int? strategy;
  final String strategyName;
  final String symbol;
  final TradeDirection direction;
  final TradeStatus status;
  final TradeResult result;
  final double positionSize;
  final double contractSize;
  final double entryPrice;
  final double? exitPrice;
  final double? stopLoss;
  final double? takeProfit;
  final DateTime entryDate;
  final DateTime? exitDate;
  final double? pnl;
  final double? pnlPct;
  final double? riskReward;
  final String notes;
  final String tags;

  bool get isOpen => status == TradeStatus.open;
  bool get isWinner => result == TradeResult.tp;
  bool get isLoser => result == TradeResult.sl;

  static double? _num(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  factory Trade.fromJson(Map<String, dynamic> json) => Trade(
        id: (json['id'] as num?)?.toInt() ?? 0,
        strategy: (json['strategy'] as num?)?.toInt(),
        strategyName: json['strategy_name'] as String? ?? '',
        symbol: json['symbol'] as String? ?? '',
        direction: TradeDirection.fromWire(json['direction'] as String?),
        status: TradeStatus.fromWire(json['status'] as String?),
        result: TradeResult.fromWire(json['result'] as String?),
        positionSize: _num(json['position_size']) ?? 0,
        contractSize: _num(json['contract_size']) ?? 100000,
        entryPrice: _num(json['entry_price']) ?? 0,
        exitPrice: _num(json['exit_price']),
        stopLoss: _num(json['stop_loss']),
        takeProfit: _num(json['take_profit']),
        entryDate: _date(json['entry_date']) ?? DateTime.now(),
        exitDate: _date(json['exit_date']),
        pnl: _num(json['pnl']),
        pnlPct: _num(json['pnl_pct']),
        riskReward: _num(json['risk_reward']),
        notes: json['notes'] as String? ?? '',
        tags: json['tags'] as String? ?? '',
      );
}
