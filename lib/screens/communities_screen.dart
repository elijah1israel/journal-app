import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/community.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import 'community_detail_screen.dart';
import 'community_form_sheet.dart';

/// Two-tab community browser: **Discover** (every published community) and
/// **My communities** (the rooms I've joined or own). FAB opens a sheet
/// that creates a new community — the creator becomes the owner and is
/// auto-joined to its free tier.
class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Communities'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.tealDarker,
          unselectedLabelColor: AppColors.gray500,
          indicatorColor: AppColors.teal,
          tabs: const [
            Tab(text: 'Discover'),
            Tab(text: 'My communities'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateSheet,
        backgroundColor: AppColors.teal,
        foregroundColor: AppColors.inkDeep,
        icon: const Icon(Icons.add),
        label: const Text('Start one'),
      ),
      body: RefreshIndicator(
        color: AppColors.teal,
        onRefresh: () => state.refreshCommunities(),
        child: TabBarView(
          controller: _tabs,
          children: [
            _CommunityList(
              communities: state.discoverCommunities,
              loading: state.loadingCommunities,
              emptyTitle: 'No communities yet',
              emptySubtitle:
                  'Be the first to start one — gurus charge, members follow signals.',
            ),
            _CommunityList(
              communities: state.myCommunities,
              loading: state.loadingCommunities,
              emptyTitle: 'You haven\'t joined anything',
              emptySubtitle:
                  'Browse Discover and tap "Join" on any community to get its feed.',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCreateSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (_) => const CommunityFormSheet(),
    );
  }
}

class _CommunityList extends StatelessWidget {
  const _CommunityList({
    required this.communities,
    required this.loading,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  final List<Community> communities;
  final bool loading;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context) {
    if (communities.isEmpty) {
      if (loading) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.teal),
        );
      }
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          EmptyState(
            icon: Icons.groups_2_outlined,
            title: emptyTitle,
            subtitle: emptySubtitle,
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: communities.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _CommunityCard(community: communities[i]),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  const _CommunityCard({required this.community});

  final Community community;

  @override
  Widget build(BuildContext context) {
    final paidTier = community.tiers
        .where((t) => !t.isFree && t.isActive)
        .fold<double?>(null, (lo, t) => lo == null || t.price < lo ? t.price : lo);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => CommunityDetailScreen(communityId: community.id),
        )),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.teal50,
                child: Text(
                  (community.name.isNotEmpty ? community.name[0] : '?')
                      .toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.tealDarker,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            community.name,
                            style: const TextStyle(
                              color: AppColors.gray900,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (community.isOwner)
                          const StatusPill(label: 'OWNER', color: AppColors.violet)
                        else if (community.isMember)
                          const StatusPill(label: 'MEMBER', color: AppColors.teal),
                      ],
                    ),
                    if (community.tagline.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        community.tagline,
                        style: const TextStyle(
                            color: AppColors.gray600, fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.people_outline,
                            size: 14, color: AppColors.gray500),
                        const SizedBox(width: 4),
                        Text('${community.memberCount}',
                            style: const TextStyle(
                                color: AppColors.gray500, fontSize: 12)),
                        const SizedBox(width: 12),
                        if (paidTier != null)
                          Text(
                            'from ${community.currency} ${paidTier.toStringAsFixed(0)}/mo',
                            style: const TextStyle(
                              color: AppColors.tealDarker,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        else
                          const Text(
                            'Free',
                            style: TextStyle(
                              color: AppColors.gray500,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
