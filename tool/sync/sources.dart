import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'text_utils.dart';

const syncUserAgent =
    'Mahallem-EventSync/1.0 (TUBITAK ogrenci projesi; kultur etkinlikleri haritasi)';

/// Kaynaktan okunmuş, henüz normalize edilmemiş etkinlik.
class RawEvent {
  RawEvent({
    required this.source,
    required this.sourceId,
    required this.sourceUrl,
    required this.title,
    required this.start,
    this.end,
    this.description = '',
    this.tags = const [],
    this.venue,
    this.imageUrl,
    this.price,
    this.isFree,
    this.organizer,
    this.town,
    this.lat,
    this.lng,
    this.kind = 'event',
    this.schedule,
    this.contact,
    this.address,
    this.defaultCategory,
  });

  final String source;
  String sourceId;
  String sourceUrl;
  final String title;
  DateTime start;
  DateTime? end;
  String description;
  List<String> tags;
  String? venue;
  String? imageUrl;
  String? price;
  bool? isFree;
  String? organizer;

  /// Coğrafi kodlamada kullanılacak ilçe (örn. "Alanya").
  String? town;
  double? lat;
  double? lng;

  /// 'event' veya 'course'.
  final String kind;

  /// Kurslar için gün/saat özeti.
  String? schedule;
  String? contact;

  /// Kaynağın verdiği açık adres (konum bulmada kullanılır).
  String? address;

  /// Başlıktan kategori çıkarılamazsa kullanılacak kategori.
  String? defaultCategory;

  DateTime get effectiveEnd =>
      end ?? start.add(kind == 'course' ? const Duration(days: 180) : const Duration(hours: 3));
}

// ---------------------------------------------------------------------------
// Alanya Belediyesi — https://www.alanya.bel.tr/etkinlik-takvimi
// ---------------------------------------------------------------------------

class AlanyaSource {
  AlanyaSource(this.client);

  final http.Client client;
  static const name = 'alanya_bel';
  static const _base = 'https://www.alanya.bel.tr';
  static const _mediaBase = 'https://admin.alanya.bel.tr';

  Future<List<RawEvent>> fetch({required DateTime from, required DateTime to}) async {
    final uri = Uri.parse('$_base/api/get').replace(queryParameters: {
      'name': 'eventsByRange',
      'start': from.toUtc().toIso8601String(),
      'end': to.toUtc().toIso8601String(),
    });
    final res = await client.get(uri, headers: _headers);
    _check(res, uri);
    final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();

    final events = <RawEvent>[];
    for (final row in list) {
      final title = (row['event_name'] as String? ?? '').trim();
      final start = DateTime.tryParse(row['event_date'] as String? ?? '');
      if (title.isEmpty || start == null) continue;
      var end = DateTime.tryParse(row['event_date_end'] as String? ?? '');
      if (end != null && !end.isAfter(start)) end = null;
      final id = '${row['id']}';
      final location = (row['location'] as String? ?? '').trim();
      events.add(RawEvent(
        source: name,
        sourceId: id,
        sourceUrl: '$_base/etkinlikler/etkinlik/$id',
        title: title,
        start: start.toUtc(),
        end: end?.toUtc(),
        venue: location.isEmpty ? null : location,
        organizer: 'Alanya Belediyesi',
        town: 'Alanya',
      ));
    }
    return events;
  }

  /// Detay sayfasındaki gömülü Nuxt verisinden açıklama, kategori ve fotoğrafı ekler.
  Future<void> enrich(RawEvent e) async {
    final uri = Uri.parse(e.sourceUrl);
    final res = await client.get(uri, headers: _headers);
    if (res.statusCode != 200) return;
    final match = RegExp(r'<script[^>]*id="__NUXT_DATA__"[^>]*>([\s\S]*?)</script>')
        .firstMatch(res.body);
    if (match == null) return;
    final root = decodeNuxtPayload(match.group(1)!);
    final data = (root is Map ? root['data'] : null);
    if (data is! Map) return;
    final detail = data.values.whereType<Map>().firstWhere(
          (v) => '${v['id']}' == e.sourceId && v.containsKey('event_content'),
          orElse: () => const {},
        );
    if (detail.isEmpty) return;

    final content = htmlToText(detail['event_content'] as String?);
    if (content.length > e.description.length) e.description = content;
    final category = detail['category'] as String?;
    if (category != null) e.tags = [...e.tags, category];
    final photos = (detail['photos'] as List?) ?? const [];
    if (photos.isNotEmpty && e.imageUrl == null) {
      final p = photos.first as Map;
      final path = (p['photo_url'] ?? p['original_url']) as String?;
      if (path != null) e.imageUrl = '$_mediaBase${path.replaceFirst('~', '')}';
    }
    final map = detail['map'];
    if (map is String) {
      final m = RegExp(r'(3[5-8]\.\d+)\s*,\s*(2[89]\.\d+|3[0-3]\.\d+)').firstMatch(map);
      if (m != null) {
        e.lat = double.parse(m.group(1)!);
        e.lng = double.parse(m.group(2)!);
      }
    }
  }
}

/// Nuxt 3 `__NUXT_DATA__` (devalue) biçimini düz JSON nesnesine çevirir.
Object? decodeNuxtPayload(String text) {
  final table = jsonDecode(text) as List;
  final memo = <int, Object?>{};
  const wrappers = {'ShallowReactive', 'Reactive', 'Ref', 'ShallowRef', 'EmptyRef'};

  Object? hydrate(Object? ref) {
    if (ref is! int) return ref;
    if (ref < 0) return null;
    if (memo.containsKey(ref)) return memo[ref];
    final v = table[ref];
    if (v is List) {
      if (v.isNotEmpty && v.first is String && wrappers.contains(v.first)) {
        final out = v.length > 1 ? hydrate(v[1]) : null;
        memo[ref] = out;
        return out;
      }
      if (v.isNotEmpty && v.first == 'Date') return memo[ref] = v[1];
      final out = <Object?>[];
      memo[ref] = out;
      for (final x in v) {
        out.add(hydrate(x));
      }
      return out;
    }
    if (v is Map) {
      final out = <String, Object?>{};
      memo[ref] = out;
      v.forEach((k, x) => out['$k'] = hydrate(x));
      return out;
    }
    return memo[ref] = v;
  }

  return hydrate(0);
}

