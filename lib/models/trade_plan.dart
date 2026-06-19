/// The trader's decision on a [TradePlan] once the checklist is run.
enum PlanDecision {
  planned('planned'),
  take('take'),
  skip('skip');

  const PlanDecision(this.wire);
  final String wire;

  static PlanDecision fromWire(String? value) {
    for (final d in PlanDecision.values) {
      if (d.wire == value) return d;
    }
    return PlanDecision.planned;
  }

  String get label => switch (this) {
        PlanDecision.planned => 'Planned',
        PlanDecision.take => 'Took it',
        PlanDecision.skip => 'Skipped',
      };
}

/// Snapshot of a single rule's tick state on a plan. `ruleText` and
/// `isRequired` are denormalised from the rule for display — the source
/// of truth still lives on [StrategyRule].
class TradePlanCheck {
  const TradePlanCheck({
    required this.ruleId,
    required this.ruleText,
    required this.isRequired,
    required this.checked,
  });

  final int ruleId;
  final String ruleText;
  final bool isRequired;
  final bool checked;

  TradePlanCheck copyWith({bool? checked}) => TradePlanCheck(
        ruleId: ruleId,
        ruleText: ruleText,
        isRequired: isRequired,
        checked: checked ?? this.checked,
      );

  factory TradePlanCheck.fromJson(Map<String, dynamic> json) => TradePlanCheck(
        ruleId: (json['rule'] as num?)?.toInt() ?? 0,
        ruleText: json['rule_text'] as String? ?? '',
        isRequired: json['is_required'] as bool? ?? true,
        checked: json['checked'] as bool? ?? false,
      );

  Map<String, dynamic> toWire() => {
        'rule': ruleId,
        'checked': checked,
      };
}

/// A pre-trade plan — the bridge between "I see a setup" and "I'm in
/// the market". The trader picks a strategy, ticks each rule, decides
/// take/skip, and optionally writes an override reason if they're
/// taking a trade with broken rules (the tilt-tag the dashboard ranks).
class TradePlan {
  const TradePlan({
    required this.id,
    required this.strategyId,
    required this.symbol,
    required this.direction,
    required this.plannedEntry,
    required this.plannedSl,
    required this.plannedTp,
    required this.plannedSize,
    required this.decision,
    required this.overrideReason,
    required this.notes,
    required this.checks,
    required this.requiredRulesFollowed,
    required this.createdAt,
    required this.decidedAt,
  });

  final int id;
  final int? strategyId;
  final String symbol;
  final String direction; // 'buy' | 'sell'
  final double? plannedEntry;
  final double? plannedSl;
  final double? plannedTp;
  final double? plannedSize;
  final PlanDecision decision;
  final String overrideReason;
  final String notes;
  final List<TradePlanCheck> checks;
  final bool requiredRulesFollowed;
  final DateTime createdAt;
  final DateTime? decidedAt;

