import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/trade.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import 'trade_form_screen.dart';

/// The trade journal — paginated list with filters (status + direction).
/// Tapping a row opens the edit sheet; the floating "+" opens the
/// log-trade form.
class TradesScreen extends StatefulWidget {
  const TradesScreen({super.key});

  @override
  State<TradesScreen> createState() => _TradesScreenState();
}

class _TradesScreenState extends State<TradesScreen> {
  String _statusFilter = '';
  String _directionFilter = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final trades = _apply(state.trades);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Trades',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: state.loadingTrades ? null : () => state.refreshTrades(),
            icon: const Icon(Icons.refresh, color: AppColors.gray700),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const TradeFormScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Log trade',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          _FilterBar(
            status: _statusFilter,
            direction: _directionFilter,
            onStatus: (v) => setState(() => _statusFilter = v),
            onDirection: (v) => setState(() => _directionFilter = v),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.teal,
              onRefresh: () => state.refreshTrades(),
              child: trades.isEmpty
                  ? ListView(
                      // ListView keeps RefreshIndicator interactive when empty.
                      children: const [
                        SizedBox(height: 80),
                        EmptyState(
                          icon: Icons.candlestick_chart_outlined,
                          title: 'No trades yet',
                          subtitle: 'Tap "Log trade" to add your first.',
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: trades.length,
                      itemBuilder: (_, i) => _TradeTile(trade: trades[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  List<Trade> _apply(List<Trade> raw) {
    return raw.where((t) {
      if (_statusFilter.isNotEmpty && t.status.wire != _statusFilter) {
        return false;
      }
      if (_directionFilter.isNotEmpty &&
          t.direction.wire != _directionFilter) {
        return false;
      }
      return true;
    }).toList();
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.status,
    required this.direction,
    required this.onStatus,
    required this.onDirection,
  });

  final String status;
  final String direction;
  final ValueChanged<String> onStatus;
  final ValueChanged<String> onDirection;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          _Chip(
            label: 'All',
            selected: status.isEmpty,
            onTap: () => onStatus(''),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Open',
            selected: status == 'open',
            onTap: () => onStatus(status == 'open' ? '' : 'open'),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Closed',
            selected: status == 'closed',
            onTap: () => onStatus(status == 'closed' ? '' : 'closed'),
          ),
          const Spacer(),
          _Chip(
            label: 'Long',
            selected: direction == 'buy',
            onTap: () => onDirection(direction == 'buy' ? '' : 'buy'),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Short',
            selected: direction == 'sell',
            onTap: () => onDirection(direction == 'sell' ? '' : 'sell'),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.ink : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.gray700,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _TradeTile extends StatelessWidget {
  const _TradeTile({required this.trade});
  final Trade trade;

  static final _date = DateFormat('MMM d, HH:mm');

  @override
  Widget build(BuildContext context) {
    final pnl = trade.pnl;
    final pnlColor = AppColors.pnl(pnl ?? 0);
    final isLong = trade.direction == TradeDirection.buy;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => TradeFormScreen(initial: trade))),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (isLong ? AppColors.success : AppColors.danger)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isLong ? Icons.trending_up : Icons.trending_down,
                    color: isLong ? AppColors.success : AppColors.danger,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(trade.symbol,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: AppColors.gray900)),
                          const SizedBox(width: 8),
                          StatusPill(
                            label: trade.direction.label.toUpperCase(),
                            color: isLong
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                          const SizedBox(width: 6),
                          if (trade.isOpen)
                            const StatusPill(
                                label: 'OPEN', color: AppColors.info)
                          else
                            StatusPill(
                              label: trade.result.label.toUpperCase(),
                              color: trade.isWinner
                                  ? AppColors.success
                                  : AppColors.gray500,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _date.format(trade.entryDate.toLocal()),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.gray500),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatPnl(pnl),
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: pnlColor)),
                    if (trade.riskReward != null)
                      Text('R:R ${trade.riskReward!.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.gray500)),
                  ],
                ),
              ],
            ),
            if (trade.strategyName.isNotEmpty ||
                trade.entryPrice > 0 ||
                trade.exitPrice != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    if (trade.strategyName.isNotEmpty) ...[
                      const Icon(Icons.tune,
                          size: 13, color: AppColors.gray400),
                      const SizedBox(width: 4),
                      Text(trade.strategyName,
                          style: const TextStyle(
                              fontSize: 11.5, color: AppColors.gray600)),
                      const SizedBox(width: 12),
                    ],
                    if (trade.entryPrice > 0)
                      Text(
                        'in ${formatPrice(trade.entryPrice)}'
                        '${trade.exitPrice != null ? " → ${formatPrice(trade.exitPrice)}" : ""}',
                        style: const TextStyle(
                            fontSize: 11.5, color: AppColors.gray600),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