// ---------------------------------------------------------------------------
// Antalya Büyükşehir Belediyesi — https://www.antalya.bel.tr/tr/etkinlikler
// ---------------------------------------------------------------------------

class AntalyaSource {
  AntalyaSource(this.client);

  final http.Client client;
  static const name = 'antalya_bb';
  static const _base = 'https://www.antalya.bel.tr';
  static const _collection = '6c75f6c0-fc5d-4d4f-9ae8-e96447fe893b';
  static const _sessionCollection = '67b4c3fa9b39d48fe84a15d1';
  static const _pageId = '67863dad3206e6473c59e30f';

  Future<List<RawEvent>> fetch({int rows = 100}) async {
    // 1) Sayfayı açıp doğrulama jetonunu ve çerezleri al.
    final page = await client.get(Uri.parse('$_base/tr/etkinlikler'), headers: _headers);
    _check(page, page.request!.url);
    final token = RegExp(r'__RequestVerificationToken" type="hidden" value="([^"]+)"')
        .firstMatch(page.body)
        ?.group(1);
    if (token == null) throw StateError('Antalya: doğrulama jetonu bulunamadı');
    final cookies = _cookieHeader(page.headers['set-cookie']);

    // 2) Sitenin kendi veri uç noktasından etkinlikleri iste.
    final body = {
      '__RequestVerificationToken': token,
      'colllection': _collection,
      'lang': '1',
      'dateformat': '',
      // Not: sunucu sıralama filtresinde "False" (büyük harf) bekliyor.
      // finisBroadcasterTime=1: sitenin kendi listesindeki gibi yalnızca
      // tarihli (seanslı) etkinlikler.
      'dbfind': jsonEncode([
        _find('custominclude.finisBroadcasterTime', '=', '1', isRequest: 'False'),
        _find('custominclude.StartDate', 'sorting', 'Desc', isRequest: 'False'),
        _find('RowCount', '=', '$rows'),
      ]),
      'pageid': _pageId,
      'requestquery': '{}',
      'collectiontype': '0',
      'relationcollection': jsonEncode([
        {
          'sourcetable': _collection,
          'sourcetableField': '_id',
          'destionationtable': _sessionCollection,
          'destionationtableField': 'refetkinlik',
          'destionatiodatalimit': 'firstdata',
          'isnulloremptycontrol': false,
        }
      ]),
      'collectionfunction': '',
      'seolink': 'etkinlikler',
      'sourcetablerefcombobox': '',
      'destinationtablerefcombobox': '',
      'tablerefselectprojectionfield': [
        '_id', 'SeoLink', 'baslik', 'aciklama', 'Summary', 'gorsel', 'fiyat',
        'refetkinliktipi', 'duzenleyen', 'coordinate_lat', 'coordinate_long',
        'LocationName', 'bilet_satis_url', 'custominclude._id',
        'custominclude.StartDate', 'custominclude.EndDate',
      ].join(','),
      'isexitingcontrolrequest': 'false',
    };
    final uri = Uri.parse('$_base/tr/seolink/VueData/GetVueData');
    final res = await client.post(uri, headers: {
      ..._headers,
      'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
      'X-Requested-With': 'XMLHttpRequest',
      'Referer': '$_base/tr/etkinlikler',
      if (cookies.isNotEmpty) 'Cookie': cookies,
    }, body: body);
    _check(res, uri);
    final envelope = jsonDecode(res.body) as Map<String, dynamic>;
    if (envelope['issuccess'] != true) throw StateError('Antalya: istek başarısız');
    final rowsData = (jsonDecode(envelope['data'] as String) as List).cast<Map<String, dynamic>>();
    if (Platform.environment.containsKey('SYNC_DEBUG')) {
      stderr.writeln('Antalya ham satır: ${rowsData.length}; tarihsiz: ${rowsData.where((r) => r['custominclude'] == null).length}');
    }

    final events = <RawEvent>[];
    for (final row in rowsData) {
      final session = row['custominclude'] is String
          ? jsonDecode(row['custominclude'] as String) as Map<String, dynamic>
          : (row['custominclude'] as Map<String, dynamic>? ?? const {});
      final start = _parseLocal(session['StartDate'] as String?);
      final title = (row['baslik'] as String? ?? '').trim();
      if (start == null || title.isEmpty) continue;
      var end = _parseLocal(session['EndDate'] as String?);
      if (end != null && !end.isAfter(start)) end = null;

      final description = htmlToText(row['aciklama'] as String?);
      final venue = _nonEmpty(row['LocationName'] as String?) ??
          RegExp(r'YER\s*:\s*([^\n]{3,120})', caseSensitive: false)
              .firstMatch(description)
              ?.group(1)
              ?.trim();
      final organizer = _nonEmpty(row['duzenleyen'] as String?);
      final price = _nonEmpty(row['fiyat'] as String?);
      final lat = double.tryParse('${row['coordinate_lat'] ?? ''}');
      final lng = double.tryParse('${row['coordinate_long'] ?? ''}');
      final seo = row['SeoLink'] as String? ?? '';
      final id = row['_id'] as String;

      events.add(RawEvent(
        source: name,
        sourceId: id,
        sourceUrl: '$_base/tr/etkinlik-detay/$seo?seans=${session['_id']}&etkinlik=$id',
        title: title,
        start: start,
        end: end,
        description: description,
        tags: (row['refetkinliktipi'] as String? ?? '')
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        venue: venue,
        imageUrl: _nonEmpty(row['gorsel'] as String?),
        price: price == null || searchKey(price) == 'ucretsiz' ? null : price,
        isFree: price == null ? null : searchKey(price) == 'ucretsiz',
        organizer: organizer,
        town: _townFrom(organizer, title, venue),
        lat: lat,
        lng: lng,
      ));
    }
    return events;
  }

