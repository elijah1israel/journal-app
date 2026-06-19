/// The authenticated user as returned by `/traders/me/`.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.bio,
    required this.experienceLevel,
    required this.preferredMarkets,
    required this.timezone,
    required this.dailyLossLimit,
    required this.coolDownMinutesAfterLoss,
  });

  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String bio;
  final String experienceLevel;
  final String preferredMarkets;
  final String timezone;

  /// Absolute daily loss cap in account currency, or null if unset.
  /// When today's realised P&L drops to `-dailyLossLimit`, the API
  /// refuses to create new pre-trade plans for the rest of the day.
  final double? dailyLossLimit;

  /// After any losing trade, new pre-trade plans are blocked for this
  /// many minutes. 0 disables the cool-down.
  final int coolDownMinutesAfterLoss;

  String get displayName {
    final full = '$firstName $lastName'.trim();
    return full.isEmpty ? email : full;
  }

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    final out = (f + l).toUpperCase();
    return out.isEmpty
        ? (email.isNotEmpty ? email[0].toUpperCase() : '?')
        : out;
  }

  static double? _maybeNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: (json['id'] as num?)?.toInt() ?? 0,
        email: json['email'] as String? ?? '',
        firstName: json['first_name'] as String? ?? '',
        lastName: json['last_name'] as String? ?? '',
        bio: json['bio'] as String? ?? '',
        experienceLevel: json['experience_level'] as String? ?? 'beginner',
        preferredMarkets: json['preferred_markets'] as String? ?? '',
        timezone: json['timezone'] as String? ?? 'UTC',
        dailyLossLimit: _maybeNum(json['daily_loss_limit']),
        coolDownMinutesAfterLoss:
            (json['cool_down_minutes_after_loss'] as num?)?.toInt() ?? 0,
      );
}
