import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/trade.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import 'trade_form_screen.dart';

/// Month-at-a-glance P&L calendar — one cell per day, tinted by the
/// signed sum of that day's closed-trade P&L. Tap a day to open a
/// bottom sheet listing its trades.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final buckets = _bucketByDay(state.trades, _month);
    final monthTotal =
        buckets.values.fold<double>(0, (sum, list) => sum + _pnlOf(list));
    final winDays =
        buckets.values.where((list) => _pnlOf(list) > 0).length;
    final lossDays =
        buckets.values.where((list) => _pnlOf(list) < 0).length;
    final monthLabel = DateFormat.yMMMM().format(_month);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Calendar',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                state.loadingTrades ? null : () => state.refreshTrades(),
            icon: const Icon(Icons.refresh, color: AppColors.gray700),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.teal,
        onRefresh: () => state.refreshTrades(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _MonthHeader(
              label: monthLabel,
              onPrev: () => _shiftMonth(-1),
              onNext: () => _shiftMonth(1),
            ),
            const SizedBox(height: 14),
            _MonthSummary(
              total: monthTotal,
              winDays: winDays,
              lossDays: lossDays,
              tradedDays: buckets.length,
            ),
            const SizedBox(height: 18),
            _DayHeaderRow(),
            const SizedBox(height: 6),
            _MonthGrid(
              month: _month,
              buckets: buckets,
              onDayTap: (day) => _openDay(context, day, buckets[day] ?? const []),
            ),
            const SizedBox(height: 18),
            _Legend(),
          ],
        ),
      ),
    );
  }

  void _openDay(BuildContext context, DateTime day, List<Trade> trades) {
    if (trades.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DaySheet(day: day, trades: trades),
    );
  }

  /// Group the month's trades by exit-date day. Open trades (no exit
  /// date) don't show on the calendar — the P&L isn't realised yet.
  Map<DateTime, List<Trade>> _bucketByDay(
      List<Trade> all, DateTime month) {
    final out = <DateTime, List<Trade>>{};
    for (final t in all) {
      final exit = t.exitDate;
      if (exit == null) continue;
      final local = exit.toLocal();
      if (local.year != month.year || local.month != month.month) continue;
      final key = DateTime(local.year, local.month, local.day);
      (out[key] ??= <Trade>[]).add(t);
    }
    return out;
  }

  double _pnlOf(List<Trade> trades) =>
      trades.fold(0, (sum, t) => sum + (t.pnl ?? 0));
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.label,
    required this.onPrev,
    required this.onNext,
  });
  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.gray700),
          onPressed: onPrev,
        ),
        Expanded(
          child: Center(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gray900)),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: AppColors.gray700),
          onPressed: onNext,
        ),
      ],
    );
  }
}

class _MonthSummary extends StatelessWidget {
  const _MonthSummary({
    required this.total,
    required this.winDays,
    required this.lossDays,
    required this.tradedDays,
  });
  final double total;
  final int winDays;
  final int lossDays;
  final int tradedDays;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCell(
              label: 'Month P&L',
              value: formatPnl(total),
              color: AppColors.pnl(total),
            ),
          ),
          const _Divider(),
          Expanded(
            child: _SummaryCell(
              label: 'Traded days',
              value: tradedDays.toString(),
              color: AppColors.gray900,
            ),
          ),
          const _Divider(),
          Expanded(
            child: _SummaryCell(
              label: 'Win · Loss',
              value: '$winDays · $lossDays',
              color: AppColors.gray900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppColors.gray500)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: color)),
        ],
      );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 30,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: AppColors.borderSoft,
      );
}

class _DayHeaderRow extends StatelessWidget {
  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final d in _days)
          Expanded(
            child: Center(
              child: Text(d,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray500)),
            ),
          ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.buckets,
    required this.onDayTap,
  });

  final DateTime month;
  final Map<DateTime, List<Trade>> buckets;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Monday = 1 → leadingBlanks = 0; Sunday = 7 → leadingBlanks = 6.
    final leadingBlanks = (first.weekday - 1) % 7;
    final totalCells = leadingBlanks + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final today = DateTime.now();
    final isThisMonth =
        today.year == month.year && today.month == month.month;

    final cells = <Widget>[];
    for (int i = 0; i < rows * 7; i++) {
      final dayNum = i - leadingBlanks + 1;
      if (dayNum < 1 || dayNum > daysInMonth) {
        cells.add(const _EmptyCell());
        continue;
      }
      final date = DateTime(month.year, month.month, dayNum);
      final trades = buckets[date] ?? const <Trade>[];
      final pnl = trades.fold<double>(0, (s, t) => s + (t.pnl ?? 0));
      cells.add(_DayCell(
        day: dayNum,
        pnl: trades.isEmpty ? null : pnl,
        tradeCount: trades.length,
        isToday: isThisMonth && dayNum == today.day,
        onTap: () => onDayTap(date),
      ));
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: cells,
    );
  }
}

class _EmptyCell extends StatelessWidget {
  const _EmptyCell();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.pnl,
    required this.tradeCount,
    required this.isToday,
    required this.onTap,
  });

  final int day;
  final double? pnl;
  final int tradeCount;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasPnl = pnl != null && tradeCount > 0;
    final tone = hasPnl ? AppColors.pnl(pnl!) : AppColors.gray500;
    final fill = hasPnl ? tone.withOpacity(0.12) : AppColors.surface;
    final borderColor = isToday
        ? AppColors.ink
        : (hasPnl ? tone.withOpacity(0.35) : AppColors.border);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: hasPnl ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: isToday ? 1.5 : 1),
        ),
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(day.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                  color: AppColors.gray900,
                )),
            if (hasPnl)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatPnl(pnl),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: tone,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendDot(color: AppColors.success, label: 'Win day'),
        const SizedBox(width: 16),
        _LegendDot(color: AppColors.danger, label: 'Loss day'),
        const SizedBox(width: 16),
        _LegendDot(color: AppColors.gray400, label: 'No trades'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color.withOpacity(0.25),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: color.withOpacity(0.55)),
            ),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 11.5, color: AppColors.gray600)),
        ],
      );
}

class _DaySheet extends StatelessWidget {
  const _DaySheet({required this.day, required this.trades});
  final DateTime day;
  final List<Trade> trades;

  static final _date = DateFormat.yMMMMEEEEd();

  @override
  Widget build(BuildContext context) {
    final pnl = trades.fold<double>(0, (s, t) => s + (t.pnl ?? 0));
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 4, bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_date.format(day),
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gray700)),
                      const SizedBox(height: 4),
                      Text('${trades.length} trade${trades.length == 1 ? "" : "s"}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.gray500)),
                    ],
                  ),
                ),
                Text(formatPnl(pnl),
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.pnl(pnl))),
              ],
            ),
            const SizedBox(height: 14),
            for (final t in trades) _DayTradeRow(trade: t),
          ],
        ),
      ),
    );
  }
}

class _DayTradeRow extends StatelessWidget {
  const _DayTradeRow({required this.trade});
  final Trade trade;

  @override
  Widget build(BuildContext context) {
    final pnl = trade.pnl ?? 0;
    final tone = AppColors.pnl(pnl);
    final isLong = trade.direction == TradeDirection.buy;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.of(context).pop();
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => TradeFormScreen(initial: trade)));
      },
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(isLong ? Icons.trending_up : Icons.trending_down,
                size: 18, color: tone),
            const SizedBox(width: 10),
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
                        fontSize: 11.5, color: AppColors.gray500),
                  ),
                ],
              ),
            ),
            Text(formatPnl(pnl),
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: tone)),
          ],
        ),
      ),
    );
  }
}
