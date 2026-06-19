import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/strategy.dart';
import '../services/api_client.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import '../widgets/wickbook_top_bar.dart';

/// List of strategies + an inline form for create / edit.
class StrategiesScreen extends StatelessWidget {
  const StrategiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: WickbookTopBar(
        section: 'Strategies',
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                state.loadingStrategies ? null : () => state.refreshStrategies(),
            icon: const Icon(Icons.refresh, color: AppColors.gray700),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.teal,
        foregroundColor: AppColors.inkDeep,
        onPressed: () => _openSheet(context, null),
        icon: const Icon(Icons.add),
        label: const Text('New strategy',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: RefreshIndicator(
        color: AppColors.teal,
        onRefresh: () => state.refreshStrategies(),
        child: state.strategies.isEmpty
            ? ListView(children: const [
                SizedBox(height: 80),
                EmptyState(
                  icon: Icons.tune,
                  title: 'No strategies yet',
                  subtitle:
                      'Group your trades by setup so you can spot which one is paying.',
                ),
              ])
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                itemCount: state.strategies.length,
                itemBuilder: (_, i) {
                  final s = state.strategies[i];
                  return _StrategyTile(
                    strategy: s,
                    onTap: () => _openSheet(context, s),
                  );
                },
              ),
      ),
    );
  }

  void _openSheet(BuildContext context, Strategy? initial) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StrategySheet(initial: initial),
    );
  }
}

class _StrategyTile extends StatelessWidget {
  const _StrategyTile({required this.strategy, required this.onTap});
  final Strategy strategy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
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
                    color: AppColors.teal50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.tune,
                      color: AppColors.tealDarker, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(strategy.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppColors.gray900)),
                      if (strategy.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            strategy.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.gray500),
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.gray400),
              ],
            ),
            if (strategy.timeframeList.isNotEmpty ||
                strategy.marketList.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final tf in strategy.timeframeList)
                      StatusPill(label: tf, color: AppColors.info),
                    for (final m in strategy.marketList)
                      StatusPill(label: m, color: AppColors.violet),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StrategySheet extends StatefulWidget {
  const _StrategySheet({required this.initial});
  final Strategy? initial;

  @override
  State<_StrategySheet> createState() => _StrategySheetState();
}

