/// A single discrete entry-rule on a Strategy's pre-trade checklist.
/// Required rules block the "Take it" decision on a [TradePlan] unless
/// the trader gives an override reason.
class StrategyRule {
  const StrategyRule({
    required this.id,
    required this.text,
    required this.isRequired,
    required this.order,
  });

  final int id;
  final String text;
  final bool isRequired;
  final int order;

  factory StrategyRule.fromJson(Map<String, dynamic> json) => StrategyRule(
        id: (json['id'] as num?)?.toInt() ?? 0,
        text: json['text'] as String? ?? '',
        isRequired: json['is_required'] as bool? ?? true,
        order: (json['order'] as num?)?.toInt() ?? 0,
      );
}

/// A trading strategy / plan — a named bundle of rules, timeframes,
/// and markets that the trader tags each [Trade] with.
class Strategy {
  const Strategy({
    required this.id,
    required this.name,
    required this.description,
    required this.rules,
    required this.timeframes,
    required this.markets,
    required this.checklist,
  });

  final int id;
  final String name;
  final String description;
  final String rules;

  /// Comma-separated; e.g. "M15,H1,H4".
  final String timeframes;

  /// Comma-separated; e.g. "Forex,Gold".
  final String markets;

  /// Structured entry rules used by the pre-trade plan flow. The legacy
  /// [rules] text field above stays as freeform notes; this is the
  /// source of truth for the checklist UI.
  final List<StrategyRule> checklist;

  List<String> get timeframeList =>
      timeframes.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  List<String> get marketList =>
      markets.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  factory Strategy.fromJson(Map<String, dynamic> json) {
    final rawChecklist = json['checklist'];
    return Strategy(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      rules: json['rules'] as String? ?? '',
      timeframes: json['timeframes'] as String? ?? '',
      markets: json['markets'] as String? ?? '',
      checklist: rawChecklist is List
          ? rawChecklist
              .map((e) => StrategyRule.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList(growable: false)
          : const <StrategyRule>[],
    );
  }
}
