import 'package:flutter_test/flutter_test.dart';

import '../tool/sync/categorize.dart';
import '../tool/sync/geocoder.dart';
import '../tool/sync/venues.dart';
import '../tool/sync/sources.dart';
import '../tool/sync/text_utils.dart';

void main() {
  group('Başlık düzenleme', () {
    test('büyük harfli başlık Türkçe kurallarıyla düzeltilir', () {
      expect(titleCaseTr('16. ALANYA ULUSLARASI NOEL PAZARI'), '16. Alanya Uluslarası Noel Pazarı');
      expect(titleCaseTr("TCG BORA ANTALYA'DA"), "TCG Bora Antalya'da");
      expect(titleCaseTr('FENER ALAYI VE "CEZA KONSERİ"'), 'Fener Alayı ve "Ceza Konseri"');
      expect(titleCaseTr('İSMAİL BAHA SÜRELSAN'), 'İsmail Baha Sürelsan');
    });

    test('karışık harfli başlığa dokunulmaz', () {
      expect(titleCaseTr('Gün Batımı Konserleri'), 'Gün Batımı Konserleri');
    });
  });

  test('HTML düz metne çevrilir', () {
    expect(
      htmlToText('<style>.a{}</style><p>TARİH: 11 KASIM</p><p>YER:&nbsp;AKM</p>'),
      'TARİH: 11 KASIM\nYER: AKM',
    );
  });

  group('Kategori çıkarımı', () {
    test('etiket ve başlıktan kategori', () {
      expect(inferCategory(title: 'GÜN BATIMI KONSERLERİ', tags: ['Genel', 'Konser']), 'music');
      expect(inferCategory(title: '12. LİSELER ARASI TİYATRO FESTİVALİ'), 'theatre');
      expect(inferCategory(title: '20. ALANYA ULUSLARASI CAZ FESTİVALİ'), 'music');
      expect(inferCategory(title: '21. ULUSLARARASI ALANYA TAŞ HEYKEL SEMPOZYUMU'), 'art');
      expect(inferCategory(title: '16. ALANYA ULUSLARASI NOEL PAZARI'), 'festival');
      expect(inferCategory(title: '8. ALANYA KİTAP FUARI', tags: ['Fuar']), 'literature');
    });

    test('kültürel olmayan kayıtlar elenir', () {
      expect(inferCategory(title: '2026 TFF PLAJ FUTBOLU', tags: ['Spor']), isNull);
      expect(inferCategory(title: 'ANTALYA KENT KÜLTÜRÜ BÜLTENİ', tags: ['Genel']), isNull);
      expect(inferCategory(title: "TCG BORA ANTALYA'DA", tags: ['Genel']), isNull);
      expect(inferCategory(title: 'BALIK TUTMA YARIŞMASI'), isNull);
    });
  });

  group('Konum', () {
    test('Türkçe adres mahalle ve sokağa ayrılır', () {
      final a = parseTurkishAddress('Şekerhane Mah. Fakılar Sk. Postalcıoğlu Apt.No:4');
      expect(a.neighbourhood, 'Şekerhane');
      expect(a.street, 'Fakılar Sokak');

      final b = parseTurkishAddress('Şekerhane Mah. Atatürk Cad. No 19 Kat:2 (Alanya Ticaret Odası Yanı)');
      expect(b.neighbourhood, 'Şekerhane');
      expect(b.street, 'Atatürk Caddesi');

      final c = parseTurkishAddress('Yenimahalle 2428 Sk. No:39 Karatay Lisesi Yanı /ANTALYA');
      expect(c.street, '2428. Sokak');

      final d = parseTurkishAddress('KIZILSARAY MAHALLESİ 81.SOKAK AYAKKABICILAR ÇARŞISI');
      expect(d.neighbourhood, 'Kızılsaray');
      expect(d.street, '81. Sokak');
    });

    test('belediyenin serbest yer adları doğrulanmış mekâna eşlenir', () {
      expect(matchVenue('Eski Alanya Belediye Binası Yanı', 'Alanya')?.name, 'Eski Alanya Belediye Binası');
      expect(matchVenue('Alaaddin Keykubat Parkı Yanı', 'Alanya')?.name, 'Alaaddin Keykubat Parkı');
      expect(matchVenue('ANTALYA HAŞİM İŞÇAN KÜLTÜR MERKEZİ', 'Antalya')?.name, 'Haşim İşcan Kültür Merkezi');
      expect(matchVenue('AKM ÖNÜ', 'Muratpaşa')?.name, 'Antalya Atatürk Kültür Merkezi');
    });

    test('açık hava ve konser sahneleri eşlenir', () {
      expect(matchVenue('ALANYA Açıkhava Tiyatrosu', 'Alanya')?.name, 'Alanya Açık Hava Tiyatrosu');
      expect(matchVenue('Alanya Aktüel Açıkhava Sahnesi', 'Alanya')?.name, 'Alanya Açık Hava Tiyatrosu');
      expect(matchVenue('Holly Stone Performance Hall Alanya', 'Alanya')?.name, 'Holly Stone Performance Hall Alanya');
      // Antalya'daki Holly Stone, Alanya'daki şubeye atanmamalı.
      expect(matchVenue('Holly Stone Performance Hall', 'Muratpaşa'), isNull);
      // Belediyenin aynı yer için kullandığı farklı yazımlar.
      expect(matchVenue('Eski Belediye Sarayı Arkası', 'Alanya')?.name, 'Eski Alanya Belediye Binası');
      expect(matchVenue('İç Kale Seyir Terası', 'Alanya')?.name, 'İç Kale');
      // Gösteri adı mekân sanılmamalı.
      expect(matchVenue('The Illusionist - Enver Ertaş', 'Alanya'), isNull);
    });

    test('mekân yalnızca kendi ilçesinde eşlenir', () {
      // Alanya'daki konservatuvar, Antalya'daki bir kayda atanmamalı.
      expect(matchVenue('Konservatuvar Konser Salonu', 'Muratpaşa'), isNull);
      expect(matchVenue('Konservatuvar', 'Alanya')?.district, 'Alanya');
      expect(sameDistrict('Kepez', 'Muratpaşa'), isTrue);
      expect(sameDistrict('Alanya', 'Gazipaşa'), isFalse);
    });
  });

  test('koordinattan ilçe bulunur', () {
    expect(nearestDistrict(36.5446, 31.9864), 'Alanya'); // Alanya Kültür Merkezi
    expect(nearestDistrict(36.5859, 31.8904), 'Alanya'); // Konaklı
    expect(nearestDistrict(36.8848, 30.6506), 'Konyaaltı');
    expect(nearestDistrict(36.5993, 30.5686), 'Kemer');
    expect(nearestDistrict(39.92, 32.85), 'Antalya'); // il dışı: varsayılan
  });

  test('kurs branşları doğru kategoriye düşer', () {
    expect(inferCategory(title: 'Darbuka', defaultCategory: 'art'), 'music');
    expect(inferCategory(title: 'Drama', defaultCategory: 'art'), 'theatre');
    expect(inferCategory(title: 'Kara Kalem', defaultCategory: 'music'), 'art');
    expect(inferCategory(title: 'Çini (1. Seviye)'), 'art');
    expect(inferCategory(title: 'Türk Halk Oyunları Antalya Yöresi'), 'dance');
    expect(inferCategory(title: 'Tel Kırma Yapımı', defaultCategory: 'workshop'), 'workshop');
  });

  test('Nuxt sayfa verisi çözülür', () {
    const payload =
        '[["ShallowReactive",1],{"data":2},["ShallowReactive",3],{"x":4},{"id":5,"event_name":6,"photos":7},20059,"NOEL PAZARI",[]]';
    final root = decodeNuxtPayload(payload) as Map;
    final event = (root['data'] as Map)['x'] as Map;
    expect(event['id'], 20059);
    expect(event['event_name'], 'NOEL PAZARI');
    expect(event['photos'], isEmpty);
  });
}