class _StrategySheetState extends State<_StrategySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _rules;
  late final Set<String> _timeframes;
  late final Set<String> _markets;
  bool _saving = false;

  static const _allTimeframes = ['M1', 'M5', 'M15', 'M30', 'H1', 'H4', 'D1', 'W1', 'MN'];
  static const _allMarkets = ['Forex', 'Gold', 'Oil', 'Crypto', 'Indices', 'Stocks', 'Commodities', 'Bonds'];

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _name = TextEditingController(text: s?.name ?? '');
    _desc = TextEditingController(text: s?.description ?? '');
    _rules = TextEditingController(text: s?.rules ?? '');
    _timeframes = {...?s?.timeframeList};
    _markets = {...?s?.marketList};
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _rules.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.initial != null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final state = context.read<AppState>();
      final payload = {
        'name': _name.text.trim(),
        'description': _desc.text.trim(),
        'rules': _rules.text.trim(),
        'timeframes': _timeframes.join(','),
        'markets': _markets.join(','),
      };
      if (_isEdit) {
        await state.updateStrategy(widget.initial!.id, payload);
      } else {
        await state.createStrategy(
          name: payload['name']!,
          description: payload['description']!,
          rules: payload['rules']!,
          timeframes: payload['timeframes']!,
          markets: payload['markets']!,
        );
      }
      if (mounted) {
        showAppSnack(context, _isEdit ? 'Saved' : 'Strategy created');
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete strategy?'),
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
      await context.read<AppState>().deleteStrategy(widget.initial!.id);
      if (mounted) {
        showAppSnack(context, 'Deleted');
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
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
                      child: Text(
                          _isEdit ? 'Edit strategy' : 'New strategy',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                    ),
                    if (_isEdit)
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.danger),
                        onPressed: _saving ? null : _delete,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                const _Mini('Name'),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                      hintText: 'e.g. Liquidity sweep + FVG'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                const _Mini('Description'),
                TextFormField(
                  controller: _desc,
                  decoration: const InputDecoration(
                      hintText: 'What it is, in a line.'),
                ),
                const SizedBox(height: 14),
                const _Mini('Notes / freeform rules'),
                TextFormField(
                  controller: _rules,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      hintText: 'Setup, entry trigger, risk, exit.'),
                ),
                if (_isEdit) ...[
                  const SizedBox(height: 18),
                  _RulesChecklistEditor(strategy: widget.initial!),
                ],
                const SizedBox(height: 14),
                const _Mini('Timeframes'),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final tf in _allTimeframes)
                      FilterChip(
                        label: Text(tf),
                        selected: _timeframes.contains(tf),
                        onSelected: (sel) => setState(() {
                          sel ? _timeframes.add(tf) : _timeframes.remove(tf);
                        }),
                        selectedColor: AppColors.teal50,
                        checkmarkColor: AppColors.tealDarker,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                const _Mini('Markets'),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final m in _allMarkets)
                      FilterChip(
                        label: Text(m),
                        selected: _markets.contains(m),
                        onSelected: (sel) => setState(() {
                          sel ? _markets.add(m) : _markets.remove(m);
                        }),
                        selectedColor: AppColors.teal50,
                        checkmarkColor: AppColors.tealDarker,
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                    label: _isEdit ? 'Save changes' : 'Create',
                    loading: _saving,
                    onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini(this.text);
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

/// Inline checklist editor — add / remove / toggle "required" for the
/// rules the pre-trade plan flow will tick. The latest version of the
/// strategy comes from AppState so additions show up immediately.
class _RulesChecklistEditor extends StatefulWidget {
  const _RulesChecklistEditor({required this.strategy});
  final Strategy strategy;

  @override
  State<_RulesChecklistEditor> createState() => _RulesChecklistEditorState();
}

class _RulesChecklistEditorState extends State<_RulesChecklistEditor> {
  final _newRule = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _newRule.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final live = state.strategies.firstWhere(
      (s) => s.id == widget.strategy.id,
      orElse: () => widget.strategy,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Mini('Entry checklist'),
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Each rule becomes a tickbox on the pre-trade plan. Required '
            'rules must be ticked to "Take" without an override reason.',
            style: TextStyle(color: AppColors.gray500, fontSize: 12),
          ),
        ),
        for (final r in live.checklist)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(r.text,
                              style: const TextStyle(
                                  color: AppColors.gray900, fontSize: 13)),
                        ),
                        if (r.isRequired)
                          const StatusPill(
                              label: 'REQUIRED', color: AppColors.warn)
                        else
                          const StatusPill(
                              label: 'OPTIONAL', color: AppColors.info),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: r.isRequired
                      ? 'Make optional'
                      : 'Make required',
                  icon: Icon(
                      r.isRequired
                          ? Icons.flag_outlined
                          : Icons.flag,
                      color: AppColors.gray500,
                      size: 18),
                  onPressed: _busy
                      ? null
                      : () => _toggleRequired(live.id, r.id, !r.isRequired),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.danger, size: 18),
                  onPressed: _busy ? null : () => _delete(live.id, r.id),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newRule,
                decoration: const InputDecoration(
                  hintText: 'Add a rule (e.g. HTF bias agrees)',
                  isDense: true,
                ),
                onSubmitted: (_) => _add(live.id),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: AppColors.inkDeep,
              ),
              onPressed: _busy ? null : () => _add(live.id),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _add(int strategyId) async {
    final text = _newRule.text.trim();
    if (text.isEmpty) return;
    setState(() => _busy = true);
    try {
      await context
          .read<AppState>()
          .addRule(strategyId, text: text, isRequired: true);
      _newRule.clear();
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleRequired(int strategyId, int ruleId, bool required) async {
    setState(() => _busy = true);
    try {
      await context
          .read<AppState>()
          .updateRule(strategyId, ruleId, isRequired: required);
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(int strategyId, int ruleId) async {
    setState(() => _busy = true);
    try {
      await context.read<AppState>().deleteRule(strategyId, ruleId);
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
