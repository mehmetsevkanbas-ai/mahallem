// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Mahallem';

  @override
  String get appTagline => 'Культурная карта Алании';

  @override
  String get navMap => 'Карта';

  @override
  String get navEvents => 'Обзор';

  @override
  String get navAdd => 'Добавить';

  @override
  String get navProfile => 'Профиль';

  @override
  String get searchHint => 'Поиск событий, мест или курсов';

  @override
  String get filterAll => 'Все';

  @override
  String get kindEvents => 'События';

  @override
  String get kindCourses => 'Курсы';

  @override
  String get kindEvent => 'Событие';

  @override
  String get kindCourse => 'Курс';

  @override
  String get dateAny => 'Любое время';

  @override
  String get dateToday => 'Сегодня';

  @override
  String get dateThisWeek => 'На этой неделе';

  @override
  String get dateWeekend => 'Выходные';

  @override
  String get dateThisMonth => 'В этом месяце';

  @override
  String get forYou => 'Для вас';

  @override
  String get forYouSubtitle => 'Подобрано по вашим интересам';

  @override
  String get upcomingEvents => 'Ближайшие события';

  @override
  String get allEvents => 'Все события и курсы';

  @override
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count результата',
      many: '$count результатов',
      few: '$count результата',
      one: '$count результат',
      zero: 'Нет результатов',
    );
    return '$_temp0';
  }

  @override
  String get noResults => 'Нет событий, подходящих под фильтры.';

  @override
  String get clearFilters => 'Сбросить фильтры';

  @override
  String get free => 'Бесплатно';

  @override
  String get ongoingCourse => 'Текущий курс';

  @override
  String todayAt(String time) {
    return 'Сегодня $time';
  }

  @override
  String tomorrowAt(String time) {
    return 'Завтра $time';
  }

  @override
  String untilDate(String date) {
    return 'До $date';
  }

  @override
  String startsOn(String date) {
    return 'Начало: $date';
  }

  @override
  String get seeDetails => 'Подробнее';

  @override
  String get getDirections => 'Проложить маршрут';

  @override
  String get location => 'Место';

  @override
  String get dateTime => 'Дата и время';

  @override
  String get schedule => 'Расписание';

  @override
  String get price => 'Цена';

  @override
  String get organizer => 'Организатор';

  @override
  String get contact => 'Контакты';

  @override
  String get about => 'Описание';

  @override
  String get addToFavorites => 'В избранное';

  @override
  String get removeFromFavorites => 'Убрать из избранного';

  @override
  String get favorites => 'Избранное';

  @override
  String get myEvents => 'Мои события';

  @override
  String get statusPending => 'На проверке';

  @override
  String get statusApproved => 'Опубликовано';

  @override
  String get statusRejected => 'Отклонено';

  @override
  String get loginRequiredFavorite => 'Войдите, чтобы добавлять в избранное';

  @override
  String get signIn => 'Войти';

  @override
  String get signUp => 'Регистрация';

  @override
  String get signOut => 'Выйти';

  @override
  String get email => 'Эл. почта';

  @override
  String get password => 'Пароль';

  @override
  String get displayName => 'Имя и фамилия';

  @override
  String get forgotPassword => 'Забыли пароль?';

  @override
  String get resetEmailSent =>
      'Ссылка для сброса пароля отправлена на вашу почту.';

  @override
  String get confirmEmailSent =>
      'Регистрация завершена! Подтвердите аккаунт по ссылке в письме, затем войдите.';

  @override
  String get authWelcome => 'Добро пожаловать в Mahallem';

  @override
  String get authSubtitle =>
      'Сохраняйте события, получайте рекомендации по интересам и добавляйте свои события.';

  @override
  String get errorInvalidEmail => 'Введите корректный адрес почты';

  @override
  String get errorPasswordShort => 'Пароль должен быть не короче 6 символов';

  @override
  String get errorRequired => 'Обязательное поле';

  @override
  String errorGeneric(String message) {
    return 'Произошла ошибка: $message';
  }

  @override
  String get retry => 'Повторить';

  @override
  String get interestsTitle => 'Что вам интересно?';

  @override
  String get interestsSubtitle => 'Мы подберём события по вашему выбору.';

  @override
  String get interestsSave => 'Сохранить и продолжить';

  @override
  String get interestsSkip => 'Пропустить';

  @override
  String get editInterests => 'Изменить интересы';

  @override
  String get myInterests => 'Мои интересы';

  @override
  String get noInterests => 'Вы ещё не выбрали интересы.';

  @override
  String get addEventTitle => 'Добавить событие';

  @override
  String get addEventSubtitle =>
      'Концерты, театр, музыка на пляже, курсы живописи... Внесите вклад в культурную жизнь города.';

  @override
  String get fieldTitle => 'Название';

  @override
  String get fieldDescription => 'Описание';

  @override
  String get fieldCategory => 'Категория';

  @override
  String get fieldKind => 'Тип';

  @override
  String get fieldStart => 'Начало';

  @override
  String get fieldEnd => 'Окончание (необязательно)';

  @override
  String get fieldSchedule => 'Расписание курса';

  @override
  String get fieldScheduleHint => 'Напр. каждый вторник и четверг 19:00-21:00';

  @override
  String get fieldVenue => 'Название места';

  @override
  String get fieldAddress => 'Адрес';

  @override
  String get fieldPrice => 'Цена';

  @override
  String get fieldPriceHint => 'Напр. 250 ₺';

  @override
  String get fieldIsFree => 'Бесплатно';

  @override
  String get fieldOrganizer => 'Организатор';

  @override
  String get fieldContact => 'Контакты (телефон, сайт, Instagram)';

  @override
  String get pickLocation => 'Место';

  @override
  String get pickLocationHint => 'Нажмите на карте место проведения';

  @override
  String get locationRequired => 'Пожалуйста, выберите место на карте';

  @override
  String get startRequired => 'Пожалуйста, выберите дату начала';

  @override
  String get addImage => 'Добавить фото';

  @override
  String get changeImage => 'Заменить фото';

  @override
  String get removeImage => 'Удалить фото';

  @override
  String get submitEvent => 'Отправить на проверку';

  @override
  String get submitSuccessTitle => 'Спасибо!';

  @override
  String get submitSuccessBody =>
      'Событие появится на карте после проверки администратором.';

  @override
  String get ok => 'ОК';

  @override
  String get cancel => 'Отмена';

  @override
  String get selectDate => 'Выберите дату';

  @override
  String get adminPanel => 'Панель администратора';

  @override
  String get adminPendingTitle => 'События на проверке';

  @override
  String get adminNoPending => 'Нет событий на проверке.';

  @override
  String get approve => 'Одобрить';

  @override
  String get reject => 'Отклонить';

  @override
  String get eventApproved => 'Событие одобрено';

  @override
  String get eventRejected => 'Событие отклонено';

  @override
  String get delete => 'Удалить';

  @override
  String get language => 'Язык';

  @override
  String get theme => 'Тема';

  @override
  String get themeSystem => 'Системная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get guestTitle => 'Создайте аккаунт';

  @override
  String get guestBody =>
      'Войдите, чтобы сохранять избранное, получать рекомендации и добавлять события.';

  @override
  String get demoModeBanner =>
      'Локальный режим: события показаны по последним данным с сайтов муниципалитетов. Аккаунты и добавленные события хранятся только в этой сессии; для постоянного хранения нужно подключение Supabase.';

  @override
  String get demoAdminHint =>
      'Локальный режим: аккаунты с \"admin\" в адресе почты становятся администраторами.';

  @override
  String get noFavorites => 'У вас пока нет избранных событий.';

  @override
  String get noMyEvents => 'Вы ещё не добавили ни одного события.';

  @override
  String get eventNotFound => 'Событие не найдено.';

  @override
  String get recenterMap => 'Вернуться к Алании';

  @override
  String get categories => 'Категории';

  @override
  String get viewOnMap => 'Показать на карте';

  @override
  String pendingCount(int count) {
    return 'На проверке: $count';
  }

  @override
  String get settings => 'Настройки';

  @override
  String get aboutApp =>
      'Mahallem — проект TÜBİTAK, объединяющий культурные события Алании на одной карте.';

  @override
  String get catMusic => 'Музыка';

  @override
  String get catTheatre => 'Театр';

  @override
  String get catArt => 'Живопись и искусство';

  @override
  String get catDance => 'Танцы';

  @override
  String get catCinema => 'Кино';

  @override
  String get catLiterature => 'Литература';

  @override
  String get catFestival => 'Фестиваль';

  @override
  String get catOutdoor => 'На открытом воздухе';

  @override
  String get catWorkshop => 'Мастер-класс';

  @override
  String get creditsTitle => 'Команда проекта';

  @override
  String get creditsDeveloper => 'Разработано командой Aperion Team.';

  @override
  String get creditsSchool =>
      'Проект TÜBİTAK, созданный учениками научного лицея имени Хюсейна Гиренеса (Hüseyin Girenes Fen Lisesi).';

  @override
  String get dataSourcesTitle => 'Источники данных';

  @override
  String get dataSourcesBody =>
      'События и курсы регулярно и автоматически загружаются с официальных сайтов муниципалитета Алании, муниципалитета Большой Анталии (события, курсы ATABEM и ATASEM) и Государственного театра оперы и балета Анталии.';

  @override
  String get source => 'Источник';

  @override
  String get openSource => 'Открыть источник';

  @override
  String lastUpdated(String date) {
    return 'Обновлено: $date';
  }

  @override
  String eventsHere(int count) {
    return 'Здесь записей: $count';
  }

  @override
  String get onboardingTitle => 'Давайте познакомимся';

  @override
  String get onboardingSubtitle =>
      'Несколько коротких вопросов, чтобы подобрать подходящие вам события и курсы.';

  @override
  String stepOf(int current, int total) {
    return '$current/$total';
  }

  @override
  String get qKinds => 'В чём вы хотите участвовать?';

  @override
  String get kindsEventsDesc =>
      'Разовые события: концерты, спектакли, фестивали';

  @override
  String get kindsCoursesDesc => 'Регулярные курсы и мастерские';

  @override
  String get kindsBoth => 'И то, и другое';

  @override
  String get qTime => 'Когда вы обычно свободны?';

  @override
  String get qTimeHint => 'Можно выбрать несколько.';

  @override
  String get timeWeekdayDay => 'Будни днём';

  @override
  String get timeWeekdayEvening => 'Будни вечером';

  @override
  String get timeWeekend => 'Выходные';

  @override
  String get qBudget => 'Ваш бюджет?';

  @override
  String get budgetFreeOnly => 'Только бесплатно';

  @override
  String get budgetAny => 'Можно и платно';

  @override
  String get qCompany => 'С кем вы обычно ходите?';

  @override
  String get companyAdults => 'Один или с друзьями';

  @override
  String get companyKids => 'С детьми / семьёй';

  @override
  String get qArea => 'Где вы живёте?';

  @override
  String get qAreaHint => 'Мы покажем ближайшие варианты первыми.';

  @override
  String get areaAny => 'Неважно';

  @override
  String get next => 'Далее';

  @override
  String get back => 'Назад';

  @override
  String get finish => 'Готово';

  @override
  String get myPreferences => 'Мои предпочтения';

  @override
  String get editPreferences => 'Изменить';

  @override
  String reasonInterest(String category) {
    return 'Ваш интерес: $category';
  }

  @override
  String get reasonFavorites => 'Похоже на избранное';

  @override
  String reasonNear(String km) {
    return 'Рядом · $km км';
  }

  @override
  String get reasonTime => 'Когда вы свободны';

  @override
  String get reasonKids => 'Подходит детям';

  @override
  String get reasonSoon => 'Скоро';

  @override
  String get forYouEmpty => 'Укажите предпочтения, чтобы увидеть рекомендации.';
}
