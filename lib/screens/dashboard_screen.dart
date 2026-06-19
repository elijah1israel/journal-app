import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/trade_plan.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import '../widgets/wickbook_top_bar.dart';

/// The dashboard tab — stat tiles + a "recent trades" list. Mirrors
/// the React `DashboardPage` from trade-journal-frontend, condensed
/// for a phone-sized layout.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final name = state.user?.displayName.split(' ').first ?? '';
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: WickbookTopBar(
        section: name.isEmpty ? 'Dashboard' : 'Hi, $name',
      ),
      body: RefreshIndicator(
        color: AppColors.teal,
        onRefresh: () => state.refreshTrades(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _StatGrid(state: state),
            if (state.discipline != null &&
                state.discipline!.plannedTrades > 0) ...[
              const SizedBox(height: 16),
              _DisciplineCard(stats: state.discipline!),
            ],
            const SizedBox(height: 20),
            const _SectionHeader(title: 'Recent trades'),
            const SizedBox(height: 8),
            if (state.loadingTrades && state.trades.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.teal)),
              )
            else if (state.trades.isEmpty)
              const EmptyState(
                icon: Icons.show_chart,
                title: 'No trades yet',
                subtitle:
                    'Once you log a trade it shows up here with running P&L.',
              )
            else
              ..._recent(state).map((t) => _MiniTradeTile(trade: t)),
          ],
        ),
      ),
    );
  }

  List _recent(AppState state) {
    final list = state.trades.toList();
    list.sort((a, b) => b.entryDate.compareTo(a.entryDate));
    return list.take(5).toList();
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppColors.gray700,
          letterSpacing: 0.2));
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final winRate = state.winRate;
    final pnl = state.totalPnl;
    final best = state.bestTradePnl;
    final avgRr = state.avgRiskReward;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _StatCard(
                    label: 'Total P&L',
                    value: formatPnl(pnl),
                    color: AppColors.pnl(pnl))),
            const SizedBox(width: 12),
            Expanded(
                child: _StatCard(
                    label: 'Win rate',
                    value: '${winRate.toStringAsFixed(0)}%',
                    color: AppColors.ink)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _StatCard(
                    label: 'Best trade',
                    value: formatPnl(best),
                    color: AppColors.success)),
            const SizedBox(width: 12),
            Expanded(
                child: _StatCard(
                    label: 'Avg R:R',
                    value: avgRr == 0 ? '–' : avgRr.toStringAsFixed(2),
                    color: AppColors.violet)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _StatCard(
                    label: 'Open',
                    value: state.openTrades.toString(),
                    color: AppColors.info)),
            const SizedBox(width: 12),
            Expanded(
                child: _StatCard(
                    label: 'Closed',
                    value: state.closedTrades.toString(),
                    color: AppColors.gray700)),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppColors.gray500)),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -0.3)),
        ],
      ),
    );
  }
}

class _MiniTradeTile extends StatelessWidget {
  const _MiniTradeTile({required this.trade});
  final dynamic trade;

  @override
  Widget build(BuildContext context) {
    final pnl = trade.pnl as double?;
    final pnlColor = AppColors.pnl(pnl ?? 0);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: pnlColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              trade.direction.label == 'Long'
                  ? Icons.trending_up
                  : Icons.trending_down,
              color: pnlColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trade.symbol,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900)),
                Text(
                  '${trade.direction.label} · ${trade.strategyName.isEmpty ? "No strategy" : trade.strategyName}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.gray500),
                ),
              ],
            ),
          ),
          Text(formatPnl(pnl),
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: pnlColor)),
        ],
      ),
    );
  }
}


/// Dashboard tile that contrasts win rate + P&L on trades where the
/// pre-trade checklist was followed vs broken. Hidden until at least
/// one planned trade exists — the comparison is only meaningful once
/// both buckets have data.
class _DisciplineCard extends StatelessWidget {
  const _DisciplineCard({required this.stats});
  final DisciplineStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rule, color: AppColors.tealDarker, size: 18),
              const SizedBox(width: 8),
              const Text('Discipline',
                  style: TextStyle(
                      color: AppColors.gray900,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
              const Spacer(),
              if (stats.planningRate != null)
                Text(
                  '${stats.planningRate!.toStringAsFixed(0)}% planned',
                  style: const TextStyle(
                      color: AppColors.gray500, fontSize: 11),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DisciplineBucket(
                  label: 'Followed rules',
                  count: stats.followedCount,
                  winRate: stats.followedWinRate,
                  pnl: stats.followedPnl,
                  accent: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DisciplineBucket(
                  label: 'Broke rules',
                  count: stats.brokenCount,
                  winRate: stats.brokenWinRate,
                  pnl: stats.brokenPnl,
                  accent: AppColors.danger,
                ),
              ),
            ],
          ),
          if (stats.hasComparison &&
              stats.followedWinRate != null &&
              stats.brokenWinRate != null) ...[
            const SizedBox(height: 10),
            Text(
              _verdict(stats.followedWinRate!, stats.brokenWinRate!),
              style: const TextStyle(
                  color: AppColors.gray600, fontSize: 12, height: 1.35),
            ),
          ],
        ],
      ),
    );
  }

  String _verdict(double followed, double broken) {
    final delta = followed - broken;
    if (delta >= 5) {
      return 'You win ${delta.toStringAsFixed(0)} percentage points more often '
          'when you follow your rules. The checklist is paying.';
    }
    if (delta <= -5) {
      return 'Counter-intuitively your rule-breaking trades win more here — '
          'worth auditing whether the rules still fit the market.';
    }
    return 'Following or breaking rules gives similar win rates right now. '
        'Watch how this trends as more trades land.';
  }
}

class _DisciplineBucket extends StatelessWidget {
  const _DisciplineBucket({
    required this.label,
    required this.count,
    required this.winRate,
    required this.pnl,
    required this.accent,
  });

  final String label;
  final int count;
  final double? winRate;
  final double pnl;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: accent)),
          const SizedBox(height: 6),
          Text(
            winRate == null ? '–' : '${winRate!.toStringAsFixed(0)}%',
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.gray900),
          ),
          Text(
            '$count trades · ${formatPnl(pnl)}',
            style: const TextStyle(
                fontSize: 11, color: AppColors.gray500),
          ),
        ],
      ),
    );
  }
}

