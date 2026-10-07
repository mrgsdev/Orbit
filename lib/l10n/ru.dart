// ignore_for_file: annotate_overrides
import 'strings.dart';

class Ru extends Strings {
  const Ru();

  String get locale => 'ru';
  String get languageName => 'Русский';

  String _p(int n, String one, String few, String many) {
    final m10 = n % 10, m100 = n % 100;
    if (m10 == 1 && m100 != 11) return one;
    if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return few;
    return many;
  }

  // ── Общее ──
  String get cancel => 'Отмена';
  String get done => 'Готово';
  String get save => 'Сохранить';
  String get delete => 'Удалить';
  String get add => 'Добавить';
  String get create => 'Создать';
  String get open => 'Открыть';
  String get show => 'Показать';
  String get hide => 'Скрыть';
  String get close => 'Закрыть';
  String get closeEsc => 'Закрыть (Esc)';
  String get clear => 'Очистить';
  String get copy => 'Скопировать';
  String get undo => 'Отменить';
  String get restore => 'Восстановить';
  String get edit => 'Изменить';
  String get continueAction => 'Продолжить';
  String get checking => 'Проверяем…';
  String get saving => 'Сохраняем…';
  String get creating => 'Создаём…';
  String get yes => 'Да';
  String get no => 'Нет';
  String get remove => 'Убрать';
  String get toFavorites => 'В избранное';
  String get removeFromFavorites => 'Убрать из избранного';
  String get toTrash => 'В корзину';
  String get toTrashKey => 'В корзину (⌫)';
  String get deleteForever => 'Удалить навсегда';
  String get exportCsv => 'Экспорт в CSV…';
  String contacts(int n) => '$n ${_p(n, 'контакт', 'контакта', 'контактов')}';
  String people(int n) => '$n ${_p(n, 'человек', 'человека', 'человек')}';
  String days(int n) => '$n ${_p(n, 'день', 'дня', 'дней')}';
  String copied(String value) => 'Скопировано: $value';

  // ── Разделы и сортировка ──
  String get segDashboard => 'Обзор';
  String get segAll => 'Контакты';
  String get segFavorites => 'Избранные';
  String get segBirthdays => 'Дни рождения';
  String get segRecent => 'Новые за месяц';
  String get segTrash => 'Корзина';
  String get sortNameAsc => 'Имя: А → Я';
  String get sortNameDesc => 'Имя: Я → А';
  String get sortNewest => 'Сначала новые';
  String get sortOldest => 'Сначала старые';
  String get sortMetRecent => 'Недавние знакомства';

