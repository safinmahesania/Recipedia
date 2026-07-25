/// Plain data model for a profile row.
/// Preference fields were added in migration 20260725000009.
class UserProfile {
  final String id;
  final String? name;
  final String? email;
  final String? avatarUrl;
  final String role;

  // identity
  final String? username;
  final String? bio;

  // preferences
  final String? dietPreference;
  final String? defaultCuisine;
  final String units;
  final String language;
  final String themeMode;
  final bool hideUnsafe;

  // notification preferences — stored now, delivered once FCM ships
  final bool notifyNewRecipes;
  final bool notifySubmissionStatus;
  final bool notifyReviewReplies;

  const UserProfile({
    required this.id,
    this.name,
    this.email,
    this.avatarUrl,
    this.role = 'user',
    this.username,
    this.bio,
    this.dietPreference,
    this.defaultCuisine,
    this.units = 'metric',
    this.language = 'en',
    this.themeMode = 'system',
    this.hideUnsafe = true,
    this.notifyNewRecipes = true,
    this.notifySubmissionStatus = true,
    this.notifyReviewReplies = true,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        id: map['id'] as String,
        name: map['name'],
        email: map['email'],
        avatarUrl: map['avatar_url'],
        role: map['role'] ?? 'user',
        username: map['username'],
        bio: map['bio'],
        dietPreference: map['diet_preference'],
        defaultCuisine: map['default_cuisine'],
        units: map['units'] ?? 'metric',
        language: map['language'] ?? 'en',
        themeMode: map['theme_mode'] ?? 'system',
        hideUnsafe: map['hide_unsafe'] ?? true,
        notifyNewRecipes: map['notify_new_recipes'] ?? true,
        notifySubmissionStatus: map['notify_submission_status'] ?? true,
        notifyReviewReplies: map['notify_review_replies'] ?? true,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'avatar_url': avatarUrl,
        'username': username,
        'bio': bio,
      };

  bool get isAdmin => role == 'admin';
  String get initial =>
      (name ?? email ?? '?').trim().isEmpty ? '?' : (name ?? email!).trim()[0].toUpperCase();
}
