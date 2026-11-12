import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import 'text_utils.dart';
import 'venues.dart';

/// Konumun ne kadar kesin olduğu.
enum GeoPrecision {
  /// Mekânın kendisi (doğrulanmış liste, OSM mekânı veya kaynağın koordinatı).
  exact,

  /// Adresteki cadde/sokak (mahalle kontrolüyle).
  street,

  /// Mahalle merkezi.
  neighbourhood,

  /// Yalnızca ilçe merkezi — haritada "yaklaşık konum" olarak işaretlenir.
  district,
}

class GeoHit {
  const GeoHit(this.lat, this.lng, this.precision, [this.label]);

  final double lat;
  final double lng;
  final GeoPrecision precision;
  final String? label;
}

/// Mekân ve adresleri koordinata çevirir.
///
/// Sıra: kaynağın koordinatı (ilçe içinde mi diye denetlenir) → doğrulanmış
/// mekân listesi → OpenStreetMap Nominatim (ilçe ve ad eşleşmesi zorunlu) →
/// adresteki sokak/mahalle → ilçe merkezi. Nominatim kullanım politikası gereği
/// saniyede en fazla 1 istek atılır ve yanıtlar dosyada önbelleklenir.
class Geocoder {
  Geocoder(this.cacheFile, this.client) {
    if (cacheFile.existsSync()) {
      try {
        final raw = jsonDecode(cacheFile.readAsStringSync());
        if (raw is Map<String, dynamic> && raw['version'] == _cacheVersion) {
          (raw['entries'] as Map<String, dynamic>).forEach((k, v) => _cache[k] = v as List);
        }
      } catch (_) {/* bozuk önbellek: sıfırdan başla */}
    }
  }

  static const _cacheVersion = 2;
  static const userAgent =
      'Mahallem-EventSync/1.0 (TUBITAK ogrenci projesi; kultur etkinlikleri haritasi)';

  final File cacheFile;
  final http.Client client;
  final _cache = <String, List>{};
  DateTime _lastRequest = DateTime.fromMillisecondsSinceEpoch(0);
  int networkCalls = 0;

  // ---------------------------------------------------------------------------

  Future<GeoHit?> locate({
    required String district,
    double? lat,
    double? lng,
    String? venue,
    String? address,
  }) async {
    final center = await districtCenter(district);

    // 1) Doğrulanmış mekânlar (yer adı veya adres metninde). Kaynağın
    //    koordinatından önce gelir ki aynı mekân hep aynı noktada toplansın.
    for (final text in [venue, address]) {
      if (text == null) continue;
      final v = matchVenue(text, district);
      if (v != null) return GeoHit(v.lat, v.lng, GeoPrecision.exact, v.name);
    }

    // 2) Kaynağın verdiği koordinat — ilçenin 35 km yakınında değilse yok sayılır
    //    (ör. ATASEM bir Muratpaşa merkezi için Kaş yakınını vermiş).
    if (lat != null && lng != null && (center == null || _km(lat, lng, center.lat, center.lng) < 35)) {
      return GeoHit(lat, lng, GeoPrecision.exact, 'kaynak');
    }

    // 3) Mekân adıyla OSM araması (ilçe + ad eşleşmesi zorunlu).
    if (venue != null && _distinctiveTokens(venue).isNotEmpty) {
      final cleaned = venue
          .replaceAll(RegExp(r'\s+(yanı|önü|arkası|karşısı|içi|çevresi|alanı)\b', caseSensitive: false), '')
          .trim();
      final hit = await _search('$cleaned, $district, Antalya',
          district: district, center: center, nameMustMatch: cleaned, poiOnly: true);
      if (hit != null) return hit;
    }

    // 4) Adres: önce sokak (mahalle tutmalı), sonra mahalle merkezi.
    if (address != null) {
      final parsed = parseTurkishAddress(address);
      if (parsed.street != null) {
        final q = [parsed.street, if (parsed.neighbourhood != null) '${parsed.neighbourhood} Mahallesi', district, 'Antalya'].join(', ');
        final hit = await _search(q,
            district: district,
            center: center,
            streetOnly: true,
            streetName: parsed.street,
            neighbourhood: parsed.neighbourhood);
        if (hit != null) return hit;
      }
      if (parsed.neighbourhood != null) {
        final hit = await _search('${parsed.neighbourhood} Mahallesi, $district, Antalya',
            district: district, center: center, neighbourhoodOnly: true, neighbourhood: parsed.neighbourhood);
        if (hit != null) return hit;
      }
    }

    // 5) İlçe merkezi.
    return center == null ? null : GeoHit(center.lat, center.lng, GeoPrecision.district, district);
  }

  final _centers = <String, GeoHit?>{};