  static double? _num(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static DateTime? _date(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());

  factory TradePlan.fromJson(Map<String, dynamic> json) {
    final rawChecks = (json['checks'] as List?) ?? const [];
    return TradePlan(
      id: (json['id'] as num?)?.toInt() ?? 0,
      strategyId: (json['strategy'] as num?)?.toInt(),
      symbol: json['symbol'] as String? ?? '',
      direction: json['direction'] as String? ?? 'buy',
      plannedEntry: _num(json['planned_entry']),
      plannedSl: _num(json['planned_sl']),
      plannedTp: _num(json['planned_tp']),
      plannedSize: _num(json['planned_size']),
      decision: PlanDecision.fromWire(json['decision'] as String?),
      overrideReason: json['override_reason'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      checks: rawChecks
          .map((e) => TradePlanCheck.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false),
      requiredRulesFollowed: json['required_rules_followed'] as bool? ?? true,
      createdAt: _date(json['created_at']) ?? DateTime.now(),
      decidedAt: _date(json['decided_at']),
    );
  }
}

/// Compact news payload the guardrail status carries when a blackout
/// fires. Only the fields the block screen needs to render the reason
/// — for the full event use the /api/news/ endpoint.
class NewsBlackoutEvent {
  const NewsBlackoutEvent({
    required this.id,
    required this.when,
    required this.currency,
    required this.impact,
    required this.title,
  });

  final int id;
  final DateTime when;
  final String currency;
  final String impact;
  final String title;

  factory NewsBlackoutEvent.fromJson(Map<String, dynamic> json) =>
      NewsBlackoutEvent(
        id: (json['id'] as num?)?.toInt() ?? 0,
        when: DateTime.tryParse(json['when'] as String? ?? '') ??
            DateTime.now(),
        currency: (json['currency'] as String? ?? '').toUpperCase(),
        impact: json['impact'] as String? ?? 'high',
        title: json['title'] as String? ?? '',
      );
}

/// Live status of the trader's risk guardrails (daily loss cap +
/// post-loss cool-down + news blackout). Computed server-side —
/// `canTrade` is what the Plan screen reads to decide between
/// rendering the form and rendering the block banner.
class GuardrailStatus {
  const GuardrailStatus({
    required this.dailyPnl,
    required this.dailyLossLimit,
    required this.dailyLossLimitHit,
    required this.coolDownMinutes,
    required this.coolDownUntil,
    required this.newsBlackoutMinutes,
    required this.newsBlackoutEvent,
    required this.canTrade,
    required this.blockReason,
  });

  final double dailyPnl;
  final double? dailyLossLimit;
  final bool dailyLossLimitHit;
  final int coolDownMinutes;
  final DateTime? coolDownUntil;
  final int newsBlackoutMinutes;
  final NewsBlackoutEvent? newsBlackoutEvent;
  final bool canTrade;
  final String blockReason;

  static double? _maybeDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  factory GuardrailStatus.fromJson(Map<String, dynamic> json) {
    final rawEvent = json['news_blackout_event'];
    return GuardrailStatus(
      dailyPnl: (json['daily_pnl'] as num?)?.toDouble() ?? 0,
      dailyLossLimit: _maybeDouble(json['daily_loss_limit']),
      dailyLossLimitHit: json['daily_loss_limit_hit'] as bool? ?? false,
      coolDownMinutes: (json['cool_down_minutes'] as num?)?.toInt() ?? 0,
      coolDownUntil: json['cool_down_until'] == null
          ? null
          : DateTime.tryParse(json['cool_down_until'] as String),
      newsBlackoutMinutes:
          (json['news_blackout_minutes'] as num?)?.toInt() ?? 0,
      newsBlackoutEvent: rawEvent is Map
          ? NewsBlackoutEvent.fromJson(Map<String, dynamic>.from(rawEvent))
          : null,
      canTrade: json['can_trade'] as bool? ?? true,
      blockReason: json['block_reason'] as String? ?? '',
    );
  }
}

/// Discipline aggregate the dashboard renders ("you trade better when
/// you follow your rules").
class DisciplineStats {
  const DisciplineStats({
    required this.closedTrades,
    required this.plannedTrades,
    required this.planningRate,
    required this.followedCount,
    required this.followedWinRate,
    required this.followedPnl,
    required this.brokenCount,
    required this.brokenWinRate,
    required this.brokenPnl,
  });

  final int closedTrades;
  final int plannedTrades;
  final double? planningRate;
  final int followedCount;
  final double? followedWinRate;
  final double followedPnl;
  final int brokenCount;
  final double? brokenWinRate;
  final double brokenPnl;

  bool get hasComparison => followedCount > 0 && brokenCount > 0;

  static double? _maybeDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  factory DisciplineStats.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> bucket(String key) =>
        Map<String, dynamic>.from((json[key] as Map?) ?? const {});
    final f = bucket('followed');
    final b = bucket('broken');
    return DisciplineStats(
      closedTrades: (json['closed_trades_total'] as num?)?.toInt() ?? 0,
      plannedTrades: (json['planned_trades_total'] as num?)?.toInt() ?? 0,
      planningRate: _maybeDouble(json['planning_rate']),
      followedCount: (f['count'] as num?)?.toInt() ?? 0,
      followedWinRate: _maybeDouble(f['win_rate']),
      followedPnl: (f['total_pnl'] as num?)?.toDouble() ?? 0,
      brokenCount: (b['count'] as num?)?.toInt() ?? 0,
      brokenWinRate: _maybeDouble(b['win_rate']),
      brokenPnl: (b['total_pnl'] as num?)?.toDouble() ?? 0,
    );
  }
}