  static Map<String, String> _find(
    String field,
    String op,
    String value, {
    String isRequest = 'false',
  }) =>
      {
        'field': field,
        'wherecluse': op,
        'fieldValue': value,
        'pageparamsid': value,
        'isrequest': isRequest,
        'fieldtype': 'string',
      };

  /// "202611152359" (Türkiye saati, UTC+3) -> UTC DateTime
  static DateTime? _parseLocal(String? v) {
    if (v == null || v.length < 12 || v == '0') return null;
    final y = int.tryParse(v.substring(0, 4));
    final mo = int.tryParse(v.substring(4, 6));
    final d = int.tryParse(v.substring(6, 8));
    final h = int.tryParse(v.substring(8, 10));
    final mi = int.tryParse(v.substring(10, 12));
    if ([y, mo, d, h, mi].contains(null)) return null;
    return DateTime.utc(y!, mo!, d!, h!, mi!).subtract(const Duration(hours: 3));
  }

  /// Düzenleyen belediyeden veya metinden ilçeyi tahmin eder.
  static String? _townFrom(String? organizer, String title, String? venue) {
    final text = searchKey('$title ${venue ?? ''} ${organizer ?? ''}');
    for (final town in _towns.entries) {
      if (text.contains(town.key)) return town.value;
    }
    return 'Antalya';
  }

  static const _towns = {
    'alanya': 'Alanya',
    'kemer': 'Kemer',
    'manavgat': 'Manavgat',
    'side': 'Side',
    'serik': 'Serik',
    'gazipasa': 'Gazipaşa',
    'elmali': 'Elmalı',
    'kas ': 'Kaş',
    'konyaalti': 'Konyaaltı',
    'kepez': 'Kepez',
    'muratpasa': 'Muratpaşa',
  };
}

// ---------------------------------------------------------------------------
// Antalya Büyükşehir kurs merkezleri — ATABEM ve ATASEM
// https://atabem.antalya.bel.tr/kurslar.html · https://atasem.antalya.bel.tr/kurslar.html
// İkisi de aynı altyapıyı kullanır: kurslar.jsp ve kursmerkezleri.jsp (JSON).
// ---------------------------------------------------------------------------

class CourseCatalogSource {
  CourseCatalogSource._(this.client, this.name, this.host, this.label, this._isArtistic);

  /// Atatürk Bilgi Eğitim Merkezi: yalnızca "Kültürel ve Sanatsal" alanı
  /// (satranç ve zekâ oyunları hariç).
  factory CourseCatalogSource.atabem(http.Client client) => CourseCatalogSource._(
        client,
        'atabem',
        'atabem',
        'ATABEM',
        (area, branch) =>
            searchKey(area) == 'kulturel ve sanatsal' &&
            !RegExp(r'satranc|zeka').hasMatch(searchKey(branch)),
      );

  /// Atatürk Sanat ve Meslek Eğitimi Kursları: sanat, müzik, geleneksel
  /// sanatlar, seramik, fotoğraf ve el sanatları (dikiş/tekstil işleri hariç).
  factory CourseCatalogSource.atasem(http.Client client) => CourseCatalogSource._(
        client,
        'atasem',
        'atasem',
        'ATASEM',
        (area, branch) {
          final a = searchKey(area);
          final b = searchKey(branch);
          if (a.startsWith('el sanatlari')) {
            return !RegExp(r'dikim|mefrusat|yorgan|tekstil|makinede|pijama|ortu').hasMatch(b);
          }
          return const {
            'sanat ve tasarim', 'geleneksel turk sanatlari', 'muzik ve gosteri sanatlari',
            'seramik ve cam teknolojisi', 'grafik ve fotograf',
          }.contains(a);
        },
      );

  final http.Client client;
  final String name;
  final String host;
  final String label;
  final bool Function(String area, String branch) _isArtistic;

  String get _api => 'https://$host.antalya.bel.tr/${host}webservice/webservices/postservices/JSON';

  Future<List<RawEvent>> fetch() async {
    final courses = await _getList('$_api/kurslar.jsp');
    final centers = {
      for (final c in await _getList('$_api/kursmerkezleri.jsp'))
        searchKey('${c['kursmerkeziadi']}'): c,
    };

    // Aynı merkezde aynı branşın grupları (ör. Resim 3A, 4A, 5A) tek kurs olur.
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final c in courses) {
      final area = '${c['kursalaniadi'] ?? ''}'.trim();
      final branch = '${c['kursbransadi'] ?? ''}'.trim();
      if (branch.isEmpty || !_isArtistic(area, branch)) continue;
      groups.putIfAbsent('${c['kursmerkeziadi']}|$branch', () => []).add(c);
    }

