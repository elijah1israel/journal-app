import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A compact "buys vs sells" breakdown — a stacked proportional bar with
/// a count legend underneath. Buys (Long) read in brand emerald, sells
/// (Short) in the bearish red, so the split speaks the same green/red
/// colour language as the rest of the P&L surfaces.
class BuySellChart extends StatelessWidget {
  const BuySellChart({
    super.key,
    required this.buys,
    required this.sells,
  });

  final int buys;
  final int sells;

  @override
  Widget build(BuildContext context) {
    final total = buys + sells;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: total == 0
          ? const Text(
              'No trades yet — log one or import a broker CSV to see your '
              'buy / sell split.',
              style: TextStyle(
                  fontSize: 12, color: AppColors.gray500, height: 1.45),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _Count(
                        label: 'Buys',
                        sublabel: 'Long',
                        value: buys,
                        color: AppColors.success,
                      ),
                    ),
                    Expanded(
                      child: _Count(
                        label: 'Sells',
                        sublabel: 'Short',
                        value: sells,
                        color: AppColors.danger,
                        alignEnd: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _StackedBar(buys: buys, sells: sells),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _LegendDot(
                      color: AppColors.success,
                      label: '${_pct(buys, total)}% buys',
                    ),
                    _LegendDot(
                      color: AppColors.danger,
                      label: '${_pct(sells, total)}% sells',
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  int _pct(int part, int total) =>
      total == 0 ? 0 : (part * 100 / total).round();
}

class _StackedBar extends StatelessWidget {
  const _StackedBar({required this.buys, required this.sells});
  final int buys;
  final int sells;

  @override
  Widget build(BuildContext context) {
    final total = buys + sells;
    // Guard against a zero-width flex when one side is empty.
    final buyFlex = buys == 0 ? 0 : buys;
    final sellFlex = sells == 0 ? 0 : sells;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 12,
        child: Row(
          children: [
            if (buyFlex > 0)
              Expanded(
                flex: buyFlex,
                child: Container(color: AppColors.success),
              ),
            if (buyFlex > 0 && sellFlex > 0) const SizedBox(width: 2),
            if (sellFlex > 0)
              Expanded(
                flex: sellFlex,
                child: Container(color: AppColors.danger),
              ),
            if (total == 0)
              Expanded(child: Container(color: AppColors.border)),
          ],
        ),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({
    required this.label,
    required this.sublabel,
    required this.value,
    required this.color,
    this.alignEnd = false,
  });

  final String label;
  final String sublabel;
  final int value;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          '$label · $sublabel'.toUpperCase(),
          style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: AppColors.gray500),
        ),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5),
        ),
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
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray500)),
        ],
      );
}
