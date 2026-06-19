import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/trade.dart';
import '../models/trade_plan.dart';
import '../services/api_client.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

/// Log-trade / edit-trade form. The backend computes P&L, R:R and
/// status server-side, so this form only ever sends the inputs.
class TradeFormScreen extends StatefulWidget {
  const TradeFormScreen({super.key, this.initial, this.plan});

  /// When set the form opens in edit mode and PATCHes; otherwise it
  /// POSTs a new trade.
  final Trade? initial;

  /// When set the form opens pre-filled from a pre-trade plan and the
  /// resulting POST carries `plan: <id>` so the trade links back to it
  /// (so the dashboard's discipline tile can count it).
  final TradePlan? plan;

  /// Convenience constructor for "take this plan now" — equivalent to
  /// `TradeFormScreen(plan: plan)` but reads more obviously at call sites.
  factory TradeFormScreen.fromPlan({required TradePlan plan, Key? key}) =>
      TradeFormScreen(key: key, plan: plan);

  @override
  State<TradeFormScreen> createState() => _TradeFormScreenState();
}

class _TradeFormScreenState extends State<TradeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _symbol;
  late final TextEditingController _entry;
  late final TextEditingController _sl;
  late final TextEditingController _tp;
  late final TextEditingController _size;
  late final TextEditingController _notes;
  late TradeDirection _direction;
  late TradeResult _result;
  int? _strategyId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.initial;
    final p = widget.plan;
    _symbol = TextEditingController(text: t?.symbol ?? p?.symbol ?? '');
    _entry = TextEditingController(
        text: t?.entryPrice != null
            ? formatPrice(t!.entryPrice)
            : (p?.plannedEntry != null ? formatPrice(p!.plannedEntry) : ''));
    _sl = TextEditingController(
        text: t?.stopLoss != null
            ? formatPrice(t!.stopLoss)
            : (p?.plannedSl != null ? formatPrice(p!.plannedSl) : ''));
    _tp = TextEditingController(
        text: t?.takeProfit != null
            ? formatPrice(t!.takeProfit)
            : (p?.plannedTp != null ? formatPrice(p!.plannedTp) : ''));
    _size = TextEditingController(
        text: t?.positionSize != null
            ? formatPrice(t!.positionSize, maxDecimals: 2)
            : (p?.plannedSize != null
                ? formatPrice(p!.plannedSize, maxDecimals: 2)
                : '1'));
    _notes = TextEditingController(text: t?.notes ?? p?.notes ?? '');
    _direction = t?.direction ??
        (p != null ? TradeDirection.fromWire(p.direction) : TradeDirection.buy);
    _result = t?.result ?? TradeResult.none;
    _strategyId = t?.strategy ?? p?.strategyId;
  }

  @override
  void dispose() {
    _symbol.dispose();
    _entry.dispose();
    _sl.dispose();
    _tp.dispose();
    _size.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.initial != null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final payload = <String, dynamic>{
      'symbol': _symbol.text.trim().toUpperCase(),
      'direction': _direction.wire,
      'entry_price': _entry.text.trim(),
      'position_size': _size.text.trim(),
      if (_sl.text.trim().isNotEmpty) 'stop_loss': _sl.text.trim(),
      if (_tp.text.trim().isNotEmpty) 'take_profit': _tp.text.trim(),
      'notes': _notes.text.trim(),
      if (_strategyId != null) 'strategy': _strategyId,
      if (widget.plan != null) 'plan': widget.plan!.id,
      if (_result != TradeResult.none) 'result': _result.wire,
    };
    if (!_isEdit) {
      payload['entry_date'] = DateTime.now().toUtc().toIso8601String();
    }
    try {
      final state = context.read<AppState>();
      if (_isEdit) {
        await state.updateTrade(widget.initial!.id, payload);
      } else {
        await state.createTrade(payload);
      }
      if (mounted) {
        showAppSnack(context, _isEdit ? 'Trade updated' : 'Trade logged');
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    } catch (_) {
      if (mounted) {
        showAppSnack(context, 'Something went wrong. Please try again.',
            error: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete trade?'),
        content:
            const Text('This removes the entry from your journal for good.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<AppState>().deleteTrade(widget.initial!.id);
      if (mounted) {
        showAppSnack(context, 'Trade deleted');
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strategies = context.watch<AppState>().strategies;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit trade' : 'Log trade',
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w800)),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if (widget.plan != null) ...[
              _PlanBanner(plan: widget.plan!),
              const SizedBox(height: 14),
            ],
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
            SegmentedButton<TradeDirection>(
              segments: const [
                ButtonSegment(
                    value: TradeDirection.buy,
                    label: Text('Long'),
                    icon: Icon(Icons.trending_up)),
                ButtonSegment(
                    value: TradeDirection.sell,
                    label: Text('Short'),
                    icon: Icon(Icons.trending_down)),
              ],
              selected: {_direction},
              onSelectionChanged: (s) =>
                  setState(() => _direction = s.first),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('Entry price'),
                      TextFormField(
                        controller: _entry,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [_decimalFormatter],
                        validator: _decimalValidator,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('Position size'),
                      TextFormField(
                        controller: _size,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [_decimalFormatter],
                        validator: _decimalValidator,
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
                      _Label('Stop loss (optional)'),
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
                      _Label('Take profit (optional)'),
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
            const SizedBox(height: 14),
            _Label('Result'),
            SegmentedButton<TradeResult>(
              segments: const [
                ButtonSegment(value: TradeResult.none, label: Text('Open')),
                ButtonSegment(value: TradeResult.tp, label: Text('TP hit')),
                ButtonSegment(value: TradeResult.sl, label: Text('SL hit')),
              ],
              selected: {_result},
              onSelectionChanged: (s) => setState(() => _result = s.first),
            ),
            const SizedBox(height: 14),
            _Label('Strategy (optional)'),
            DropdownButtonFormField<int?>(
              value: _strategyId,
              decoration: const InputDecoration(hintText: 'No strategy'),
              items: [
                const DropdownMenuItem<int?>(
                    value: null, child: Text('No strategy')),
                for (final s in strategies)
                  DropdownMenuItem<int?>(value: s.id, child: Text(s.name)),
              ],
              onChanged: (v) => setState(() => _strategyId = v),
            ),
            const SizedBox(height: 14),
            _Label('Notes'),
            TextFormField(
              controller: _notes,
              maxLines: 4,
              decoration: const InputDecoration(
                  hintText: 'Setup, emotion, what you saw…'),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: _isEdit ? 'Save changes' : 'Log trade',
              loading: _saving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  static final _decimalFormatter =
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'));

  String? _decimalValidator(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Required';
    final n = double.tryParse(value);
    if (n == null || n <= 0) return 'Must be > 0';
    return null;
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

/// Headline strip shown on the trade form when the user is logging a
/// trade off the back of a [TradePlan] — keeps the discipline context
/// front-and-centre. Green when rules were followed, red with the
/// override reason when they weren't.
class _PlanBanner extends StatelessWidget {
  const _PlanBanner({required this.plan});
  final TradePlan plan;

  @override
  Widget build(BuildContext context) {
    final followed = plan.requiredRulesFollowed;
    final accent = followed ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(followed ? Icons.check_circle : Icons.warning_amber_rounded,
              color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  followed ? 'Plan followed' : 'Plan broken',
                  style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 13),
                ),
                Text(
                  followed
                      ? 'Pre-trade checklist passed — this trade counts toward your discipline rate.'
                      : 'You took this despite required rules being unticked. '
                          'Reason on file: "${plan.overrideReason}".',
                  style: const TextStyle(
                      color: AppColors.gray700, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