  /// İlçe merkezi (OSM'deki ilçe/kasaba nesnesi).
  Future<GeoHit?> districtCenter(String district) async {
    final key = searchKey(district);
    if (_centers.containsKey(key)) return _centers[key];
    final query = key == 'antalya' ? 'Antalya, Muratpaşa' : '$district, Antalya';
    final results = await _query(query);
    GeoHit? hit;
    for (final r in results) {
      final type = r['addresstype'] ?? r['type'];
      // Ad birebir tutmalı: "Alanya, Antalya" sorgusu Antalya şehrini de döndürür.
      if (searchKey('${r['name']}') != key) continue;
      if (const {'town', 'city', 'county', 'municipality', 'district', 'village'}.contains(type) ||
          r['category'] == 'boundary' || r['category'] == 'place') {
        hit = GeoHit(double.parse(r['lat'] as String), double.parse(r['lon'] as String),
            GeoPrecision.district, district);
        break;
      }
    }
    return _centers[key] = hit;
  }

  Future<GeoHit?> _search(
    String query, {
    required String district,
    required GeoHit? center,
    String? nameMustMatch,
    String? neighbourhood,
    String? streetName,
    bool poiOnly = false,
    bool streetOnly = false,
    bool neighbourhoodOnly = false,
  }) async {
    GeoHit? fallback;
    for (final r in await _query(query)) {
      final category = r['category'] as String? ?? '';
      final type = r['type'] as String? ?? '';
      final address = (r['address'] as Map?)?.cast<String, dynamic>() ?? const {};
      final lat = double.parse(r['lat'] as String);
      final lng = double.parse(r['lon'] as String);

      // Doğru ilçede mi?
      final areaText = searchKey([
        address['county'], address['town'], address['city'], address['municipality'],
        address['city_district'], address['district'],
      ].whereType<String>().join(' '));
      if (!districtKeys(district).any(areaText.contains)) continue;
      if (center != null && _km(lat, lng, center.lat, center.lng) > 35) continue;

      if (poiOnly) {
        if (!const {'amenity', 'tourism', 'leisure', 'historic', 'building', 'place'}.contains(category)) continue;
        // Yer adlarından meydan, köy, mahalle ve yaylalar kabul edilir; ilçe/şehir
        // merkezi "mekân" sayılmaz (onun için ayrı, yaklaşık konum adımı var).
        if (category == 'place' &&
            !const {'square', 'village', 'hamlet', 'locality', 'neighbourhood', 'isolated_dwelling', 'quarter'}
                .contains(type)) {
          continue;
        }
        if (nameMustMatch != null) {
          final wanted = _distinctiveTokens(nameMustMatch);
          final got = _distinctiveTokens('${r['name'] ?? ''}');
          if (wanted.intersection(got).isEmpty) continue;
        }
        return GeoHit(lat, lng, GeoPrecision.exact, '${r['name']}');
      }
      if (streetOnly) {
        if (category != 'highway') continue;
        // Sokak adı tutmalı: "2428. Sokak" için "2445. Sokak" kabul edilmez.
        if (streetName != null && !_streetMatches(streetName, '${r['name'] ?? ''}')) continue;
        if (neighbourhood != null) {
          final hood = searchKey([address['suburb'], address['quarter'], address['neighbourhood']]
              .whereType<String>()
              .join(' '));
          if (!hood.contains(searchKey(neighbourhood))) continue;
        }
        return GeoHit(lat, lng, GeoPrecision.street, '${r['name']}');
      }
      if (neighbourhoodOnly) {
        final want = searchKey(neighbourhood ?? '');
        final isArea = category == 'boundary' || category == 'place';
        if (isArea && searchKey('${r['name']}').contains(want)) {
          return GeoHit(lat, lng, GeoPrecision.neighbourhood, '${r['name']}');
        }
        // Küçük ilçelerde mahalle sınırı çizilmemiş olabilir; o mahalleyi
        // semt/köy olarak taşıyan bir nesne yedek olarak kullanılır.
        final hood = searchKey([address['suburb'], address['quarter'], address['neighbourhood'], address['village']]
            .whereType<String>()
            .join(' '));
        if (want.isNotEmpty && hood.contains(want)) {
          fallback ??= GeoHit(lat, lng, GeoPrecision.neighbourhood, '$neighbourhood');
        }
      }
    }
    return fallback;
  }

  Future<List<Map<String, dynamic>>> _query(String query) async {
    final key = searchKey(query);
    final cached = _cache[key];
    if (cached != null) return cached.cast<Map<String, dynamic>>();

    final wait = const Duration(milliseconds: 1100) - DateTime.now().difference(_lastRequest);
    if (!wait.isNegative) await Future<void>.delayed(wait);
    _lastRequest = DateTime.now();
    networkCalls++;

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'jsonv2',
      'limit': '5',
      'countrycodes': 'tr',
      'addressdetails': '1',
      'viewbox': '29.2,37.6,32.8,35.9', // Antalya ili
      'bounded': '1',
      'accept-language': 'tr',
    });
    try {
      final res = await client.get(uri, headers: {'User-Agent': userAgent}).timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return const [];
      final list = (jsonDecode(utf8.decode(res.bodyBytes)) as List).cast<Map<String, dynamic>>();
      // Önbellekte yalnızca gereken alanlar tutulur.
      final slim = list
          .map((r) => {
                'lat': r['lat'],
                'lon': r['lon'],
                'name': r['name'],
                'category': r['category'],
                'type': r['type'],
                'addresstype': r['addresstype'],
                'address': r['address'],
              })
          .toList();
      _cache[key] = slim;
      return slim;
    } catch (_) {
      return const []; // Ağ hatası önbelleğe yazılmaz.
    }
  }

  void save() {
    final sorted = Map.fromEntries(_cache.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
    cacheFile.writeAsStringSync(
      const JsonEncoder.withIndent(' ').convert({'version': _cacheVersion, 'entries': sorted}),
    );
  }
}

