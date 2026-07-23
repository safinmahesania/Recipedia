/// Plain data model for a profile row.
class UserProfile {
  final String id;
  final String? name;
  final String? email;
  final String? avatarUrl;
  final String role;

  const UserProfile({
    required this.id,
    this.name,
    this.email,
    this.avatarUrl,
    this.role = 'user',
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        id: map['id'] as String,
        name: map['name'],
        email: map['email'],
        avatarUrl: map['avatar_url'],
        role: map['role'] ?? 'user',
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'avatar_url': avatarUrl,
      };

  bool get isAdmin => role == 'admin';
}
