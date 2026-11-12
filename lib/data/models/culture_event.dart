import 'package:latlong2/latlong.dart';

import 'event_category.dart';

enum EventKind {
  event,
  course;

  static EventKind fromName(String? name) =>
      name == 'course' ? EventKind.course : EventKind.event;
}

enum EventStatus {
  pending,
  approved,
  rejected;

  static EventStatus fromName(String? name) => EventStatus.values
      .firstWhere((s) => s.name == name, orElse: () => EventStatus.pending);
}

/// Haritada gösterilen kültürel etkinlik veya kurs.
class CultureEvent {
  const CultureEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.kind,
    required this.lat,
    required this.lng,
    required this.status,
    required this.createdAt,
    this.startAt,
    this.endAt,
    this.schedule,
    this.venueName,
    this.address,
    this.imageUrl,
    this.price,
    this.isFree = true,
    this.organizer,
    this.contact,
    this.createdBy,
    this.source,
    this.sourceUrl,
  });

  final String id;
  final String title;
  final String description;
  final EventCategory category;
  final EventKind kind;
  final DateTime? startAt;
  final DateTime? endAt;

  /// Kurslar için serbest metin program (örn. "Her Salı 19:00").
  final String? schedule;
  final double lat;
  final double lng;
  final String? venueName;
  final String? address;
  final String? imageUrl;
  final String? price;
  final bool isFree;
  final String? organizer;
  final String? contact;
  final EventStatus status;
  final String? createdBy;
  final DateTime createdAt;

  /// Otomatik aktarılan etkinliklerde kaynak kurum (`alanya_bel`, `antalya_bb`).
  final String? source;

  /// Etkinliğin kaynak sitedeki sayfası.
  final String? sourceUrl;

  bool get isImported => source != null;

  /// Kaynağın okunabilir adı.
  String? get sourceName => switch (source) {
        'alanya_bel' => 'Alanya Belediyesi',
        'antalya_bb' => 'Antalya Büyükşehir Belediyesi',
        'dob_antalya' => 'Antalya Devlet Opera ve Balesi',
        'atabem' => 'ATABEM · Antalya Büyükşehir Belediyesi',
        'biletinial' => 'Biletinial',
        'iticket' => 'iTicket',
        'beyazperde' => 'Beyazperde',
        'atasem' => 'ATASEM · Antalya Büyükşehir Belediyesi',
        null => null,
        _ => source,
      };

  LatLng get point => LatLng(lat, lng);
  bool get isCourse => kind == EventKind.course;

  /// Etkinliğin aktif olduğu zaman aralığı. Tarihsiz kurslar süresiz kabul edilir.
  DateTime get rangeStart => startAt ?? DateTime(2000);
  DateTime get rangeEnd {
    if (endAt != null) return endAt!;
    if (startAt != null && !isCourse) {
      // Bitiş saati verilmemiş etkinlik: başlangıçtan 3 saat sonra biter say.
      return startAt!.add(const Duration(hours: 3));
    }
    return DateTime(2100);
  }

  bool get isUpcoming => rangeEnd.isAfter(DateTime.now());

  /// Sıralama için: kurslar tarihsizse listede sona yakın durur.
  /// Listelerde tarihli etkinlikler önce (tarih sırasıyla), süregelen
  /// kurslar sonra gelir; kurslar da kendi içinde başlangıca göre sıralanır.
  DateTime get sortKey {
    final now = DateTime.now();
    if (isCourse) {
      return (startAt ?? now).add(const Duration(days: 3650));
    }
    return startAt ?? now.add(const Duration(days: 7300));
  }

  factory CultureEvent.fromJson(Map<String, dynamic> json) => CultureEvent(
        id: json['id'] as String,
        title: json['title'] as String,
        description: (json['description'] as String?) ?? '',
        category: EventCategory.fromSlug(json['category'] as String?),
        kind: EventKind.fromName(json['kind'] as String?),
        startAt: _parseDate(json['start_at']),
        endAt: _parseDate(json['end_at']),
        schedule: json['schedule'] as String?,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        venueName: json['venue_name'] as String?,
        address: json['address'] as String?,
        imageUrl: json['image_url'] as String?,
        price: json['price'] as String?,
        isFree: (json['is_free'] as bool?) ?? true,
        organizer: json['organizer'] as String?,
        contact: json['contact'] as String?,
        status: EventStatus.fromName(json['status'] as String?),
        createdBy: json['created_by'] as String?,
        createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
        source: json['source'] as String?,
        sourceUrl: json['source_url'] as String?,
      );

  static DateTime? _parseDate(Object? value) =>
      value == null ? null : DateTime.parse(value as String).toLocal();

  CultureEvent copyWith({EventStatus? status, String? imageUrl}) => CultureEvent(
        id: id,
        title: title,
        description: description,
        category: category,
        kind: kind,
        startAt: startAt,
        endAt: endAt,
        schedule: schedule,
        lat: lat,
        lng: lng,
        venueName: venueName,
        address: address,
        imageUrl: imageUrl ?? this.imageUrl,
        price: price,
        isFree: isFree,
        organizer: organizer,
        contact: contact,
        status: status ?? this.status,
        createdBy: createdBy,
        createdAt: createdAt,
        source: source,
        sourceUrl: sourceUrl,
      );
}

/// Kullanıcının oluşturduğu, henüz kaydedilmemiş etkinlik.
class EventDraft {
  const EventDraft({
    required this.title,
    required this.description,
    required this.category,
    required this.kind,
    required this.lat,
    required this.lng,
    this.startAt,
    this.endAt,
    this.schedule,
    this.venueName,
    this.address,
    this.price,
    this.isFree = true,
    this.organizer,
    this.contact,
  });

  final String title;
  final String description;
  final EventCategory category;
  final EventKind kind;
  final DateTime? startAt;
  final DateTime? endAt;
  final String? schedule;
  final double lat;
  final double lng;
  final String? venueName;
  final String? address;
  final String? price;
  final bool isFree;
  final String? organizer;
  final String? contact;

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'category': category.slug,
        'kind': kind.name,
        'start_at': startAt?.toUtc().toIso8601String(),
        'end_at': endAt?.toUtc().toIso8601String(),
        'schedule': _nullIfEmpty(schedule),
        'lat': lat,
        'lng': lng,
        'venue_name': _nullIfEmpty(venueName),
        'address': _nullIfEmpty(address),
        'price': isFree ? null : _nullIfEmpty(price),
        'is_free': isFree,
        'organizer': _nullIfEmpty(organizer),
        'contact': _nullIfEmpty(contact),
      };

  static String? _nullIfEmpty(String? v) =>
      (v == null || v.trim().isEmpty) ? null : v.trim();
}
