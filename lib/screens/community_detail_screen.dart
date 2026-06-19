import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/community.dart';
import '../services/api_client.dart';
import '../services/community_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import 'post_compose_sheet.dart';

/// One community's room: header card with join/leave, then the feed of
/// posts the viewer is allowed to see (tier-gated server-side).
class CommunityDetailScreen extends StatefulWidget {
  const CommunityDetailScreen({super.key, required this.communityId});

  final int communityId;

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  final _service = CommunityService();
  Community? _community;
  List<CommunityPost> _posts = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final community = await _service.get(widget.communityId);
      List<CommunityPost> posts = const [];
      if (community.isMember || community.isOwner) {
        posts = await _service.listPosts(widget.communityId);
      }
      if (!mounted) return;
      setState(() {
        _community = community;
        _posts = posts;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _join() async {
    final appState = context.read<AppState>();
    try {
      await appState.joinCommunity(widget.communityId);
      await _load();
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    }
  }

  Future<void> _leave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Leave community?'),
        content: const Text(
            'You\'ll stop seeing this community\'s posts in your feed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Leave',
                  style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final appState = context.read<AppState>();
    try {
      await appState.leaveCommunity(widget.communityId);
      await _load();
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    }
  }

  Future<void> _openCompose() async {
    final c = _community;
    if (c == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (_) => PostComposeSheet(community: c),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = _community;
    return Scaffold(
      appBar: AppBar(
        title: Text(c?.name ?? 'Community'),
        actions: [
          if (c != null && c.isMember && !c.isOwner)
            IconButton(
              tooltip: 'Leave',
              icon: const Icon(Icons.logout),
              onPressed: _leave,
            ),
        ],
      ),
      floatingActionButton: (c != null && c.isOwner)
          ? FloatingActionButton.extended(
              onPressed: _openCompose,
              backgroundColor: AppColors.teal,
              foregroundColor: AppColors.inkDeep,
              icon: const Icon(Icons.edit),
              label: const Text('Post'),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: const TextStyle(color: AppColors.danger)),
                )
              : c == null
                  ? const SizedBox.shrink()
                  : RefreshIndicator(
                      color: AppColors.teal,
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                        children: [
                          _Header(community: c, onJoin: _join),
                          const SizedBox(height: 20),
                          if (!c.isMember && !c.isOwner)
                            const EmptyState(
                              icon: Icons.lock_outline,
                              title: 'Join to see the feed',
                              subtitle:
                                  'Posts are visible to members of this community.',
                            )
                          else if (_posts.isEmpty)
                            const EmptyState(
                              icon: Icons.forum_outlined,
                              title: 'No posts yet',
                              subtitle:
                                  'The owner hasn\'t shared anything here.',
                            )
                          else
                            for (final p in _posts) ...[
                              _PostCard(
                                post: p,
                                isOwner: c.isOwner,
                                onCallStatusChanged: _load,
                              ),
                              const SizedBox(height: 10),
                            ],
                        ],
                      ),
                    ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.community, required this.onJoin});

  final Community community;
  final Future<void> Function() onJoin;

  @override
  Widget build(BuildContext context) {
    final paidTier = community.tiers
        .where((t) => !t.isFree && t.isActive)
        .fold<double?>(
            null, (lo, t) => lo == null || t.price < lo ? t.price : lo);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.teal50,
                child: Text(
                  (community.name.isNotEmpty ? community.name[0] : '?')
                      .toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.tealDarker,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(community.name,
                        style: const TextStyle(
                          color: AppColors.gray900,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        )),
                    const SizedBox(height: 2),
                    Text('by ${community.ownerName}',
                        style: const TextStyle(
                            color: AppColors.gray500, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          if (community.tagline.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(community.tagline,
                style: const TextStyle(
                    color: AppColors.gray700, fontSize: 14)),
          ],
          if (community.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(community.description,
                style: const TextStyle(
                    color: AppColors.gray600, fontSize: 13, height: 1.35)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.people_outline, size: 14, color: AppColors.gray500),
              const SizedBox(width: 4),
              Text('${community.memberCount} members',
                  style: const TextStyle(
                      color: AppColors.gray500, fontSize: 12)),
              const SizedBox(width: 14),
              if (paidTier != null)
                Text(
                  'VIP from ${community.currency} ${paidTier.toStringAsFixed(0)}/mo',
                  style: const TextStyle(
                    color: AppColors.tealDarker,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                const Text('Free community',
                    style: TextStyle(
                      color: AppColors.gray500,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    )),
            ],
          ),
          if (!community.isOwner) ...[
            const SizedBox(height: 14),
            if (community.isMember)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.teal50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.tealDarker, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'You\'re on the ${community.myMembership?.tierName ?? "Free"} tier',
                      style: const TextStyle(
                        color: AppColors.tealDarker,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            else
              PrimaryButton(
                label: 'Join free',
                onPressed: onJoin,
                icon: Icons.group_add,
              ),
          ],
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.isOwner,
    required this.onCallStatusChanged,
  });

  final CommunityPost post;
  final bool isOwner;
  final Future<void> Function() onCallStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(post.authorName,
                    style: const TextStyle(
                        color: AppColors.gray700,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
              Text(DateFormat('MMM d · HH:mm').format(post.createdAt.toLocal()),
                  style: const TextStyle(
                      color: AppColors.gray500, fontSize: 11)),
            ],
          ),
          if (post.title.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(post.title,
                style: const TextStyle(
                  color: AppColors.gray900,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                )),
          ],
          if (post.isTradeCall && post.tradeCall != null) ...[
            const SizedBox(height: 10),
            _TradeCallCard(
              call: post.tradeCall!,
              communityId: post.communityId,
              postId: post.id,
              isOwner: isOwner,
              onStatusChanged: onCallStatusChanged,
            ),
          ],
          if (post.body.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(post.body,
                style: const TextStyle(
                    color: AppColors.gray700, fontSize: 14, height: 1.4)),
          ],
          if (!post.isPublic) ...[
            const SizedBox(height: 10),
            const StatusPill(label: 'VIP', color: AppColors.violet),
          ],
        ],
      ),
    );
  }
}

/// Structured trade-call card — the differentiator over a plain text
/// signal post. Direction tints the header, prices sit in a compact
/// grid, a status pill shows live state, and the owner gets a menu to
/// flip the status as the call plays out.
class _TradeCallCard extends StatelessWidget {
  const _TradeCallCard({
    required this.call,
    required this.communityId,
    required this.postId,
    required this.isOwner,
    required this.onStatusChanged,
  });

  final TradeCall call;
  final int communityId;
  final int postId;
  final bool isOwner;
  final Future<void> Function() onStatusChanged;

  Color get _directionColor =>
      call.direction == 'long' ? AppColors.success : AppColors.danger;

  Color get _statusColor {
    if (call.isWinner) return AppColors.success;
    if (call.isLoser) return AppColors.danger;
    if (call.isOpen) return AppColors.info;
    return AppColors.gray500;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _directionColor.withValues(alpha: 0.12),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Icon(
                  call.direction == 'long'
                      ? Icons.trending_up
                      : Icons.trending_down,
                  color: _directionColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '${call.instrument} · ${call.direction.toUpperCase()}',
                  style: TextStyle(
                    color: _directionColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                StatusPill(label: call.statusLabel.toUpperCase(), color: _statusColor),
                if (isOwner) ...[
                  const SizedBox(width: 4),
                  _StatusFlipMenu(
                    communityId: communityId,
                    postId: postId,
                    current: call.status,
                    onChanged: onStatusChanged,
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              children: [
                Row(children: [
                  _CallPrice(label: 'Entry', value: call.entry),
                  _CallPrice(
                      label: 'SL',
                      value: call.stopLoss,
                      tint: AppColors.danger),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  _CallPrice(
                      label: 'TP1',
                      value: call.takeProfit1,
                      tint: AppColors.success),
                  _CallPrice(
                      label: 'TP2',
                      value: call.takeProfit2,
                      tint: AppColors.success),
                ]),
                if (call.takeProfit3 != null || call.riskPct != null) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    _CallPrice(
                        label: 'TP3',
                        value: call.takeProfit3,
                        tint: AppColors.success),
                    _CallPrice(
                      label: 'Risk',
                      value: call.riskPct,
                      suffix: '%',
                    ),
                  ]),
                ],
                if (call.closedPnlPips != null) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    const Text('Realised',
                        style: TextStyle(
                            color: AppColors.gray500, fontSize: 11.5)),
                    const SizedBox(width: 6),
                    Text(
                      '${call.closedPnlPips!.toStringAsFixed(1)} pips',
                      style: TextStyle(
                          color: AppColors.pnl(call.closedPnlPips!),
                          fontSize: 13,
                          fontWeight: FontWeight.w800),
                    ),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CallPrice extends StatelessWidget {
  const _CallPrice({
    required this.label,
    required this.value,
    this.tint,
    this.suffix = '',
  });

  final String label;
  final double? value;
  final Color? tint;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.gray500,
                )),
            const SizedBox(height: 2),
            Text(
              value == null ? '–' : '${formatPrice(value)}$suffix',
              style: TextStyle(
                color: tint ?? AppColors.gray900,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Three-dot menu the community owner uses to flip a call's status
/// as it plays out. Calls the parent's `onStatusChanged` after a
/// successful flip so the detail screen re-loads the feed.
class _StatusFlipMenu extends StatelessWidget {
  const _StatusFlipMenu({
    required this.communityId,
    required this.postId,
    required this.current,
    required this.onChanged,
  });

  final int communityId;
  final int postId;
  final String current;
  final Future<void> Function() onChanged;

  static const _options = [
    ('tp1_hit',     'Mark TP1 hit'),
    ('tp2_hit',     'Mark TP2 hit'),
    ('tp3_hit',     'Mark TP3 hit'),
    ('sl_hit',      'Mark SL hit'),
    ('closed',      'Mark closed'),
    ('invalidated', 'Invalidate'),
  ];

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18, color: AppColors.gray500),
      tooltip: 'Update status',
      onSelected: (status) => _flip(context, status),
      itemBuilder: (_) => [
        for (final (wire, label) in _options)
          PopupMenuItem(
            value: wire,
            enabled: wire != current,
            child: Text(label),
          ),
      ],
    );
  }

  Future<void> _flip(BuildContext context, String status) async {
    try {
      await CommunityService()
          .updateCallStatus(communityId, postId, status: status);
      await onChanged();
    } on ApiException catch (e) {
      if (context.mounted) showAppSnack(context, e.message, error: true);
    }
  }
}
