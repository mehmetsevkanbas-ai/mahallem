import 'text_utils.dart';

/// Elle doğrulanmış mekân koordinatları.
///
/// Belediye kayıtlarındaki yer adları serbest metin olduğu için ("Eski Alanya
/// Belediye Binası Yanı", "AKM Önü"...) otomatik arama yanlış yere düşebiliyor.
/// Buradaki her kayıt OpenStreetMap'teki ilgili nesneden (yorumdaki kimlik)
/// alınmış ve kaynaklarla karşılaştırılmıştır.
class Venue {
  const Venue(this.name, this.district, this.lat, this.lng, this.aliases);

  final String name;

  /// İlçe (searchKey biçiminde değil, okunur haliyle).
  final String district;
  final double lat;
  final double lng;

  /// Yer metninde geçmesi yeterli olan anahtarlar (searchKey biçiminde).
  final List<String> aliases;
}

const knownVenues = <Venue>[
  // --- Alanya ---------------------------------------------------------------
  // OSM w485942959 — merkezdeki (eski) belediye binası; Noel Pazarı arkasındaki
  // Belediye Parkı'nda (w373198792) kurulur.
  Venue('Eski Alanya Belediye Binası', 'Alanya', 36.54280, 32.00265, [
    'eski alanya belediye', 'eski belediye binasi', 'belediye binasi arkasi',
    'alanya belediye parki', 'belediye parki', 'eski belediye sarayi', 'alanya belediye sarayi',
  ]),
  // OSM w988461907 — Cumhuriyet Mah. Eğriköprü Cd. hizmet binası
  Venue('Alanya Belediyesi Hizmet Binası', 'Alanya', 36.54234, 32.03623, [
    'belediye hizmet binasi', 'yeni belediye binasi',
  ]),
  // OSM w323396688
  Venue('Alaaddin Keykubat Parkı', 'Alanya', 36.55617, 31.96957, ['alaaddin keykubat parki']),
  // OSM w382548670 (İçkale Kilisesi kalıntısı, İç Kale içinde)
  Venue('İç Kale', 'Alanya', 36.53343, 31.99042, ['ic kale', 'ickale']),
  // OSM w57953594
  Venue('Ehmedek', 'Alanya', 36.53665, 31.99266, ['ehmedek']),
  // OSM w57956094
  Venue('Kızılkule', 'Alanya', 36.53640, 31.99825, ['kizilkule', 'kizil kule']),
  // OSM w35817967 (İskele Caddesi, liman meydanı)
  Venue('İskele Meydanı', 'Alanya', 36.53990, 31.99797, ['iskele meydani', 'alanya iskele', 'liman meydani']),
  // OSM n719113468 / w736593508
  Venue('Damlataş', 'Alanya', 36.54187, 31.98879, ['damlatas magara', 'damlatas plaj', 'damlatas sahil', 'damlatas']),
  // OSM w308856447
  Venue('Kleopatra Plajı', 'Alanya', 36.54818, 31.97888, ['kleopatra plaj', 'kleopatra']),
  // OSM w486557510 (işletmeci: Alanya Belediyesi)
  // Biletinial/iticket'taki "Alanya Açıkhava Tiyatrosu" ve "Aktüel Açıkhava
  // Sahnesi" (Kızlar Pınarı, Asri Mezarlık Cd.) koordinatları da 70 m içinde.
  Venue('Alanya Açık Hava Tiyatrosu', 'Alanya', 36.55913, 31.97313, [
    'acik hava tiyatrosu', 'acikhava tiyatrosu',
    'aktuel acikhava', 'amfi tiyatro',
  ]),
  // Rıhtım Cd. No:26 — Biletinial'deki iki ayrı kayıt (36.54082,31.99911 ve aynı
  // adresteki pub 36.54071,31.99922) birbirini doğruluyor.
  Venue('Holly Stone Performance Hall Alanya', 'Alanya', 36.54082, 31.99911, ['holly stone']),
  // Kestel, Sigorta Cd. No:18/1 (Biletinial koordinatı)
  Venue('Alanya Doğa Koleji Gösteri Salonu', 'Alanya', 36.52224, 32.05708, ['doga koleji']),
  // Dinek Yeni Yat Limanı (Biletinial koordinatı)
  Venue('Alanya Illusion', 'Alanya', 36.55994, 31.95005, ['alanya illusion']),
  // OSM w72231170 (Belediye Konservatuarı) — Biletinial'deki "Alanya Kültür
  // Merkezi, İsmet Hilmi Balcı Cd. No:4" koordinatıyla 25 m içinde aynı bina.
  Venue('Alanya Kültür Merkezi', 'Alanya', 36.54441, 31.98914, [
    'alanya kultur merkezi', 'konservatuvar', 'konservatuar',
  ]),
  // OSM w72231171
  Venue('Alanya Arkeoloji Müzesi', 'Alanya', 36.54394, 31.98894, ['arkeoloji muzesi']),
  // OSM w485953102
  Venue('Atatürk Evi Müzesi', 'Alanya', 36.54907, 31.99982, ['ataturk evi']),
  // OSM w485953119 — Alanyum AVM (sinema salonları içinde)
  Venue('Alanyum', 'Alanya', 36.54357, 32.03206, ['alanyum']),
  // OSM w373206768
  Venue('Damlataş Örnek Sineması', 'Alanya', 36.54494, 31.98842, ['ornek sinema']),
  // OSM r12184698
  Venue('Keykubat Plajı', 'Alanya', 36.53935, 32.01761, ['keykubat plaj']),

  // --- Gazipaşa -------------------------------------------------------------
  // OSM: Gazipaşa Kültür Merkezi (amenity=community_centre)
  Venue('Gazipaşa Kültür Merkezi', 'Gazipaşa', 36.26438, 32.31456, ['gazipasa kultur merkezi']),

  // --- Antalya merkez -------------------------------------------------------
  // OSM w469035184 — Evliya Çelebi Cd.; Antalya DOB ve Devlet Tiyatrosu sahnesi
  Venue('Haşim İşcan Kültür Merkezi', 'Muratpaşa', 36.89995, 30.70315, [
    'hasim iscan kultur merkezi', 'hasim iscan', 'antalya devlet opera',
  ]),
  // OSM w1452372826
  Venue('Antalya Nekropol Müzesi', 'Muratpaşa', 36.88718, 30.71330, ['nekropol muzesi']),
  // OSM w425188380
  Venue('Cam Piramit', 'Muratpaşa', 36.88440, 30.66631, ['cam piramit', 'sabanci kongre']),
  // OSM n6715963286 (AKM girişi)
  Venue('Antalya Atatürk Kültür Merkezi', 'Muratpaşa', 36.88617, 30.66938, [
    'ataturk kultur merkezi', 'akm onu', 'akm',
  ]),
  // OSM w1090877687 — Antalya Şehir Tiyatroları sahneleri
  Venue('Doğu Garajı Kültür Merkezi', 'Muratpaşa', 36.88815, 30.71275, ['dogu garaji']),
  // Antalya kent merkezi meydanı
  Venue('Cumhuriyet Meydanı', 'Muratpaşa', 36.88688, 30.70302, ['cumhuriyet meydani']),
];

