import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/strategy.dart';
import '../models/trade_plan.dart';
import '../services/api_client.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import 'trade_form_screen.dart';

/// The pre-trade discipline gate. Pick a strategy → tick the entry
/// checklist → fill in price levels → decide **Take it** or **Skip it**.
///
/// Taking with any required rule unchecked forces a one-line override
/// reason (FOMO / news / revenge / …) — that tag is the tilt-signal
/// the dashboard ranks by P&L. On "Take it" the screen pushes the
/// existing [TradeFormScreen] pre-filled with the plan's inputs and
/// links the new Trade back to the plan.
class PlanTradeScreen extends StatefulWidget {
  const PlanTradeScreen({super.key});

  @override
  State<PlanTradeScreen> createState() => _PlanTradeScreenState();
}

class _PlanTradeScreenState extends State<PlanTradeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _symbol = TextEditingController();
  final _entry = TextEditingController();
  final _sl = TextEditingController();
  final _tp = TextEditingController();
  final _size = TextEditingController(text: '1');
  final _override = TextEditingController();
  final _notes = TextEditingController();

  Strategy? _strategy;
  String _direction = 'buy';
  final Map<int, bool> _ticks = {};
  bool _saving = false;

  static final _decimalFormatter =
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'));

  @override
  void dispose() {
    _symbol.dispose();
    _entry.dispose();
    _sl.dispose();
    _tp.dispose();
    _size.dispose();
    _override.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _pickStrategy(Strategy? s) {
    setState(() {
      _strategy = s;
      _ticks
        ..clear()
        ..addEntries((s?.checklist ?? const <StrategyRule>[])
            .map((r) => MapEntry(r.id, false)));
    });
  }

  /// "Required broken" = at least one required rule on the picked
  /// strategy is unchecked. Drives the override-reason requirement.
  bool get _hasBrokenRequired {
    final s = _strategy;
    if (s == null) return false;
    for (final r in s.checklist) {
      if (r.isRequired && !(_ticks[r.id] ?? false)) return true;
    }
    return false;
  }

  double? _parseNum(TextEditingController c) {
    final t = c.text.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  Future<void> _decide(String decision) async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    // "Take it" with broken required rules requires an override reason.
    if (decision == 'take' && _hasBrokenRequired) {
      if (_override.text.trim().isEmpty) {
        showAppSnack(
          context,
          'Required rules are unchecked — write a one-line reason to take it anyway.',
          error: true,
        );
        return;
      }
    }

    setState(() => _saving = true);
    final appState = context.read<AppState>();
    try {
      final plan = await appState.createTradePlan(
        strategyId: _strategy?.id,
        symbol: _symbol.text.trim().toUpperCase(),
        direction: _direction,
        plannedEntry: _parseNum(_entry),
        plannedSl: _parseNum(_sl),
        plannedTp: _parseNum(_tp),
        plannedSize: _parseNum(_size),
        decision: decision,
        overrideReason: _override.text.trim(),
        notes: _notes.text.trim(),
        checks: [
          for (final r in _strategy?.checklist ?? const <StrategyRule>[])
            TradePlanCheck(
              ruleId: r.id,
              ruleText: r.text,
              isRequired: r.isRequired,
              checked: _ticks[r.id] ?? false,
            ),
        ],
      );

      if (!mounted) return;
      if (decision == 'skip') {
        showAppSnack(context, 'Saved — good discipline.');
        Navigator.of(context).pop();
        return;
      }

      // "Take it" → push the existing trade form, pre-filled and linked.
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => TradeFormScreen.fromPlan(plan: plan),
      ));
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strategies = context.watch<AppState>().strategies;
    final s = _strategy;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Plan a trade',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            _Label('Strategy'),
            DropdownButtonFormField<Strategy?>(
              value: _strategy,
              decoration:
                  const InputDecoration(hintText: 'Pick a strategy'),
              items: [
                const DropdownMenuItem<Strategy?>(
                    value: null, child: Text('No strategy (free plan)')),
                for (final s in strategies)
                  DropdownMenuItem<Strategy?>(value: s, child: Text(s.name)),
              ],
              onChanged: _pickStrategy,
            ),
            const SizedBox(height: 14),
            _Label('Symbol'),
            TextFormField(
              controller: _symbol,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                  hintText: 'EURUSD, XAUUSD, BTCUSD…'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            _Label('Direction'),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'buy',
                    label: Text('Long'),
                    icon: Icon(Icons.trending_up)),
                ButtonSegment(
                    value: 'sell',
                    label: Text('Short'),
                    icon: Icon(Icons.trending_down)),
              ],
              selected: {_direction},
              onSelectionChanged: (sel) =>
                  setState(() => _direction = sel.first),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('Entry'),
                      TextFormField(
                        controller: _entry,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [_decimalFormatter],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('Size'),
                      TextFormField(
                        controller: _size,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [_decimalFormatter],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('Stop loss'),
                      TextFormField(
                        controller: _sl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [_decimalFormatter],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('Take profit'),
                      TextFormField(
                        controller: _tp,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [_decimalFormatter],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (s == null)
              const _ChecklistEmpty()
            else if (s.checklist.isEmpty)
              _ChecklistMissing(strategyName: s.name)
            else
              _Checklist(
                rules: s.checklist,
                values: _ticks,
                onChanged: (id, v) => setState(() => _ticks[id] = v),
              ),
            const SizedBox(height: 18),
            if (_hasBrokenRequired) ...[
              _Label('Override reason (required)'),
              TextFormField(
                controller: _override,
                decoration: const InputDecoration(
                  hintText: 'e.g. FOMO, news spike, gut feel',
                ),
                maxLength: 120,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: AppColors.danger, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Required rules are broken. Taking this trade '
                        'tags it with your reason so the discipline '
                        'dashboard can rank tilt patterns.',
                        style: TextStyle(
                            color: AppColors.gray700, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            _Label('Notes (optional)'),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(
                  hintText: 'What you saw, why you waited…'),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : () => _decide('skip'),
                    icon: const Icon(Icons.do_not_disturb_alt),
                    label: const Text('Skip it'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.gray700,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Take it',
                    icon: Icons.check,
                    loading: _saving,
                    onPressed: () => _decide('take'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text.toUpperCase(),
            style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: AppColors.gray500)),
      );
}

class _Checklist extends StatelessWidget {
  const _Checklist({
    required this.rules,
    required this.values,
    required this.onChanged,
  });

  final List<StrategyRule> rules;
  final Map<int, bool> values;
  final void Function(int ruleId, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text('ENTRY CHECKLIST',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppColors.gray500,
                )),
          ),
          for (final r in rules)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onChanged(r.id, !(values[r.id] ?? false)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Checkbox(
                      value: values[r.id] ?? false,
                      onChanged: (v) => onChanged(r.id, v ?? false),
                      activeColor: AppColors.teal,
                      checkColor: AppColors.inkDeep,
                    ),
                    Expanded(
                      child: Text(r.text,
                          style: const TextStyle(
                              color: AppColors.gray900, fontSize: 14)),
                    ),
                    if (r.isRequired)
                      const StatusPill(
                          label: 'REQUIRED', color: AppColors.warn),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChecklistEmpty extends StatelessWidget {
  const _ChecklistEmpty();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.gray500, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pick a strategy above to see its entry checklist. '
              'No strategy? You can still take a freeform plan.',
              style: TextStyle(color: AppColors.gray500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistMissing extends StatelessWidget {
  const _ChecklistMissing({required this.strategyName});
  final String strategyName;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.checklist_rtl,
              color: AppColors.gray500, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '"$strategyName" has no checklist yet. Open the strategy '
              'editor to add the rules you want to tick before entering.',
              style: const TextStyle(color: AppColors.gray500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
