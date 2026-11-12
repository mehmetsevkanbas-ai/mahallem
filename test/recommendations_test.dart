import 'package:flutter_test/flutter_test.dart';
import 'package:mahallem/data/models/culture_event.dart';
import 'package:mahallem/data/models/event_category.dart';
import 'package:mahallem/data/models/user_preferences.dart';
import 'package:mahallem/providers/recommendations.dart';

void main() {
  // 12 Kasım 2026 Perşembe 10:00
  final now = DateTime(2026, 11, 12, 10);

  CultureEvent ev(
    String id,
    EventCategory c, {
    EventKind kind = EventKind.event,
    DateTime? start,
    String? schedule,
    String description = '',
    bool free = true,
    double lat = 36.5446,
    double lng = 31.9890,
    String? venue,
  }) =>
      CultureEvent(
        id: id,
        title: 'Kayıt $id',
        description: description,
        category: c,
        kind: kind,
        startAt: start,
        schedule: schedule,
        lat: lat,
        lng: lng,
        venueName: venue,
        isFree: free,
        status: EventStatus.approved,
        createdAt: now,
      );

  test('ilgi alanındaki etkinlik öne çıkar ve gerekçesi yazılır', () {
    final recs = recommendEvents(
      events: [
        ev('konser', EventCategory.music, start: now.add(const Duration(days: 20))),
        ev('sergi', EventCategory.art, start: now.add(const Duration(days: 20))),
      ],
      interests: {EventCategory.music},
      prefs: const UserPreferences(),
      now: now,
    );
    expect(recs.first.event.id, 'konser');
    expect(recs.first.reasons.first.type, ReasonType.interest);
  });

  test('"sadece ücretsiz" ve "sadece kurs" tercihleri kesin filtredir', () {
    final events = [
      ev('ucretli', EventCategory.music, start: now.add(const Duration(days: 2)), free: false),
      ev('ucretsiz', EventCategory.music, start: now.add(const Duration(days: 2))),
      ev('kurs', EventCategory.music, kind: EventKind.course, schedule: 'Cumartesi 10:00-12:00'),
    ];
    final freeOnly = recommendEvents(
      events: events,
      interests: {EventCategory.music},
      prefs: const UserPreferences(freeOnly: true),
      now: now,
    );
    expect(freeOnly.map((r) => r.event.id), isNot(contains('ucretli')));

    final coursesOnly = recommendEvents(
      events: events,
      interests: {EventCategory.music},
      prefs: const UserPreferences(kinds: {EventKind.course}),
      now: now,
    );
    expect(coursesOnly.map((r) => r.event.id), ['kurs']);
  });

  test('müsait zaman dilimi kurs programından okunur', () {
    final weekend = ev('hs', EventCategory.art, kind: EventKind.course, schedule: 'Cumartesi 10:00-12:00, Pazar 10:00-12:00');
    final evening = ev('ak', EventCategory.art, kind: EventKind.course, schedule: 'Salı 18:30-20:30');
    expect(eventTimeSlots(weekend), {TimeSlot.weekend});
    expect(eventTimeSlots(evening), {TimeSlot.weekdayEvening});
    // "Pazartesi", "Pazar" ile karışmamalı.
    expect(eventTimeSlots(ev('pzt', EventCategory.art, kind: EventKind.course, schedule: 'Pazartesi 09:00-11:00')),
        {TimeSlot.weekdayDay});

    final recs = recommendEvents(
      events: [weekend, evening],
      interests: {EventCategory.art},
      prefs: const UserPreferences(timeSlots: {TimeSlot.weekend}),
      now: now,
    );
    expect(recs.first.event.id, 'hs');
  });

  test('çocuklu aileye çocuk kursu önerilir, yetişkine önerilmez', () {
    final kids = ev('cocuk', EventCategory.art,
        kind: EventKind.course, description: '• Resim (3A): Cumartesi 10:00-11:30 · 7-14 yaş');
    expect(ageRange(kids), (7, 14));

    final forFamily = recommendEvents(
      events: [kids],
      interests: {EventCategory.art},
      prefs: const UserPreferences(withKids: true),
      now: now,
    );
    expect(forFamily.single.reasons.map((r) => r.type), contains(ReasonType.kids));

    final forAdult = recommendEvents(
      events: [kids],
      interests: {EventCategory.art},
      prefs: const UserPreferences(),
      now: now,
    );
    expect(forAdult, isEmpty);
  });

  test('yakındaki etkinlik öne geçer, başka şehirdeki geriler', () {
    final near = ev('yakin', EventCategory.theatre, start: now.add(const Duration(days: 20)));
    final far = ev('antalya', EventCategory.theatre,
        start: now.add(const Duration(days: 20)), lat: 36.8999, lng: 30.7031);
    final recs = recommendEvents(
      events: [far, near],
      interests: {EventCategory.theatre},
      prefs: const UserPreferences(areaId: 'alanya_merkez'),
      now: now,
    );
    expect(recs.first.event.id, 'yakin');
    expect(recs.first.reasons.map((r) => r.type), contains(ReasonType.near));
    expect(recs.map((r) => r.event.id), isNot(contains('antalya')));
  });

  test('favorilerden kategori eğilimi öğrenilir, favoriler tekrar önerilmez', () {
    final fav = ev('fav', EventCategory.dance, start: now.add(const Duration(days: 30)), venue: 'AKM');
    final similar = ev('benzer', EventCategory.dance, start: now.add(const Duration(days: 30)), venue: 'AKM');
    final other = ev('diger', EventCategory.cinema, start: now.add(const Duration(days: 30)));
    final recs = recommendEvents(
      events: [fav, similar, other],
      interests: const {},
      prefs: const UserPreferences(),
      favorites: [fav],
      now: now,
    );
    expect(recs.map((r) => r.event.id), ['benzer']);
    expect(recs.single.reasons.first.type, ReasonType.favorites);
  });

  test('tercihler JSON ile gidip gelir', () {
    const prefs = UserPreferences(
      kinds: {EventKind.course},
      timeSlots: {TimeSlot.weekend, TimeSlot.weekdayEvening},
      freeOnly: true,
      withKids: true,
      areaId: 'mahmutlar',
    );
    final back = UserPreferences.fromJson(prefs.toJson());
    expect(back.kinds, prefs.kinds);
    expect(back.timeSlots, prefs.timeSlots);
    expect(back.freeOnly, isTrue);
    expect(back.withKids, isTrue);
    expect(back.area?.name, 'Mahmutlar');
  });
}