/// Antalya merkez ilçeleri birbirine bitişik; mekân eşleştirmede tek ilçe sayılır.
const _antalyaCentral = {'muratpasa', 'kepez', 'konyaalti', 'dosemealti', 'aksu', 'antalya'};

/// Bir ilçe için kabul edilen adres anahtarları (merkez ilçeler birlikte).
Set<String> districtKeys(String district) {
  final k = searchKey(district);
  return _antalyaCentral.contains(k) ? _antalyaCentral : {k};
}

bool sameDistrict(String a, String b) {
  final ka = searchKey(a);
  final kb = searchKey(b);
  if (ka == kb) return true;
  return _antalyaCentral.contains(ka) && _antalyaCentral.contains(kb);
}

/// Yer metni bilinen bir mekâna karşılık geliyorsa onu döndürür.
Venue? matchVenue(String text, String district) {
  final key = ' ${searchKey(text)} ';
  Venue? best;
  var bestLength = 0;
  for (final v in knownVenues) {
    if (!sameDistrict(v.district, district)) continue;
    for (final alias in v.aliases) {
      // En uzun (en özgül) eşleşmeyi seç: "damlatas magara" > "damlatas".
      if (key.contains(' $alias') && alias.length > bestLength) {
        best = v;
        bestLength = alias.length;
      }
    }
  }
  return best;
}
