// Belediye sitelerinden kültür etkinliklerini toplayıp Mahallem'e aktarır.
//
// Kullanım:
//   dart run tool/sync_events.dart                  # assets/data/events.json yazar
//   dart run tool/sync_events.dart --supabase       # ayrıca Supabase'e yazar
//   dart run tool/sync_events.dart --dry-run        # yalnızca özet yazdırır
//
// --supabase için ortam değişkenleri: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
// (service role anahtarı GİZLİDİR; yalnızca sunucu/CI tarafında kullanılır.)
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'sync/categorize.dart';
import 'sync/geocoder.dart';
import 'sync/sources.dart';
import 'sync/text_utils.dart';

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final toSupabase = args.contains('--supabase');
  final outIndex = args.indexOf('--out');
  final outPath = outIndex >= 0 ? args[outIndex + 1] : 'assets/data/events.json';

  final client = http.Client();
  if (args.contains('--discover-venues')) {
    final slugs = await BiletinialSource(client).discoverVenues();
    final known = BiletinialSource.defaultVenues.toSet();
    stdout.writeln('Biletinial mekân sayfaları (* = takip ediliyor):');
    for (final s in slugs) {
      stdout.writeln('  ${known.contains(s) ? '*' : ' '} https://biletinial.com/tr-tr/mekan/$s');
    }
    client.close();
    return;
  }
  final now = DateTime.now().toUtc();
  final report = <String, int>{};

  try {
    // --- Alanya Belediyesi -------------------------------------------------
    final alanya = AlanyaSource(client);
    var alanyaEvents = <RawEvent>[];
    try {
      final raw = await alanya.fetch(
        from: now.subtract(const Duration(days: 45)),
        to: now.add(const Duration(days: 365)),
      );
      alanyaEvents = _mergeDailyRepeats(raw).where((e) => _isCurrent(e, now)).toList();
      for (final e in alanyaEvents) {
        await alanya.enrich(e);
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
      report['alanya_ham'] = raw.length;
    } catch (e) {
      stderr.writeln('UYARI: Alanya Belediyesi okunamadı: $e');
    }

    // --- Antalya Büyükşehir Belediyesi --------------------------------------
    var antalyaEvents = <RawEvent>[];
    try {
      final raw = await AntalyaSource(client).fetch();
      antalyaEvents = raw.where((e) => _isCurrent(e, now)).toList();
      report['antalya_ham'] = raw.length;
    } catch (e) {
      stderr.writeln('UYARI: Antalya Büyükşehir okunamadı: $e');
    }

    // --- Devlet Opera ve Balesi (Antalya) -------------------------------------
    var dobEvents = <RawEvent>[];
    try {
      final raw = await DobSource(client).fetch();
      dobEvents = raw.where((e) => _isCurrent(e, now)).toList();
      report['dob_ham'] = raw.length;
    } catch (e) {
      stderr.writeln('UYARI: Devlet Opera ve Balesi okunamadı: $e');
    }

    // --- Biletinial (konser, tiyatro vb. biletli etkinlikler) -----------------
    var ticketEvents = <RawEvent>[];
    try {
      final raw = await BiletinialSource(client).fetch();
      ticketEvents = raw.where((e) => _isCurrent(e, now)).toList();
      report['biletinial_ham'] = raw.length;
    } catch (e) {
      stderr.writeln('UYARI: Biletinial okunamadı: $e');
    }

    // --- iTicket (Antalya ili) ------------------------------------------------
    var iticketEvents = <RawEvent>[];
    try {
      final raw = await ITicketSource(client).fetch();
      iticketEvents = raw.where((e) => _isCurrent(e, now)).toList();
      report['iticket_ham'] = raw.length;
    } catch (e) {
      stderr.writeln('UYARI: iTicket okunamadı: $e');
    }

    // --- Sinema seansları (Beyazperde) ----------------------------------------
    var cinemaEvents = <RawEvent>[];
    try {
      final raw = await CinemaSource(client).fetch();
      cinemaEvents = raw.where((e) => _isCurrent(e, now)).toList();
      report['sinema_film'] = raw.length;
    } catch (e) {
      stderr.writeln('UYARI: Sinema seansları okunamadı: $e');
    }

    // --- Büyükşehir kurs merkezleri (sanatsal kurslar) ------------------------
    final courses = <RawEvent>[];
    for (final source in [CourseCatalogSource.atabem(client), CourseCatalogSource.atasem(client)]) {
      try {
        final raw = await source.fetch();
        courses.addAll(raw.where((e) => _isCurrent(e, now)));
        report['${source.name}_kurs'] = raw.length;
      } catch (e) {
        stderr.writeln('UYARI: ${source.label} okunamadı: $e');
      }
    }

    // --- Kültürel olmayanları ele, kaynaklar arası tekrarları birleştir -----
    final categorized = <(RawEvent, String)>[];
    for (final e in [
      ...alanyaEvents,
      ..._dropDuplicates(antalyaEvents, alanyaEvents),
      ...dobEvents,
      ..._dropDuplicates(ticketEvents, [...alanyaEvents, ...antalyaEvents, ...dobEvents]),
      ..._dropDuplicates(iticketEvents, [...alanyaEvents, ...antalyaEvents, ...dobEvents, ...ticketEvents]),
      ...cinemaEvents,
      ...courses,
    ]) {
      final category = inferCategory(
        title: e.title,
        tags: e.tags,
        description: e.description,
        defaultCategory: e.defaultCategory,
      );
      if (category != null) categorized.add((e, category));
    }

    // --- Konum --------------------------------------------------------------
    final geocoder = Geocoder(File('tool/sync/geocode_cache.json'), client);
    final rows = <Map<String, dynamic>>[];
    final precisionCount = <String, int>{};
    for (final (e, category) in categorized) {
      final hit = await _locate(e, geocoder);
      if (hit == null) continue;
      precisionCount[hit.precision.name] = (precisionCount[hit.precision.name] ?? 0) + 1;
      final title = titleCaseTr(e.title);
      final town = e.town ?? 'Antalya';
      rows.add({
        'id': '${e.source}:${e.sourceId}',
        'source': e.source,
        'source_id': e.sourceId,
        'source_url': e.sourceUrl,
        'title': title.length > 120 ? '${title.substring(0, 119)}…' : title,
        'description': e.description,
        'category': category,
        'kind': e.kind,
        'start_at': e.start.toIso8601String(),
        'end_at': e.end?.toIso8601String(),
        'schedule': e.schedule,
        'lat': double.parse(hit.lat.toStringAsFixed(6)),
        'lng': double.parse(hit.lng.toStringAsFixed(6)),
        'venue_name': e.venue == null ? null : titleCaseTr(e.venue!),
        'address': switch (hit.precision) {
          GeoPrecision.district => '$town (yaklaşık konum)',
          GeoPrecision.neighbourhood => '${e.address ?? hit.label}, $town',
          _ => e.address == null ? '$town, Antalya' : '${e.address}, $town',
        },
        'image_url': e.imageUrl,
        'price': e.price,
        'is_free': e.isFree ?? e.price == null,
        'organizer': e.organizer == null ? null : titleCaseTr(e.organizer!),
        'contact': e.contact,
        'status': 'approved',
        'created_by': null,
        'created_at': now.toIso8601String(),
      });
      if (args.contains('--verbose')) {
        stdout.writeln('    konum[${hit.precision.name}] ${hit.label} -> ${e.title}');
      }
    }
    rows.sort((a, b) => (a['start_at'] as String).compareTo(b['start_at'] as String));
    geocoder.save();

    report['kultur_kaydi'] = rows.length;
    report['nominatim_istegi'] = geocoder.networkCalls;
    stdout.writeln('Özet: $report');
    stdout.writeln('Konum kesinliği: $precisionCount');
    for (final r in rows) {
      stdout.writeln('  ${(r['start_at'] as String).substring(0, 10)}  '
          '[${r['kind'] == 'course' ? 'kurs/' : ''}${r['category']}] ${r['title']} — ${r['venue_name'] ?? r['address']}');
    }
    if (dryRun) return;

    // --- Çıktılar -----------------------------------------------------------
    final snapshot = {
      'generated_at': now.toIso8601String(),
      'sources': [
        {'id': AlanyaSource.name, 'name': 'Alanya Belediyesi', 'url': 'https://www.alanya.bel.tr/etkinlikler'},
        {'id': AntalyaSource.name, 'name': 'Antalya Büyükşehir Belediyesi', 'url': 'https://www.antalya.bel.tr/tr/etkinlikler'},
        {'id': DobSource.name, 'name': 'Antalya Devlet Opera ve Balesi', 'url': 'https://www.operabale.gov.tr/directorates/antalya-opera-ve-balesi-5'},
        {'id': ITicketSource.name, 'name': 'iTicket', 'url': 'https://iticket.com.tr/etkinlikler'},
        {'id': CinemaSource.name, 'name': 'Beyazperde (sinema seansları)', 'url': 'https://www.beyazperde.com/sinemalar/sinema-T0042/'},
        {'id': BiletinialSource.name, 'name': 'Biletinial', 'url': 'https://biletinial.com/tr-tr/mekan/alanya-kultur-merkezi'},
        {'id': 'atabem', 'name': 'ATABEM (Antalya Büyükşehir Belediyesi)', 'url': 'https://atabem.antalya.bel.tr/kurslar.html'},
        {'id': 'atasem', 'name': 'ATASEM (Antalya Büyükşehir Belediyesi)', 'url': 'https://atasem.antalya.bel.tr/kurslar.html'},
      ],
      'events': rows,
    };
    File(outPath)
      ..createSync(recursive: true)
      ..writeAsStringSync(const JsonEncoder.withIndent('  ').convert(snapshot));
    stdout.writeln('Anlık görüntü yazıldı: $outPath');

    if (toSupabase) {
      await _pushToSupabase(client, rows, {
        if (report.containsKey('alanya_ham')) AlanyaSource.name,
        if (report.containsKey('antalya_ham')) AntalyaSource.name,
        if (report.containsKey('dob_ham')) DobSource.name,
        if (report.containsKey('biletinial_ham')) BiletinialSource.name,
        if (report.containsKey('iticket_ham')) ITicketSource.name,
        if (report.containsKey('sinema_film')) CinemaSource.name,
        if (report.containsKey('atabem_kurs')) 'atabem',
        if (report.containsKey('atasem_kurs')) 'atasem',
      });
    }
  } finally {
    client.close();
  }
}

