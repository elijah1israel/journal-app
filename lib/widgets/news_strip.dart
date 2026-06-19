import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/news_event.dart';
import '../theme/app_theme.dart';

/// Horizontal strip of the next high-impact news events for the
/// trader's watched currencies. Sits on the Dashboard above Recent
/// trades; hidden when nothing's in the next 48h window.
///
/// Stays read-only — tapping a card doesn't open anything in Phase 1;
/// the event payload is also surfaced on the Plan-screen block when
/// it's the reason new plans are refused.
class NewsStrip extends StatelessWidget {
  const NewsStrip({super.key, required this.events});

  final List<NewsEvent> events;

  /// Cap at 5 so we don't take over the dashboard.
  List<NewsEvent> get _shown {
    final upcoming = events.where((e) => e.when.isAfter(DateTime.now())).toList();
    upcoming.sort((a, b) {
      // High impact first, then soonest.
      final byImpact = b.impact.index.compareTo(a.impact.index);
      if (byImpact != 0) return byImpact;
      return a.when.compareTo(b.when);
    });
    return upcoming.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
    if (shown.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'NEXT NEWS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: AppColors.gray500,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            itemCount: shown.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _NewsCard(event: shown[i]),
          ),
        ),
      ],
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.event});
  final NewsEvent event;

  Color get _accent => switch (event.impact) {
        NewsImpact.high => AppColors.danger,
        NewsImpact.medium => AppColors.warn,
        NewsImpact.low => AppColors.gray500,
      };

  String _timeUntil() {
    final delta = event.when.difference(DateTime.now());
    if (delta.inMinutes < 60) return 'in ${delta.inMinutes}m';
    if (delta.inHours < 24) return 'in ${delta.inHours}h';
    return DateFormat('MMM d HH:mm').format(event.when.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  event.currency,
                  style: TextStyle(
                      color: _accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4),
                ),
              ),
              const Spacer(),
              Text(_timeUntil(),
                  style: const TextStyle(
                      color: AppColors.gray500, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              event.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.gray900,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  height: 1.25),
            ),
          ),
          if (event.forecast.isNotEmpty || event.previous.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _forecastLine(),
                style: const TextStyle(
                    color: AppColors.gray500, fontSize: 10.5),
              ),
            ),
        ],
      ),
    );
  }

  String _forecastLine() {
    final parts = <String>[];
    if (event.forecast.isNotEmpty) parts.add('fcst ${event.forecast}');
    if (event.previous.isNotEmpty) parts.add('prev ${event.previous}');
    return parts.join(' · ');
  }
}
