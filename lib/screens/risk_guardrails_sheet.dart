import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

/// Bottom-sheet editor for the two risk caps the API hard-enforces:
/// `daily_loss_limit` (absolute daily P&L floor) and
/// `cool_down_minutes_after_loss` (minutes the plan screen is blocked
/// after a losing trade). Empty / 0 disables each.
class RiskGuardrailsSheet extends StatefulWidget {
  const RiskGuardrailsSheet({super.key});

  @override
  State<RiskGuardrailsSheet> createState() => _RiskGuardrailsSheetState();
}

class _RiskGuardrailsSheetState extends State<RiskGuardrailsSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _limit;
  late final TextEditingController _cooldown;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AppState>().user;
    _limit = TextEditingController(
      text: u?.dailyLossLimit == null
          ? ''
          : u!.dailyLossLimit!.toStringAsFixed(0),
    );
    _cooldown = TextEditingController(
      text: u == null ? '0' : u.coolDownMinutesAfterLoss.toString(),
    );
  }

  @override
  void dispose() {
    _limit.dispose();
    _cooldown.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final limitText = _limit.text.trim();
    final cooldownText = _cooldown.text.trim();
    final payload = <String, dynamic>{
      // null clears the cap server-side
      'daily_loss_limit': limitText.isEmpty ? null : double.parse(limitText),
      'cool_down_minutes_after_loss':
          cooldownText.isEmpty ? 0 : int.parse(cooldownText),
    };
    setState(() => _saving = true);
    try {
      await context.read<AppState>().saveProfile(payload);
      if (mounted) {
        showAppSnack(context, 'Risk guardrails saved.');
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
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
            const Text('Risk guardrails',
                style: TextStyle(
                    color: AppColors.gray900,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text(
              'Both are hard blocks on starting a new pre-trade plan. '
              'Trades that already happened can still be logged.',
              style: TextStyle(color: AppColors.gray500, fontSize: 12.5),
            ),
            const SizedBox(height: 16),
            const Text('DAILY LOSS LIMIT',
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.gray500)),
            const SizedBox(height: 4),
            TextFormField(
              controller: _limit,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(
                hintText: 'e.g. 200 (account currency). Empty to disable.',
              ),
              validator: (v) {
                if ((v ?? '').trim().isEmpty) return null;
                final n = double.tryParse(v!.trim());
                if (n == null || n <= 0) return 'Must be > 0';
                return null;
              },
            ),
            const SizedBox(height: 14),
            const Text('COOL-DOWN AFTER LOSS (MIN)',
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.gray500)),
            const SizedBox(height: 4),
            TextFormField(
              controller: _cooldown,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                hintText: 'e.g. 30. 0 disables the cool-down.',
              ),
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return null;
                final n = int.tryParse(t);
                if (n == null || n < 0) return 'Must be ≥ 0';
                return null;
              },
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Save guardrails',
              loading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
