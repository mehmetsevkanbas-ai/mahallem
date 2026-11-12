<p align="center">
  <img src="assets/brand/png/icon.png" width="120" alt="Mahallem logosu">
</p>

# Mahallem · Alanya Kültür Haritası

Mahallem; konser, tiyatro, sergi, resim/müzik/dans kursları gibi kültürel faaliyetleri
**tek bir harita üzerinde** buluşturan bir platformdur. Pilot şehir **Alanya**'dır.

**Aperion Team** tarafından geliştirilmiştir. **Hüseyin Girenes Fen Lisesi** öğrencileri
tarafından oluşturulan bir TÜBİTAK projesidir.

Tek Flutter kod tabanından **Web**, **Android** ve **iOS** olarak çalışır.

## Özellikler

- 🗺️ **Kültür haritası**: Etkinlikler kategori renkleriyle haritada. Kurslar kare, etkinlikler yuvarlak işaretle gösterilir.
- 🏛️ **Gerçek veri**: Etkinlikler ve sanat kursları Alanya Belediyesi, Antalya Büyükşehir Belediyesi (ATABEM, ATASEM) ve Antalya Devlet Opera ve Balesi'nin resmi sitelerinden otomatik alınır, kaynağına bağlantı verilir.
- 📅 **Yaklaşan etkinlikler**: Arama ve kategori, tür (etkinlik/kurs) ve tarih filtreleri (bugün, bu hafta, hafta sonu, bu ay).
- 👤 **Hesap ve kişisel deneyim**: Kayıtta 6 kısa soru (ilgi alanları, etkinlik/kurs, müsait zaman, bütçe, çocuklu mu, yaşanan bölge). "Senin için" önerileri bu yanıtlar ve favorilerden öğrenilen eğilimle puanlanır; her önerinin gerekçesi gösterilir ("İlgi alanın: Müzik · Sana yakın 1,2 km").
- ➕ **Etkinlik ekleme**: Kullanıcılar haritadan konum seçip görselli etkinlik veya kurs ekler.
- ✅ **Moderasyon**: Kullanıcıların eklediği etkinlikler yönetici onayından sonra yayınlanır.
- ⚡ **Canlı güncelleme**: Supabase Realtime ile yeni veriler sayfa yenilemeden görünür.
- 🌍 **4 dil**: Türkçe, İngilizce, Rusça, Almanca.
- 📱 **Responsive tasarım**: Mobilde alt menü, geniş ekranda yan menü ve harita + liste görünümü. Açık ve koyu tema.

## Teknoloji (tamamı ücretsiz)