  // ── Главное окно ──
  String movedToTrashOne(String name) => '«$name» в корзине';
  String movedToTrashMany(int n) => 'В корзине: ${contacts(n)}';
  String restoredMany(int n) => 'Восстановлено: ${contacts(n)}';
  String purgeTitle(int n) => 'Удалить навсегда ${contacts(n)}?';
  String get purgeMessage => 'Контакты и их фото будут удалены без возможности восстановления.';
  String get nothingToExport => 'Нечего экспортировать';
  String savedContacts(int n) => 'Сохранено: ${contacts(n)}';
  String saveFileFailed(Object e) => 'Не удалось сохранить файл: $e';
  String get searchPlaceholder => 'Поиск по контактам…';
  String get personalBase => 'Личная база';
  String get menuImport => 'Импорт из CSV или vCard…';
  String get menuBackup => 'Резервная копия…';
  String get menuRestore => 'Восстановить из копии…';
  String get lock => 'Заблокировать';
  String get about => 'О приложении';
  String get language => 'Язык';
  String get systemLanguage => 'Системный';
  String get allInterests => 'Все интересы';
  String get interestsHint => 'Интересы: создать и удалить';
  String get emptyTrash => 'Очистить корзину';
  String get viewTable => 'Таблица';
  String get viewCards => 'Карточки';
  String get newShort => 'Новый';
  String get noContactsTitle => 'Контактов пока нет';
  String get noContactsSubtitle => 'Добавьте первого человека или импортируйте контакты из CSV или vCard';
  String get importShort => 'Импорт…';
  String get newContact => 'Новый контакт';
  String get nothingFound => 'Ничего не найдено';
  String nothingFoundFor(String q) => 'По запросу «$q» нет контактов';
  String get trashEmpty => 'Корзина пуста';
  String trashEmptySubtitle(int days) => 'Удалённые контакты хранятся здесь ${this.days(days)}';
  String get favoritesEmpty => 'В избранном пока никого';
  String get favoritesEmptySubtitle => 'Отметьте звёздочкой тех, кто вам особенно дорог';
  String get recentEmpty => 'Новых знакомств пока нет';
  String get recentEmptySubtitle => 'Здесь появятся люди, добавленные за последние 30 дней';
  String get birthdaysEmpty => 'Ближайших дней рождения нет';
  String get birthdaysEmptySubtitle => 'Здесь появятся те, у кого день рождения в ближайшие 30 дней';
  String get segmentEmpty => 'Здесь пока никого';
  String get segmentEmptySubtitle => 'В этом разделе нет контактов';
  String get noSelectionTitle => 'Контакт не выбран';
  String noSelectionSubtitle(String mod, String shift) => 'Выберите человека в списке. С $mod или $shift — несколько сразу';
  String get interests => 'Интересы';
  String get fieldsAndSections => 'Поля и разделы';
  String selectedCount(int n) => 'Выбрано: ${contacts(n)}';

  // ── Главный экран ──
  String get goodNight => 'Доброй ночи';
  String get goodMorning => 'Доброе утро';
  String get goodAfternoon => 'Добрый день';
  String get goodEvening => 'Добрый вечер';
  String get totalContacts => 'Всего контактов';
  String get viewList => 'Смотреть список';

  // ── Оформление ──
  String get appearance => 'Оформление';
  String get themeLight => 'Светлая';
  String get themeSystem => 'Системная';
  String get themeDark => 'Тёмная';

  // ── Импорт, экспорт, копии ──
  String get contactsFileType => 'Контакты';
  String get imagesFileType => 'Изображения';
  String get backupFileType => 'Резервная копия Orbit';
  String readFileFailed(Object e) => 'Не удалось прочитать файл: $e';
  String get noContactsInFile => 'В файле не нашлось контактов';
  String allAlreadyExist(int n) => 'Все ${contacts(n)} из файла уже есть в базе';
  String importTitle(String file) => 'Импорт из «$file»';
  String importMessage(int found, int dupes) =>
      'Найдено ${contacts(found)}.${dupes > 0 ? ' ${contacts(dupes)} уже есть в базе — их пропустим.' : ''}';
  String importConfirm(int n) => 'Импортировать $n';
  String imported(int n) => 'Импортировано: ${contacts(n)}';
  String get backupSaved => 'Резервная копия сохранена';
  String backupSaveFailed(Object e) => 'Не удалось сохранить копию: $e';
  String get restoreTitle => 'Восстановить из копии?';
  String restoreMessage(int n, String? date) =>
      'В копии ${contacts(n)}${date == null ? '' : ' от $date'}. '
      'Новые люди добавятся, а у тех, кто уже есть, останется более свежая версия.';
  String get restoreNothingNew => 'Всё из копии уже есть в базе';
  String restoreResult(int added, int updated) => 'Добавлено: $added, обновлено: $updated';
  String get notABackup => 'Это не резервная копия Orbit';
  String get fileCorrupted => 'Файл повреждён';
  String codeLength(int n) => 'В коде $n символов';
  String get codeNotForBackup => 'Код не подходит к этой копии';
  String get needRecoveryTitle => 'Нужен recovery code';
  String get needRecoverySubtitle => 'Копия сделана на другой установке Orbit';
  String get recoveryFromOtherInstall => 'Код, который та установка показала при первой настройке';
  String openFolderFailed(String path) => 'Не удалось открыть папку: $path';

