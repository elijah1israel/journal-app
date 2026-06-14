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
  });

  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String bio;
  final String experienceLevel;
  final String preferredMarkets;
  final String timezone;

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

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: (json['id'] as num?)?.toInt() ?? 0,
        email: json['email'] as String? ?? '',
        firstName: json['first_name'] as String? ?? '',
        lastName: json['last_name'] as String? ?? '',
        bio: json['bio'] as String? ?? '',
        experienceLevel: json['experience_level'] as String? ?? 'beginner',
        preferredMarkets: json['preferred_markets'] as String? ?? '',
        timezone: json['timezone'] as String? ?? 'UTC',
      );
}
