double _toDouble(Object? v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

double? _maybeDouble(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

/// Structured trade call payload attached 1:1 to a [CommunityPost] when
/// `kind == 'trade_call'`. Status flips as the call plays out (TP1 hit,
/// SL hit, closed, invalidated); subscribers see the status change in
/// the feed without the guru re-posting.
class TradeCall {
  const TradeCall({
    required this.id,
    required this.instrument,
    required this.direction,
    required this.entry,
    required this.stopLoss,
    required this.takeProfit1,
    required this.takeProfit2,
    required this.takeProfit3,
    required this.riskPct,
    required this.status,
    required this.closedAt,
    required this.closedPnlPips,
  });

  final int id;
  final String instrument;
  final String direction; // 'long' | 'short'
  final double entry;
  final double stopLoss;
  final double takeProfit1;
  final double? takeProfit2;
  final double? takeProfit3;
  final double? riskPct;
  final String status;
  final DateTime? closedAt;
  final double? closedPnlPips;

  bool get isOpen => status == 'active';
  bool get isWinner =>
      status == 'tp1_hit' || status == 'tp2_hit' || status == 'tp3_hit';
  bool get isLoser => status == 'sl_hit';

  String get statusLabel => switch (status) {
        'active'      => 'Active',
        'tp1_hit'     => 'TP1 hit',
        'tp2_hit'     => 'TP2 hit',
        'tp3_hit'     => 'TP3 hit',
        'sl_hit'      => 'SL hit',
        'closed'      => 'Closed',
        'invalidated' => 'Invalidated',
        _             => status,
      };

  factory TradeCall.fromJson(Map<String, dynamic> json) => TradeCall(
        id: (json['id'] as num?)?.toInt() ?? 0,
        instrument: json['instrument'] as String? ?? '',
        direction: json['direction'] as String? ?? 'long',
        entry: _toDouble(json['entry']),
        stopLoss: _toDouble(json['stop_loss']),
        takeProfit1: _toDouble(json['take_profit_1']),
        takeProfit2: _maybeDouble(json['take_profit_2']),
        takeProfit3: _maybeDouble(json['take_profit_3']),
        riskPct: _maybeDouble(json['risk_pct']),
        status: json['status'] as String? ?? 'active',
        closedAt: json['closed_at'] == null
            ? null
            : DateTime.tryParse(json['closed_at'] as String),
        closedPnlPips: _maybeDouble(json['closed_pnl_pips']),
      );
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
    required this.tradeCall,
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
  final TradeCall? tradeCall;

  bool get isPublic => minTierId == null;
  bool get isTradeCall => kind == 'trade_call';

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    final rawCall = json['trade_call'];
    return CommunityPost(
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
      tradeCall: rawCall is Map
          ? TradeCall.fromJson(Map<String, dynamic>.from(rawCall))
          : null,
    );
  }
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