bool _isCurrent(RawEvent e, DateTime now) =>
    e.effectiveEnd.isAfter(now.subtract(const Duration(hours: 6))) &&
    e.start.isBefore(now.add(const Duration(days: 365)));

/// Alanya takviminde çok günlük etkinlikler her gün için ayrı kayıt olarak gelir;
/// aynı ad + yerdeki ardışık günleri tek etkinlikte birleştirir.
List<RawEvent> _mergeDailyRepeats(List<RawEvent> events) {
  final groups = <String, List<RawEvent>>{};
  for (final e in events) {
    groups.putIfAbsent('${searchKey(e.title)}|${searchKey(e.venue ?? '')}', () => []).add(e);
  }
  final merged = <RawEvent>[];
  for (final list in groups.values) {
    list.sort((a, b) => a.start.compareTo(b.start));
    RawEvent? current;
    for (final e in list) {
      if (current != null &&
          e.start.difference(current.effectiveEnd).inHours <= 36) {
        if (e.effectiveEnd.isAfter(current.effectiveEnd)) current.end = e.effectiveEnd;
        continue;
      }
      if (current != null) merged.add(current);
      current = e;
    }
    if (current != null) merged.add(current);
  }
  return merged;
}

/// Antalya listesinde Alanya'dan zaten gelen etkinlikleri ayıklar,
/// eksik bilgileri (görsel, açıklama, fiyat) Alanya kaydına aktarır.
List<RawEvent> _dropDuplicates(List<RawEvent> antalya, List<RawEvent> alanya) {
  final result = <RawEvent>[];
  for (final a in antalya) {
    final key = searchKey(a.title);
    // Kiril/kısa başlıklarda anahtar boş veya çok kısa kalır; boş anahtar her
    // başlığın "içinde" sayılacağı için bu kayıtlar eşleştirmeye girmez.
    final match = key.length < 4
        ? null
        : alanya.where((b) {
            final bk = searchKey(b.title);
            if (bk.length < 4) return false;
            final sameName = bk == key || bk.contains(key) || key.contains(bk);
            return sameName && (a.start.difference(b.start).inHours.abs() <= 48);
          }).firstOrNull;
    if (match == null) {
      result.add(a);
      continue;
    }
    match.imageUrl ??= a.imageUrl;
    if (a.description.length > match.description.length) match.description = a.description;
    match.price ??= a.price;
    match.isFree ??= a.isFree;
    match.tags = {...match.tags, ...a.tags}.toList();
    if (match.lat == null && a.lat != null) {
      match.lat = a.lat;
      match.lng = a.lng;
    }
  }
  return result;
}

