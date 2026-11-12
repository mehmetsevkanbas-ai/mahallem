/// Türkçe metin yardımcıları (senkronizasyon aracı için, Flutter'a bağımlı değil).
library;

String trLower(String s) =>
    s.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();

String trUpper(String s) =>
    s.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();

/// Arama/eşleştirme için sade anahtar: küçük harf, aksansız, yalnızca harf-rakam.
String searchKey(String s) => trLower(s)
    .replaceAll('ç', 'c')
    .replaceAll('ğ', 'g')
    .replaceAll('ı', 'i')
    .replaceAll('ö', 'o')
    .replaceAll('ş', 's')
    .replaceAll('ü', 'u')
    .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
    .trim();

const _keepUpper = {
  'TFF', 'TCG', 'AKM', 'ALKÜ', 'DOB', 'TRT', 'ABD', 'AB', 'UNESCO', 'DJ',
  'TÜBİTAK', 'MEB', 'KTB', 'ATABEM', 'AVM',
};
const _lowerWords = {'ve', 'ile', 'için', 'veya', 'de', 'da', 'ki'};

/// "16. ALANYA ULUSLARASI NOEL PAZARI" -> "16. Alanya Uluslarası Noel Pazarı"
/// Kaynaklar başlıkları tamamen büyük harfle yayınladığı için okunurluğu artırır.
String titleCaseTr(String input) {
  final text = input.trim().replaceAll(RegExp(r'\s+'), ' ');
  final letters = text.replaceAll(RegExp(r'[^A-Za-zÇĞİÖŞÜçğıöşü]'), '');
  final upperCount = letters.split('').where((c) => c == trUpper(c) && c != trLower(c)).length;
  // Zaten karışık harfliyse dokunma.
  if (letters.isEmpty || upperCount < letters.length * 0.7) return text;

  final words = text.split(' ');
  final out = <String>[];
  for (var i = 0; i < words.length; i++) {
    final word = words[i];
    final bare = word.replaceAll(RegExp(r'''^["'“”‘’(]+|["'“”‘’),.:;!?]+$'''), '');
    if (_keepUpper.contains(bare) || RegExp(r'^[IVXLC]+$').hasMatch(bare) && bare.length > 1) {
      out.add(word);
      continue;
    }
    var lower = trLower(word);
    if (i > 0 && _lowerWords.contains(lower)) {
      out.add(lower);
      continue;
    }
    // İlk harfi büyüt (tırnak/parantez sonrası dahil); kesme işaretinden sonrası küçük kalır.
    final idx = lower.indexOf(RegExp(r'[a-zçğıöşü]'));
    if (idx >= 0) {
      lower = lower.substring(0, idx) + trUpper(lower[idx]) + lower.substring(idx + 1);
    }
    out.add(lower);
  }
  return out.join(' ');
}

const _entities = {
  'nbsp': ' ', 'amp': '&', 'quot': '"', 'apos': "'", 'lt': '<', 'gt': '>',
  'ccedil': 'ç', 'Ccedil': 'Ç', 'ouml': 'ö', 'Ouml': 'Ö', 'uuml': 'ü',
  'Uuml': 'Ü', 'rsquo': '’', 'lsquo': '‘', 'rdquo': '”', 'ldquo': '“',
  'ndash': '–', 'mdash': '—', 'hellip': '…',
};

/// HTML'i düz metne çevirir (stil/script blokları atılır, satır sonları korunur).
String htmlToText(String? html, {int maxLength = 2000}) {
  if (html == null || html.trim().isEmpty) return '';
  var s = html
      .replaceAll(RegExp(r'<(style|script)[^>]*>[\s\S]*?</\1>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</(p|div|li|h[1-6]|tr)>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), ' ');
  s = s.replaceAllMapped(RegExp(r'&#(x?[0-9a-fA-F]+);'), (m) {
    final v = m[1]!;
    final code = v.startsWith('x') ? int.parse(v.substring(1), radix: 16) : int.parse(v);
    return String.fromCharCode(code);
  });
  s = s.replaceAllMapped(RegExp(r'&([a-zA-Z]+);'), (m) => _entities[m[1]] ?? m[0]!);
  s = s
      .split('\n')
      .map((l) => l.replaceAll(RegExp(r'[ \t ]+'), ' ').trim())
      .where((l) => l.isNotEmpty)
      .join('\n');
  return s.length > maxLength ? '${s.substring(0, maxLength - 1)}…' : s;
}
