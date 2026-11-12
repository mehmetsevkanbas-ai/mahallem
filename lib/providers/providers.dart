import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/env.dart';
import '../data/models/culture_event.dart';
import '../data/models/event_category.dart';
import '../data/models/user_preferences.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/repositories.dart';
import 'event_filter.dart';
import 'recommendations.dart';

export 'event_filter.dart';
export 'recommendations.dart';

// ---------------------------------------------------------------------------
// Altyapı (main.dart içinde override edilir)
// ---------------------------------------------------------------------------

final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('main.dart içinde override edilmeli'),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => throw UnimplementedError('main.dart içinde override edilmeli'),
);

final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => throw UnimplementedError('main.dart içinde override edilmeli'),
);

final isDemoModeProvider = Provider<bool>((ref) => !Env.useSupabase);

// ---------------------------------------------------------------------------
// Oturum ve profil
// ---------------------------------------------------------------------------

final authStateProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

final currentUserProvider = Provider<AppUser?>((ref) {
  final auth = ref.watch(authStateProvider);
  return auth.hasValue ? auth.value : ref.read(authRepositoryProvider).currentUser;
});

class ProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return null;
    return ref.read(authRepositoryProvider).fetchProfile(user.id);
  }

  Future<void> save(UserProfile profile) async {
    await ref.read(authRepositoryProvider).updateProfile(profile);
    state = AsyncData(profile);
  }

  Future<void> saveInterests(Set<EventCategory> interests) async {
    final current = state.value;
    if (current == null) return;
    await save(current.copyWith(interests: interests, onboarded: true));
  }

  /// Kayıt sorularının yanıtlarını kaydeder.
  Future<void> saveOnboarding(Set<EventCategory> interests, UserPreferences prefs) async {
    final current = state.value;
    if (current == null) return;
    await save(current.copyWith(interests: interests, prefs: prefs, onboarded: true));
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, UserProfile?>(ProfileNotifier.new);

// ---------------------------------------------------------------------------
// Etkinlikler
// ---------------------------------------------------------------------------

final approvedEventsProvider = FutureProvider<List<CultureEvent>>((ref) {
  final repo = ref.watch(eventRepositoryProvider);
  // Veritabanı değişince (yeni senkronizasyon, onay) listeyi kendiliğinden yenile.
  final sub = repo.changes().listen((_) => ref.invalidateSelf());
  ref.onDispose(sub.cancel);
  return repo.fetchApproved();
});

/// Belediye verilerinin son alınma zamanı.
final dataUpdatedAtProvider = FutureProvider<DateTime?>((ref) {
  ref.watch(approvedEventsProvider);
  return ref.read(eventRepositoryProvider).dataUpdatedAt();
});

final eventByIdProvider =
    FutureProvider.family<CultureEvent?, String>((ref, id) async {
  final cached = ref.read(approvedEventsProvider).value;
  final hit = cached?.where((e) => e.id == id).firstOrNull;
  return hit ?? ref.read(eventRepositoryProvider).fetchById(id);
});

final pendingEventsProvider = FutureProvider<List<CultureEvent>>(
  (ref) => ref.watch(eventRepositoryProvider).fetchPending(),
);

final myEventsProvider = FutureProvider<List<CultureEvent>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];
  return ref.read(eventRepositoryProvider).fetchByUser(user.id);
});

/// Etkinlik ekleme / onaylama sonrası ilgili listeleri yeniler.
void refreshEventLists(WidgetRef ref) {
  ref.invalidate(approvedEventsProvider);
  ref.invalidate(pendingEventsProvider);
  ref.invalidate(myEventsProvider);
  ref.invalidate(eventByIdProvider);
}

// ---------------------------------------------------------------------------
// Filtreler
// ---------------------------------------------------------------------------

class FilterNotifier extends Notifier<EventFilter> {
  @override
  EventFilter build() => const EventFilter();

  void toggleCategory(EventCategory category) {
    final next = {...state.categories};
    next.contains(category) ? next.remove(category) : next.add(category);
    state = state.copyWith(categories: next);
  }

  void setKind(KindFilter kind) => state = state.copyWith(kind: kind);
  void setDate(DateFilter date) => state = state.copyWith(date: date);
  void setQuery(String query) => state = state.copyWith(query: query);
  void setForYou(bool value) => state = state.copyWith(forYou: value);
  void reset() => state = const EventFilter();
}

