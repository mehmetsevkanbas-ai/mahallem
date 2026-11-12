import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/culture_event.dart';
import '../models/event_category.dart';
import '../models/user_profile.dart';
import 'repositories.dart';

/// Supabase anahtarları verilmediğinde kullanılan yerel mod.
///
/// Etkinlikler, `tool/sync_events.dart` aracının belediye sitelerinden ürettiği
/// gerçek veri dosyasından (`assets/data/events.json`) okunur. Hesaplar,
/// favoriler ve kullanıcıların eklediği etkinlikler yalnızca bu oturumda tutulur.
class LocalStore {
  LocalStore({List<CultureEvent>? events, this.generatedAt}) : events = events ?? [];

  static const snapshotAsset = 'assets/data/events.json';

  final List<CultureEvent> events;
  final DateTime? generatedAt;
  final profiles = <String, UserProfile>{};
  final favorites = <String, Set<String>>{};

  static Future<LocalStore> loadSnapshot([AssetBundle? bundle]) async {
    try {
      final raw = await (bundle ?? rootBundle).loadString(snapshotAsset);
      return parseSnapshot(raw);
    } catch (_) {
      return LocalStore();
    }
  }

  static LocalStore parseSnapshot(String raw) {
    final json = jsonDecode(raw);
    if (json is! Map<String, dynamic>) return LocalStore();
    final list = (json['events'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(CultureEvent.fromJson)
        .toList();
    return LocalStore(
      events: list,
      generatedAt: DateTime.tryParse(json['generated_at'] as String? ?? '')?.toLocal(),
    );
  }
}

class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._store);

  final LocalStore _store;
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _user;

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _user;
    yield* _controller.stream;
  }

  String _idFor(String email) =>
      'user-${base64Url.encode(utf8.encode(email.toLowerCase()))}';

  @override
  Future<void> signIn({required String email, required String password}) async {
    final id = _idFor(email);
    _store.profiles.putIfAbsent(
      id,
      () => UserProfile(
        id: id,
        displayName: email.split('@').first,
        interests: const {},
        role: email.contains('admin') ? UserRole.admin : UserRole.user,
        onboarded: false,
      ),
    );
    _user = AppUser(id: id, email: email);
    _controller.add(_user);
  }

  @override
  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final id = _idFor(email);
    _store.profiles[id] = UserProfile(
      id: id,
      displayName: displayName,
      interests: const <EventCategory>{},
      role: email.contains('admin') ? UserRole.admin : UserRole.user,
      onboarded: false,
    );
    await signIn(email: email, password: password);
    return SignUpResult.signedIn;
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<UserProfile?> fetchProfile(String userId) async => _store.profiles[userId];

  @override
  Future<void> updateProfile(UserProfile profile) async {
    _store.profiles[profile.id] = profile;
  }
}

class LocalEventRepository implements EventRepository {
  LocalEventRepository(this._store, this._auth);

  final LocalStore _store;
  final AuthRepository _auth;
  final _changes = StreamController<void>.broadcast();

  @override
  Future<List<CultureEvent>> fetchApproved() async => _store.events
      .where((e) => e.status == EventStatus.approved && e.isUpcoming)
      .toList();

  @override
  Future<CultureEvent?> fetchById(String id) async =>
      _store.events.where((e) => e.id == id).firstOrNull;

  @override
  Future<List<CultureEvent>> fetchPending() async =>
      _store.events.where((e) => e.status == EventStatus.pending).toList();

  @override
  Future<List<CultureEvent>> fetchByUser(String userId) async =>
      _store.events.where((e) => e.createdBy == userId).toList().reversed.toList();

  @override
  Future<CultureEvent> create(EventDraft draft, {PickedImage? image}) async {
    final event = CultureEvent.fromJson({
      ...draft.toJson(),
      'id': 'local-${DateTime.now().microsecondsSinceEpoch}',
      'status': 'pending',
      'created_by': _auth.currentUser?.id,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      // Yerel modda görsel, veri URI'si olarak saklanır.
      'image_url': image == null
          ? null
          : 'data:image/${image.extension};base64,${base64Encode(image.bytes)}',
    });
    _store.events.add(event);
    _changes.add(null);
    return event;
  }

  @override
  Future<void> setStatus(String id, EventStatus status) async {
    final index = _store.events.indexWhere((e) => e.id == id);
    if (index >= 0) {
      _store.events[index] = _store.events[index].copyWith(status: status);
      _changes.add(null);
    }
  }

  @override
  Future<void> delete(String id) async {
    _store.events.removeWhere((e) => e.id == id);
    _changes.add(null);
  }

  @override
  Future<Set<String>> fetchFavoriteIds(String userId) async =>
      {...?_store.favorites[userId]};

  @override
  Future<List<CultureEvent>> fetchFavorites(String userId) async {
    final ids = _store.favorites[userId] ?? const <String>{};
    return _store.events.where((e) => ids.contains(e.id)).toList();
  }

  @override
  Future<void> setFavorite(String userId, String eventId, bool favorite) async {
    final set = _store.favorites.putIfAbsent(userId, () => <String>{});
    favorite ? set.add(eventId) : set.remove(eventId);
  }

  @override
  Stream<void> changes() => _changes.stream;

  @override
  Future<DateTime?> dataUpdatedAt() async => _store.generatedAt;
}
