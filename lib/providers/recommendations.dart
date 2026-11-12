import 'dart:math' as math;

import '../data/models/culture_event.dart';
import '../data/models/event_category.dart';
import '../data/models/user_preferences.dart';

/// Bir önerinin neden yapıldığı (arayüzde kısa etiket olarak gösterilir).
enum ReasonType { interest, favorites, near, time, free, kids, soon }

class Reason {
  const Reason(this.type, {this.category, this.km});

  final ReasonType type;
  final EventCategory? category;
  final double? km;
}

class Recommendation {
  const Recommendation(this.event, this.score, this.reasons);

  final CultureEvent event;
  final double score;

  /// En güçlüden zayıfa sıralı.
  final List<Reason> reasons;
}

/// Kullanıcının ilgi alanları, tercih soruları ve favorilerine göre puanlama.
///
/// Puanlama kasıtlı olarak basit ve açıklanabilir tutulmuştur: her kural
/// puana katkı yapar ve gerekçesini kaydeder. Bütçe ("yalnızca ücretsiz") ve
/// tür ("yalnızca kurslar") tercihleri kesin filtredir.
List<Recommendation> recommendEvents({
  required List<CultureEvent> events,
  required Set<EventCategory> interests,
  required UserPreferences prefs,
  List<CultureEvent> favorites = const [],
  bool excludeFavorites = true,
  DateTime? now,
  int limit = 20,
}) {
  final today = now ?? DateTime.now();
  final favoriteIds = favorites.map((e) => e.id).toSet();

  // Favorilerden öğrenilen kategori ve mekân eğilimleri.
  final favCategoryCount = <EventCategory, int>{};
  final favVenues = <String>{};
  for (final f in favorites) {
    favCategoryCount[f.category] = (favCategoryCount[f.category] ?? 0) + 1;
    if (f.venueName != null) favVenues.add(f.venueName!.toLowerCase());
  }
  final favTotal = favorites.length;

  final out = <Recommendation>[];
  for (final e in events) {
    if (excludeFavorites && favoriteIds.contains(e.id)) continue; // zaten kaydetmiş
    if (prefs.kinds.isNotEmpty && !prefs.kinds.contains(e.kind)) continue;
    if (prefs.freeOnly && !e.isFree) continue;

    var score = 0.0;
    final reasons = <(double, Reason)>[];
    void add(double points, Reason? reason) {
      score += points;
      if (reason != null && points > 0) reasons.add((points, reason));
    }

    // İlgi alanı
    if (interests.contains(e.category)) {
      add(3, Reason(ReasonType.interest, category: e.category));
    }

    // Favorilere benzerlik
    if (favTotal > 0) {
      final share = (favCategoryCount[e.category] ?? 0) / favTotal;
      if (share > 0) add(2.5 * share, const Reason(ReasonType.favorites));
      if (e.venueName != null && favVenues.contains(e.venueName!.toLowerCase())) {
        add(1, const Reason(ReasonType.favorites));
      }
    }

    // Müsait olunan zaman
    if (prefs.timeSlots.isNotEmpty) {
      final slots = eventTimeSlots(e);
      if (slots.isEmpty) {
        // Bilinmiyor: nötr
      } else if (slots.intersection(prefs.timeSlots).isNotEmpty) {
        add(1.5, const Reason(ReasonType.time));
      } else {
        add(-1.5, null);
      }
    }

    // Çocuk / yetişkin uygunluğu
    final ages = ageRange(e);
    final kidsFriendly = isKidFriendly(e, ages);
    if (!prefs.withKids && ages != null && ages.$2 <= 14) {
      continue; // yalnızca çocuklara açık kurs: yetişkin katılamaz
    }
    if (prefs.withKids && kidsFriendly) add(2, const Reason(ReasonType.kids));

    // Yakınlık
    final area = prefs.area;
    if (area != null) {
      final km = distanceKm(area.lat, area.lng, e.lat, e.lng);
      if (km < 3) {
        add(2, Reason(ReasonType.near, km: km));
      } else if (km < 10) {
        add(1, Reason(ReasonType.near, km: km));
      } else if (km > 40) {
        add(-4, null); // başka şehir: ancak çok güçlü eşleşmede önerilir
      }
    }

    // Ücretsiz küçük bir artı
    if (e.isFree) add(0.4, const Reason(ReasonType.free));

    // Yakın tarihli etkinlikler öne
    if (!e.isCourse && e.startAt != null) {
      final days = e.startAt!.difference(today).inHours / 24;
      if (days >= -0.5 && days <= 7) {
        add(1, const Reason(ReasonType.soon));
      } else if (days <= 14) {
        add(0.5, null);
      }
    }

    if (score <= 0.5) continue;
    reasons.sort((a, b) => b.$1.compareTo(a.$1));
    // Aynı türden gerekçeyi tekrarlama.
    final seen = <ReasonType>{};
    out.add(Recommendation(
      e,
      score,
      [for (final r in reasons) if (seen.add(r.$2.type)) r.$2],
    ));
  }

  out.sort((a, b) {
    final c = b.score.compareTo(a.score);
    return c != 0 ? c : a.event.sortKey.compareTo(b.event.sortKey);
  });
  return out.take(limit).toList();
}

