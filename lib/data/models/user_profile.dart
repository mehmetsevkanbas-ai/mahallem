import 'event_category.dart';
import 'user_preferences.dart';

class AppUser {
  const AppUser({required this.id, required this.email});

  final String id;
  final String email;
}

enum UserRole { user, admin }

class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.interests,
    required this.role,
    required this.onboarded,
    this.prefs = const UserPreferences(),
  });

  final String id;
  final String displayName;
  final Set<EventCategory> interests;
  final UserRole role;
  final bool onboarded;

  /// Kayıtta sorulan tercih soruları (zaman, bütçe, bölge...).
  final UserPreferences prefs;

  bool get isAdmin => role == UserRole.admin;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        displayName: (json['display_name'] as String?) ?? '',
        interests: ((json['interests'] as List?) ?? const [])
            .map((s) => EventCategory.fromSlug(s as String))
            .toSet(),
        role: json['role'] == 'admin' ? UserRole.admin : UserRole.user,
        onboarded: (json['onboarded'] as bool?) ?? false,
        prefs: UserPreferences.fromJson((json['prefs'] as Map?)?.cast<String, dynamic>()),
      );

  UserProfile copyWith({
    String? displayName,
    Set<EventCategory>? interests,
    bool? onboarded,
    UserPreferences? prefs,
  }) =>
      UserProfile(
        id: id,
        displayName: displayName ?? this.displayName,
        interests: interests ?? this.interests,
        role: role,
        onboarded: onboarded ?? this.onboarded,
        prefs: prefs ?? this.prefs,
      );
}
