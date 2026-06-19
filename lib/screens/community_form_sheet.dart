import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

/// Bottom-sheet form for starting a new community. The owner is set
/// server-side from the JWT, and a default Free tier is auto-created so
/// the new community has something for members to join.
class CommunityFormSheet extends StatefulWidget {
  const CommunityFormSheet({super.key});

  @override
  State<CommunityFormSheet> createState() => _CommunityFormSheetState();
}

class _CommunityFormSheetState extends State<CommunityFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _tagline = TextEditingController();
  final _description = TextEditingController();
  String _currency = 'UGX';
  bool _saving = false;

  static const _currencies = ['UGX', 'KES', 'TZS', 'RWF', 'CDF'];

  @override
  void dispose() {
    _name.dispose();
    _tagline.dispose();
    _description.dispose();
    super.dispose();
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
            Container(
              width: 40,
              height: 4,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.gray400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Start a community',
              style: TextStyle(
                color: AppColors.gray900,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'You\'ll be the owner. A free tier is created automatically; '
              'add paid tiers later once payouts are enabled.',
              style: TextStyle(color: AppColors.gray500, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tagline,
              decoration: const InputDecoration(
                labelText: 'Tagline (optional)',
                hintText: 'e.g. Daily forex signals, London session',
              ),
              maxLength: 140,
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _currency,
              decoration: const InputDecoration(labelText: 'Currency'),
              items: [
                for (final c in _currencies)
                  DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (v) => setState(() => _currency = v ?? 'UGX'),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Create community',
              loading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<AppState>().createCommunity(
            name: _name.text.trim(),
            tagline: _tagline.text.trim(),
            description: _description.text.trim(),
            currency: _currency,
          );
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