  // ── PIN и recovery code ──
  String get pinChanged => 'PIN-код изменён';
  String get wrongCurrentPin => 'Неверный текущий PIN';
  String get wrongPin => 'Неверный PIN-код';
  String get changePinTitle => 'Сменить PIN-код';
  String get changePinSubtitle => 'Recovery code останется прежним';
  String get currentPin => 'Текущий PIN';
  String get newPinOrPassword => 'Новый PIN-код или пароль';
  String get pinOrPassword => 'PIN-код или пароль';
  String get repeat => 'Повторите';
  String minLength(int n) => 'Не короче $n символов';
  String pinHint(int n) => 'Не короче $n символов. Длинный пароль надёжнее короткого числового PIN.';
  String get pinsMismatch => 'PIN-коды не совпадают';
  String get regenerateTitle => 'Создать новый recovery code?';
  String get regenerateMessage =>
      'Старый код перестанет открывать базу. Резервные копии, сделанные раньше, '
      'по-прежнему открываются только старым кодом — если он у вас есть, сохраните его вместе с ними.';
  String get revealIntro => 'Recovery code нужен, если вы забудете PIN, и чтобы открыть резервную копию на другом компьютере. Чтобы его показать, введите PIN.';
  String get revealKeepSafe => 'Сохраните код в менеджере паролей или запишите. Не храните его рядом с резервными копиями.';
  String get revealLegacy =>
      'Эта база настроена в более ранней версии Orbit, и recovery code в ней не сохранён — '
      'показать его нельзя. Можно создать новый код.';
  String get createNewCode => 'Создать новый код';
  String get saveRecoveryTitle => 'Сохраните recovery code';
  String get saveRecoverySubtitle => 'Он нужен, если вы забудете PIN, и чтобы восстановить резервную копию на другом компьютере. Код показывается только сейчас.';
  String get savedCodeCheck => 'Я сохранил код в надёжном месте';
  String get encrypting => 'Шифруем базу…';
  String get openOrbit => 'Открыть Orbit';
  String get protectTitle => 'Защитите базу';
  String get protectExisting => 'Придумайте PIN-код или пароль — существующие контакты и фото будут зашифрованы на диске.';
  String get protectNew => 'Придумайте PIN-код или пароль — контакты и фото будут храниться на диске в зашифрованном виде.';
  String get creatingKeys => 'Создаём ключи…';
  String get codeCopied => 'Recovery code скопирован';
  String get codeWrongCase => 'Код не подходит. Проверьте регистр букв';
  String get lockedTitle => 'Orbit заблокирован';
  String get lockedSubtitle => 'Введите PIN-код, чтобы открыть базу';
  String tooManyAttempts(int s) => 'Слишком много попыток. Подождите $s с';
  String get forgotPin => 'Забыли PIN? Войти по recovery code';
  String get recoveryLoginTitle => 'Вход по recovery code';
  String get recoveryLoginSubtitle => 'Введите код, который Orbit показал при первой настройке. Потом нужно будет придумать новый PIN.';
  String get backToPin => 'Назад к PIN-коду';
  String get newPinTitle => 'Новый PIN-код';
  String get newPinSubtitle => 'Код подошёл. Придумайте новый PIN — recovery code останется прежним.';
  String get saveAndOpen => 'Сохранить и открыть';

