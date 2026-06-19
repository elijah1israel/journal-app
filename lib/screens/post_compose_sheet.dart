import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/community.dart';
import '../services/api_client.dart';
import '../services/community_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

/// Owner-only composer for a new community post. The "Kind" toggle
/// switches between freeform text and a structured **trade call** —
/// the latter requires instrument, direction, entry, SL and TP1 so
/// subscribers see a clean card and the guru can flip its status as
/// the call plays out.
class PostComposeSheet extends StatefulWidget {
  const PostComposeSheet({super.key, required this.community});

  final Community community;

  @override
  State<PostComposeSheet> createState() => _PostComposeSheetState();
}

class _PostComposeSheetState extends State<PostComposeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _service = CommunityService();

  // Trade-call fields — only validated when kind == trade_call.
  final _instrument = TextEditingController();
  final _entry = TextEditingController();
  final _sl = TextEditingController();
  final _tp1 = TextEditingController();
  final _tp2 = TextEditingController();
  final _tp3 = TextEditingController();
  final _riskPct = TextEditingController();
  String _direction = 'long';

  String _kind = 'text'; // text | trade_call
  int? _minTierId;
  bool _saving = false;

  static final _decimalFormatter =
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'));

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _instrument.dispose();
    _entry.dispose();
    _sl.dispose();
    _tp1.dispose();
    _tp2.dispose();
    _tp3.dispose();
    _riskPct.dispose();
    super.dispose();
  }

  double? _parseNum(TextEditingController c) {
    final t = c.text.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  String? _requiredDecimalValidator(String? v) {
    if (_kind != 'trade_call') return null;
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Required';
    if (double.tryParse(t) == null) return 'Number';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gray400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text('New post',
                  style: TextStyle(
                    color: AppColors.gray900,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  )),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                      value: 'text',
                      label: Text('Text'),
                      icon: Icon(Icons.notes)),
                  ButtonSegment(
                      value: 'trade_call',
                      label: Text('Trade call'),
                      icon: Icon(Icons.show_chart)),
                ],
                selected: {_kind},
                onSelectionChanged: (s) => setState(() => _kind = s.first),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _title,
                decoration:
                    const InputDecoration(labelText: 'Title (optional)'),
                maxLength: 140,
              ),
              TextFormField(
                controller: _body,
                decoration: InputDecoration(
                  labelText: _kind == 'trade_call'
                      ? 'Notes / setup rationale'
                      : 'What\'s on your mind?',
                ),
                maxLines: _kind == 'trade_call' ? 3 : 6,
                validator: (v) {
                  if (_kind == 'trade_call') return null; // body optional for calls
                  return (v ?? '').trim().isEmpty ? 'Required' : null;
                },
              ),
              if (_kind == 'trade_call') ...[
                const SizedBox(height: 14),
                _CallFields(
                  instrument: _instrument,
                  direction: _direction,
                  onDirectionChanged: (d) =>
                      setState(() => _direction = d),
                  entry: _entry,
                  sl: _sl,
                  tp1: _tp1,
                  tp2: _tp2,
                  tp3: _tp3,
                  riskPct: _riskPct,
                  decimalFormatter: _decimalFormatter,
                  requiredValidator: _requiredDecimalValidator,
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                value: _minTierId,
                decoration: const InputDecoration(labelText: 'Visible to'),
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('Everyone in the community')),
                  for (final t in widget.community.tiers.where((t) => !t.isFree))
                    DropdownMenuItem(
                      value: t.id,
                      child: Text(
                          '${t.name} (${widget.community.currency} ${t.price.toStringAsFixed(0)}+ /mo)'),
                    ),
                ],
                onChanged: (v) => setState(() => _minTierId = v),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Publish',
                loading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    Map<String, dynamic>? callPayload;
    if (_kind == 'trade_call') {
      callPayload = {
        'instrument': _instrument.text.trim().toUpperCase(),
        'direction': _direction,
        'entry': _parseNum(_entry),
        'stop_loss': _parseNum(_sl),
        'take_profit_1': _parseNum(_tp1),
        if (_parseNum(_tp2) != null) 'take_profit_2': _parseNum(_tp2),
        if (_parseNum(_tp3) != null) 'take_profit_3': _parseNum(_tp3),
        if (_parseNum(_riskPct) != null) 'risk_pct': _parseNum(_riskPct),
      };
    }

    try {
      await _service.createPost(
        widget.community.id,
        title: _title.text.trim(),
        body: _body.text.trim(),
        kind: _kind,
        minTierId: _minTierId,
        tradeCall: callPayload,
      );
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _CallFields extends StatelessWidget {
  const _CallFields({
    required this.instrument,
    required this.direction,
    required this.onDirectionChanged,
    required this.entry,
    required this.sl,
    required this.tp1,
    required this.tp2,
    required this.tp3,
    required this.riskPct,
    required this.decimalFormatter,
    required this.requiredValidator,
  });

  final TextEditingController instrument;
  final String direction;
  final ValueChanged<String> onDirectionChanged;
  final TextEditingController entry;
  final TextEditingController sl;
  final TextEditingController tp1;
  final TextEditingController tp2;
  final TextEditingController tp3;
  final TextEditingController riskPct;
  final TextInputFormatter decimalFormatter;
  final String? Function(String?) requiredValidator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: instrument,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Instrument',
            hintText: 'EURUSD, XAUUSD, BTCUSD…',
          ),
          validator: (v) =>
              (v ?? '').trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 10),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
                value: 'long',
                label: Text('Long'),
                icon: Icon(Icons.trending_up)),
            ButtonSegment(
                value: 'short',
                label: Text('Short'),
                icon: Icon(Icons.trending_down)),
          ],
          selected: {direction},
          onSelectionChanged: (s) => onDirectionChanged(s.first),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: entry,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [decimalFormatter],
                decoration: const InputDecoration(labelText: 'Entry'),
                validator: requiredValidator,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: sl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [decimalFormatter],
                decoration: const InputDecoration(labelText: 'Stop loss'),
                validator: requiredValidator,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: tp1,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [decimalFormatter],
                decoration: const InputDecoration(labelText: 'TP1'),
                validator: requiredValidator,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: tp2,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [decimalFormatter],
                decoration:
                    const InputDecoration(labelText: 'TP2 (optional)'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: tp3,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [decimalFormatter],
                decoration:
                    const InputDecoration(labelText: 'TP3 (optional)'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: riskPct,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [decimalFormatter],
                decoration: const InputDecoration(
                  labelText: 'Risk % (optional)',
                  hintText: 'e.g. 0.5',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
