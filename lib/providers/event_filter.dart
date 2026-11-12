import '../data/models/culture_event.dart';
import '../data/models/event_category.dart';

enum DateFilter { any, today, thisWeek, weekend, thisMonth }

enum KindFilter { all, events, courses }

class EventFilter {
  const EventFilter({
    this.categories = const {},
    this.kind = KindFilter.all,
    this.date = DateFilter.any,
    this.query = '',
    this.forYou = false,
  });

  final Set<EventCategory> categories;
  final KindFilter kind;
  final DateFilter date;
  final String query;

  /// Yalnızca kullanıcının ilgi alanlarındaki kategorileri göster.
  final bool forYou;

  bool get isActive =>
      categories.isNotEmpty ||
      kind != KindFilter.all ||
      date != DateFilter.any ||
      query.trim().isNotEmpty ||
      forYou;

  EventFilter copyWith({
    Set<EventCategory>? categories,
    KindFilter? kind,
    DateFilter? date,
    String? query,
    bool? forYou,
  }) =>
      EventFilter(
        categories: categories ?? this.categories,
        kind: kind ?? this.kind,
        date: date ?? this.date,
        query: query ?? this.query,
        forYou: forYou ?? this.forYou,
      );
}

/// Türkçe karakterlere duyarlı, büyük/küçük harf bağımsız arama için normalleştirme.
String normalizeForSearch(String input) => input
    .replaceAll('İ', 'i')
    .replaceAll('I', 'i')
    .toLowerCase()
    .replaceAll('ı', 'i')
    .replaceAll('ş', 's')
    .replaceAll('ğ', 'g')
    .replaceAll('ü', 'u')
    .replaceAll('ö', 'o')
    .replaceAll('ç', 'c');

/// Tarih filtresine karşılık gelen [başlangıç, bitiş) aralığı.
(DateTime, DateTime)? dateRangeFor(DateFilter filter, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  switch (filter) {
    case DateFilter.any:
      return null;
    case DateFilter.today:
      return (now, today.add(const Duration(days: 1)));
    case DateFilter.thisWeek:
      // Pazar gecesine kadar (DateTime.weekday: Pazartesi=1, Pazar=7).
      final daysLeft = DateTime.sunday - now.weekday + 1;
      return (now, today.add(Duration(days: daysLeft)));
    case DateFilter.weekend:
      final isWeekend = now.weekday >= DateTime.saturday;
      final saturday = isWeekend
          ? today.subtract(Duration(days: now.weekday - DateTime.saturday))
          : today.add(Duration(days: DateTime.saturday - now.weekday));
      final start = isWeekend ? now : saturday;
      return (start, saturday.add(const Duration(days: 2)));
    case DateFilter.thisMonth:
      return (now, DateTime(now.year, now.month + 1));
  }
}

List<CultureEvent> applyEventFilter(
  List<CultureEvent> events,
  EventFilter filter,
  Set<EventCategory> interests, {
  DateTime? now,
}) {
  final range = dateRangeFor(filter.date, now ?? DateTime.now());
  final query = normalizeForSearch(filter.query.trim());

  final result = events.where((e) {
    if (filter.categories.isNotEmpty && !filter.categories.contains(e.category)) {
      return false;
    }
    if (filter.forYou && interests.isNotEmpty && !interests.contains(e.category)) {
      return false;
    }
    if (filter.kind == KindFilter.events && e.isCourse) return false;
    if (filter.kind == KindFilter.courses && !e.isCourse) return false;
    if (range != null) {
      final (start, end) = range;
      if (!(e.rangeStart.isBefore(end) && e.rangeEnd.isAfter(start))) {
        return false;
      }
    }
    if (query.isNotEmpty) {
      final haystack = normalizeForSearch(
        '${e.title} ${e.venueName ?? ''} ${e.address ?? ''} ${e.organizer ?? ''}',
      );
      if (!haystack.contains(query)) return false;
    }
    return true;
  }).toList()
    ..sort((a, b) => a.sortKey.compareTo(b.sortKey));
  return result;
}
