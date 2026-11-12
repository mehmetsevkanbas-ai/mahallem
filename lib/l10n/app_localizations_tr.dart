// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Mahallem';

  @override
  String get appTagline => 'Alanya\'nın kültür haritası';

  @override
  String get navMap => 'Harita';

  @override
  String get navEvents => 'Keşfet';

  @override
  String get navAdd => 'Ekle';

  @override
  String get navProfile => 'Profil';

  @override
  String get searchHint => 'Etkinlik, mekan veya kurs ara';

  @override
  String get filterAll => 'Tümü';

  @override
  String get kindEvents => 'Etkinlikler';

  @override
  String get kindCourses => 'Kurslar';

  @override
  String get kindEvent => 'Etkinlik';

  @override
  String get kindCourse => 'Kurs';

  @override
  String get dateAny => 'Her zaman';

  @override
  String get dateToday => 'Bugün';

  @override
  String get dateThisWeek => 'Bu hafta';

  @override
  String get dateWeekend => 'Hafta sonu';

  @override
  String get dateThisMonth => 'Bu ay';

  @override
  String get forYou => 'Senin için';

  @override
  String get forYouSubtitle => 'İlgi alanlarına göre seçtiklerimiz';

  @override
  String get upcomingEvents => 'Yaklaşan etkinlikler';

  @override
  String get allEvents => 'Tüm etkinlik ve kurslar';

  @override
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sonuç',
      zero: 'Sonuç yok',
    );
    return '$_temp0';
  }

  @override
  String get noResults => 'Bu filtrelere uygun etkinlik bulunamadı.';

  @override
  String get clearFilters => 'Filtreleri temizle';

  @override
  String get free => 'Ücretsiz';

  @override
  String get ongoingCourse => 'Devam eden kurs';

  @override
  String todayAt(String time) {
    return 'Bugün $time';
  }

  @override
  String tomorrowAt(String time) {
    return 'Yarın $time';
  }

  @override
  String untilDate(String date) {
    return '$date tarihine kadar';
  }

  @override
  String startsOn(String date) {
    return 'Başlangıç: $date';
  }

  @override
  String get seeDetails => 'Detaylar';

  @override
  String get getDirections => 'Yol tarifi al';

  @override
  String get location => 'Konum';

  @override
  String get dateTime => 'Tarih ve saat';

  @override
  String get schedule => 'Program';

  @override
  String get price => 'Ücret';

  @override
  String get organizer => 'Düzenleyen';

  @override
  String get contact => 'İletişim';

  @override
  String get about => 'Hakkında';

  @override
  String get addToFavorites => 'Favorilere ekle';

  @override
  String get removeFromFavorites => 'Favorilerden çıkar';

  @override
  String get favorites => 'Favorilerim';

  @override
  String get myEvents => 'Eklediğim etkinlikler';

  @override
  String get statusPending => 'Onay bekliyor';

  @override
  String get statusApproved => 'Yayında';

  @override
  String get statusRejected => 'Reddedildi';

  @override
  String get loginRequiredFavorite => 'Favorilere eklemek için giriş yap';

  @override
  String get signIn => 'Giriş yap';

  @override
  String get signUp => 'Kayıt ol';

  @override
  String get signOut => 'Çıkış yap';

  @override
  String get email => 'E-posta';

  @override
  String get password => 'Şifre';

  @override
  String get displayName => 'Ad Soyad';

  @override
  String get forgotPassword => 'Şifremi unuttum';

  @override
  String get resetEmailSent =>
      'Şifre sıfırlama bağlantısı e-postana gönderildi.';

  @override
  String get confirmEmailSent =>
      'Kayıt tamamlandı! Hesabını doğrulamak için e-postanı kontrol et, ardından giriş yap.';

  @override
  String get authWelcome => 'Mahallem\'e hoş geldin';

  @override
  String get authSubtitle =>
      'Etkinlikleri kaydet, ilgi alanlarına göre öneriler al ve kendi etkinliğini ekle.';

  @override
  String get errorInvalidEmail => 'Geçerli bir e-posta gir';

  @override
  String get errorPasswordShort => 'Şifre en az 6 karakter olmalı';

  @override
  String get errorRequired => 'Bu alan zorunlu';

  @override
  String errorGeneric(String message) {
    return 'Bir hata oluştu: $message';
  }

  @override
  String get retry => 'Tekrar dene';

  @override
  String get interestsTitle => 'Neler ilgini çekiyor?';

  @override
  String get interestsSubtitle =>
      'Seçimlerine göre sana özel etkinlikler gösterelim.';

  @override
  String get interestsSave => 'Kaydet ve devam et';

  @override
  String get interestsSkip => 'Şimdilik geç';

  @override
  String get editInterests => 'İlgi alanlarını düzenle';

  @override
  String get myInterests => 'İlgi alanlarım';

  @override
  String get noInterests => 'Henüz ilgi alanı seçmedin.';

  @override
  String get addEventTitle => 'Etkinlik ekle';

  @override
  String get addEventSubtitle =>
      'Konser, tiyatro, sahilde müzik, resim kursu... Şehrin kültür hayatına katkıda bulun.';

  @override
  String get fieldTitle => 'Başlık';

  @override
  String get fieldDescription => 'Açıklama';

  @override
  String get fieldCategory => 'Kategori';

  @override
  String get fieldKind => 'Tür';

  @override
  String get fieldStart => 'Başlangıç';

  @override
  String get fieldEnd => 'Bitiş (isteğe bağlı)';

  @override
  String get fieldSchedule => 'Kurs programı';

  @override
  String get fieldScheduleHint => 'Örn. Her Salı ve Perşembe 19:00-21:00';

  @override
  String get fieldVenue => 'Mekan adı';

  @override
  String get fieldAddress => 'Adres';

  @override
  String get fieldPrice => 'Ücret';

  @override
  String get fieldPriceHint => 'Örn. 250 ₺';

  @override
  String get fieldIsFree => 'Ücretsiz';

  @override
  String get fieldOrganizer => 'Düzenleyen';

  @override
  String get fieldContact => 'İletişim (telefon, web, Instagram)';

  @override
  String get pickLocation => 'Konum';

  @override
  String get pickLocationHint => 'Etkinliğin yapılacağı yere haritada dokun';

  @override
  String get locationRequired => 'Lütfen haritadan konum seç';

  @override
  String get startRequired => 'Lütfen başlangıç tarihini seç';

  @override
  String get addImage => 'Görsel ekle';

  @override
  String get changeImage => 'Görseli değiştir';

  @override
  String get removeImage => 'Görseli kaldır';

  @override
  String get submitEvent => 'Onaya gönder';

  @override
  String get submitSuccessTitle => 'Teşekkürler!';

  @override
  String get submitSuccessBody =>
      'Etkinliğin yönetici onayından sonra haritada yayınlanacak.';

  @override
  String get ok => 'Tamam';

  @override
  String get cancel => 'Vazgeç';

  @override
  String get selectDate => 'Tarih seç';

  @override
  String get adminPanel => 'Yönetici paneli';

  @override
  String get adminPendingTitle => 'Onay bekleyen etkinlikler';

  @override
  String get adminNoPending => 'Onay bekleyen etkinlik yok.';

  @override
  String get approve => 'Onayla';

  @override
  String get reject => 'Reddet';

  @override
  String get eventApproved => 'Etkinlik onaylandı';

  @override
  String get eventRejected => 'Etkinlik reddedildi';

  @override
  String get delete => 'Sil';

  @override
  String get language => 'Dil';

  @override
  String get theme => 'Tema';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeDark => 'Koyu';

  @override
  String get guestTitle => 'Hesabını oluştur';

  @override
  String get guestBody =>
      'Favorilerini kaydetmek, kişisel öneriler almak ve etkinlik eklemek için giriş yap.';

  @override
  String get demoModeBanner =>
      'Yerel mod: etkinlikler belediye sitelerinden alınan son veriyle gösteriliyor. Hesaplar ve eklenen etkinlikler yalnızca bu oturumda tutulur; kalıcı kayıt için Supabase bağlantısı gerekir.';

  @override
  String get demoAdminHint =>
      'Yerel mod: e-postasında \"admin\" geçen hesaplar yönetici olur.';

  @override
  String get noFavorites => 'Henüz favori etkinliğin yok.';

  @override
  String get noMyEvents => 'Henüz etkinlik eklemedin.';

  @override
  String get eventNotFound => 'Etkinlik bulunamadı.';

  @override
  String get recenterMap => 'Alanya\'ya dön';

  @override
  String get categories => 'Kategoriler';

  @override
  String get viewOnMap => 'Haritada göster';

  @override
  String pendingCount(int count) {
    return '$count bekleyen';
  }

  @override
  String get settings => 'Ayarlar';

  @override
  String get aboutApp =>
      'Mahallem, Alanya\'daki kültür ve sanat etkinliklerini tek bir haritada buluşturan bir TÜBİTAK projesidir.';

  @override
  String get catMusic => 'Müzik';

  @override
  String get catTheatre => 'Tiyatro';

  @override
  String get catArt => 'Resim & Sanat';

  @override
  String get catDance => 'Dans';

  @override
  String get catCinema => 'Sinema';

  @override
  String get catLiterature => 'Edebiyat';

  @override
  String get catFestival => 'Festival';

  @override
  String get catOutdoor => 'Açık hava';

  @override
  String get catWorkshop => 'Atölye';

  @override
  String get creditsTitle => 'Proje ekibi';

  @override
  String get creditsDeveloper => 'Aperion Team tarafından geliştirilmiştir.';

  @override
  String get creditsSchool =>
      'Hüseyin Girenes Fen Lisesi öğrencileri tarafından oluşturulan bir TÜBİTAK projesidir.';

  @override
  String get dataSourcesTitle => 'Veri kaynakları';

  @override
  String get dataSourcesBody =>
      'Etkinlikler ve kurslar Alanya Belediyesi, Antalya Büyükşehir Belediyesi (etkinlikler, ATABEM ve ATASEM kursları) ve Antalya Devlet Opera ve Balesi\'nin resmi sitelerinden düzenli olarak otomatik alınır.';

  @override
  String get source => 'Kaynak';

  @override
  String get openSource => 'Kaynakta görüntüle';

  @override
  String lastUpdated(String date) {
    return 'Son güncelleme: $date';
  }

  @override
  String eventsHere(int count) {
    return 'Bu konumda $count kayıt';
  }

  @override
  String get onboardingTitle => 'Seni tanıyalım';

  @override
  String get onboardingSubtitle =>
      'Birkaç kısa soruyla sana uygun etkinlik ve kursları önerelim.';

  @override
  String stepOf(int current, int total) {
    return '$current/$total';
  }

  @override
  String get qKinds => 'Neye katılmak istersin?';

  @override
  String get kindsEventsDesc =>
      'Konser, tiyatro, festival gibi tek seferlik etkinlikler';

  @override
  String get kindsCoursesDesc => 'Düzenli devam eden kurs ve atölyeler';

  @override
  String get kindsBoth => 'İkisi de';

  @override
  String get qTime => 'Genelde ne zaman müsaitsin?';

  @override
  String get qTimeHint => 'Birden fazla seçebilirsin.';

  @override
  String get timeWeekdayDay => 'Hafta içi gündüz';

  @override
  String get timeWeekdayEvening => 'Hafta içi akşam';

  @override
  String get timeWeekend => 'Hafta sonu';

  @override
  String get qBudget => 'Bütçe tercihin?';

  @override
  String get budgetFreeOnly => 'Sadece ücretsiz';

  @override
  String get budgetAny => 'Ücretli de olur';

  @override
  String get qCompany => 'Kiminle katılırsın?';

  @override
  String get companyAdults => 'Yalnız veya arkadaşlarla';

  @override
  String get companyKids => 'Çocuğumla / ailemle';

  @override
  String get qArea => 'Nerede yaşıyorsun?';

  @override
  String get qAreaHint => 'Sana yakın olanları öne çıkarırız.';

  @override
  String get areaAny => 'Fark etmez';

  @override
  String get next => 'Devam';

  @override
  String get back => 'Geri';

  @override
  String get finish => 'Bitir';

  @override
  String get myPreferences => 'Tercihlerim';

  @override
  String get editPreferences => 'Düzenle';

  @override
  String reasonInterest(String category) {
    return 'İlgi alanın: $category';
  }

  @override
  String get reasonFavorites => 'Favorilerine benzer';

  @override
  String reasonNear(String km) {
    return 'Sana yakın · $km km';
  }

  @override
  String get reasonTime => 'Müsait olduğun zaman';

  @override
  String get reasonKids => 'Çocuklara uygun';

  @override
  String get reasonSoon => 'Yakında';

  @override
  String get forYouEmpty => 'Önerileri görmek için tercihlerini belirle.';
}