    final events = <RawEvent>[];
    for (final entry in groups.entries) {
      final list = entry.value;
      final first = list.first;
      final centerName = '${first['kursmerkeziadi']}'.replaceAll(RegExp(r'\s+'), ' ').trim();
      final center = centers[searchKey(centerName)] ?? const <String, dynamic>{};
      final branch = '${first['kursbransadi']}'.trim();
      final area = '${first['kursalaniadi']}'.trim();

      final starts = list.map((c) => _parseDay('${c['kursbaslangic']}')).whereType<DateTime>().toList()..sort();
      final ends = list.map((c) => _parseDay('${c['kursbitis']}')).whereType<DateTime>().toList()..sort();

      final lines = <String>[];
      final days = <String>{};
      for (final c in list) {
        final slots = _slots('${c['kursgunleri']}', '${c['kurssaatleri']}');
        days.addAll(slots.map((s) => s.$1));
        final age = '${c['enkucukyassiniri']}-${c['enbuyukyassiniri']} yaş';
        final gender = '${c['cinsiyetsarti']}'.trim();
        lines.add('• ${titleCaseTr('${c['kursadi']}'.trim())}: '
            '${slots.map((s) => '${s.$1} ${s.$2}').join(', ')}'
            ' · $age${gender.isNotEmpty && gender != 'Yok' ? ' · $gender' : ''}');
      }
      final firstSlots = _slots('${first['kursgunleri']}', '${first['kurssaatleri']}');
      final schedule = list.length == 1
          ? firstSlots.map((s) => '${s.$1} ${s.$2}').join(', ')
          : '${list.length} grup · ${_orderedDays(days).join(', ')}';

      final district = titleCaseTr('${first['kursmerkeziilcesi']}'.trim());
      final phone = _nonEmpty('${center['kursmerkezitelefon1'] ?? ''}');
      events.add(RawEvent(
        source: name,
        sourceId: '${searchKey(centerName)}|${searchKey(branch)}'.replaceAll(' ', '-'),
        sourceUrl: 'https://$host.antalya.bel.tr/kurslar.html',
        title: _courseTitle(branch),
        start: (starts.isEmpty ? DateTime.now() : starts.first).toUtc(),
        end: ends.isEmpty ? null : ends.last.add(const Duration(hours: 23)).toUtc(),
        description: [
          '$label $centerName bünyesinde açılan ${titleCaseTr(branch)} kursu '
              '(${titleCaseTr(area)}, ${titleCaseTr('${first['kursdonemadi'] ?? ''}'.trim())}).',
          '',
          'Gruplar:',
          ...lines,
          '',
          'Kayıt: https://$host.antalya.bel.tr/${host}kursiyer/kayitol.jsp',
        ].join('\n'),
        tags: [area, branch],
        venue: searchKey(centerName).contains(name) ? centerName : '$label $centerName',
        address: _nonEmpty('${center['kursmerkeziadresi'] ?? ''}'),
        lat: double.tryParse('${center['kursmerkezilatitude'] ?? ''}'),
        lng: double.tryParse('${center['kursmerkezilongitude'] ?? ''}'),
        isFree: true, // Büyükşehir kurs merkezlerindeki kurslar ücretsizdir.
        organizer: '$label · Antalya Büyükşehir Belediyesi',
        contact: phone,
        town: district,
        kind: 'course',
        schedule: schedule,
        defaultCategory: _areaCategory(area),
      ));
    }
    return events;
  }

  Future<List<Map<String, dynamic>>> _getList(String url) async {
    final uri = Uri.parse(url);
    final res = await client.get(uri, headers: _headers);
    _check(res, uri);
    return (jsonDecode(utf8.decode(res.bodyBytes)) as List).cast<Map<String, dynamic>>();
  }

  static String _areaCategory(String area) {
    final a = searchKey(area);
    if (a.startsWith('muzik')) return 'music';
    if (a.startsWith('el sanatlari')) return 'workshop';
    return 'art';
  }

  /// "Resim" -> "Resim Kursu", "Hüsn-İ Hat (1. Seviye)" -> "Hüsn-i Hat Kursu (1. Seviye)"
  static String _courseTitle(String branch) {
    var base = titleCaseTr(branch).replaceAll('-İ ', '-i ');
    String? level;
    final m = RegExp(r'^(.*?)\s*\(([^)]*)\)\s*$').firstMatch(base);
    if (m != null) {
      base = m.group(1)!.trim();
      level = m.group(2)!.trim();
    }
    final k = searchKey(base);
    final hasSuffix = RegExp(r'(egitimi|kursu|yapimi|teknigi|teknikleri|sanati|seviyesi|programi)$').hasMatch(k);
    final title = hasSuffix ? base : '$base Kursu';
    return level == null ? title : '$title ($level)';
  }

  static DateTime? _parseDay(String v) {
    final m = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$').firstMatch(v.trim());
    if (m == null) return null;
    // Türkiye saatiyle gün başı (UTC+3).
    return DateTime.utc(int.parse(m[3]!), int.parse(m[2]!), int.parse(m[1]!))
        .subtract(const Duration(hours: 3));
  }

  /// "Çarşamba <BR>Cumartesi" + "17:40-19:10 <BR>15:10-16:40"
  static List<(String, String)> _slots(String days, String hours) {
    List<String> split(String s) =>
        s.split(RegExp(r'<br\s*/?>', caseSensitive: false)).map((x) => x.trim()).where((x) => x.isNotEmpty && x != 'null').toList();
    final d = split(days);
    final h = split(hours);
    return [for (var i = 0; i < d.length; i++) (d[i], i < h.length ? h[i] : '')];
  }

  static const _weekOrder = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

  static List<String> _orderedDays(Set<String> days) =>
      [..._weekOrder.where(days.contains), ...days.where((d) => !_weekOrder.contains(d))];
}

// ---------------------------------------------------------------------------
// Devlet Opera ve Balesi — Antalya Müdürlüğü
// https://www.operabale.gov.tr/directorates/antalya-opera-ve-balesi-5
// ---------------------------------------------------------------------------

class DobSource {
  DobSource(this.client);

  final http.Client client;
  static const name = 'dob_antalya';
  static const _directorateId = 5; // Antalya

  Future<List<RawEvent>> fetch() async {
    final uri = Uri.parse('https://apimain.operabale.gov.tr/v1/web/temsil/mudurluk/listele/$_directorateId');
    final res = await client.get(uri, headers: _headers);
    _check(res, uri);
    final list = (jsonDecode(utf8.decode(res.bodyBytes)) as List).cast<Map<String, dynamic>>();

    // Aynı eserin aynı sahnedeki temsilleri tek etkinlikte toplanır.
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final p in list) {
      groups.putIfAbsent('${p['eserKodu']}|${p['sahneAdi']}', () => []).add(p);
    }

