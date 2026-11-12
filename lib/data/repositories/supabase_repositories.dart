import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/culture_event.dart';
import '../models/user_profile.dart';
import 'repositories.dart';

const _imageBucket = 'event-images';

AppUser? _toAppUser(User? user) =>
    user == null ? null : AppUser(id: user.id, email: user.email ?? '');

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  AppUser? get currentUser => _toAppUser(_client.auth.currentUser);

  @override
  Stream<AppUser?> authStateChanges() => _client.auth.onAuthStateChange
      .map((state) => _toAppUser(state.session?.user));

  @override
  Future<void> signIn({required String email, required String password}) =>
      _client.auth.signInWithPassword(email: email, password: password);

  @override
  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final res = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName},
    );
    return res.session == null
        ? SignUpResult.needsEmailConfirmation
        : SignUpResult.signedIn;
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<void> sendPasswordReset(String email) =>
      _client.auth.resetPasswordForEmail(email);

  @override
  Future<UserProfile?> fetchProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return row == null ? null : UserProfile.fromJson(row);
  }

  @override
  Future<void> updateProfile(UserProfile profile) => _client
      .from('profiles')
      .update({
        'display_name': profile.displayName,
        'interests': profile.interests.map((c) => c.slug).toList(),
        'onboarded': profile.onboarded,
        'prefs': profile.prefs.toJson(),
      })
      .eq('id', profile.id);
}

class SupabaseEventRepository implements EventRepository {
  SupabaseEventRepository(this._client);

  final SupabaseClient _client;

  List<CultureEvent> _map(List<Map<String, dynamic>> rows) =>
      rows.map(CultureEvent.fromJson).toList();

  @override
  Future<List<CultureEvent>> fetchApproved() async {
    final rows = await _client
        .from('events')
        .select()
        .eq('status', 'approved')
        .order('start_at', ascending: true, nullsFirst: false)
        .limit(500);
    return _map(rows).where((e) => e.isUpcoming).toList();
  }

  @override
  Future<CultureEvent?> fetchById(String id) async {
    final row =
        await _client.from('events').select().eq('id', id).maybeSingle();
    return row == null ? null : CultureEvent.fromJson(row);
  }

  @override
  Future<List<CultureEvent>> fetchPending() async {
    final rows = await _client
        .from('events')
        .select()
        .eq('status', 'pending')
        .order('created_at', ascending: true);
    return _map(rows);
  }

  @override
  Future<List<CultureEvent>> fetchByUser(String userId) async {
    final rows = await _client
        .from('events')
        .select()
        .eq('created_by', userId)
        .order('created_at', ascending: false);
    return _map(rows);
  }

  @override
  Future<CultureEvent> create(EventDraft draft, {PickedImage? image}) async {
    final userId = _client.auth.currentUser!.id;
    String? imageUrl;
    if (image != null) {
      final path =
          '$userId/${DateTime.now().millisecondsSinceEpoch}.${image.extension}';
      await _client.storage.from(_imageBucket).uploadBinary(
            path,
            image.bytes,
            fileOptions: FileOptions(
              contentType: 'image/${image.extension == 'jpg' ? 'jpeg' : image.extension}',
            ),
          );
      imageUrl = _client.storage.from(_imageBucket).getPublicUrl(path);
    }
    final row = await _client
        .from('events')
        .insert({
          ...draft.toJson(),
          'image_url': imageUrl,
          'created_by': userId,
          'status': 'pending',
        })
        .select()
        .single();
    return CultureEvent.fromJson(row);
  }

  @override
  Future<void> setStatus(String id, EventStatus status) =>
      _client.from('events').update({'status': status.name}).eq('id', id);

  @override
  Future<void> delete(String id) => _client.from('events').delete().eq('id', id);

  @override
  Future<Set<String>> fetchFavoriteIds(String userId) async {
    final rows = await _client
        .from('favorites')
        .select('event_id')
        .eq('user_id', userId);
    return rows.map((r) => r['event_id'] as String).toSet();
  }

  @override
  Future<List<CultureEvent>> fetchFavorites(String userId) async {
    final rows = await _client
        .from('favorites')
        .select('events(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return rows
        .map((r) => r['events'])
        .whereType<Map<String, dynamic>>()
        .map(CultureEvent.fromJson)
        .toList();
  }

  @override
  Future<void> setFavorite(String userId, String eventId, bool favorite) async {
    if (favorite) {
      await _client
          .from('favorites')
          .upsert({'user_id': userId, 'event_id': eventId});
    } else {
      await _client
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('event_id', eventId);
    }
  }

  StreamController<void>? _changes;
  Timer? _debounce;

  /// Supabase Realtime ile `events` tablosundaki değişiklikleri dinler.
  /// Senkronizasyon aynı anda çok satır yazdığı için olaylar birleştirilir.
  @override
  Stream<void> changes() {
    final existing = _changes;
    if (existing != null) return existing.stream;
    final controller = StreamController<void>.broadcast();
    _changes = controller;
    _client
        .channel('public:events')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'events',
          callback: (_) {
            _debounce?.cancel();
            _debounce = Timer(
              const Duration(milliseconds: 800),
              () => controller.add(null),
            );
          },
        )
        .subscribe();
    return controller.stream;
  }

  @override
  Future<DateTime?> dataUpdatedAt() async {
    final row = await _client
        .from('events')
        .select('synced_at')
        .not('synced_at', 'is', null)
        .order('synced_at', ascending: false)
        .limit(1)
        .maybeSingle();
    final value = row?['synced_at'] as String?;
    return value == null ? null : DateTime.parse(value).toLocal();
  }
}
