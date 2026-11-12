import 'dart:typed_data';

import '../models/culture_event.dart';
import '../models/user_profile.dart';

/// Seçilen görsel (web ve mobilde ortak kullanılabilsin diye bayt olarak).
class PickedImage {
  const PickedImage({required this.bytes, required this.extension});

  final Uint8List bytes;
  final String extension;
}

/// Kayıt sonucu: e-posta doğrulaması gerekiyorsa oturum açılmaz.
enum SignUpResult { signedIn, needsEmailConfirmation }

abstract class AuthRepository {
  AppUser? get currentUser;
  Stream<AppUser?> authStateChanges();

  Future<void> signIn({required String email, required String password});
  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String displayName,
  });
  Future<void> signOut();
  Future<void> sendPasswordReset(String email);

  Future<UserProfile?> fetchProfile(String userId);
  Future<void> updateProfile(UserProfile profile);
}

abstract class EventRepository {
  /// Yayındaki (onaylı) ve henüz bitmemiş etkinlikler.
  Future<List<CultureEvent>> fetchApproved();
  Future<CultureEvent?> fetchById(String id);
  Future<List<CultureEvent>> fetchPending();
  Future<List<CultureEvent>> fetchByUser(String userId);

  Future<CultureEvent> create(EventDraft draft, {PickedImage? image});
  Future<void> setStatus(String id, EventStatus status);
  Future<void> delete(String id);

  Future<Set<String>> fetchFavoriteIds(String userId);
  Future<List<CultureEvent>> fetchFavorites(String userId);
  Future<void> setFavorite(String userId, String eventId, bool favorite);

  /// Etkinlik tablosu değiştiğinde (yeni senkronizasyon, onay vb.) tetiklenir.
  Stream<void> changes();

  /// Belediye verilerinin en son ne zaman alındığı.
  Future<DateTime?> dataUpdatedAt();
}