/// Uygulama aynı noktadaki kayıtları tek işarette topladığı için konumlar
/// kaydırılmaz; yalnızca ilçe merkezi bilinenler "yaklaşık konum" olarak yazılır.
Future<GeoHit?> _locate(RawEvent e, Geocoder geocoder) => geocoder.locate(
      district: e.town ?? 'Antalya',
      lat: e.lat,
      lng: e.lng,
      venue: e.venue,
      address: e.address,
    );

Future<void> _pushToSupabase(
  http.Client client,
  List<Map<String, dynamic>> rows,
  Set<String> okSources,
) async {
  final url = Platform.environment['SUPABASE_URL'];
  final key = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'];
  if (url == null || url.isEmpty || key == null || key.isEmpty) {
    stderr.writeln('HATA: SUPABASE_URL ve SUPABASE_SERVICE_ROLE_KEY tanımlı olmalı.');
    exitCode = 2;
    return;
  }
  // Yalnızca başarıyla okunan kaynaklar güncellenir; okunamayan kaynağın
  // mevcut kayıtları silinmesin.
  for (final source in okSources) {
    final events = rows
        .where((r) => r['source'] == source)
        .map((r) => Map.of(r)..remove('id')..remove('created_at')..remove('created_by'))
        .toList();
    final res = await client.post(
      Uri.parse('$url/rest/v1/rpc/upsert_synced_events'),
      headers: {
        'apikey': key,
        // Eski service_role anahtarı JWT'dir ve Bearer olarak da gönderilir; yeni
        // sb_secret_ anahtarları JWT değildir, yalnızca apikey başlığıyla gider.
        if (key.startsWith('eyJ')) 'Authorization': 'Bearer $key',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'p_source': source, 'p_events': events}),
    );
    if (res.statusCode >= 300) {
      stderr.writeln('HATA: Supabase ($source) ${res.statusCode}: ${res.body}');
      exitCode = 1;
    } else {
      stdout.writeln('Supabase: $source -> ${events.length} etkinlik (${res.body})');
    }
  }
}
