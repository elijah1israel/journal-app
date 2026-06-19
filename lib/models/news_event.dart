/// Impact ranking on an economic-calendar event. Match the backend's
/// string codes 1-for-1 so the wire format round-trips cleanly.
enum NewsImpact {
  low('low'),
  medium('medium'),
  high('high');

  const NewsImpact(this.wire);
  final String wire;

  static NewsImpact fromWire(String? value) {
    for (final i in NewsImpact.values) {
      if (i.wire == value) return i;
    }
    return NewsImpact.low;
  }

  String get label => switch (this) {
        NewsImpact.low => 'Low',
        NewsImpact.medium => 'Medium',
        NewsImpact.high => 'High',
      };
}

/// One scheduled economic-calendar event (NFP, CPI, FOMC, …).
/// What the dashboard strip renders and what the news-blackout guardrail
/// triggers on. Mirrors `news.NewsEvent` on the backend.
class NewsEvent {
  const NewsEvent({
    required this.id,
    required this.when,
    required this.currency,
    required this.country,
    required this.impact,
    required this.title,
    required this.actual,
    required this.forecast,
    required this.previous,
  });

  final int id;
  final DateTime when;
  final String currency;
  final String country;
  final NewsImpact impact;
  final String title;
  final String actual;
  final String forecast;
  final String previous;

  factory NewsEvent.fromJson(Map<String, dynamic> json) => NewsEvent(
        id: (json['id'] as num?)?.toInt() ?? 0,
        when: DateTime.tryParse(json['when'] as String? ?? '') ??
            DateTime.now(),
        currency: (json['currency'] as String? ?? '').toUpperCase(),
        country: (json['country'] as String? ?? '').toUpperCase(),
        impact: NewsImpact.fromWire(json['impact'] as String?),
        title: json['title'] as String? ?? '',
        actual: json['actual'] as String? ?? '',
        forecast: json['forecast'] as String? ?? '',
        previous: json['previous'] as String? ?? '',
      );
}