  // ── Карточка контакта ──
  String get editContact => 'Изменить контакт';
  String formShortcuts(String save) => '$save — сохранить, Esc — отменить';
  String get enterName => 'Укажите имя';
  String get badEmail => 'Некорректный email';
  String get addOwnSection => 'Добавить свой раздел';
  String get choosePhoto => 'Выбрать фото';
  String get photo => 'Фотография';
  String get chooseEllipsis => 'Выбрать…';
  String get replaceEllipsis => 'Заменить…';
  String get fieldButton => 'Поле';
  String get configureSection => 'Настроить раздел';
  String get emptySectionHint => 'Пустой раздел — добавьте поле кнопкой «Поле»';
  String get name => 'Имя';
  String get namePlaceholder => 'Имя и фамилия';
  String get handlePlaceholder => '@ник или ссылка';
  String get position => 'Должность';
  String get positionPlaceholder => 'Дизайнер';
  String get company => 'Компания';
  String get companyPlaceholder => 'Где работает';
  String get whereMet => 'Где познакомились';
  String get whereMetPlaceholder => 'Конференция, через друзей, …';
  String get where => 'Где';
  String get when => 'Когда';
  String get birthday => 'День рождения';
  String get notesPlaceholder => 'Всё, что стоит помнить о человеке';
  String get phone => 'Телефон';
  String get phones => 'Телефоны';
  String get email => 'Email';
  String get mail => 'Почта';
  String get phonePlaceholder => '+7 900 000-00-00';
  String get addPhone => 'Добавить телефон';
  String get addEmail => 'Добавить email';
  String get chooseOrCreate => 'Выбрать или создать';
  String get interest => 'Интерес';
  String get configureField => 'Настроить поле';
  String get noOptions => 'Нет вариантов — добавьте в настройках поля';
  String get notSelected => 'Не выбрано';
  String get findOrCreate => 'Найти или создать…';
  String createNamed(String q) => 'Создать «$q»';
  String get noInterestsCreate => 'Интересов пока нет — введите название, чтобы создать';
  String get manageInterests => 'Управлять интересами…';
  String get birthdayToday => '🎂 День рождения сегодня';
  String birthdayIn(int n) => '🎂 День рождения через ${days(n)}';
  String addedChanged(String added, String changed) => 'Добавлен $added\nИзменён $changed';
  String get trashTomorrow => 'В корзине · удалится завтра';
  String trashIn(int n) => 'В корзине · удалится через ${days(n)}';
  String notSpecified(String what) => '$what не указан';

  // ── Подписи телефонов и почты ──
  String get labelMobile => 'мобильный';
  String get labelWork => 'рабочий';
  String get labelHome => 'домашний';
  String get labelOther => 'другой';
  String get labelPersonal => 'личный';

  // ── Таблица ──
  String get colWork => 'Работа';
  String get colMet => 'Знакомство';
  String get colFavorite => 'Избранное';
  String get colCreated => 'Добавлен';
  String get configureColumn => 'Настроить колонку';
  String get sort => 'Сортировать';
  String get addColumn => 'Добавить колонку';
  String get columns => 'Столбцы';
  String get cannotHideColumn => 'Этот столбец нельзя скрыть';
  String get nameAlwaysFirst => 'Имя всегда первое и не скрывается';
  String get reorderHint => 'Порядок меняется перетаскиванием за ';
  String get newFieldEllipsis => 'Новое поле…';

  // ── Поля и разделы ──
  String get typeText => 'Текст';
  String get typeMultiline => 'Длинный текст';
  String get typeNumber => 'Число';
  String get typeUrl => 'Ссылка';
  String get typeDate => 'Дата';
  String get typeSelect => 'Список';
  String get typeCheckbox => 'Да / нет';
  String get sectionMain => 'Основное';
  String get sectionInterests => 'Сфера интересов';
  String get notes => 'Заметки';
  String get emails => 'Email-адреса';
  String get metDate => 'Дата знакомства';
  String deleteFieldTitle(String name) => 'Удалить поле «$name»?';
  String get deleteFieldMessage => 'Значения этого поля будут удалены у всех контактов.';
  String get newField => 'Новое поле';
  String get fieldSettings => 'Настройка поля';
  String get deleteField => 'Удалить поле';
  String get title => 'Название';
  String get fieldNamePlaceholder => 'Например: Город, Любимый кофе';
  String get fieldType => 'Тип поля';
  String get optionsLabel => 'Варианты · Enter или запятая — добавить';
  String get newOption => 'Новый вариант';
  String get section => 'Раздел';
  String get icon => 'Иконка';
  String get tableColumn => 'Колонка в таблице';
  String get tableColumnHint => 'Показывать это поле в списке контактов';
  String deleteSectionTitle(String name) => 'Удалить раздел «$name»?';
  String get sectionEmptyNoLoss => 'Раздел пустой, ничего не потеряется.';
  String deleteSectionFields(int n) =>
      'Вместе с разделом удалятся $n ${_p(n, 'поле', 'поля', 'полей')} и их значения у всех контактов.';
  String get newSection => 'Новый раздел';
  String get sectionSettings => 'Настройка раздела';
  String get builtInSectionNote => 'Стандартный раздел можно переименовать, но не удалить';
  String get deleteSection => 'Удалить раздел';
  String get sectionName => 'Название раздела';
  String get sectionNamePlaceholder => 'Например: Соцсети, Семья, Проекты';
  String get dragToReorder => 'Перетаскивайте за ⠿, чтобы поменять порядок';
  String get standardTag => 'стандартный';
  String get builtInField => 'Встроенное поле';
  String get shownInTable => 'Показывается в таблице';
  String get noFieldsInSection => 'В разделе пока нет полей';
  String get addField => 'Добавить поле';