| Katman | Teknoloji |
|---|---|
| Uygulama | Flutter 3.44 · Riverpod 3 · go_router |
| Backend | [Supabase](https://supabase.com) (Postgres, Auth, Storage, Realtime), ücretsiz plan |
| Veri toplama | `tool/sync_events.dart` (Dart) + GitHub Actions zamanlayıcısı |
| Harita | flutter_map + OpenStreetMap karoları, Nominatim adres→koordinat (API anahtarı gerekmez) |
| Web yayını | GitHub Pages (GitHub Actions ile otomatik) |

## Veri kaynakları

| Kaynak | Uç nokta | Alınan bilgiler |
|---|---|---|
| [Alanya Belediyesi](https://www.alanya.bel.tr/etkinlik-takvimi) | `GET /api/get?name=eventsByRange&start=…&end=…` + etkinlik sayfasındaki gömülü veri | ad, tarih aralığı, yer, açıklama, fotoğraf |
| [Antalya Büyükşehir Belediyesi](https://www.antalya.bel.tr/tr/etkinlikler) | `POST /tr/seolink/VueData/GetVueData` (sitenin kendi listeleme isteği) | ad, tarih, tür, görsel, fiyat, düzenleyen, yer, açıklama |
| [Antalya Devlet Opera ve Balesi](https://www.operabale.gov.tr/directorates/antalya-opera-ve-balesi-5) | `GET apimain.operabale.gov.tr/v1/web/temsil/mudurluk/listele/5` | temsil tarihleri, sahne, afiş, konu, bilet bağlantısı |
| [Biletinial](https://biletinial.com/tr-tr/mekan/alanya-kultur-merkezi) (mekân sayfaları) | sayfalardaki schema.org `Event` verisi | yalnızca olgusal bilgiler: ad, tarih/saat, salon, başlangıç fiyatı, bilet bağlantısı |
| [iTicket](https://iticket.com.tr/etkinlikler) | sitenin kullandığı `api.iticket.com.tr/tr/v6/events?city_id=8` (Antalya) | etkinlik adı, tarih, salon ve koordinatı, kategori, başlangıç fiyatı, bilet bağlantısı |
| [Beyazperde](https://www.beyazperde.com/sinemalar/sinema-T0042/) (sinema) | sinema sayfasını dolduran `/_/showtimes/theater-<kod>/d-<gün>/` JSON'u | vizyondaki filmler, tür, süre, yaş sınırı, önümüzdeki 5 günün seansları |
| [ATABEM](https://atabem.antalya.bel.tr/kurslar.html) (Büyükşehir) | `kurslar.jsp`, `kursmerkezleri.jsp` | "Kültürel ve Sanatsal" kurslar: resim, kara kalem, piyano, gitar, darbuka, drama, tiyatro… |
| [ATASEM](https://atasem.antalya.bel.tr/kurslar.html) (Büyükşehir) | `kurslar.jsp`, `kursmerkezleri.jsp` | Sanat ve tasarım, geleneksel Türk sanatları, müzik ve gösteri sanatları, seramik, fotoğraf, el sanatları |

Kurslarda aynı merkezdeki aynı branşın grupları (ör. Resim 3A, 4A, 5A) tek kurs olarak gösterilir; grupların gün, saat ve yaş aralığı açıklamada listelenir.
Satranç, zekâ oyunları, akademik dersler, dikiş/tekstil gibi sanat dışı kurslar alınmaz.

**Biletinial hakkında:** Sitenin [kullanım koşulları](https://biletinial.com/tr-tr/sayfa/sozlesme-ve-politikalar) içerik ve materyallerin
yazılı izin olmadan kopyalanmasını/yayınlanmasını yasaklar; robots.txt mekân sayfalarına izin verir. Bu yüzden afiş ve tanıtım
metni **alınmaz**; yalnızca arama motorları için yayımlanan olgusal etkinlik bilgileri kullanılır ve kullanıcı bilet için Biletinial'e
yönlendirilir. Takip edilen mekânlar `BiletinialSource.defaultVenues` listesindedir: Alanya Kültür Merkezi, **Alanya Açık Hava
Tiyatrosu** (ve aynı amfi için açılmış "Aktüel Açıkhava Sahnesi" sayfası), Holly Stone Alanya, Doğa Koleji Gösteri Salonu, Alanya
Illusion ve Gazipaşa Kültür Merkezi. Açık hava sahneleri sezonluk olduğundan kışın etkinlik görünmemesi normaldir; satış açılınca
etkinlikler kendiliğinden gelir. Yeni mekân sayfası bulmak için `dart run tool/sync_events.dart --discover-venues` (Biletinial site
haritasını tarar, takip edilenleri `*` ile gösterir). Kalıcı kullanım için Biletinial'den yazılı izin
alınması önerilir.

**iTicket ve sinemalar hakkında:** Her iki kaynakta da sitenin kendi sayfalarını dolduran herkese açık veri servisleri kullanılır;
istekler sayfalar arasında bekleyerek ve düşük sıklıkta yapılır. Bilet platformlarındaki gibi afiş, film özeti ve tanıtım metni alınmaz.
iTicket'ın kullanım koşulları platformda otomatik yazılım kullanımını kısıtladığından, kalıcı kullanım için iTicket'tan da yazılı
izin alınması önerilir. Takip edilen sinemalar `CinemaSource.defaultTheaters` listesindedir (şu an Alanya Alanyum, 5 salon);
başka bir salon eklemek için Beyazperde'deki sinema kodunu (ör. `T0049` Manavgat Kültür Merkezi) listeye eklemek yeterlidir.
Bir film, aynı sinemadaki tüm seanslarıyla tek kayıt olur; seanslar gün gün açıklamada listelenir.

Araştırılıp **eklenemeyen** kaynaklar:
- *Halk Eğitim Merkezi (e-Yaygın)*: kurs listesi e-Devlet girişi gerektiriyor.
- *Antalya Şehir Tiyatroları*: aylık program yalnızca afiş görseli olarak yayınlanıyor; seans tarihleri bilet sitesinde.
- *Alanya Belediyesi Şehir Tiyatrosu* sitesi bağlantıyı reddediyor.
- *Bubilet*: otomatik isteklere 403 (erişim engeli) döndürüyor.
- *Biletix, Passo*: kullanım koşulları otomatik okunamadı, açık bir izin de bulunmadığı için eklenmedi.
- *Songkick*: Açık Hava Tiyatrosu konserlerini listeliyor, ancak API'si yeni başvurulara kapalı.
- *ALKÜ (Alanya Alaaddin Keykubat Üniversitesi)*: etkinlik sayfası çoğunlukla akademik duyurular içeriyor ve etkinlik tarihi değil yayın tarihi veriyor.

İki belediye sitesi tarayıcıdan doğrudan erişime (CORS) kapalı olduğu için veri, sunucu tarafında
çalışan **senkronizasyon aracı** ile alınır:

1. Kaynaklar okunur. Alanya'nın her gün için ayrı yayınladığı çok günlük etkinlikler tek kayıtta birleştirilir.
2. Kültürel olmayan kayıtlar (spor, duyuru, bülten vb.) elenir. Kategori, etiket, başlık ve branştan çıkarılır.
3. İki kaynakta birden geçen etkinlikler eşleştirilir; eksik görsel/açıklama tamamlanır.
4. Konum belirlenir (aşağıya bakın).
5. Sonuç [`assets/data/events.json`](assets/data/events.json) dosyasına ve isteğe bağlı olarak Supabase'e yazılır.

### Konum doğruluğu

Kaynaklardaki yer bilgisi çoğunlukla serbest metindir ("Eski Alanya Belediye Binası Yanı", "AKM Önü").
Rastgele adres araması yanlış yere düşebildiği için konum şu sırayla, her adımda **ilçe kontrolüyle** bulunur:

1. **Kaynağın koordinatı**: yalnızca ilçe merkezine 35 km'den yakınsa kabul edilir (bir kurs merkezi için kaynakta 100 km öteye düşen koordinat bulundu).
2. **Doğrulanmış mekân listesi** ([`tool/sync/venues.dart`](tool/sync/venues.dart)): Kızılkule, Damlataş, eski belediye binası, Açık Hava Tiyatrosu, Haşim İşcan Kültür Merkezi gibi mekânlar; her biri OpenStreetMap nesne kimliğiyle.
3. **OpenStreetMap mekân araması**: sonucun adı mekân adıyla, ilçesi kaydın ilçesiyle tutmalı.
4. **Adresteki sokak**: sokak adı/numarası ve mahalle tutmalı ("2428. Sokak" için "2445. Sokak" kabul edilmez).
5. **Mahalle merkezi**.
6. **İlçe merkezi**: adres alanında "(yaklaşık konum)" yazar.

Aynı noktaya düşen kayıtlar (ör. bir kurs merkezindeki 13 kurs) haritada sayılı tek işaret olarak gösterilir; dokununca liste açılır.
Yeni bir mekân sık kullanılıyorsa `venues.dart` dosyasına OSM'den doğrulanmış koordinatıyla eklenmelidir.

```bash
dart run tool/sync_events.dart --dry-run --verbose   # özet + her kaydın konum kesinliği
dart run tool/sync_events.dart                       # assets/data/events.json günceller
dart run tool/sync_events.dart --supabase            # ayrıca Supabase'e yazar (SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY gerekir)
```

> Kaynak sitelerin yapısı değişirse araç uyarı verip o kaynağı atlar; diğer kaynaklar ve mevcut kayıtlar korunur.
> İstekler 2 saatte bir, araç kendini `Mahallem-EventSync` adıyla tanıtarak yapılır.

## Hızlı başlangıç (yerel mod)

Supabase bağlantısı olmadan da çalışır. Etkinlikler belediye sitelerinden alınmış son veri dosyasından gösterilir:

```bash
flutter pub get
dart run tool/sync_events.dart     # (isteğe bağlı) en güncel veriyi çek
flutter run -d chrome
```

Yerel modda hesaplar, favoriler ve kullanıcıların eklediği etkinlikler yalnızca o oturumda tutulur.
E-postasında `admin` geçen hesaplar (örn. `admin@mahallem.app`) yönetici olur ve onay panelini görür.

## Supabase kurulumu

1. [supabase.com](https://supabase.com) üzerinde ücretsiz hesap açıp yeni proje oluşturun (bölge: *Central EU (Frankfurt)*).
2. **SQL Editor**'de sırayla çalıştırın:
   - [`supabase/migrations/0001_init.sql`](supabase/migrations/0001_init.sql): tablolar, güvenlik kuralları (RLS), görsel deposu
   - [`supabase/migrations/0002_synced_events.sql`](supabase/migrations/0002_synced_events.sql): belediye verisi alanları, senkronizasyon fonksiyonu, Realtime
   - [`supabase/migrations/0003_preferences.sql`](supabase/migrations/0003_preferences.sql): kişiselleştirme tercihleri
3. **Project Settings → API Keys** bölümünden *Project URL*, *Publishable key* ve *Secret (service_role) key* değerlerini alın.
4. Proje kökünde `env.json` oluşturun (git'e eklenmez, örnek için `env.example.json`):

   ```json
   {
     "SUPABASE_URL": "https://PROJE-ID.supabase.co",
     "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_..."
   }
   ```

5. İlk veriyi yükleyin ve çalıştırın:

   ```bash
   SUPABASE_URL=https://PROJE-ID.supabase.co SUPABASE_SERVICE_ROLE_KEY=... dart run tool/sync_events.dart --supabase
   flutter run -d chrome --dart-define-from-file=env.json
   ```

   > ⚠️ *Service role* anahtarı tüm güvenlik kurallarını aşar. Yalnızca senkronizasyon aracında
   > ve GitHub gizli değişkenlerinde kullanın; uygulamaya veya `env.json`'a **koymayın**.

6. **Authentication → URL Configuration** altında *Site URL*'yi yayındaki web adresinize ayarlayın
   (doğrulama ve şifre sıfırlama e-postalarındaki bağlantılar buraya yönlenir).

### Yönetici atama

Kayıt olduktan sonra SQL Editor'de:

```sql
update public.profiles set role = 'admin'
where id = (select id from auth.users where email = 'yonetici@ornek.com');
```

Kullanıcılar kendi rollerini değiştiremez. `role` sütununa yazma yetkisi yalnızca SQL tarafındadır.

## Yayınlama

### GitHub Actions iş akışları

| İş akışı | Ne zaman | Ne yapar |
|---|---|---|
| [`deploy-web.yml`](.github/workflows/deploy-web.yml) | `main`'e push + her gün 06:30 | Test eder, veriyi günceller, web sitesini GitHub Pages'e yayınlar |
| [`sync-events.yml`](.github/workflows/sync-events.yml) | 2 saatte bir | Belediye verisini Supabase'e aktarır |
| [`supabase-keepalive.yml`](.github/workflows/supabase-keepalive.yml) | Haftada 2 kez | Ücretsiz Supabase projesinin uykuya geçmesini önler |

Gerekli ayarlar:

1. **Settings → Pages → Source: GitHub Actions**
2. **Settings → Secrets and variables → Actions** altına: `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `SUPABASE_SERVICE_ROLE_KEY`

Site adresi: `https://KULLANICI.github.io/REPO-ADI/`

### Android

```bash
flutter build apk --release --dart-define-from-file=env.json
```

Çıktı: `build/app/outputs/flutter-apk/app-release.apk`. Play Store için `flutter build appbundle` kullanılır
(Google Play geliştirici hesabı tek seferlik 25$).

### iOS

macOS ve Xcode gerekir. App Store dağıtımı için Apple Developer Program (yıllık 99$) üyeliği gerekir.

## Kişisel öneriler

[`lib/providers/recommendations.dart`](lib/providers/recommendations.dart) açıklanabilir bir puanlama kullanır:

| Kural | Etki |
|---|---|
| İlgi alanındaki kategori | +3 |
| Favorilerdeki kategori payı / aynı mekân | +2,5 × pay / +1 |
| Müsait olunan zaman dilimine uyuyor (kurs programından okunur) | +1,5 (uymuyorsa −1,5) |
| Çocuklu aileye çocuklara uygun | +2 |
| Yaşanan bölgeye <3 km / <10 km / >40 km | +2 / +1 / −4 |
| 7 gün içinde | +1 |
| Ücretsiz | +0,4 |
| "Sadece ücretsiz", "sadece kurs/etkinlik", yetişkine yalnızca çocuk kursu | kesin eleme |

Tercihler `profiles.prefs` (jsonb) sütununda tutulur: [`0003_preferences.sql`](supabase/migrations/0003_preferences.sql).

## Marka

Logo: konum iğnesinin içinde iki çatıdan oluşan bir **"M"** (mahalle) ve aralarında gün batımı güneşi.
Renkler: deniz turkuazı `#0E8C9B`, gün batımı turuncusu `#FF7A59`.

| Dosya | Kullanım |
|---|---|
| [`assets/brand/mahallem_icon.svg`](assets/brand/mahallem_icon.svg) | Uygulama içi logo, yuvarlatılmış ikon |
| `assets/brand/mahallem_icon_square.svg` | iOS / Android ikon kaynağı |
| `assets/brand/mahallem_foreground.svg`, `mahallem_background.svg` | Android uyarlanabilir ikon katmanları |

Logoyu değiştirdikten sonra ikonları ve telefon açılış ekranını yeniden üretmek için:

```bash
flutter test tool/render_brand_test.dart    # SVG -> assets/brand/png/*.png
dart run flutter_launcher_icons              # web, Android ve iOS ikonları
dart run flutter_native_splash:create        # Android/iOS açılış ekranı
```

## Proje yapısı

```
lib/
  core/        config (ortam), theme, router, utils, ortak widget'lar
  data/        modeller, Supabase ve yerel mod depoları
  providers/   Riverpod durum yönetimi ve filtre mantığı
  features/    map, events, add_event, auth, onboarding, profile, admin, shell
  l10n/        çeviri dosyaları (app_tr.arb şablon)
assets/
  brand/       logo kaynakları
  data/        belediye verisi anlık görüntüsü (senkronizasyon aracı üretir)
tool/
  sync_events.dart   veri toplama aracı
  sync/              kaynak okuyucular, kategori çıkarımı, konum bulucu
supabase/      veritabanı şeması
```

Yeni bir çeviri anahtarı eklerken önce `lib/l10n/app_tr.arb` dosyasına, sonra diğer dillere ekleyin.
`flutter gen-l10n` (veya `flutter run`) kodu otomatik üretir.

## Ücretsiz plan sınırları (pilot için yeterli)

- **Supabase**: 500 MB veritabanı, 1 GB dosya depolama, 50.000 aylık aktif kullanıcı
- **GitHub Actions**: herkese açık depolarda ücretsiz; özel depolarda aylık 2.000 dakika (senkronizasyon ~1 dk × 12/gün)
- **OpenStreetMap karoları / Nominatim**: düşük trafikli projeler için ücretsizdir
  ([karo politikası](https://operations.osmfoundation.org/policies/tiles/), [Nominatim politikası](https://operations.osmfoundation.org/policies/nominatim/)).
  Kullanıcı sayısı büyürse MapTiler / Stadia Maps gibi ücretsiz kotalı bir sağlayıcının adresi
  `--dart-define=MAP_TILE_URL=...` ile verilebilir; kod değişikliği gerekmez.
- **GitHub Pages**: aylık 100 GB trafik

## Testler

```bash
flutter analyze
flutter test test
```
