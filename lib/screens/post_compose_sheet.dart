import 'package:flutter/material.dart';

import '../models/community.dart';
import '../services/api_client.dart';
import '../services/community_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

/// Owner-only composer for a new community post. Lets the owner pick a
/// minimum tier so only members at that tier (or higher-priced) can read
/// it; defaults to public (everyone in the community).
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
  int? _minTierId; // null = public
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
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
              decoration: BoxDecoration(
                color: AppColors.gray400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('New post',
                style: TextStyle(
                  color: AppColors.gray900,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: 12),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                  labelText: 'Title (optional)'),
              maxLength: 140,
            ),
            TextFormField(
              controller: _body,
              decoration: const InputDecoration(labelText: 'What\'s on your mind?'),
              maxLines: 6,
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Required' : null,
            ),
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
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _service.createPost(
        widget.community.id,
        title: _title.text.trim(),
        body: _body.text.trim(),
        minTierId: _minTierId,
      );
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