  // ── Интересы ──
  String get interestExists => 'Такой интерес уже есть';
  String deleteInterestTitle(String name) => 'Удалить интерес «$name»?';
  String get deleteInterestUnused => 'Ни у кого из контактов этого интереса нет.';
  String deleteInterestMessage(int n) =>
      'Этот интерес указан у ${contacts(n)}. Если его удалить, он пропадёт '
      'из ${_p(n, 'карточки', 'карточек', 'карточек')} и быстрый поиск по интересу '
      'перестанет ${_p(n, 'находить этот контакт', 'находить эти контакты', 'находить эти контакты')}.';
  String get interestsSubtitle => 'Создайте заранее — потом их можно выбрать в карточке контакта';
  String get newInterestLabel => 'Новый интерес · можно несколько через запятую';
  String get interestsPlaceholder => 'Например: Дизайн, Бег, Книги';
  String get noInterests => 'Интересов пока нет';
  String get nobody => 'ни у кого';
  String get deleteInterest => 'Удалить интерес';

  // ── Календарь ──
  String get dateNotSet => 'Не указана';
  String get prevMonth => 'Предыдущий месяц';
  String get nextMonth => 'Следующий месяц';
  String get today => 'Сегодня';

  // ── Быстрый поиск ──
  String get spotlightPlaceholder => 'Имя человека…';
  String noneFoundFor(String q) => 'Никого не нашлось по запросу «$q»';
  String get favoritesAndRecentCaps => 'ИЗБРАННЫЕ И НЕДАВНИЕ';
  String get contactsCaps => 'КОНТАКТЫ';

  // ── О приложении ──
  String get tagline => 'Личная база контактов';
  String get developer => 'Разработчик';
  String get design => 'Дизайн';
  String designCredit(String title, String author) =>
      'Вдохновлён макетом «$title» от $author (Figma Community). Интерфейс переработан и изменён mrgsdev.';
  String get figmaLayout => 'Макет в Figma';
  String license(String name) => 'Лицензия $name';
  String get fonts => 'Шрифты';
  String get fontsLicense => 'Montserrat и Marck Script — SIL Open Font License 1.1';

