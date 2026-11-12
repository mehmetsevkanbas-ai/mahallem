import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahallem/data/models/culture_event.dart';
import 'package:mahallem/data/models/event_category.dart';
import 'package:mahallem/data/repositories/local_repositories.dart';
import 'package:mahallem/features/events/event_widgets.dart';
import 'package:mahallem/l10n/app_localizations.dart';
import 'package:mahallem/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Testler için sabit örnek kayıtlar (uygulamada sahte veri yoktur).
List<CultureEvent> fixtureEvents(DateTime now) {
  CultureEvent e(String id, String title, EventCategory c,
          {EventKind kind = EventKind.event, String? venue, int startDay = 1}) =>
      CultureEvent(
        id: id,
        title: title,
        description: '',
        category: c,
        kind: kind,
        startAt: kind == EventKind.course ? null : now.add(Duration(days: startDay)),
        lat: 36.54,
        lng: 32.0,
        venueName: venue,
        status: EventStatus.approved,
        createdAt: now,
        source: 'alanya_bel',
        sourceUrl: 'https://www.alanya.bel.tr/etkinlikler/etkinlik/$id',
      );
  return [
    e('1', 'Caz Gecesi', EventCategory.music, venue: 'Kızılkule'),
    e('2', 'Hamlet', EventCategory.theatre, venue: 'Alanya Kültür Merkezi'),
    e('3', 'Bağlama Kursu', EventCategory.music, kind: EventKind.course),
    e('4', 'Taş Heykel Sempozyumu', EventCategory.art, startDay: 10),
  ];
}

const _snapshot = '''
{
  "generated_at": "2026-11-12T20:00:00Z",
  "events": [
    {
      "id": "alanya_bel:20059", "source": "alanya_bel", "source_id": "20059",
      "source_url": "https://www.alanya.bel.tr/etkinlikler/etkinlik/20059",
      "title": "16. Alanya Uluslarası Noel Pazarı", "description": "",
      "category": "festival", "kind": "event",
      "start_at": "2099-12-11T05:00:00.000Z", "end_at": "2099-12-11T20:00:00.000Z",
      "lat": 36.54, "lng": 32.0, "status": "approved", "is_free": true
    }
  ]
}
''';

void main() {
  group('Filtreler', () {
    final now = DateTime(2026, 11, 12, 10); // Perşembe
    final events = fixtureEvents(now);

    test('kategori filtresi', () {
      final r = applyEventFilter(events, const EventFilter(categories: {EventCategory.music}), const {});
      expect(r.map((e) => e.id), containsAll(['1', '3']));
      expect(r.every((e) => e.category == EventCategory.music), isTrue);
    });

    test('kurs filtresi', () {
      final r = applyEventFilter(events, const EventFilter(kind: KindFilter.courses), const {});
      expect(r.single.id, '3');
    });

    test('arama Türkçe karakterlere duyarsız', () {
      final r = applyEventFilter(events, const EventFilter(query: 'KIZILKULE'), const {});
      expect(r.single.id, '1');
    });

    test('"Senin için" ilgi alanlarına göre süzer', () {
      final r = applyEventFilter(events, const EventFilter(forYou: true), {EventCategory.theatre});
      expect(r.single.id, '2');
    });

    test('hafta sonu ve bu hafta aralıkları', () {
      final (ws, we) = dateRangeFor(DateFilter.weekend, now)!;
      expect(ws, DateTime(2026, 11, 14));
      expect(we, DateTime(2026, 11, 16));
      final (_, end) = dateRangeFor(DateFilter.thisWeek, now)!;
      expect(end, DateTime(2026, 11, 16));
    });
  });

  group('Yerel depo', () {
    test('belediye anlık görüntüsü okunur', () async {
      final store = LocalStore.parseSnapshot(_snapshot);
      expect(store.generatedAt, isNotNull);
      final repo = LocalEventRepository(store, LocalAuthRepository(store));
      final events = await repo.fetchApproved();
      expect(events.single.title, '16. Alanya Uluslarası Noel Pazarı');
      expect(events.single.sourceName, 'Alanya Belediyesi');
      expect(events.single.isImported, isTrue);
    });

    test('kullanıcı etkinliği onaydan sonra yayına girer', () async {
      final store = LocalStore();
      final auth = LocalAuthRepository(store);
      final repo = LocalEventRepository(store, auth);
      await auth.signIn(email: 'test@ornek.com', password: '123456');

      final created = await repo.create(EventDraft(
        title: 'Sahilde Caz',
        description: 'Deneme',
        category: EventCategory.music,
        kind: EventKind.event,
        startAt: DateTime.now().add(const Duration(days: 2)),
        lat: 36.55,
        lng: 32.0,
      ));
      expect(created.status, EventStatus.pending);
      expect((await repo.fetchApproved()), isEmpty);
      await repo.setStatus(created.id, EventStatus.approved);
      expect((await repo.fetchApproved()).single.id, created.id);
    });

    test('e-postasında admin geçen hesap yönetici olur', () async {
      final store = LocalStore();
      final auth = LocalAuthRepository(store);
      await auth.signIn(email: 'admin@mahallem.app', password: '123456');
      expect((await auth.fetchProfile(auth.currentUser!.id))!.isAdmin, isTrue);
    });
  });

  testWidgets('EventCard başlığı ve kategoriyi gösterir', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalStore(events: fixtureEvents(DateTime.now()));
    final auth = LocalAuthRepository(store);
    final event = store.events.first;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(auth),
          eventRepositoryProvider.overrideWithValue(LocalEventRepository(store, auth)),
        ],
        child: MaterialApp(
          locale: const Locale('tr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: SizedBox(width: 360, height: 300, child: EventCard(event: event)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(event.title), findsOneWidget);
    expect(find.text('Müzik'), findsOneWidget);
  });
}