// ---------------------------------------------------------------------------

const _days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
final _daySlotPattern = RegExp(
  r'(Pazartesi|Salı|Çarşamba|Perşembe|Cumartesi|Cuma|Pazar)(?:\s+(\d{1,2}):(\d{2}))?',
);

/// Etkinliğin hangi zaman dilim(ler)ine düştüğü.
/// Kurslarda program metnindeki gün/saatlerden çıkarılır.
Set<TimeSlot> eventTimeSlots(CultureEvent e) {
  if (!e.isCourse && e.startAt != null) {
    return {_slotFor(e.startAt!.weekday, e.startAt!.hour)};
  }
  final text = '${e.schedule ?? ''}\n${e.description}';
  final slots = <TimeSlot>{};
  for (final m in _daySlotPattern.allMatches(text)) {
    final weekday = _days.indexOf(m.group(1)!) + 1;
    final hour = m.group(2) == null ? null : int.parse(m.group(2)!);
    if (weekday >= DateTime.saturday) {
      slots.add(TimeSlot.weekend);
    } else if (hour == null) {
      slots.addAll({TimeSlot.weekdayDay, TimeSlot.weekdayEvening});
    } else {
      slots.add(_slotFor(weekday, hour));
    }
  }
  return slots;
}

TimeSlot _slotFor(int weekday, int hour) {
  if (weekday >= DateTime.saturday) return TimeSlot.weekend;
  return hour >= 17 ? TimeSlot.weekdayEvening : TimeSlot.weekdayDay;
}

/// Açıklamadaki "7-14 yaş" gibi ifadelerden en geniş yaş aralığı.
(int, int)? ageRange(CultureEvent e) {
  int? lo;
  int? hi;
  for (final m in RegExp(r'(\d{1,2})\s*-\s*(\d{1,2})\s*yaş').allMatches(e.description)) {
    final a = int.parse(m.group(1)!);
    final b = int.parse(m.group(2)!);
    lo = lo == null ? a : math.min(lo, a);
    hi = hi == null ? b : math.max(hi, b);
  }
  return lo == null ? null : (lo, hi!);
}

bool isKidFriendly(CultureEvent e, [(int, int)? ages]) {
  final range = ages ?? ageRange(e);
  if (range != null && range.$1 <= 12) return true;
  final text = '${e.title} ${e.description}'.toLowerCase();
  return RegExp(r'çocuk|cocuk|aile|kukla|sirk|masal').hasMatch(text);
}

double distanceKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLng = (lng2 - lng1) * math.pi / 180;
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180) * math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.sqrt(a));
}