  // ── Настройки ──
  String get settings => 'Настройки';
  String get menuSettings => 'Настройки…';
  String get settingsGeneral => 'Основные';
  String get settingsSecurity => 'Безопасность';
  String get settingsData => 'Данные';
  String get languageHint => 'Язык меню, кнопок и сообщений';
  String get appearanceHint => 'Светлая, тёмная или как в системе';
  String get interestsRowHint => 'Для быстрого фильтра по людям';
  String interestsCount(int n) => '$n ${_p(n, 'интерес', 'интереса', 'интересов')}';
  String get fieldsRowHint => 'Свои поля и разделы в карточке контакта';
  String get configureEllipsis => 'Настроить…';
  String trashRowHint(int d) => 'Удалённые контакты хранятся ${days(d)}, потом исчезают';
  String get pinRow => 'PIN-код';
  String get pinRowHint => 'Открывает базу при запуске';
  String get changeEllipsis => 'Сменить…';
  String get recoveryRow => 'Recovery code';
  String get recoveryRowHint => 'Нужен, если забудете PIN, и для копий на другом компьютере';
  String get showEllipsis => 'Показать…';
  String get lockNow => 'Заблокировать сейчас';
  String lockRowHint(String combo) => 'Или $combo в любой момент';
  String get importRowHint => 'CSV (Google, Excel, экспорт Orbit) и vCard';
  String get exportRowHint => 'Все контакты в один CSV-файл';
  String get exportEllipsis => 'Экспорт…';
  String get backupRow => 'Резервная копия';
  String get backupRowHint => 'Зашифрованный файл .orbit со всеми контактами и фото';
  String get createEllipsis => 'Создать…';
  String get restoreRow => 'Восстановление';
  String get restoreRowHint => 'Добавить контакты из резервной копии';
  String get restoreEllipsis => 'Восстановить…';
  String get appFolder => 'Папка приложения';
  String get showInFinder => 'Показать в Finder';
  String get showInExplorer => 'Показать в Проводнике';
  String get openFolderAction => 'Открыть папку';

  // ── Горячие клавиши ──
  String get settingsShortcuts => 'Горячие клавиши';
  String get shortcutsIntro => 'Нажмите «Изменить», затем новое сочетание клавиш. Esc — отмена.';
  String get shortcutsFixed => 'Встроенные';
  String get changeShort => 'Изменить';
  String get pressKeys => 'Нажмите сочетание…';
  String get resetDefault => 'Вернуть по умолчанию';
  String get resetAll => 'Сбросить все';
  String needModifier(String first, String last) => 'Добавьте $first или $last';
  String reservedCombo(String c) => 'Сочетание $c занято системой';
  String comboInUse(String c, String action) => 'Сочетание $c уже у действия «$action»';
  String get actQuickSearch => 'Быстрый поиск';
  String actOpen(String s) => 'Открыть «$s»';
  String get actSelectAll => 'Выделить все';
  String get actMoveSelection => 'Перемещение по списку';
  String get actMultiSelect => 'Выделить несколько';
  String get click => 'клик';
  String get actEditSelected => 'Изменить выбранный контакт';
  String get actTrashSelected => 'Выбранные в корзину';
  String get actSaveEditor => 'Сохранить в редакторе';
  String get actCloseWindow => 'Закрыть окно или снять выделение';
  // ── Знакомство ──
  String get onbSkip => 'Пропустить';
  String get onbNext => 'Далее';
  String get onbBack => 'Назад';
  String get onbStart => 'Начать';
  String get onbWelcomeTitle => 'Добро пожаловать в Orbit';
  String get onbWelcomeText => 'Личная база людей, которые вам важны. Контакты, интересы, дни рождения и заметки в одном месте.';
  String get onbPeopleTitle => 'Все люди под рукой';
  String get onbPeopleText => 'Несколько телефонов и почт, Telegram и Instagram, свои поля. Отмечайте интересы, чтобы быстро находить нужных людей.';
  String get onbDatesTitle => 'Ничего не забудете';
  String get onbDatesText => 'На главном экране видны ближайшие дни рождения и новые знакомства за месяц. Самых важных отмечайте звёздочкой.';
  String get onbPrivacyTitle => 'Только на вашем компьютере';
  String get onbPrivacyText => 'База и фото зашифрованы и хранятся только на этом компьютере. PIN открывает базу, recovery code выручит, если вы его забудете. Резервные копии тоже зашифрованы.';
  String get onbKeysText => 'Самые нужные действия доступны с клавиатуры. Сочетания можно поменять в Настройках → Горячие клавиши.';
  String get onbChangeShortcuts => 'Изменить сочетания';
  String get onbRow => 'Знакомство с Orbit';
  String get onbRowHint => 'Короткий рассказ о возможностях и горячих клавишах';

  // ── CSV ──
  String get csvYes => 'да';
}
