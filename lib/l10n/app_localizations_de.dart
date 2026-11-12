// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Mahallem';

  @override
  String get appTagline => 'Die Kulturkarte von Alanya';

  @override
  String get navMap => 'Karte';

  @override
  String get navEvents => 'Entdecken';

  @override
  String get navAdd => 'Hinzufügen';

  @override
  String get navProfile => 'Profil';

  @override
  String get searchHint => 'Events, Orte oder Kurse suchen';

  @override
  String get filterAll => 'Alle';

  @override
  String get kindEvents => 'Events';

  @override
  String get kindCourses => 'Kurse';

  @override
  String get kindEvent => 'Event';

  @override
  String get kindCourse => 'Kurs';

  @override
  String get dateAny => 'Jederzeit';

  @override
  String get dateToday => 'Heute';

  @override
  String get dateThisWeek => 'Diese Woche';

  @override
  String get dateWeekend => 'Wochenende';

  @override
  String get dateThisMonth => 'Diesen Monat';

  @override
  String get forYou => 'Für dich';

  @override
  String get forYouSubtitle => 'Passend zu deinen Interessen';

  @override
  String get upcomingEvents => 'Kommende Events';

  @override
  String get allEvents => 'Alle Events und Kurse';

  @override
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ergebnisse',
      one: '1 Ergebnis',
      zero: 'Keine Ergebnisse',
    );
    return '$_temp0';
  }

  @override
  String get noResults => 'Keine Events passen zu diesen Filtern.';

  @override
  String get clearFilters => 'Filter zurücksetzen';

  @override
  String get free => 'Kostenlos';

  @override
  String get ongoingCourse => 'Laufender Kurs';

  @override
  String todayAt(String time) {
    return 'Heute $time';
  }

  @override
  String tomorrowAt(String time) {
    return 'Morgen $time';
  }

  @override
  String untilDate(String date) {
    return 'Bis $date';
  }

  @override
  String startsOn(String date) {
    return 'Beginn: $date';
  }

  @override
  String get seeDetails => 'Details';

  @override
  String get getDirections => 'Route planen';

  @override
  String get location => 'Ort';

  @override
  String get dateTime => 'Datum und Uhrzeit';

  @override
  String get schedule => 'Zeitplan';

  @override
  String get price => 'Preis';

  @override
  String get organizer => 'Veranstalter';

  @override
  String get contact => 'Kontakt';

  @override
  String get about => 'Beschreibung';

  @override
  String get addToFavorites => 'Zu Favoriten hinzufügen';

  @override
  String get removeFromFavorites => 'Aus Favoriten entfernen';

  @override
  String get favorites => 'Meine Favoriten';

  @override
  String get myEvents => 'Meine Events';

  @override
  String get statusPending => 'Wartet auf Freigabe';

  @override
  String get statusApproved => 'Veröffentlicht';

  @override
  String get statusRejected => 'Abgelehnt';

  @override
  String get loginRequiredFavorite =>
      'Melde dich an, um Favoriten zu speichern';

  @override
  String get signIn => 'Anmelden';

  @override
  String get signUp => 'Registrieren';

  @override
  String get signOut => 'Abmelden';

  @override
  String get email => 'E-Mail';

  @override
  String get password => 'Passwort';

  @override
  String get displayName => 'Vor- und Nachname';

  @override
  String get forgotPassword => 'Passwort vergessen';

  @override
  String get resetEmailSent =>
      'Ein Link zum Zurücksetzen wurde an deine E-Mail gesendet.';

  @override
  String get confirmEmailSent =>
      'Registrierung abgeschlossen! Bestätige dein Konto per E-Mail und melde dich dann an.';

  @override
  String get authWelcome => 'Willkommen bei Mahallem';

  @override
  String get authSubtitle =>
      'Speichere Events, erhalte Empfehlungen nach deinen Interessen und füge eigene Events hinzu.';

  @override
  String get errorInvalidEmail => 'Gib eine gültige E-Mail ein';

  @override
  String get errorPasswordShort =>
      'Das Passwort muss mindestens 6 Zeichen haben';

  @override
  String get errorRequired => 'Pflichtfeld';

  @override
  String errorGeneric(String message) {
    return 'Ein Fehler ist aufgetreten: $message';
  }

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get interestsTitle => 'Was interessiert dich?';

  @override
  String get interestsSubtitle =>
      'Wir zeigen dir Events passend zu deiner Auswahl.';

  @override
  String get interestsSave => 'Speichern und weiter';

  @override
  String get interestsSkip => 'Später';

  @override
  String get editInterests => 'Interessen bearbeiten';

  @override
  String get myInterests => 'Meine Interessen';

  @override
  String get noInterests => 'Du hast noch keine Interessen gewählt.';

  @override
  String get addEventTitle => 'Event hinzufügen';

  @override
  String get addEventSubtitle =>
      'Konzerte, Theater, Musik am Strand, Malkurse... Gestalte das Kulturleben der Stadt mit.';

  @override
  String get fieldTitle => 'Titel';

  @override
  String get fieldDescription => 'Beschreibung';

  @override
  String get fieldCategory => 'Kategorie';

  @override
  String get fieldKind => 'Art';

  @override
  String get fieldStart => 'Beginn';

  @override
  String get fieldEnd => 'Ende (optional)';

  @override
  String get fieldSchedule => 'Kurszeiten';

  @override
  String get fieldScheduleHint =>
      'z. B. Jeden Dienstag und Donnerstag 19:00-21:00';

  @override
  String get fieldVenue => 'Name des Ortes';

  @override
  String get fieldAddress => 'Adresse';

  @override
  String get fieldPrice => 'Preis';

  @override
  String get fieldPriceHint => 'z. B. 250 ₺';

  @override
  String get fieldIsFree => 'Kostenlos';

  @override
  String get fieldOrganizer => 'Veranstalter';

  @override
  String get fieldContact => 'Kontakt (Telefon, Website, Instagram)';

  @override
  String get pickLocation => 'Ort';

  @override
  String get pickLocationHint =>
      'Tippe auf der Karte auf den Veranstaltungsort';

  @override
  String get locationRequired => 'Bitte wähle einen Ort auf der Karte';

  @override
  String get startRequired => 'Bitte wähle ein Startdatum';

  @override
  String get addImage => 'Bild hinzufügen';

  @override
  String get changeImage => 'Bild ändern';

  @override
  String get removeImage => 'Bild entfernen';

  @override
  String get submitEvent => 'Zur Freigabe senden';

  @override
  String get submitSuccessTitle => 'Danke!';

  @override
  String get submitSuccessBody =>
      'Dein Event erscheint auf der Karte, sobald ein Admin es freigibt.';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get selectDate => 'Datum wählen';

  @override
  String get adminPanel => 'Admin-Bereich';

  @override
  String get adminPendingTitle => 'Events zur Freigabe';

  @override
  String get adminNoPending => 'Keine Events warten auf Freigabe.';

  @override
  String get approve => 'Freigeben';

  @override
  String get reject => 'Ablehnen';

  @override
  String get eventApproved => 'Event freigegeben';

  @override
  String get eventRejected => 'Event abgelehnt';

  @override
  String get delete => 'Löschen';

  @override
  String get language => 'Sprache';

  @override
  String get theme => 'Design';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get guestTitle => 'Konto erstellen';

  @override
  String get guestBody =>
      'Melde dich an, um Favoriten zu speichern, persönliche Empfehlungen zu erhalten und Events hinzuzufügen.';

  @override
  String get demoModeBanner =>
      'Lokaler Modus: Veranstaltungen stammen aus den zuletzt von den Websites der Gemeinden abgerufenen Daten. Konten und hinzugefügte Events werden nur in dieser Sitzung gespeichert; für dauerhafte Speicherung ist eine Supabase-Verbindung nötig.';

  @override
  String get demoAdminHint =>
      'Lokaler Modus: Konten mit \"admin\" in der E-Mail werden Admins.';

  @override
  String get noFavorites => 'Du hast noch keine Favoriten.';

  @override
  String get noMyEvents => 'Du hast noch keine Events hinzugefügt.';

  @override
  String get eventNotFound => 'Event nicht gefunden.';

  @override
  String get recenterMap => 'Zurück nach Alanya';

  @override
  String get categories => 'Kategorien';

  @override
  String get viewOnMap => 'Auf der Karte zeigen';

  @override
  String pendingCount(int count) {
    return '$count ausstehend';
  }

  @override
  String get settings => 'Einstellungen';

  @override
  String get aboutApp =>
      'Mahallem ist ein TÜBİTAK-Projekt, das die Kultur- und Kunstveranstaltungen in Alanya auf einer Karte vereint.';

  @override
  String get catMusic => 'Musik';

  @override
  String get catTheatre => 'Theater';

  @override
  String get catArt => 'Malerei & Kunst';

  @override
  String get catDance => 'Tanz';

  @override
  String get catCinema => 'Kino';

  @override
  String get catLiterature => 'Literatur';

  @override
  String get catFestival => 'Festival';

  @override
  String get catOutdoor => 'Open Air';

  @override
  String get catWorkshop => 'Workshop';

  @override
  String get creditsTitle => 'Projektteam';

  @override
  String get creditsDeveloper => 'Entwickelt von Aperion Team.';

  @override
  String get creditsSchool =>
      'Ein TÜBİTAK-Projekt von Schülerinnen und Schülern des Hüseyin Girenes Naturwissenschaftlichen Gymnasiums (Hüseyin Girenes Fen Lisesi).';

  @override
  String get dataSourcesTitle => 'Datenquellen';

  @override
  String get dataSourcesBody =>
      'Veranstaltungen und Kurse werden regelmäßig und automatisch von den offiziellen Websites der Stadt Alanya, der Großstadtgemeinde Antalya (Events, ATABEM- und ATASEM-Kurse) und der Staatsoper und des Staatsballetts Antalya übernommen.';

  @override
  String get source => 'Quelle';

  @override
  String get openSource => 'An der Quelle ansehen';

  @override
  String lastUpdated(String date) {
    return 'Zuletzt aktualisiert: $date';
  }

  @override
  String eventsHere(int count) {
    return '$count Einträge an diesem Ort';
  }

  @override
  String get onboardingTitle => 'Lass uns dich kennenlernen';

  @override
  String get onboardingSubtitle =>
      'Ein paar kurze Fragen, damit wir dir passende Events und Kurse vorschlagen können.';

  @override
  String stepOf(int current, int total) {
    return '$current/$total';
  }

  @override
  String get qKinds => 'Woran möchtest du teilnehmen?';

  @override
  String get kindsEventsDesc =>
      'Einmalige Events wie Konzerte, Theater und Festivals';

  @override
  String get kindsCoursesDesc => 'Regelmäßige Kurse und Workshops';

  @override
  String get kindsBoth => 'Beides';

  @override
  String get qTime => 'Wann hast du meistens Zeit?';

  @override
  String get qTimeHint => 'Mehrfachauswahl möglich.';

  @override
  String get timeWeekdayDay => 'Wochentags tagsüber';

  @override
  String get timeWeekdayEvening => 'Wochentags abends';

  @override
  String get timeWeekend => 'Am Wochenende';

  @override
  String get qBudget => 'Dein Budget?';

  @override
  String get budgetFreeOnly => 'Nur kostenlos';

  @override
  String get budgetAny => 'Auch kostenpflichtig';

  @override
  String get qCompany => 'Mit wem gehst du meistens?';

  @override
  String get companyAdults => 'Allein oder mit Freunden';

  @override
  String get companyKids => 'Mit Kindern / Familie';

  @override
  String get qArea => 'Wo wohnst du?';

  @override
  String get qAreaHint => 'Wir zeigen Angebote in deiner Nähe zuerst.';

  @override
  String get areaAny => 'Egal';

  @override
  String get next => 'Weiter';

  @override
  String get back => 'Zurück';

  @override
  String get finish => 'Fertig';

  @override
  String get myPreferences => 'Meine Vorlieben';

  @override
  String get editPreferences => 'Bearbeiten';

  @override
  String reasonInterest(String category) {
    return 'Dein Interesse: $category';
  }

  @override
  String get reasonFavorites => 'Ähnlich wie deine Favoriten';

  @override
  String reasonNear(String km) {
    return 'In deiner Nähe · $km km';
  }

  @override
  String get reasonTime => 'Wenn du Zeit hast';

  @override
  String get reasonKids => 'Kinderfreundlich';

  @override
  String get reasonSoon => 'Demnächst';

  @override
  String get forYouEmpty =>
      'Lege deine Vorlieben fest, um Empfehlungen zu sehen.';
}
