import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/trade.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import '../widgets/wickbook_top_bar.dart';
import 'trade_form_screen.dart';

/// Month-at-a-glance P&L calendar. Swipe horizontally between months,
/// or tap the month label for a year/month picker. Each day cell is
/// tinted by the signed sum of that day's closed-trade P&L; tap a day
/// to drill into its trade list.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  /// Anchor month used as the PageView's base — index 0 maps to here,
  /// page _baseIndex is `_anchor`, every step is one month away. We
  /// pick "today" so the initial render lands on the current month.
  late final DateTime _anchor;

  // Large initial index so the user can swipe back many years without
  // hitting the start of the PageView.
  static const int _baseIndex = 1200;

  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _anchor = DateTime(now.year, now.month);
    _currentIndex = _baseIndex;
    _controller = PageController(initialPage: _baseIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  DateTime _monthForIndex(int index) {
    final delta = index - _baseIndex;
    return DateTime(_anchor.year, _anchor.month + delta);
  }

  int _indexForMonth(DateTime month) {
    return _baseIndex +
        (month.year - _anchor.year) * 12 +
        (month.month - _anchor.month);
  }

  bool get _isOnAnchor => _currentIndex == _baseIndex;

  void _jumpToMonth(DateTime month, {bool animate = true}) {
    final target = _indexForMonth(DateTime(month.year, month.month));
    if (animate && (target - _currentIndex).abs() <= 1) {
      _controller.animateToPage(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    } else {
      _controller.jumpToPage(target);
    }
  }

  Future<void> _openMonthPicker(DateTime current) async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MonthYearPickerSheet(initial: current),
    );
    if (picked != null) {
      _jumpToMonth(picked, animate: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final current = _monthForIndex(_currentIndex);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: WickbookTopBar(
        section: 'Calendar',
        actions: [
          if (!_isOnAnchor)
            TextButton(
              onPressed: () => _jumpToMonth(_anchor, animate: false),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.teal,
                textStyle:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              child: const Text('Today'),
            ),
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
        child: Column(
          children: [
            _MonthHeader(
              month: current,
              onPrev: () => _controller.previousPage(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
              ),
              onNext: () => _controller.nextPage(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
              ),
              onTapLabel: () => _openMonthPicker(current),
            ),
            const _DayHeaderRow(),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (_, index) {
                  final month = _monthForIndex(index);
                  return _MonthPage(
                    month: month,
                    trades: state.trades,
                    onDayTap: (day, trades) => _openDay(context, day, trades),
                  );
                },
              ),
            ),
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
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onPrev,
    required this.onNext,
    required this.onTapLabel,
  });
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onTapLabel;

  @override
  Widget build(BuildContext context) {
    final label = DateFormat.yMMMM().format(month);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppColors.gray700),
            onPressed: onPrev,
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onTapLabel,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: AppColors.gray900,
                            letterSpacing: -0.3)),
                    const SizedBox(width: 6),
                    const Icon(Icons.expand_more,
                        size: 20, color: AppColors.gray500),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppColors.gray700),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _DayHeaderRow extends StatelessWidget {
  const _DayHeaderRow();
  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Row(
        children: [
          for (final d in _days)
            Expanded(
              child: Center(
                child: Text(d,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppColors.gray500)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Renders a single month: summary card on top, then the grid of days.
class _MonthPage extends StatelessWidget {
  const _MonthPage({
    required this.month,
    required this.trades,
    required this.onDayTap,
  });

  final DateTime month;
  final List<Trade> trades;
  final void Function(DateTime day, List<Trade> trades) onDayTap;

  Map<DateTime, List<Trade>> _bucket() {
    final out = <DateTime, List<Trade>>{};
    for (final t in trades) {
      final exit = t.exitDate;
      if (exit == null) continue;
      final local = exit.toLocal();
      if (local.year != month.year || local.month != month.month) continue;
      final key = DateTime(local.year, local.month, local.day);
      (out[key] ??= <Trade>[]).add(t);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final buckets = _bucket();
    final monthTotal =
        buckets.values.fold<double>(0, (s, list) => s + _pnlOf(list));
    final winDays = buckets.values.where((l) => _pnlOf(l) > 0).length;
    final lossDays = buckets.values.where((l) => _pnlOf(l) < 0).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      physics: const BouncingScrollPhysics(),
      children: [
        _MonthSummary(
          total: monthTotal,
          winDays: winDays,
          lossDays: lossDays,
          tradedDays: buckets.length,
        ),
        const SizedBox(height: 12),
        _MonthGrid(month: month, buckets: buckets, onDayTap: onDayTap),
        const SizedBox(height: 16),
        const _Legend(),
        if (trades.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Text(
              'No trades yet — log one or import a broker CSV from the Trades tab to start seeing days light up.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, color: AppColors.gray500, height: 1.45),
            ),
          ),
      ],
    );
  }

  double _pnlOf(List<Trade> list) =>
      list.fold(0, (sum, t) => sum + (t.pnl ?? 0));
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
    final pnlColor = AppColors.pnl(total);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MONTH P&L',
                    style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.gray500)),
                const SizedBox(height: 4),
                Text(
                  formatPnl(total),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: pnlColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          _MetricCell(label: 'Days', value: tradedDays.toString()),
          const SizedBox(width: 16),
          _MetricCell(
            label: 'W · L',
            value: '$winDays · $lossDays',
          ),
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.gray500)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.gray900)),
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
  final void Function(DateTime day, List<Trade> trades) onDayTap;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
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
        cells.add(const SizedBox.shrink());
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
        onTap: () => onDayTap(date, trades),
      ));
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      childAspectRatio: 0.85,
      children: cells,
    );
  }
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

    Color fillColor;
    Color borderColor;
    if (hasPnl) {
      fillColor = tone.withOpacity(0.14);
      borderColor = tone.withOpacity(0.30);
    } else {
      fillColor = AppColors.surface;
      borderColor = AppColors.border;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: hasPnl ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: isToday
                      ? BoxDecoration(
                          color: AppColors.teal,
                          borderRadius: BorderRadius.circular(999),
                        )
                      : null,
                  child: Text(
                    day.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isToday
                          ? AppColors.inkDeep
                          : AppColors.gray900,
                    ),
                  ),
                ),
              ],
            ),
            if (hasPnl)
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.bottomLeft,
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
  const _Legend();
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendDot(color: AppColors.success, label: 'Win'),
        const SizedBox(width: 16),
        _LegendDot(color: AppColors.danger, label: 'Loss'),
        const SizedBox(width: 16),
        _LegendDot(color: AppColors.gray500, label: 'No trades'),
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
              color: color.withOpacity(0.28),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: color.withOpacity(0.55)),
            ),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 11.5, color: AppColors.gray500)),
        ],
      );
}