    final events = <RawEvent>[];
    for (final entry in groups.entries) {
      final shows = entry.value
        ..sort((a, b) => '${a['oyunTarihi']}'.compareTo('${b['oyunTarihi']}'));
      final dates = shows.map((p) => DateTime.tryParse('${p['oyunTarihi']}')).whereType<DateTime>().toList();
      if (dates.isEmpty) continue;
      final first = shows.first;
      final title = '${first['eserAdi']}'.trim();
      final stage = '${first['sahneAdi'] ?? ''}'.trim();
      final konu = htmlToText('${first['eserKonu'] ?? ''}'.replaceAll('\r\n', '<br>'), maxLength: 1500);
      final posters = (first['afisler'] as List?)?.cast<String>() ?? const [];
      final seo = '${first['seoUrl'] ?? ''}';
      // Saatler Türkiye saatidir (UTC+3).
      DateTime utc(DateTime d) => DateTime.utc(d.year, d.month, d.day, d.hour, d.minute).subtract(const Duration(hours: 3));

      events.add(RawEvent(
        source: name,
        sourceId: entry.key.replaceAll(RegExp(r'[^0-9A-Za-z|]'), '-'),
        sourceUrl: seo.isEmpty ? 'https://www.operabale.gov.tr/directorates/antalya-opera-ve-balesi-5' : 'https://www.operabale.gov.tr/eser/$seo',
        title: title,
        start: utc(dates.first),
        end: dates.length > 1 ? utc(dates.last).add(const Duration(hours: 3)) : null,
        description: [
          if (dates.length > 1) 'Temsiller: ${dates.map(_trDateTime).join(' · ')}\n',
          konu,
        ].join('\n').trim(),
        tags: [if (RegExp(r'konser|solist').hasMatch(searchKey(title))) 'Konser'],
        venue: titleCaseTr(stage),
        imageUrl: posters.isEmpty ? null : posters.first,
        price: 'Biletli',
        isFree: false,
        organizer: 'Antalya Devlet Opera ve Balesi',
        contact: _nonEmpty('${first['seoFullUrl'] ?? ''}'),
        town: searchKey(stage).contains('alanya') ? 'Alanya' : 'Antalya',
        defaultCategory: 'music',
      ));
    }
    return events;
  }

  static const _months = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
  ];

  static String _trDateTime(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------------------
// Biletinial — mekân sayfaları (ör. Alanya Kültür Merkezi)
//
// Kullanım koşulları gereği sitedeki telifli içerik (afiş, tanıtım metni)
// alınmaz. Yalnızca sayfaların arama motorları için yayımladığı schema.org
// Event verisindeki olgusal bilgiler (ad, tarih, mekân, başlangıç fiyatı)
// kullanılır ve kullanıcı bilet için Biletinial sayfasına yönlendirilir.
// Not: mekân sayfasındaki tarihler 3 saat kaymış yayınlandığından tarih ve
// saat, her etkinliğin kendi sayfasından okunur.
// ---------------------------------------------------------------------------

class BiletinialSource {
  BiletinialSource(this.client, {this.venues = defaultVenues});

  final http.Client client;
  final List<String> venues;
  static const name = 'biletinial';
  static const _base = 'https://biletinial.com';

  /// Takip edilen mekân sayfaları (`biletinial.com/tr-tr/mekan/<slug>`).
  /// Bölgedeki kültür-sanat sahneleri. Biletinial aynı mekân için birden çok
  /// sayfa açabildiğinden (ör. Holly Stone) hepsi listelenir. Yeni mekân
  /// bulmak için: `dart run tool/sync_events.dart --discover-venues`
  static const defaultVenues = [
    // Alanya
    'alanya-kultur-merkezi',
    'alanya-acikhava-tiyatrosu',
    'alanya-aktuel-acikhava-sahnesi-sanart',
    'holly-stone-performance-hall-alanya',
    'holly-stone-performance-hall-alanya-1',
    'alanya-holly-stone',
    'alanya-holly-stone-2',
    'alanya-holly-stone-3',
    'alanya-holly-stone-3-1',
    'alanya-holly-stone-3-2',
    'alanya-doga-koleji-gosteri-salonu',
    'alanya-illusion',
    // Gazipaşa
    'gazipasa-belediye-kultur-merkezi-1',
    'gazipasa-bld-km-mps-1',
    'gazipasa-belediyesi-gazipasa-kultur-merkezi',
  ];

  /// Site haritasından bölgedeki mekân sayfalarını listeler (bakım için).
  Future<List<String>> discoverVenues({
    List<String> keywords = const ['alanya', 'gazipasa', 'mahmutlar', 'konakli', 'kestel', 'avsallar'],
  }) async {
    final uri = Uri.parse('$_base/tr-tr/sitemap-place.xml');
    final res = await client.get(uri, headers: _headers);
    _check(res, uri);
    return RegExp(r'<loc>[^<]*/mekan/([^<]+)</loc>')
        .allMatches(res.body)
        .map((m) => m.group(1)!)
        .where((slug) => keywords.any(slug.contains))
        .toList();
  }

  Future<List<RawEvent>> fetch() async {
    final eventUrls = <String>{};
    for (final slug in venues) {
      final List<Map<String, dynamic>> ld;
      try {
        ld = await _jsonLd('$_base/tr-tr/mekan/$slug');
      } catch (_) {
        continue; // kaldırılmış mekân sayfası diğerlerini engellemesin
      }
      await Future<void>.delayed(const Duration(milliseconds: 800));
      for (final item in ld) {
        for (final e in (item['event'] as List? ?? const [])) {
          final url = (e as Map)['url'] as String?;
          if (url != null && url.startsWith(_base)) eventUrls.add(url);
        }
      }
    }

    final events = <RawEvent>[];
    for (final url in eventUrls) {
      await Future<void>.delayed(const Duration(milliseconds: 1500)); // nazik tarama
      final List<Map<String, dynamic>> ld;
      try {
        ld = await _jsonLd(url);
      } catch (_) {
        continue;
      }
      final path = Uri.parse(url).pathSegments;
      final section = path.length > 1 ? path[1] : '';
      for (final item in ld) {
        final type = item['@type'];
        if (type != 'Event' && type != 'MusicEvent' && type != 'TheaterEvent') continue;
        final location = (item['location'] as Map?)?.cast<String, dynamic>() ?? const {};
        final address = (location['address'] as Map?)?.cast<String, dynamic>() ?? const {};
        // Yalnızca Antalya ilindeki temsiller.
        final region = searchKey('${address['addressLocality'] ?? ''} ${address['addressRegion'] ?? ''} ${address['streetAddress'] ?? ''}');
        if (!region.contains('antalya')) continue;
        final start = DateTime.tryParse('${item['startDate'] ?? ''}');
        if (start == null) continue;
        var end = DateTime.tryParse('${item['endDate'] ?? ''}');
        if (end != null && !end.isAfter(start)) end = null;

        final venueName = '${location['name'] ?? ''}'.trim().replaceAll(RegExp(r'[\s\-–]+$'), '');
        final geo = (location['geo'] as Map?) ?? const {};
        final lat = double.tryParse('${geo['latitude'] ?? ''}');
        final lng = double.tryParse('${geo['longitude'] ?? ''}');
        final offers = item['offers'];
        final offer = (offers is List ? (offers.isEmpty ? null : offers.first) : offers) as Map?;
        final price = num.tryParse('${offer?['price'] ?? offer?['lowPrice'] ?? ''}');
        final street = '${address['streetAddress'] ?? ''}';
        final title = '${item['name'] ?? ''}'.trim();
        if (title.isEmpty) continue;

        events.add(RawEvent(
          source: name,
          sourceId: '${path.last}@${start.toUtc().toIso8601String().substring(0, 16)}',
          sourceUrl: url,
          title: title,
          start: start.toUtc(),
          end: end?.toUtc(),
          description: 'Bilet, oyuncu/sanatçı bilgisi ve ayrıntılar için Biletinial etkinlik sayfasına bakın.',
          tags: [_sectionTag(section)],
          venue: venueName,
          address: street.isEmpty ? null : street,
          // 0,0 gibi geçersiz koordinatlar konum bulucuda elenir.
          lat: (lat == null || lat.abs() < 1) ? null : lat,
          lng: (lng == null || lng.abs() < 1) ? null : lng,
          price: price == null || price <= 0 ? null : '₺${price.round()}\'den başlayan',
          isFree: price != null && price <= 0 ? true : false,
          organizer: 'Biletinial',
          contact: url,
          town: (lat != null && lat.abs() > 1 && lng != null)
              ? nearestDistrict(lat, lng)
              : _town('$venueName $street'),
          defaultCategory: _sectionCategory(section),
        ));
      }
    }
    return _mergeSameDay(events);
  }

  /// Aynı gün aynı salondaki seanslar (ör. 13:00, 16:00, 19:00) tek kayıt olur.
  static List<RawEvent> _mergeSameDay(List<RawEvent> events) {
    final groups = <String, List<RawEvent>>{};
    for (final e in events) {
      final day = e.start.add(const Duration(hours: 3)).toIso8601String().substring(0, 10);
      groups.putIfAbsent('${e.sourceUrl}|${searchKey(e.venue ?? '')}|$day', () => []).add(e);
    }
    return [
      for (final g in groups.values)
        if (g.length == 1)
          g.first
        else
          (g..sort((a, b) => a.start.compareTo(b.start))).first
            ..end = g.last.start.add(const Duration(hours: 2))
            ..description = 'Seanslar: ${g.map(_localTime).join(', ')}\n\n${g.first.description}',
    ];
  }

  static String _localTime(RawEvent e) {
    final t = e.start.add(const Duration(hours: 3)); // Türkiye saati
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Future<List<Map<String, dynamic>>> _jsonLd(String url) async {
    final uri = Uri.parse(url);
    final res = await client.get(uri, headers: {..._headers, 'Accept': 'text/html'});
    _check(res, uri);
    final html = utf8.decode(res.bodyBytes);
    final out = <Map<String, dynamic>>[];
    for (final m in RegExp(r'<script[^>]*application/ld\+json[^>]*>([\s\S]*?)</script>').allMatches(html)) {
      try {
        final d = jsonDecode(m.group(1)!);
        if (d is List) {
          out.addAll(d.whereType<Map<String, dynamic>>());
        } else if (d is Map<String, dynamic>) {
          out.add(d);
        }
      } catch (_) {/* bozuk blok */}
    }
    return out;
  }

  static String _sectionTag(String section) => switch (section) {
        'muzik' => 'Konser',
        'tiyatro' => 'Tiyatro',
        'sinema' => 'Sinema',
        _ => section,
      };

  static String? _sectionCategory(String section) => switch (section) {
        'muzik' => 'music',
        'tiyatro' => 'theatre',
        'opera-bale' => 'music',
        'sinema' => 'cinema',
        'cocuk' => 'theatre',
        _ => 'festival',
      };

  static String _town(String text) {
    final k = searchKey(text);
    for (final t in const ['Alanya', 'Gazipaşa', 'Manavgat', 'Kemer', 'Kumluca', 'Serik', 'Kaş', 'Finike', 'Konyaaltı', 'Kepez', 'Muratpaşa']) {
      if (k.contains(searchKey(t))) return t;
    }
    return 'Antalya';
  }
}

// ---------------------------------------------------------------------------
// Sinema seansları — Beyazperde (AlloCiné altyapısı)
// https://www.beyazperde.com/sinemalar/sinema-T0042/
// Sitenin seans sayfasını dolduran JSON uç noktası kullanılır. Telifli
// içerik (afiş, özet) alınmaz; film adı, tür, süre, yaş sınırı ve seans
// saatleri gibi olgusal bilgiler kullanılır.
// ---------------------------------------------------------------------------

class CinemaSource {
  CinemaSource(this.client, {this.theaters = defaultTheaters, this.days = 5});

  final http.Client client;
  final List<(String, String)> theaters; // (Beyazperde kodu, ilçe)
  final int days;
  static const name = 'beyazperde';
  static const _base = 'https://www.beyazperde.com';

  static const defaultTheaters = [
    ('T0042', 'Alanya'), // Alanya Alanyum, Keykubat Blv. No:219
  ];

  Future<List<RawEvent>> fetch() async {
    final events = <RawEvent>[];
    final today = DateTime.now().toUtc().add(const Duration(hours: 3)); // Türkiye saati
    for (final (code, district) in theaters) {
      final info = await _theaterInfo(code);
      final films = <String, (Map<String, dynamic>, List<DateTime>, String?)>{};
      for (var i = 0; i < days; i++) {
        final day = today.add(Duration(days: i));
        final d = '${day.year}-${_two(day.month)}-${_two(day.day)}';
        final uri = Uri.parse('$_base/_/showtimes/theater-$code/d-$d/');
        final http.Response res;
        try {
          res = await client.get(uri, headers: {..._headers, 'Accept': 'application/json'});
        } catch (_) {
          continue;
        }
        if (res.statusCode != 200) continue;
        final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        for (final r in (body['results'] as List? ?? const []).cast<Map<String, dynamic>>()) {
          final movie = (r['movie'] as Map?)?.cast<String, dynamic>();
          if (movie == null) continue;
          final id = '${movie['internalId']}';
          final times = <DateTime>[];
          String? ticket;
          for (final list in (r['showtimes'] as Map? ?? const {}).values) {
            for (final st in (list as List? ?? const []).cast<Map<String, dynamic>>()) {
              final t = DateTime.tryParse('${st['startsAt']}');
              if (t != null) times.add(t);
              ticket ??= _ticketUrl(st);
            }
          }
          final prev = films[id];
          films[id] = (movie, [...?prev?.$2, ...times], prev?.$3 ?? ticket);
        }
        await Future<void>.delayed(const Duration(milliseconds: 800));
      }

      for (final entry in films.entries) {
        final (movie, local, ticket) = entry.value;
        if (local.isEmpty) continue;
        local.sort();
        // Saatler Türkiye saatidir (UTC+3).
        DateTime utc(DateTime t) =>
            DateTime.utc(t.year, t.month, t.day, t.hour, t.minute).subtract(const Duration(hours: 3));
        final genres = ((movie['genres'] as List?) ?? const [])
            .map((g) => '${(g as Map)['translate'] ?? g['tag'] ?? ''}')
            .where((g) => g.isNotEmpty)
            .toList();
        final releases = (movie['releases'] as List?) ?? const [];
        final cert = releases.isEmpty
            ? null
            : ((releases.first as Map)['certificate'] as Map?)?['code'] as String?;
        final runtime = '${movie['runtime'] ?? ''}'.trim();
        final kidFriendly = genres.any((g) => const {'Animasyon', 'Aile'}.contains(g)) &&
            !(cert ?? '').contains(RegExp(r'1[368]\+'));

        final byDay = <String, List<String>>{};
        for (final t in local) {
          byDay.putIfAbsent(_trDay(t), () => []).add('${_two(t.hour)}:${_two(t.minute)}');
        }
        final title = '${movie['title'] ?? ''}'.trim();
        if (title.isEmpty) continue;
        events.add(RawEvent(
          source: name,
          sourceId: '$code-${entry.key}',
          sourceUrl: '$_base/sinemalar/sinema-$code/',
          title: title,
          start: utc(local.first),
          end: local.length > 1 ? utc(local.last).add(const Duration(hours: 2)) : null,
          description: [
            [
              if (genres.isNotEmpty) genres.join(', '),
              if (runtime.isNotEmpty) runtime,
              ?cert,
            ].join(' · '),
            if (kidFriendly) 'Aile ve çocuklar için uygun.',
            '',
            'Seanslar:',
            for (final d in byDay.entries) '• ${d.key}: ${d.value.join(', ')}',
            '',
            'Seans saatleri değişebilir; bilet almadan önce sinemadan teyit edin.',
          ].join('\n'),
          tags: ['Sinema'],
          venue: info.$1,
          address: info.$2,
          price: 'Biletli',
          isFree: false,
          organizer: info.$1,
          // Seansa özel bilet bağlantıları giriş sayfasına gider; kaynak bağlantısı yeterli.
          contact: null,
          town: district,
          defaultCategory: 'cinema',
        ));
      }
    }
    return events;
  }

  /// (sinema adı, adres) — sinema sayfasındaki schema.org MovieTheater verisi.
  Future<(String, String?)> _theaterInfo(String code) async {
    try {
      final res = await client.get(Uri.parse('$_base/sinemalar/sinema-$code/'), headers: _headers);
      final html = utf8.decode(res.bodyBytes);
      for (final m in RegExp(r'<script[^>]*application/ld\+json[^>]*>([\s\S]*?)</script>').allMatches(html)) {
        final d = jsonDecode(m.group(1)!);
        if (d is Map && d['@type'] == 'MovieTheater') {
          final a = (d['address'] as Map?) ?? const {};
          return (
            '${d['name']} Sineması',
            [a['streetAddress'], a['addressLocality']].whereType<String>().join(', '),
          );
        }
      }
    } catch (_) {/* ad, kod olarak kalır */}
    return ('Sinema $code', null);
  }

  static String? _ticketUrl(Map<String, dynamic> showtime) {
    final ticketing = ((showtime['data'] as Map?)?['ticketing'] as List?) ?? const [];
    for (final t in ticketing.cast<Map>()) {
      final urls = (t['urls'] as List?)?.cast<String>() ?? const [];
      final direct = urls.where((u) => !u.contains('relay.')).firstOrNull;
      if (direct != null) return direct;
    }
    return null;
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  static const _months = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
  ];
  static const _weekdays = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
  static String _trDay(DateTime t) => '${t.day} ${_months[t.month - 1]} ${_weekdays[t.weekday - 1]}';
}

// ---------------------------------------------------------------------------
// iTicket — Antalya ilindeki etkinlikler
// Sitenin kullandığı herkese açık api.iticket.com.tr/tr/v6/events?city_id=8
// uç noktası. Düşük sıklıkta ve sayfalar arasında bekleyerek okunur; afiş ve
// tanıtım metni alınmaz, kullanıcı bilet için iTicket'a yönlendirilir.
// ---------------------------------------------------------------------------

class ITicketSource {
  ITicketSource(this.client, {this.cityId = 8, this.maxPages = 25});

  final http.Client client;
  final int cityId; // 8 = Antalya
  final int maxPages;
  static const name = 'iticket';
  static const _api = 'https://api.iticket.com.tr/tr/v6';
  static const _site = 'https://iticket.com.tr';

  Future<List<RawEvent>> fetch() async {
    final events = <RawEvent>[];
    final venueCoords = <String, (double, double)>{};
    for (var page = 1; page <= maxPages; page++) {
      final uri = Uri.parse('$_api/events?city_id=$cityId&client=web&page=$page');
      final res = await client.get(uri, headers: {..._headers, 'Accept': 'application/json'});
      _check(res, uri);
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final response = (body['response'] as Map?)?.cast<String, dynamic>() ?? const {};
      for (final v in ((response['venues'] as List?) ?? const []).cast<Map>()) {
        final lat = double.tryParse('${v['map_lat'] ?? ''}');
        final lng = double.tryParse('${v['map_lng'] ?? ''}');
        if (lat != null && lng != null && lat.abs() > 1) venueCoords['${v['name']}'.trim()] = (lat, lng);
      }
      final list = (response['events'] as Map?)?.cast<String, dynamic>() ?? const {};
      for (final e in ((list['data'] as List?) ?? const []).cast<Map<String, dynamic>>()) {
        if (e['is_open_dated'] == true) continue;
        final start = DateTime.tryParse('${e['event_starts_at'] ?? ''}');
        final title = '${e['name'] ?? ''}'.trim();
        if (start == null || title.isEmpty) continue;
        final venue = ((e['venues'] as List?) ?? const [])
            .cast<Map>()
            .map((v) => '${v['name']}'.trim())
            .firstOrNull;
        final coords = venue == null ? null : venueCoords[venue];
        final min = num.tryParse('${e['min_price'] ?? ''}');
        final path = ((e['paths'] as Map?)?['tr'] as String?) ?? '/etkinlikler/${e['slug']}';
        final category = '${e['category_slug'] ?? ''}';
        events.add(RawEvent(
          source: name,
          sourceId: '${e['id']}',
          sourceUrl: '$_site$path',
          title: title,
          start: start.toUtc(),
          description: [
            if (e['age_limit'] != null) 'Yaş sınırı: ${e['age_limit']}+',
            'Bilet ve ayrıntılar için iTicket etkinlik sayfasına bakın.',
          ].join('\n'),
          tags: [_categoryTag(category)],
          venue: venue,
          lat: coords?.$1,
          lng: coords?.$2,
          price: min == null || min <= 0 ? null : "₺${min.round()}'den başlayan",
          isFree: min != null && min <= 0,
          organizer: 'iTicket',
          contact: '$_site$path',
          town: coords == null ? 'Antalya' : nearestDistrict(coords.$1, coords.$2),
          defaultCategory: _categoryDefault(category),
        ));
      }
      if (list['next_page_url'] == null) break;
      await Future<void>.delayed(const Duration(milliseconds: 1200));
    }
    return events;
  }

  static String _categoryTag(String slug) => switch (slug) {
        'konser' => 'Konser',
        'tiyatro' || 'stand-up' => 'Tiyatro',
        'festival' => 'Festival',
        _ => slug,
      };

  static String? _categoryDefault(String slug) => switch (slug) {
        'konser' => 'music',
        'tiyatro' || 'stand-up' || 'cocuk' => 'theatre',
        'festival' => 'festival',
        'sergi' => 'art',
        'atolye' || 'egitim' => 'workshop',
        _ => null, // spor, parti vb. kültür dışı kategoriler elenir
      };
}

/// Koordinattan en yakın ilçe (yalnızca konum doğrulaması için ilçe seçer).
String nearestDistrict(double lat, double lng) {
  const centers = <String, (double, double)>{
    'Alanya': (36.5437, 32.0019),
    'Gazipaşa': (36.2683, 32.3175),
    'Manavgat': (36.7870, 31.4407),
    'Side': (36.7670, 31.3890),
    'Serik': (36.9170, 31.1000),
    'Aksu': (36.9490, 30.8420),
    'Muratpaşa': (36.8889, 30.7209),
    'Kepez': (36.9370, 30.7240),
    'Konyaaltı': (36.8650, 30.6330),
    'Döşemealtı': (37.0300, 30.6000),
    'Kemer': (36.5970, 30.5600),
    'Kumluca': (36.3700, 30.2900),
    'Finike': (36.2970, 30.1470),
    'Demre': (36.2440, 29.9870),
    'Kaş': (36.2020, 29.6380),
    'Elmalı': (36.7380, 29.9170),
    'Korkuteli': (37.0650, 30.1960),
  };
  var best = 'Antalya';
  var bestD = double.infinity;
  centers.forEach((name, c) {
    final d = (c.$1 - lat) * (c.$1 - lat) + (c.$2 - lng) * (c.$2 - lng);
    if (d < bestD) {
      bestD = d;
      best = name;
    }
  });
  return bestD < 0.09 ? best : 'Antalya'; // yaklaşık 30 km
}

// ---------------------------------------------------------------------------

const _headers = {
  'User-Agent': syncUserAgent,
  'Accept': 'application/json, text/html;q=0.9, */*;q=0.8',
  'Accept-Language': 'tr-TR,tr;q=0.9',
};

void _check(http.Response res, Uri uri) {
  if (res.statusCode != 200) {
    throw StateError('HTTP ${res.statusCode}: $uri');
  }
}

String? _nonEmpty(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();

/// `set-cookie` başlığından "ad=değer; ad2=değer2" biçiminde Cookie başlığı üretir.
String _cookieHeader(String? setCookie) {
  if (setCookie == null) return '';
  // http paketi birden fazla Set-Cookie'yi virgülle birleştirir; tarih alanlarındaki
  // virgüllere takılmamak için yalnızca "ad=değer" kalıplarını topla.
  final parts = RegExp(r'(?:^|,\s*)([^=;,\s]+)=([^;]*)')
      .allMatches(setCookie)
      .map((m) => '${m.group(1)}=${m.group(2)}')
      .where((c) {
    final n = c.split('=').first.toLowerCase();
    return !const {'path', 'expires', 'domain', 'samesite', 'max-age'}.contains(n);
  });
  return parts.join('; ');
}
