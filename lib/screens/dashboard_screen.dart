import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

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
      appBar: AppBar(
        title: Text(name.isEmpty ? 'Dashboard' : 'Hi, $name',
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      body: RefreshIndicator(
        color: AppColors.teal,
        onRefresh: () => state.refreshTrades(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _StatGrid(state: state),
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