/// Bottom-sheet month + year picker. Year stepper on top, 4×3 month
/// grid below — same idiom as the iOS calendar pickers.
class _MonthYearPickerSheet extends StatefulWidget {
  const _MonthYearPickerSheet({required this.initial});
  final DateTime initial;

  @override
  State<_MonthYearPickerSheet> createState() => _MonthYearPickerSheetState();
}

class _MonthYearPickerSheetState extends State<_MonthYearPickerSheet> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    _year = widget.initial.year;
    _month = widget.initial.month;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final isThisYear = _year == today.year;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 8, bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left,
                        color: AppColors.gray700),
                    onPressed: () => setState(() => _year--),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        _year.toString(),
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.gray900,
                            letterSpacing: -0.5),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right,
                        color: AppColors.gray700),
                    onPressed: () => setState(() => _year++),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.7,
                children: List.generate(12, (i) {
                  final m = i + 1;
                  final isSelected = m == _month;
                  final isCurrentMonth = isThisYear && m == today.month;
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => _month = m),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.teal
                            : AppColors.bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.teal
                              : (isCurrentMonth
                                  ? AppColors.teal.withOpacity(0.5)
                                  : AppColors.border),
                          width: isCurrentMonth && !isSelected ? 1.5 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        DateFormat.MMM().format(DateTime(_year, m)),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? AppColors.inkDeep
                              : AppColors.gray900,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() {
                        _year = today.year;
                        _month = today.month;
                      }),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: AppColors.gray700,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Today',
                          style:
                              TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      label: 'Go',
                      icon: Icons.calendar_today_outlined,
                      onPressed: () => Navigator.of(context)
                          .pop(DateTime(_year, _month)),
                    ),
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
                              fontWeight: FontWeight.w800,
                              color: AppColors.gray900)),
                      const SizedBox(height: 4),
                      Text(
                          '${trades.length} trade${trades.length == 1 ? "" : "s"}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.gray500)),
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
                          fontWeight: FontWeight.w800,
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
