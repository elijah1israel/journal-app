import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import '../widgets/wickbook_top_bar.dart';
import 'risk_guardrails_sheet.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.user;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: const WickbookTopBar(section: 'Profile'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.ink,
                  child: Text(user?.initials ?? '?',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.displayName ?? 'Signed in',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.gray900)),
                      const SizedBox(height: 2),
                      Text(user?.email ?? '',
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.gray500)),
                      if ((user?.experienceLevel ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: StatusPill(
                            label: user!.experienceLevel.toUpperCase(),
                            color: AppColors.violet,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _StatRow(
              label: 'Total trades',
              value: state.totalTrades.toString()),
          _StatRow(label: 'Win rate', value: '${state.winRate.toStringAsFixed(0)}%'),
          _StatRow(
              label: 'Open positions', value: state.openTrades.toString()),
          _StatRow(
              label: 'Strategies', value: state.strategies.length.toString()),
          const SizedBox(height: 20),
          const _SectionLabel('Risk guardrails'),
          _GuardrailRow(user: user),
          const SizedBox(height: 20),
          const _SectionLabel('App'),
          _LinkRow(
            icon: Icons.cloud_outlined,
            label: 'API',
            trailing: Text(
              Uri.tryParse(ApiConfig.baseUrl)?.host ?? ApiConfig.baseUrl,
              style: const TextStyle(
                  fontSize: 12.5, color: AppColors.gray500),
            ),
          ),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (_, snap) {
              final v = snap.data;
              return _LinkRow(
                icon: Icons.info_outline,
                label: 'Version',
                trailing: Text(
                  v == null ? '–' : '${v.version} (${v.buildNumber})',
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.gray500),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout, color: AppColors.danger),
            label: const Text('Sign out',
                style: TextStyle(
                    color: AppColors.danger, fontWeight: FontWeight.w700)),
            onPressed: () => _confirmSignOut(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
            "You'll need to sign back in to log new trades."),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('Sign out')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await withBlockingLoader(
      context,
      () => context.read<AppState>().signOut(),
      label: 'Signing out…',
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
        child: Text(text.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: AppColors.gray500)),
      );
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray700))),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gray900)),
        ],
      ),
    );
  }
}

class _GuardrailRow extends StatelessWidget {
  const _GuardrailRow({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    final limit = user?.dailyLossLimit as double?;
    final cooldown = user?.coolDownMinutesAfterLoss as int?;
    final summary = _summary(limit, cooldown);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        builder: (_) => const RiskGuardrailsSheet(),
      ),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.shield_outlined,
                size: 18, color: AppColors.gray500),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Daily loss + cool-down',
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray700)),
                  const SizedBox(height: 2),
                  Text(summary,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.gray500)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }

  String _summary(double? limit, int? cooldown) {
    if (limit == null && (cooldown ?? 0) == 0) {
      return 'Disabled — tap to set hard guardrails.';
    }
    final parts = <String>[];
    if (limit != null) parts.add('Cap: −${limit.toStringAsFixed(0)}/day');
    if ((cooldown ?? 0) > 0) parts.add('Cool-down: ${cooldown}m');
    return parts.join(' · ');
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.label,
    required this.trailing,
  });
  final IconData icon;
  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.gray500),
          const SizedBox(width: 10),
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray700))),
          trailing,
        ],
      ),
    );
  }
}