final filterProvider =
    NotifierProvider<FilterNotifier, EventFilter>(FilterNotifier.new);

final userInterestsProvider = Provider<Set<EventCategory>>(
  (ref) => ref.watch(profileProvider).value?.interests ?? const {},
);

final userPrefsProvider = Provider<UserPreferences>(
  (ref) => ref.watch(profileProvider).value?.prefs ?? const UserPreferences(),
);

final filteredEventsProvider = Provider<AsyncValue<List<CultureEvent>>>((ref) {
  final events = ref.watch(approvedEventsProvider);
  final filter = ref.watch(filterProvider);
  final interests = ref.watch(userInterestsProvider);
  if (!filter.forYou) {
    return events.whenData((list) => applyEventFilter(list, filter, interests));
  }
  // "Senin için": diğer filtreler uygulanır, sonra kişisel puana göre sıralanır.
  final prefs = ref.watch(userPrefsProvider);
  final favorites = ref.watch(favoriteEventsProvider).value ?? const <CultureEvent>[];
  return events.whenData((list) {
    final base = applyEventFilter(list, filter.copyWith(forYou: false), interests);
    return recommendEvents(
      events: base,
      interests: interests,
      prefs: prefs,
      favorites: favorites,
      excludeFavorites: false,
      limit: 1000,
    ).map((r) => r.event).toList();
  });
});

/// Kişisel öneriler (filtrelerden bağımsız): ilgi alanları, kayıt soruları
/// ve favorilere göre puanlanır; her önerinin gerekçesi de döner.
final recommendedEventsProvider = Provider<List<Recommendation>>((ref) {
  if (ref.watch(currentUserProvider) == null) return const [];
  final interests = ref.watch(userInterestsProvider);
  final prefs = ref.watch(userPrefsProvider);
  final favorites = ref.watch(favoriteEventsProvider).value ?? const <CultureEvent>[];
  final events = ref.watch(approvedEventsProvider).value ?? const [];
  if (interests.isEmpty && prefs.isEmpty && favorites.isEmpty) return const [];
  return recommendEvents(
    events: events,
    interests: interests,
    prefs: prefs,
    favorites: favorites,
    limit: 12,
  );
});

/// Haritada seçili etkinlik.
class SelectedEventNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}

final selectedEventIdProvider =
    NotifierProvider<SelectedEventNotifier, String?>(SelectedEventNotifier.new);

// ---------------------------------------------------------------------------
// Favoriler
// ---------------------------------------------------------------------------

class FavoritesNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return {};
    return ref.read(eventRepositoryProvider).fetchFavoriteIds(user.id);
  }

  Future<void> toggle(String eventId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final current = state.value ?? <String>{};
    final makeFavorite = !current.contains(eventId);
    state = AsyncData(
      makeFavorite ? {...current, eventId} : ({...current}..remove(eventId)),
    );
    try {
      await ref
          .read(eventRepositoryProvider)
          .setFavorite(user.id, eventId, makeFavorite);
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
    ref.invalidate(favoriteEventsProvider);
  }
}

final favoritesProvider =
    AsyncNotifierProvider<FavoritesNotifier, Set<String>>(FavoritesNotifier.new);

final favoriteEventsProvider = FutureProvider<List<CultureEvent>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];
  return ref.read(eventRepositoryProvider).fetchFavorites(user.id);
});

// ---------------------------------------------------------------------------
// Ayarlar (dil ve tema), cihazda saklanır
// ---------------------------------------------------------------------------

const supportedLanguageCodes = ['tr', 'en', 'ru', 'de'];

class LocaleNotifier extends Notifier<Locale?> {
  static const _key = 'locale';

  @override
  Locale? build() {
    final code = ref.read(sharedPrefsProvider).getString(_key);
    return code == null ? null : Locale(code);
  }

  Future<void> set(Locale? locale) async {
    state = locale;
    final prefs = ref.read(sharedPrefsProvider);
    locale == null
        ? await prefs.remove(_key)
        : await prefs.setString(_key, locale.languageCode);
  }
}

final localeProvider =
    NotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    final name = ref.read(sharedPrefsProvider).getString(_key);
    return ThemeMode.values.firstWhere(
      (m) => m.name == name,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPrefsProvider).setString(_key, mode.name);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
