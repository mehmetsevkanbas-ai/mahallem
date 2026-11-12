import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../data/models/culture_event.dart';
import '../../l10n/app_localizations.dart';

String _locale(BuildContext context) =>
    Localizations.localeOf(context).languageCode;

String formatTime(BuildContext context, DateTime dt) =>
    DateFormat.Hm(_locale(context)).format(dt);

String formatDay(BuildContext context, DateTime dt) =>
    DateFormat('d MMMM EEEE', _locale(context)).format(dt);

String formatShortDay(BuildContext context, DateTime dt) =>
    DateFormat('d MMM', _locale(context)).format(dt);

String formatFullDateTime(BuildContext context, DateTime dt) =>
    '${formatDay(context, dt)}, ${formatTime(context, dt)}';

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Kartlarda kullanılan kısa "ne zaman" metni.
String formatEventWhen(BuildContext context, CultureEvent e) {
  final l10n = AppLocalizations.of(context);
  if (e.isCourse) {
    final schedule = e.schedule?.trim();
    if (schedule != null && schedule.isNotEmpty) return schedule;
    if (e.endAt != null) return l10n.untilDate(formatShortDay(context, e.endAt!));
    return l10n.ongoingCourse;
  }
  final start = e.startAt;
  if (start == null) return '';
  final now = DateTime.now();
  final time = formatTime(context, start);
  final end = e.endAt;

  if (end != null && !_sameDay(start, end)) {
    return '${formatShortDay(context, start)} – ${formatShortDay(context, end)}';
  }
  if (_sameDay(start, now)) return l10n.todayAt(time);
  if (_sameDay(start, now.add(const Duration(days: 1)))) {
    return l10n.tomorrowAt(time);
  }
  return '${DateFormat('d MMM EEE', _locale(context)).format(start)}, $time';
}

/// Detay sayfasındaki uzun tarih metni.
String formatEventWhenLong(BuildContext context, CultureEvent e) {
  final l10n = AppLocalizations.of(context);
  final start = e.startAt;
  final end = e.endAt;
  if (e.isCourse) {
    final parts = <String>[
      if (start != null) l10n.startsOn(formatShortDay(context, start)),
      if (end != null) l10n.untilDate(formatShortDay(context, end)),
    ];
    return parts.isEmpty ? l10n.ongoingCourse : parts.join(' · ');
  }
  if (start == null) return '';
  if (end == null) return formatFullDateTime(context, start);
  if (_sameDay(start, end)) {
    return '${formatDay(context, start)}, ${formatTime(context, start)} – ${formatTime(context, end)}';
  }
  return '${formatFullDateTime(context, start)} –\n${formatFullDateTime(context, end)}';
}