const _genericWords = {
  'alanya', 'antalya', 'merkezi', 'merkez', 'kultur', 'sanat', 'parki', 'park', 'mahallesi',
  'belediyesi', 'belediye', 'yani', 'onu', 'arkasi', 'karsisi', 'ici', 'alani', 'salonu',
  'buyuksehir', 'kurs', 'sahne', 'sahnesi', 've', 'ile', 'binasi', 'meydani', 'caddesi',
  'sokak', 'uluslararasi', 'turk', 'yayla', 'yaylasi', 'plaji', 'sahili',
};

const _streetWords = {'sokak', 'sokagi', 'sk', 'sok', 'caddesi', 'cadde', 'cad', 'cd', 'bulvari', 'bulv', 'blv'};

/// "2428. Sokak" ~ "2428. Sokak" (numara aynı olmalı); "Fakılar Sokak" ~ "Fakilar Sokak".
bool _streetMatches(String wanted, String got) {
  List<String> core(String s) => searchKey(s).split(' ').where((w) => w.isNotEmpty && !_streetWords.contains(w)).toList();
  final w = core(wanted);
  final g = core(got);
  if (w.isEmpty || g.isEmpty) return false;
  return w.every(g.contains);
}

Set<String> _distinctiveTokens(String s) =>
    searchKey(s).split(' ').where((w) => w.length > 2 && !_genericWords.contains(w)).toSet();

double _km(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLng = (lng2 - lng1) * math.pi / 180;
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180) * math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.sqrt(a));
}

/// Normalleştirilmiş kopyada bulunan 1. grubun asıl metindeki karşılığı
/// (iki metin aynı uzunluktadır).
String _original(String text, String norm, RegExpMatch m) {
  final group = m.group(1)!;
  final at = norm.indexOf(group, m.start);
  return text.substring(at, at + group.length);
}

/// "Şekerhane Mah. Fakılar Sk. Postalcıoğlu Apt.No:4" ->
/// (neighbourhood: "Şekerhane", street: "Fakılar Sokak")
({String? neighbourhood, String? street}) parseTurkishAddress(String raw) {
  final text = raw.replaceAll(RegExp(r'\s+'), ' ');
  // Büyük "İ" küçük harfe çevrilince iki karakter olduğu için duyarsız eşleşme
  // "MAHALLESİ"yi yakalayamaz; eşleşme aynı uzunlukta bir kopyada yapılır.
  final norm = text.replaceAll('İ', 'I');
  String? hood;
  final h = RegExp(r"([A-Za-zÇĞİÖŞÜçğıöşü0-9]+(?:\s[A-Za-zÇĞİÖŞÜçğıöşü]+)?)\s*(?:\([^)]*\))?\s*(?:Mahallesi|Mahalle|Mah\.?|Mh\.?)(?=[\s:.,]|$)",
          caseSensitive: false)
      .firstMatch(norm);
  if (h != null) {
    hood = _original(text, norm, h).trim();
    // "Altonova Sinan" gibi iki kelimelik adlarda baştaki ilçe/semt adını koru.
    hood = titleCaseTr(hood);
  }

  String? street;
  final s = RegExp(r"([A-Za-zÇĞİÖŞÜçğıöşü0-9.]+(?:\s[A-Za-zÇĞİÖŞÜçğıöşü]+)?)\s*(Caddesi|Cadde|Cad\.?|Cd\.?|Sokağı|Sokak|Sok\.?|Sk\.?|Bulvarı|Bulv\.?|Blv\.?)(?=[\s:.,/]|$)",
          caseSensitive: false)
      .firstMatch(norm);
  if (s != null) {
    var name = _original(text, norm, s).trim();
    // Mahalle adı sokak adına karışmasın: "Şekerhane Mah. Atatürk" -> "Atatürk"
    name = name.replaceFirst(RegExp(r'^(Mah\.?|Mh\.?)\s*', caseSensitive: false), '');
    final kind = trLower(s.group(2)!);
    final suffix = kind.startsWith('c')
        ? 'Caddesi'
        : kind.startsWith('b')
            ? 'Bulvarı'
            : 'Sokak';
    if (RegExp(r'^\d+\.?$').hasMatch(name)) {
      name = '${name.replaceAll('.', '')}.'; // OSM: "2428. Sokak"
    } else {
      name = titleCaseTr(name);
    }
    street = '$name $suffix';
  }
  return (neighbourhood: hood, street: street);
}
