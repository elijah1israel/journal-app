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
  });

  final int id;
  final String name;
  final String description;
  final String rules;

  /// Comma-separated; e.g. "M15,H1,H4".
  final String timeframes;

  /// Comma-separated; e.g. "Forex,Gold".
  final String markets;

  List<String> get timeframeList =>
      timeframes.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  List<String> get marketList =>
      markets.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  factory Strategy.fromJson(Map<String, dynamic> json) => Strategy(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        rules: json['rules'] as String? ?? '',
        timeframes: json['timeframes'] as String? ?? '',
        markets: json['markets'] as String? ?? '',
      );
}
