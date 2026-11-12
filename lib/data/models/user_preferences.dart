import 'culture_event.dart';

/// Kullanıcının müsait olduğu zaman dilimleri.
enum TimeSlot { weekdayDay, weekdayEvening, weekend }

/// Kayıt sırasında seçilebilen yaşam bölgesi (yakınlık önerisi için).
/// Koordinatlar OpenStreetMap mahalle/yer nesnelerinden alınmıştır.
class HomeArea {
  const HomeArea(this.id, this.name, this.lat, this.lng);

  final String id;
  final String name;
  final double lat;
  final double lng;
}

const homeAreas = <HomeArea>[
  HomeArea('alanya_merkez', 'Alanya Merkez', 36.5436, 31.9989),
  HomeArea('oba', 'Oba', 36.5363, 32.0436),
  HomeArea('cikcilli', 'Cikcilli', 36.5476, 32.0287),
  HomeArea('tosmur', 'Tosmur', 36.5279, 32.0510),
  HomeArea('kestel', 'Kestel', 36.5073, 32.0784),
  HomeArea('mahmutlar', 'Mahmutlar', 36.4902, 32.0990),
  HomeArea('kargicak', 'Kargıcak', 36.4610, 32.1253),
  HomeArea('konakli', 'Konaklı', 36.5859, 31.8904),
  HomeArea('payallar', 'Payallar', 36.6122, 31.8599),
  HomeArea('turkler', 'Türkler', 36.6024, 31.8154),
  HomeArea('avsallar', 'Avsallar', 36.6234, 31.7679),
  HomeArea('gazipasa', 'Gazipaşa', 36.2683, 32.3175),
  HomeArea('manavgat', 'Manavgat', 36.7870, 31.4407),
  HomeArea('antalya', 'Antalya Merkez', 36.8889, 30.7209),
];

HomeArea? homeAreaById(String? id) =>
    homeAreas.where((a) => a.id == id).firstOrNull;

/// Kayıt sırasındaki kısa sorulara verilen yanıtlar.
class UserPreferences {
  const UserPreferences({
    this.kinds = const {},
    this.timeSlots = const {},
    this.freeOnly = false,
    this.withKids = false,
    this.areaId,
  });

  /// Boşsa hem etkinlik hem kurs.
  final Set<EventKind> kinds;

  /// Boşsa zaman fark etmez.
  final Set<TimeSlot> timeSlots;
  final bool freeOnly;
  final bool withKids;
  final String? areaId;

  HomeArea? get area => homeAreaById(areaId);

  bool get isEmpty =>
      kinds.isEmpty && timeSlots.isEmpty && !freeOnly && !withKids && areaId == null;

  factory UserPreferences.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UserPreferences();
    return UserPreferences(
      kinds: ((json['kinds'] as List?) ?? const [])
          .map((k) => EventKind.fromName(k as String))
          .toSet(),
      timeSlots: ((json['time_slots'] as List?) ?? const [])
          .map((s) => TimeSlot.values.where((t) => t.name == s).firstOrNull)
          .whereType<TimeSlot>()
          .toSet(),
      freeOnly: (json['free_only'] as bool?) ?? false,
      withKids: (json['with_kids'] as bool?) ?? false,
      areaId: json['area'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'kinds': kinds.map((k) => k.name).toList(),
        'time_slots': timeSlots.map((t) => t.name).toList(),
        'free_only': freeOnly,
        'with_kids': withKids,
        'area': areaId,
      };

  UserPreferences copyWith({
    Set<EventKind>? kinds,
    Set<TimeSlot>? timeSlots,
    bool? freeOnly,
    bool? withKids,
    String? areaId,
    bool clearArea = false,
  }) =>
      UserPreferences(
        kinds: kinds ?? this.kinds,
        timeSlots: timeSlots ?? this.timeSlots,
        freeOnly: freeOnly ?? this.freeOnly,
        withKids: withKids ?? this.withKids,
        areaId: clearArea ? null : (areaId ?? this.areaId),
      );
}
