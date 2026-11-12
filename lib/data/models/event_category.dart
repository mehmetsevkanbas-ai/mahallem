import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Kültürel etkinlik kategorileri. Veritabanında `slug` olarak saklanır,
/// kullanıcı ilgi alanları da bu listeden seçilir.
enum EventCategory {
  music('music', Icons.music_note_rounded, Color(0xFF7C4DFF)),
  theatre('theatre', Icons.theater_comedy_rounded, Color(0xFFE53958)),
  art('art', Icons.palette_rounded, Color(0xFFFF8A00)),
  dance('dance', Icons.nightlife_rounded, Color(0xFFD81B9A)),
  cinema('cinema', Icons.movie_rounded, Color(0xFF3949AB)),
  literature('literature', Icons.menu_book_rounded, Color(0xFF6D4C41)),
  festival('festival', Icons.celebration_rounded, Color(0xFFF4511E)),
  outdoor('outdoor', Icons.beach_access_rounded, Color(0xFF00A3A3)),
  workshop('workshop', Icons.handyman_rounded, Color(0xFF2E7D32));

  const EventCategory(this.slug, this.icon, this.color);

  final String slug;
  final IconData icon;
  final Color color;

  static EventCategory fromSlug(String? slug) => EventCategory.values
      .firstWhere((c) => c.slug == slug, orElse: () => EventCategory.festival);

  String label(AppLocalizations l10n) => switch (this) {
        EventCategory.music => l10n.catMusic,
        EventCategory.theatre => l10n.catTheatre,
        EventCategory.art => l10n.catArt,
        EventCategory.dance => l10n.catDance,
        EventCategory.cinema => l10n.catCinema,
        EventCategory.literature => l10n.catLiterature,
        EventCategory.festival => l10n.catFestival,
        EventCategory.outdoor => l10n.catOutdoor,
        EventCategory.workshop => l10n.catWorkshop,
      };
}
