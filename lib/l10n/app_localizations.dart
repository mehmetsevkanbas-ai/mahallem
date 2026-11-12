import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('ru'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In tr, this message translates to:
  /// **'Mahallem'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In tr, this message translates to:
  /// **'Alanya\'nın kültür haritası'**
  String get appTagline;

  /// No description provided for @navMap.
  ///
  /// In tr, this message translates to:
  /// **'Harita'**
  String get navMap;

  /// No description provided for @navEvents.
  ///
  /// In tr, this message translates to:
  /// **'Keşfet'**
  String get navEvents;

  /// No description provided for @navAdd.
  ///
  /// In tr, this message translates to:
  /// **'Ekle'**
  String get navAdd;

  /// No description provided for @navProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// No description provided for @searchHint.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik, mekan veya kurs ara'**
  String get searchHint;

  /// No description provided for @filterAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get filterAll;

  /// No description provided for @kindEvents.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlikler'**
  String get kindEvents;

  /// No description provided for @kindCourses.
  ///
  /// In tr, this message translates to:
  /// **'Kurslar'**
  String get kindCourses;

  /// No description provided for @kindEvent.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik'**
  String get kindEvent;

  /// No description provided for @kindCourse.
  ///
  /// In tr, this message translates to:
  /// **'Kurs'**
  String get kindCourse;

  /// No description provided for @dateAny.
  ///
  /// In tr, this message translates to:
  /// **'Her zaman'**
  String get dateAny;

  /// No description provided for @dateToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get dateToday;

  /// No description provided for @dateThisWeek.
  ///
  /// In tr, this message translates to:
  /// **'Bu hafta'**
  String get dateThisWeek;

  /// No description provided for @dateWeekend.
  ///
  /// In tr, this message translates to:
  /// **'Hafta sonu'**
  String get dateWeekend;

  /// No description provided for @dateThisMonth.
  ///
  /// In tr, this message translates to:
  /// **'Bu ay'**
  String get dateThisMonth;

  /// No description provided for @forYou.
  ///
  /// In tr, this message translates to:
  /// **'Senin için'**
  String get forYou;

  /// No description provided for @forYouSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'İlgi alanlarına göre seçtiklerimiz'**
  String get forYouSubtitle;

  /// No description provided for @upcomingEvents.
  ///
  /// In tr, this message translates to:
  /// **'Yaklaşan etkinlikler'**
  String get upcomingEvents;

  /// No description provided for @allEvents.
  ///
  /// In tr, this message translates to:
  /// **'Tüm etkinlik ve kurslar'**
  String get allEvents;

  /// No description provided for @resultsCount.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =0{Sonuç yok} other{{count} sonuç}}'**
  String resultsCount(int count);

  /// No description provided for @noResults.
  ///
  /// In tr, this message translates to:
  /// **'Bu filtrelere uygun etkinlik bulunamadı.'**
  String get noResults;

  /// No description provided for @clearFilters.
  ///
  /// In tr, this message translates to:
  /// **'Filtreleri temizle'**
  String get clearFilters;

  /// No description provided for @free.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz'**
  String get free;

  /// No description provided for @ongoingCourse.
  ///
  /// In tr, this message translates to:
  /// **'Devam eden kurs'**
  String get ongoingCourse;

  /// No description provided for @todayAt.
  ///
  /// In tr, this message translates to:
  /// **'Bugün {time}'**
  String todayAt(String time);

  /// No description provided for @tomorrowAt.
  ///
  /// In tr, this message translates to:
  /// **'Yarın {time}'**
  String tomorrowAt(String time);

  /// No description provided for @untilDate.
  ///
  /// In tr, this message translates to:
  /// **'{date} tarihine kadar'**
  String untilDate(String date);

  /// No description provided for @startsOn.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç: {date}'**
  String startsOn(String date);

  /// No description provided for @seeDetails.
  ///
  /// In tr, this message translates to:
  /// **'Detaylar'**
  String get seeDetails;

  /// No description provided for @getDirections.
  ///
  /// In tr, this message translates to:
  /// **'Yol tarifi al'**
  String get getDirections;

  /// No description provided for @location.
  ///
  /// In tr, this message translates to:
  /// **'Konum'**
  String get location;

  /// No description provided for @dateTime.
  ///
  /// In tr, this message translates to:
  /// **'Tarih ve saat'**
  String get dateTime;

  /// No description provided for @schedule.
  ///
  /// In tr, this message translates to:
  /// **'Program'**
  String get schedule;

  /// No description provided for @price.
  ///
  /// In tr, this message translates to:
  /// **'Ücret'**
  String get price;

  /// No description provided for @organizer.
  ///
  /// In tr, this message translates to:
  /// **'Düzenleyen'**
  String get organizer;

  /// No description provided for @contact.
  ///
  /// In tr, this message translates to:
  /// **'İletişim'**
  String get contact;

  /// No description provided for @about.
  ///
  /// In tr, this message translates to:
  /// **'Hakkında'**
  String get about;

  /// No description provided for @addToFavorites.
  ///
  /// In tr, this message translates to:
  /// **'Favorilere ekle'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In tr, this message translates to:
  /// **'Favorilerden çıkar'**
  String get removeFromFavorites;

  /// No description provided for @favorites.
  ///
  /// In tr, this message translates to:
  /// **'Favorilerim'**
  String get favorites;

  /// No description provided for @myEvents.
  ///
  /// In tr, this message translates to:
  /// **'Eklediğim etkinlikler'**
  String get myEvents;

  /// No description provided for @statusPending.
  ///
  /// In tr, this message translates to:
  /// **'Onay bekliyor'**
  String get statusPending;

  /// No description provided for @statusApproved.
  ///
  /// In tr, this message translates to:
  /// **'Yayında'**
  String get statusApproved;

  /// No description provided for @statusRejected.
  ///
  /// In tr, this message translates to:
  /// **'Reddedildi'**
  String get statusRejected;

  /// No description provided for @loginRequiredFavorite.
  ///
  /// In tr, this message translates to:
  /// **'Favorilere eklemek için giriş yap'**
  String get loginRequiredFavorite;

  /// No description provided for @signIn.
  ///
  /// In tr, this message translates to:
  /// **'Giriş yap'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt ol'**
  String get signUp;

  /// No description provided for @signOut.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış yap'**
  String get signOut;

  /// No description provided for @email.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get email;

  /// No description provided for @password.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get password;

  /// No description provided for @displayName.
  ///
  /// In tr, this message translates to:
  /// **'Ad Soyad'**
  String get displayName;

  /// No description provided for @forgotPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifremi unuttum'**
  String get forgotPassword;

  /// No description provided for @resetEmailSent.
  ///
  /// In tr, this message translates to:
  /// **'Şifre sıfırlama bağlantısı e-postana gönderildi.'**
  String get resetEmailSent;

  /// No description provided for @confirmEmailSent.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt tamamlandı! Hesabını doğrulamak için e-postanı kontrol et, ardından giriş yap.'**
  String get confirmEmailSent;

  /// No description provided for @authWelcome.
  ///
  /// In tr, this message translates to:
  /// **'Mahallem\'e hoş geldin'**
  String get authWelcome;

  /// No description provided for @authSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlikleri kaydet, ilgi alanlarına göre öneriler al ve kendi etkinliğini ekle.'**
  String get authSubtitle;

  /// No description provided for @errorInvalidEmail.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir e-posta gir'**
  String get errorInvalidEmail;

  /// No description provided for @errorPasswordShort.
  ///
  /// In tr, this message translates to:
  /// **'Şifre en az 6 karakter olmalı'**
  String get errorPasswordShort;

  /// No description provided for @errorRequired.
  ///
  /// In tr, this message translates to:
  /// **'Bu alan zorunlu'**
  String get errorRequired;

  /// No description provided for @errorGeneric.
  ///
  /// In tr, this message translates to:
  /// **'Bir hata oluştu: {message}'**
  String errorGeneric(String message);

  /// No description provided for @retry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get retry;

  /// No description provided for @interestsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Neler ilgini çekiyor?'**
  String get interestsTitle;

  /// No description provided for @interestsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Seçimlerine göre sana özel etkinlikler gösterelim.'**
  String get interestsSubtitle;

  /// No description provided for @interestsSave.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet ve devam et'**
  String get interestsSave;

  /// No description provided for @interestsSkip.
  ///
  /// In tr, this message translates to:
  /// **'Şimdilik geç'**
  String get interestsSkip;

  /// No description provided for @editInterests.
  ///
  /// In tr, this message translates to:
  /// **'İlgi alanlarını düzenle'**
  String get editInterests;

  /// No description provided for @myInterests.
  ///
  /// In tr, this message translates to:
  /// **'İlgi alanlarım'**
  String get myInterests;

  /// No description provided for @noInterests.
  ///
  /// In tr, this message translates to:
  /// **'Henüz ilgi alanı seçmedin.'**
  String get noInterests;

  /// No description provided for @addEventTitle.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik ekle'**
  String get addEventTitle;

  /// No description provided for @addEventSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Konser, tiyatro, sahilde müzik, resim kursu... Şehrin kültür hayatına katkıda bulun.'**
  String get addEventSubtitle;

  /// No description provided for @fieldTitle.
  ///
  /// In tr, this message translates to:
  /// **'Başlık'**
  String get fieldTitle;

  /// No description provided for @fieldDescription.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama'**
  String get fieldDescription;

  /// No description provided for @fieldCategory.
  ///
  /// In tr, this message translates to:
  /// **'Kategori'**
  String get fieldCategory;

  /// No description provided for @fieldKind.
  ///
  /// In tr, this message translates to:
  /// **'Tür'**
  String get fieldKind;

  /// No description provided for @fieldStart.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç'**
  String get fieldStart;

  /// No description provided for @fieldEnd.
  ///
  /// In tr, this message translates to:
  /// **'Bitiş (isteğe bağlı)'**
  String get fieldEnd;

  /// No description provided for @fieldSchedule.
  ///
  /// In tr, this message translates to:
  /// **'Kurs programı'**
  String get fieldSchedule;

  /// No description provided for @fieldScheduleHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn. Her Salı ve Perşembe 19:00-21:00'**
  String get fieldScheduleHint;

  /// No description provided for @fieldVenue.
  ///
  /// In tr, this message translates to:
  /// **'Mekan adı'**
  String get fieldVenue;

  /// No description provided for @fieldAddress.
  ///
  /// In tr, this message translates to:
  /// **'Adres'**
  String get fieldAddress;

  /// No description provided for @fieldPrice.
  ///
  /// In tr, this message translates to:
  /// **'Ücret'**
  String get fieldPrice;

  /// No description provided for @fieldPriceHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn. 250 ₺'**
  String get fieldPriceHint;

  /// No description provided for @fieldIsFree.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz'**
  String get fieldIsFree;

  /// No description provided for @fieldOrganizer.
  ///
  /// In tr, this message translates to:
  /// **'Düzenleyen'**
  String get fieldOrganizer;

  /// No description provided for @fieldContact.
  ///
  /// In tr, this message translates to:
  /// **'İletişim (telefon, web, Instagram)'**
  String get fieldContact;

  /// No description provided for @pickLocation.
  ///
  /// In tr, this message translates to:
  /// **'Konum'**
  String get pickLocation;

  /// No description provided for @pickLocationHint.
  ///
  /// In tr, this message translates to:
  /// **'Etkinliğin yapılacağı yere haritada dokun'**
  String get pickLocationHint;

  /// No description provided for @locationRequired.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen haritadan konum seç'**
  String get locationRequired;

  /// No description provided for @startRequired.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen başlangıç tarihini seç'**
  String get startRequired;

  /// No description provided for @addImage.
  ///
  /// In tr, this message translates to:
  /// **'Görsel ekle'**
  String get addImage;

  /// No description provided for @changeImage.
  ///
  /// In tr, this message translates to:
  /// **'Görseli değiştir'**
  String get changeImage;

  /// No description provided for @removeImage.
  ///
  /// In tr, this message translates to:
  /// **'Görseli kaldır'**
  String get removeImage;

  /// No description provided for @submitEvent.
  ///
  /// In tr, this message translates to:
  /// **'Onaya gönder'**
  String get submitEvent;

  /// No description provided for @submitSuccessTitle.
  ///
  /// In tr, this message translates to:
  /// **'Teşekkürler!'**
  String get submitSuccessTitle;

  /// No description provided for @submitSuccessBody.
  ///
  /// In tr, this message translates to:
  /// **'Etkinliğin yönetici onayından sonra haritada yayınlanacak.'**
  String get submitSuccessBody;

  /// No description provided for @ok.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get cancel;

  /// No description provided for @selectDate.
  ///
  /// In tr, this message translates to:
  /// **'Tarih seç'**
  String get selectDate;

  /// No description provided for @adminPanel.
  ///
  /// In tr, this message translates to:
  /// **'Yönetici paneli'**
  String get adminPanel;

  /// No description provided for @adminPendingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Onay bekleyen etkinlikler'**
  String get adminPendingTitle;

  /// No description provided for @adminNoPending.
  ///
  /// In tr, this message translates to:
  /// **'Onay bekleyen etkinlik yok.'**
  String get adminNoPending;

  /// No description provided for @approve.
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In tr, this message translates to:
  /// **'Reddet'**
  String get reject;

  /// No description provided for @eventApproved.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik onaylandı'**
  String get eventApproved;

  /// No description provided for @eventRejected.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik reddedildi'**
  String get eventRejected;

  /// No description provided for @delete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get delete;

  /// No description provided for @language.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In tr, this message translates to:
  /// **'Tema'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In tr, this message translates to:
  /// **'Sistem'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In tr, this message translates to:
  /// **'Koyu'**
  String get themeDark;

  /// No description provided for @guestTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesabını oluştur'**
  String get guestTitle;

  /// No description provided for @guestBody.
  ///
  /// In tr, this message translates to:
  /// **'Favorilerini kaydetmek, kişisel öneriler almak ve etkinlik eklemek için giriş yap.'**
  String get guestBody;

  /// No description provided for @demoModeBanner.
  ///
  /// In tr, this message translates to:
  /// **'Yerel mod: etkinlikler belediye sitelerinden alınan son veriyle gösteriliyor. Hesaplar ve eklenen etkinlikler yalnızca bu oturumda tutulur; kalıcı kayıt için Supabase bağlantısı gerekir.'**
  String get demoModeBanner;

  /// No description provided for @demoAdminHint.
  ///
  /// In tr, this message translates to:
  /// **'Yerel mod: e-postasında \"admin\" geçen hesaplar yönetici olur.'**
  String get demoAdminHint;

  /// No description provided for @noFavorites.
  ///
  /// In tr, this message translates to:
  /// **'Henüz favori etkinliğin yok.'**
  String get noFavorites;

  /// No description provided for @noMyEvents.
  ///
  /// In tr, this message translates to:
  /// **'Henüz etkinlik eklemedin.'**
  String get noMyEvents;

  /// No description provided for @eventNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlik bulunamadı.'**
  String get eventNotFound;

  /// No description provided for @recenterMap.
  ///
  /// In tr, this message translates to:
  /// **'Alanya\'ya dön'**
  String get recenterMap;

  /// No description provided for @categories.
  ///
  /// In tr, this message translates to:
  /// **'Kategoriler'**
  String get categories;

  /// No description provided for @viewOnMap.
  ///
  /// In tr, this message translates to:
  /// **'Haritada göster'**
  String get viewOnMap;

  /// No description provided for @pendingCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} bekleyen'**
  String pendingCount(int count);

  /// No description provided for @settings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settings;

  /// No description provided for @aboutApp.
  ///
  /// In tr, this message translates to:
  /// **'Mahallem, Alanya\'daki kültür ve sanat etkinliklerini tek bir haritada buluşturan bir TÜBİTAK projesidir.'**
  String get aboutApp;

  /// No description provided for @catMusic.
  ///
  /// In tr, this message translates to:
  /// **'Müzik'**
  String get catMusic;

  /// No description provided for @catTheatre.
  ///
  /// In tr, this message translates to:
  /// **'Tiyatro'**
  String get catTheatre;

  /// No description provided for @catArt.
  ///
  /// In tr, this message translates to:
  /// **'Resim & Sanat'**
  String get catArt;

  /// No description provided for @catDance.
  ///
  /// In tr, this message translates to:
  /// **'Dans'**
  String get catDance;

  /// No description provided for @catCinema.
  ///
  /// In tr, this message translates to:
  /// **'Sinema'**
  String get catCinema;

  /// No description provided for @catLiterature.
  ///
  /// In tr, this message translates to:
  /// **'Edebiyat'**
  String get catLiterature;

  /// No description provided for @catFestival.
  ///
  /// In tr, this message translates to:
  /// **'Festival'**
  String get catFestival;

  /// No description provided for @catOutdoor.
  ///
  /// In tr, this message translates to:
  /// **'Açık hava'**
  String get catOutdoor;

  /// No description provided for @catWorkshop.
  ///
  /// In tr, this message translates to:
  /// **'Atölye'**
  String get catWorkshop;

  /// No description provided for @creditsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Proje ekibi'**
  String get creditsTitle;

  /// No description provided for @creditsDeveloper.
  ///
  /// In tr, this message translates to:
  /// **'Aperion Team tarafından geliştirilmiştir.'**
  String get creditsDeveloper;

  /// No description provided for @creditsSchool.
  ///
  /// In tr, this message translates to:
  /// **'Hüseyin Girenes Fen Lisesi öğrencileri tarafından oluşturulan bir TÜBİTAK projesidir.'**
  String get creditsSchool;

  /// No description provided for @dataSourcesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Veri kaynakları'**
  String get dataSourcesTitle;

  /// No description provided for @dataSourcesBody.
  ///
  /// In tr, this message translates to:
  /// **'Etkinlikler ve kurslar Alanya Belediyesi, Antalya Büyükşehir Belediyesi (etkinlikler, ATABEM ve ATASEM kursları) ve Antalya Devlet Opera ve Balesi\'nin resmi sitelerinden düzenli olarak otomatik alınır.'**
  String get dataSourcesBody;

  /// No description provided for @source.
  ///
  /// In tr, this message translates to:
  /// **'Kaynak'**
  String get source;

  /// No description provided for @openSource.
  ///
  /// In tr, this message translates to:
  /// **'Kaynakta görüntüle'**
  String get openSource;

  /// No description provided for @lastUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Son güncelleme: {date}'**
  String lastUpdated(String date);

  /// No description provided for @eventsHere.
  ///
  /// In tr, this message translates to:
  /// **'Bu konumda {count} kayıt'**
  String eventsHere(int count);

  /// No description provided for @onboardingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Seni tanıyalım'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Birkaç kısa soruyla sana uygun etkinlik ve kursları önerelim.'**
  String get onboardingSubtitle;

  /// No description provided for @stepOf.
  ///
  /// In tr, this message translates to:
  /// **'{current}/{total}'**
  String stepOf(int current, int total);

  /// No description provided for @qKinds.
  ///
  /// In tr, this message translates to:
  /// **'Neye katılmak istersin?'**
  String get qKinds;

  /// No description provided for @kindsEventsDesc.
  ///
  /// In tr, this message translates to:
  /// **'Konser, tiyatro, festival gibi tek seferlik etkinlikler'**
  String get kindsEventsDesc;

  /// No description provided for @kindsCoursesDesc.
  ///
  /// In tr, this message translates to:
  /// **'Düzenli devam eden kurs ve atölyeler'**
  String get kindsCoursesDesc;

  /// No description provided for @kindsBoth.
  ///
  /// In tr, this message translates to:
  /// **'İkisi de'**
  String get kindsBoth;

  /// No description provided for @qTime.
  ///
  /// In tr, this message translates to:
  /// **'Genelde ne zaman müsaitsin?'**
  String get qTime;

  /// No description provided for @qTimeHint.
  ///
  /// In tr, this message translates to:
  /// **'Birden fazla seçebilirsin.'**
  String get qTimeHint;

  /// No description provided for @timeWeekdayDay.
  ///
  /// In tr, this message translates to:
  /// **'Hafta içi gündüz'**
  String get timeWeekdayDay;

  /// No description provided for @timeWeekdayEvening.
  ///
  /// In tr, this message translates to:
  /// **'Hafta içi akşam'**
  String get timeWeekdayEvening;

  /// No description provided for @timeWeekend.
  ///
  /// In tr, this message translates to:
  /// **'Hafta sonu'**
  String get timeWeekend;

  /// No description provided for @qBudget.
  ///
  /// In tr, this message translates to:
  /// **'Bütçe tercihin?'**
  String get qBudget;

  /// No description provided for @budgetFreeOnly.
  ///
  /// In tr, this message translates to:
  /// **'Sadece ücretsiz'**
  String get budgetFreeOnly;

  /// No description provided for @budgetAny.
  ///
  /// In tr, this message translates to:
  /// **'Ücretli de olur'**
  String get budgetAny;

  /// No description provided for @qCompany.
  ///
  /// In tr, this message translates to:
  /// **'Kiminle katılırsın?'**
  String get qCompany;

  /// No description provided for @companyAdults.
  ///
  /// In tr, this message translates to:
  /// **'Yalnız veya arkadaşlarla'**
  String get companyAdults;

  /// No description provided for @companyKids.
  ///
  /// In tr, this message translates to:
  /// **'Çocuğumla / ailemle'**
  String get companyKids;

  /// No description provided for @qArea.
  ///
  /// In tr, this message translates to:
  /// **'Nerede yaşıyorsun?'**
  String get qArea;

  /// No description provided for @qAreaHint.
  ///
  /// In tr, this message translates to:
  /// **'Sana yakın olanları öne çıkarırız.'**
  String get qAreaHint;

  /// No description provided for @areaAny.
  ///
  /// In tr, this message translates to:
  /// **'Fark etmez'**
  String get areaAny;

  /// No description provided for @next.
  ///
  /// In tr, this message translates to:
  /// **'Devam'**
  String get next;

  /// No description provided for @back.
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get back;

  /// No description provided for @finish.
  ///
  /// In tr, this message translates to:
  /// **'Bitir'**
  String get finish;

  /// No description provided for @myPreferences.
  ///
  /// In tr, this message translates to:
  /// **'Tercihlerim'**
  String get myPreferences;

  /// No description provided for @editPreferences.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get editPreferences;

  /// No description provided for @reasonInterest.
  ///
  /// In tr, this message translates to:
  /// **'İlgi alanın: {category}'**
  String reasonInterest(String category);

  /// No description provided for @reasonFavorites.
  ///
  /// In tr, this message translates to:
  /// **'Favorilerine benzer'**
  String get reasonFavorites;

  /// No description provided for @reasonNear.
  ///
  /// In tr, this message translates to:
  /// **'Sana yakın · {km} km'**
  String reasonNear(String km);

  /// No description provided for @reasonTime.
  ///
  /// In tr, this message translates to:
  /// **'Müsait olduğun zaman'**
  String get reasonTime;

  /// No description provided for @reasonKids.
  ///
  /// In tr, this message translates to:
  /// **'Çocuklara uygun'**
  String get reasonKids;

  /// No description provided for @reasonSoon.
  ///
  /// In tr, this message translates to:
  /// **'Yakında'**
  String get reasonSoon;

  /// No description provided for @forYouEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Önerileri görmek için tercihlerini belirle.'**
  String get forYouEmpty;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'ru', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
