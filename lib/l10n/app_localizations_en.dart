// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mahallem';

  @override
  String get appTagline => 'The cultural map of Alanya';

  @override
  String get navMap => 'Map';

  @override
  String get navEvents => 'Discover';

  @override
  String get navAdd => 'Add';

  @override
  String get navProfile => 'Profile';

  @override
  String get searchHint => 'Search events, venues or courses';

  @override
  String get filterAll => 'All';

  @override
  String get kindEvents => 'Events';

  @override
  String get kindCourses => 'Courses';

  @override
  String get kindEvent => 'Event';

  @override
  String get kindCourse => 'Course';

  @override
  String get dateAny => 'Any time';

  @override
  String get dateToday => 'Today';

  @override
  String get dateThisWeek => 'This week';

  @override
  String get dateWeekend => 'Weekend';

  @override
  String get dateThisMonth => 'This month';

  @override
  String get forYou => 'For you';

  @override
  String get forYouSubtitle => 'Picked for your interests';

  @override
  String get upcomingEvents => 'Upcoming events';

  @override
  String get allEvents => 'All events and courses';

  @override
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
      zero: 'No results',
    );
    return '$_temp0';
  }

  @override
  String get noResults => 'No events match these filters.';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get free => 'Free';

  @override
  String get ongoingCourse => 'Ongoing course';

  @override
  String todayAt(String time) {
    return 'Today $time';
  }

  @override
  String tomorrowAt(String time) {
    return 'Tomorrow $time';
  }

  @override
  String untilDate(String date) {
    return 'Until $date';
  }

  @override
  String startsOn(String date) {
    return 'Starts: $date';
  }

  @override
  String get seeDetails => 'Details';

  @override
  String get getDirections => 'Get directions';

  @override
  String get location => 'Location';

  @override
  String get dateTime => 'Date and time';

  @override
  String get schedule => 'Schedule';

  @override
  String get price => 'Price';

  @override
  String get organizer => 'Organizer';

  @override
  String get contact => 'Contact';

  @override
  String get about => 'About';

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get favorites => 'My favorites';

  @override
  String get myEvents => 'Events I added';

  @override
  String get statusPending => 'Pending approval';

  @override
  String get statusApproved => 'Published';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get loginRequiredFavorite => 'Sign in to add favorites';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Sign up';

  @override
  String get signOut => 'Sign out';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get displayName => 'Full name';

  @override
  String get forgotPassword => 'Forgot password';

  @override
  String get resetEmailSent =>
      'A password reset link has been sent to your email.';

  @override
  String get confirmEmailSent =>
      'Registration complete! Check your email to verify your account, then sign in.';

  @override
  String get authWelcome => 'Welcome to Mahallem';

  @override
  String get authSubtitle =>
      'Save events, get recommendations based on your interests and add your own events.';

  @override
  String get errorInvalidEmail => 'Enter a valid email';

  @override
  String get errorPasswordShort => 'Password must be at least 6 characters';

  @override
  String get errorRequired => 'This field is required';

  @override
  String errorGeneric(String message) {
    return 'Something went wrong: $message';
  }

  @override
  String get retry => 'Try again';

  @override
  String get interestsTitle => 'What are you interested in?';

  @override
  String get interestsSubtitle =>
      'We\'ll show you events tailored to your choices.';

  @override
  String get interestsSave => 'Save and continue';

  @override
  String get interestsSkip => 'Skip for now';

  @override
  String get editInterests => 'Edit interests';

  @override
  String get myInterests => 'My interests';

  @override
  String get noInterests => 'You haven\'t picked any interests yet.';

  @override
  String get addEventTitle => 'Add event';

  @override
  String get addEventSubtitle =>
      'Concerts, theatre, music on the beach, painting courses... Contribute to the city\'s cultural life.';

  @override
  String get fieldTitle => 'Title';

  @override
  String get fieldDescription => 'Description';

  @override
  String get fieldCategory => 'Category';

  @override
  String get fieldKind => 'Type';

  @override
  String get fieldStart => 'Start';

  @override
  String get fieldEnd => 'End (optional)';

  @override
  String get fieldSchedule => 'Course schedule';

  @override
  String get fieldScheduleHint => 'e.g. Every Tuesday and Thursday 19:00-21:00';

  @override
  String get fieldVenue => 'Venue name';

  @override
  String get fieldAddress => 'Address';

  @override
  String get fieldPrice => 'Price';

  @override
  String get fieldPriceHint => 'e.g. 250 ₺';

  @override
  String get fieldIsFree => 'Free';

  @override
  String get fieldOrganizer => 'Organizer';

  @override
  String get fieldContact => 'Contact (phone, website, Instagram)';

  @override
  String get pickLocation => 'Location';

  @override
  String get pickLocationHint => 'Tap the map where the event takes place';

  @override
  String get locationRequired => 'Please pick a location on the map';

  @override
  String get startRequired => 'Please pick a start date';

  @override
  String get addImage => 'Add image';

  @override
  String get changeImage => 'Change image';

  @override
  String get removeImage => 'Remove image';

  @override
  String get submitEvent => 'Submit for approval';

  @override
  String get submitSuccessTitle => 'Thank you!';

  @override
  String get submitSuccessBody =>
      'Your event will appear on the map once an admin approves it.';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get selectDate => 'Select date';

  @override
  String get adminPanel => 'Admin panel';

  @override
  String get adminPendingTitle => 'Events awaiting approval';

  @override
  String get adminNoPending => 'No events awaiting approval.';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Reject';

  @override
  String get eventApproved => 'Event approved';

  @override
  String get eventRejected => 'Event rejected';

  @override
  String get delete => 'Delete';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get guestTitle => 'Create your account';

  @override
  String get guestBody =>
      'Sign in to save favorites, get personal recommendations and add events.';

  @override
  String get demoModeBanner =>
      'Local mode: events are shown from the latest data collected from municipality websites. Accounts and added events are kept only for this session; a Supabase connection is needed for permanent storage.';

  @override
  String get demoAdminHint =>
      'Local mode: accounts whose email contains \"admin\" become admins.';

  @override
  String get noFavorites => 'You have no favorite events yet.';

  @override
  String get noMyEvents => 'You haven\'t added any events yet.';

  @override
  String get eventNotFound => 'Event not found.';

  @override
  String get recenterMap => 'Back to Alanya';

  @override
  String get categories => 'Categories';

  @override
  String get viewOnMap => 'Show on map';

  @override
  String pendingCount(int count) {
    return '$count pending';
  }

  @override
  String get settings => 'Settings';

  @override
  String get aboutApp =>
      'Mahallem is a TÜBİTAK project that brings the arts and culture events of Alanya together on a single map.';

  @override
  String get catMusic => 'Music';

  @override
  String get catTheatre => 'Theatre';

  @override
  String get catArt => 'Painting & Art';

  @override
  String get catDance => 'Dance';

  @override
  String get catCinema => 'Cinema';

  @override
  String get catLiterature => 'Literature';

  @override
  String get catFestival => 'Festival';

  @override
  String get catOutdoor => 'Outdoor';

  @override
  String get catWorkshop => 'Workshop';

  @override
  String get creditsTitle => 'Project team';

  @override
  String get creditsDeveloper => 'Developed by Aperion Team.';

  @override
  String get creditsSchool =>
      'A TÜBİTAK project created by students of Hüseyin Girenes Science High School.';

  @override
  String get dataSourcesTitle => 'Data sources';

  @override
  String get dataSourcesBody =>
      'Events and courses are collected automatically and regularly from the official websites of Alanya Municipality, Antalya Metropolitan Municipality (events, ATABEM and ATASEM courses) and Antalya State Opera and Ballet.';

  @override
  String get source => 'Source';

  @override
  String get openSource => 'View at source';

  @override
  String lastUpdated(String date) {
    return 'Last updated: $date';
  }

  @override
  String eventsHere(int count) {
    return '$count listings at this location';
  }

  @override
  String get onboardingTitle => 'Let us get to know you';

  @override
  String get onboardingSubtitle =>
      'A few quick questions so we can suggest events and courses that suit you.';

  @override
  String stepOf(int current, int total) {
    return '$current/$total';
  }

  @override
  String get qKinds => 'What would you like to join?';

  @override
  String get kindsEventsDesc =>
      'One-off events like concerts, plays and festivals';

  @override
  String get kindsCoursesDesc => 'Regular courses and workshops';

  @override
  String get kindsBoth => 'Both';

  @override
  String get qTime => 'When are you usually free?';

  @override
  String get qTimeHint => 'You can pick more than one.';

  @override
  String get timeWeekdayDay => 'Weekday daytime';

  @override
  String get timeWeekdayEvening => 'Weekday evenings';

  @override
  String get timeWeekend => 'Weekends';

  @override
  String get qBudget => 'Your budget?';

  @override
  String get budgetFreeOnly => 'Free only';

  @override
  String get budgetAny => 'Paid is fine too';

  @override
  String get qCompany => 'Who do you usually go with?';

  @override
  String get companyAdults => 'Alone or with friends';

  @override
  String get companyKids => 'With my kids / family';

  @override
  String get qArea => 'Where do you live?';

  @override
  String get qAreaHint => 'We\'ll put nearby options first.';

  @override
  String get areaAny => 'Doesn\'t matter';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get finish => 'Finish';

  @override
  String get myPreferences => 'My preferences';

  @override
  String get editPreferences => 'Edit';

  @override
  String reasonInterest(String category) {
    return 'Your interest: $category';
  }

  @override
  String get reasonFavorites => 'Like your favorites';

  @override
  String reasonNear(String km) {
    return 'Near you · $km km';
  }

  @override
  String get reasonTime => 'When you are free';

  @override
  String get reasonKids => 'Kid-friendly';

  @override
  String get reasonSoon => 'Coming soon';

  @override
  String get forYouEmpty => 'Set your preferences to see recommendations.';
}
