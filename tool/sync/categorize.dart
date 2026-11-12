import 'text_utils.dart';

/// Kaynak etiketleri ve başlıktan uygulama kategorisini çıkarır.
/// Kültürel olmayan kayıtlar (spor, duyuru, eğitim vb.) için `null` döner.
String? inferCategory({
  required String title,
  List<String> tags = const [],
  String description = '',
  String? defaultCategory,
}) {
  final t = ' ${searchKey(title)} ';
  final tagKeys = tags.map(searchKey).toSet();

  // Kesin olarak etkinlik olmayan kayıtlar.
  if (_hasAny(t, const ['bulten', 'ihale', 'duyuru', 'dagitimi', 'kisirlastirma'])) {
    return null;
  }

  for (final rule in _rules) {
    if (tagKeys.any(rule.tags.contains)) {
      // "Fuar" etiketi: kitap fuarıysa edebiyat, değilse festival.
      if (rule.slug == 'festival' && tagKeys.contains('fuar') && t.contains(' kitap')) {
        return 'literature';
      }
      return rule.slug;
    }
  }
  for (final rule in _rules) {
    if (_hasAny(t, rule.words)) return rule.slug;
  }
  // Başlık yetersizse açıklamada güçlü ipuçlarına bak.
  final d = ' ${searchKey(description)} ';
  for (final rule in _rules) {
    if (_hasAny(d, rule.strongWords)) return rule.slug;
  }
  return defaultCategory;
}

bool _hasAny(String haystack, List<String> words) =>
    words.any((w) => haystack.contains(' $w'));

class _Rule {
  const _Rule(this.slug, this.tags, this.words, [this.strongWords = const []]);

  final String slug;
  final Set<String> tags;
  final List<String> words;
  final List<String> strongWords;
}

// Öncelik sırası önemlidir: "tiyatro festivali" -> tiyatro, "caz festivali" -> müzik.
const _rules = [
  _Rule('theatre', {'tiyatro'}, ['tiyatro', 'muzikal', 'stand up', 'kukla', 'drama'], ['tiyatro', 'oyunu sahne']),
  _Rule('cinema', {'sinema', 'film'}, ['sinema', 'film '], ['film gosterimi', 'sinema']),
  _Rule('dance', {'dans'}, ['dans', 'bale', 'halk oyunlari', 'folklor'], ['halk oyunlari', 'bale']),
  _Rule('music', {'konser', 'muzik'}, [
    'konser', 'muzik', 'caz', 'jazz', 'orkestra', 'koro', 'resital',
    'dinleti', 'opera', 'turku', 'senfoni', 'bando', 'darbuka', 'gitar',
    'piyano', 'keman', 'baglama', 'ney ', 'bendir', 'mehter', 'solist',
  ], ['konser', 'dinleti']),
  _Rule('art', {'sergi', 'sanat'}, [
    'sergi', 'resim', 'heykel', 'karikatur', 'fotograf', 'minyatur',
    'tezhip', 'ebru', 'bienal', 'seramik', 'cini', 'husn i hat', 'hat sanati',
    'kara kalem', 'karakalem', 'sulu boya', 'akrilik', 'guaj', 'yagli boya', 'boyama',
  ], ['sergi', 'sergisi']),
  _Rule('literature', {'edebiyat', 'soylesi'}, ['kitap', 'siir', 'edebiyat', 'soylesi', 'imza gunu'], ['soylesi', 'siir']),
  _Rule('workshop', {'atolye'}, ['atolye', 'workshop'], ['atolye']),
  _Rule('festival', {'festival', 'senlik', 'cocuklar', 'fuar'}, [
    'festival', 'fest', 'senlik', 'noel pazari', 'kutlama', 'fener alayi',
  ]),
];
