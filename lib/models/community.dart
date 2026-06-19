double _toDouble(Object? v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

/// A subscription tier inside a [Community]. `price == 0` is free.
class SubscriptionTier {
  const SubscriptionTier({
    required this.id,
    required this.communityId,
    required this.name,
    required this.description,
    required this.price,
    required this.interval,
    required this.isActive,
  });

  final int id;
  final int communityId;
  final String name;
  final String description;
  final double price;
  final String interval;
  final bool isActive;

  bool get isFree => price == 0;

  factory SubscriptionTier.fromJson(Map<String, dynamic> json) =>
      SubscriptionTier(
        id: (json['id'] as num?)?.toInt() ?? 0,
        communityId: (json['community'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        price: _toDouble(json['price']),
        interval: json['interval'] as String? ?? 'month',
        isActive: json['is_active'] as bool? ?? true,
      );
}

/// Membership summary the API returns for the signed-in viewer of a
/// community. `null` means "not a member". Status mirrors the backend
/// `Membership.STATUS_*` strings.
class MyMembership {
  const MyMembership({
    required this.id,
    required this.tierId,
    required this.tierName,
    required this.status,
    required this.isActive,
  });

  final int id;
  final int tierId;
  final String tierName;
  final String status;
  final bool isActive;

  factory MyMembership.fromJson(Map<String, dynamic> json) => MyMembership(
        id: (json['id'] as num?)?.toInt() ?? 0,
        tierId: (json['tier_id'] as num?)?.toInt() ?? 0,
        tierName: json['tier_name'] as String? ?? '',
        status: json['status'] as String? ?? '',
        isActive: json['is_active'] as bool? ?? false,
      );
}

/// A trading community ("guru's room"). The viewer's membership comes
/// embedded so screens can decide between a "Join" CTA and the post feed.
class Community {
  const Community({
    required this.id,
    required this.slug,
    required this.name,
    required this.tagline,
    required this.description,
    required this.currency,
    required this.ownerId,
    required this.ownerName,
    required this.memberCount,
    required this.tiers,
    required this.coverImageUrl,
    required this.avatarUrl,
    required this.isOwner,
    required this.myMembership,
  });

  final int id;
  final String slug;
  final String name;
  final String tagline;
  final String description;
  final String currency;
  final int ownerId;
  final String ownerName;
  final int memberCount;
  final List<SubscriptionTier> tiers;
  final String? coverImageUrl;
  final String? avatarUrl;
  final bool isOwner;
  final MyMembership? myMembership;

  bool get isMember => myMembership?.isActive == true;
  bool get hasPaidTier => tiers.any((t) => !t.isFree && t.isActive);

  factory Community.fromJson(Map<String, dynamic> json) {
    final tiersRaw = (json['tiers'] as List?) ?? const [];
    final myRaw = json['my_membership'];
    return Community(
      id: (json['id'] as num?)?.toInt() ?? 0,
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      tagline: json['tagline'] as String? ?? '',
      description: json['description'] as String? ?? '',
      currency: json['currency'] as String? ?? 'UGX',
      ownerId: (json['owner'] as num?)?.toInt() ?? 0,
      ownerName: json['owner_name'] as String? ?? '',
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      tiers: tiersRaw
          .map((e) => SubscriptionTier.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false),
      coverImageUrl: json['cover_image'] as String?,
      avatarUrl: json['avatar'] as String?,
      isOwner: json['is_owner'] as bool? ?? false,
      myMembership: myRaw is Map
          ? MyMembership.fromJson(Map<String, dynamic>.from(myRaw))
          : null,
    );
  }
}

/// A guru's post in the community feed. `isLocked` lets the client render
/// an "upgrade to read" stub even if a gated post ever leaks into a
/// viewer's response — the list endpoint already filters, this is belt
/// and braces.
class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.communityId,
    required this.authorId,
    required this.authorName,
    required this.kind,
    required this.title,
    required this.body,
    required this.imageUrl,
    required this.minTierId,
    required this.isLocked,
    required this.commentCount,
    required this.createdAt,
  });

  final int id;
  final int communityId;
  final int authorId;
  final String authorName;
  final String kind;
  final String title;
  final String body;
  final String? imageUrl;
  final int? minTierId;
  final bool isLocked;
  final int commentCount;
  final DateTime createdAt;

  bool get isPublic => minTierId == null;

  factory CommunityPost.fromJson(Map<String, dynamic> json) => CommunityPost(
        id: (json['id'] as num?)?.toInt() ?? 0,
        communityId: (json['community'] as num?)?.toInt() ?? 0,
        authorId: (json['author'] as num?)?.toInt() ?? 0,
        authorName: json['author_name'] as String? ?? '',
        kind: json['kind'] as String? ?? 'text',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        imageUrl: json['image'] as String?,
        minTierId: (json['min_tier'] as num?)?.toInt(),
        isLocked: json['is_locked'] as bool? ?? false,
        commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// A single-level comment on a [CommunityPost].
class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.body,
    required this.createdAt,
  });

  final int id;
  final int authorId;
  final String authorName;
  final String body;
  final DateTime createdAt;

  factory CommunityComment.fromJson(Map<String, dynamic> json) =>
      CommunityComment(
        id: (json['id'] as num?)?.toInt() ?? 0,
        authorId: (json['author'] as num?)?.toInt() ?? 0,
        authorName: json['author_name'] as String? ?? '',
        body: json['body'] as String? ?? '',
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}
