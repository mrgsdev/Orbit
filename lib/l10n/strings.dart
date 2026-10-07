import 'package:intl/intl.dart';

import '../models/field_schema.dart';
import 'en.dart';
import 'es.dart';
import 'fr.dart';
import 'hi.dart';
import 'ru.dart';
import 'zh.dart';

/// Языки интерфейса. Порядок — как в меню выбора.
const List<Strings> languages = [Ru(), En(), Zh(), Hi(), Es(), Fr()];

/// Строки текущего языка. Меняется вместе с выбором языка; цвета темы
/// устроены так же, поэтому интерфейс перестраивается целиком.
Strings tr = const Ru();

/// Язык по коду (`ru`, `en`…); null — такого нет.
Strings? languageByCode(String code) {
  for (final l in languages) {
    if (l.locale == code) return l;
  }
  return null;
}

/// Все строки интерфейса. Каждый язык реализует их все, иначе проект не
/// соберётся, поэтому пропущенный перевод виден сразу.
abstract class Strings {
  const Strings();

  String get locale;
  String get languageName;
  String get cancel;
  String get done;
  String get save;
  String get delete;
  String get add;
  String get create;
  String get open;
  String get show;
  String get hide;
  String get close;
  String get closeEsc;
  String get clear;
  String get copy;
  String get undo;
  String get restore;
  String get edit;
  String get continueAction;
  String get checking;
  String get saving;
  String get creating;
  String get yes;
  String get no;
  String get remove;
  String get toFavorites;
  String get removeFromFavorites;
  String get toTrash;
  String get toTrashKey;
  String get deleteForever;
  String get exportCsv;
  String contacts(int n);
  String people(int n);
  String days(int n);
  String copied(String value);
  String get segDashboard;
  String get segAll;
  String get segFavorites;
  String get segBirthdays;
  String get segRecent;
  String get segTrash;
  String get sortNameAsc;
  String get sortNameDesc;
  String get sortNewest;
  String get sortOldest;
  String get sortMetRecent;
  String movedToTrashOne(String name);
  String movedToTrashMany(int n);
  String restoredMany(int n);
  String purgeTitle(int n);
  String get purgeMessage;
  String get nothingToExport;
  String savedContacts(int n);
  String saveFileFailed(Object e);
  String get searchPlaceholder;
  String get personalBase;
  String get menuImport;
  String get menuBackup;
  String get menuRestore;
  String get lock;
  String get about;
  String get language;
  String get systemLanguage;
  String get allInterests;
  String get interestsHint;
  String get emptyTrash;
  String get viewTable;
  String get viewCards;
  String get newShort;
  String get noContactsTitle;
  String get noContactsSubtitle;
  String get importShort;
  String get newContact;
  String get nothingFound;
  String nothingFoundFor(String q);
  String get trashEmpty;
  String trashEmptySubtitle(int days);
  String get favoritesEmpty;
  String get favoritesEmptySubtitle;
  String get recentEmpty;
  String get recentEmptySubtitle;
  String get birthdaysEmpty;
  String get birthdaysEmptySubtitle;
  String get segmentEmpty;
  String get segmentEmptySubtitle;
  String get noSelectionTitle;
  String noSelectionSubtitle(String mod, String shift);
  String get interests;
  String get fieldsAndSections;
  String selectedCount(int n);
  String get goodNight;
  String get goodMorning;
  String get goodAfternoon;
  String get goodEvening;
  String get totalContacts;
  String get viewList;
  String get appearance;
  String get themeLight;
  String get themeSystem;
  String get themeDark;
  String get contactsFileType;
  String get imagesFileType;
  String get backupFileType;
  String readFileFailed(Object e);
  String get noContactsInFile;
  String allAlreadyExist(int n);
  String importTitle(String file);
  String importMessage(int found, int dupes);
  String importConfirm(int n);
  String imported(int n);
  String get backupSaved;
  String backupSaveFailed(Object e);
  String get restoreTitle;
  String restoreMessage(int n, String? date);
  String get restoreNothingNew;
  String restoreResult(int added, int updated);
  String get notABackup;
  String get fileCorrupted;
  String codeLength(int n);
  String get codeNotForBackup;
  String get needRecoveryTitle;
  String get needRecoverySubtitle;
  String get recoveryFromOtherInstall;
  String openFolderFailed(String path);
  String get pinChanged;
  String get wrongCurrentPin;
  String get wrongPin;
  String get changePinTitle;
  String get changePinSubtitle;
  String get currentPin;
  String get newPinOrPassword;
  String get pinOrPassword;
  String get repeat;
  String minLength(int n);
  String pinHint(int n);
  String get pinsMismatch;
  String get regenerateTitle;
  String get regenerateMessage;
  String get revealIntro;
  String get revealKeepSafe;
  String get revealLegacy;
  String get createNewCode;
  String get saveRecoveryTitle;
  String get saveRecoverySubtitle;
  String get savedCodeCheck;
  String get encrypting;
  String get openOrbit;
  String get protectTitle;
  String get protectExisting;
  String get protectNew;
  String get creatingKeys;
  String get codeCopied;
  String get codeWrongCase;
  String get lockedTitle;
  String get lockedSubtitle;
  String tooManyAttempts(int s);
  String get forgotPin;
  String get recoveryLoginTitle;
  String get recoveryLoginSubtitle;
  String get backToPin;
  String get newPinTitle;
  String get newPinSubtitle;
  String get saveAndOpen;
  String get editContact;
  String formShortcuts(String save);
  String get enterName;
  String get badEmail;
  String get addOwnSection;
  String get choosePhoto;
  String get photo;
  String get chooseEllipsis;
  String get replaceEllipsis;
  String get fieldButton;
  String get configureSection;
  String get emptySectionHint;
  String get name;
  String get namePlaceholder;
  String get handlePlaceholder;
  String get position;
  String get positionPlaceholder;
  String get company;
  String get companyPlaceholder;
  String get whereMet;
  String get whereMetPlaceholder;
  String get where;
  String get when;
  String get birthday;
  String get notesPlaceholder;
  String get phone;
  String get phones;
  String get email;
  String get mail;
  String get phonePlaceholder;
  String get addPhone;
  String get addEmail;
  String get chooseOrCreate;
  String get interest;
  String get configureField;
  String get noOptions;
  String get notSelected;
  String get findOrCreate;
  String createNamed(String q);
  String get noInterestsCreate;
  String get manageInterests;
  String get birthdayToday;
  String birthdayIn(int n);
  String addedChanged(String added, String changed);
  String get trashTomorrow;
  String trashIn(int n);
  String notSpecified(String what);
  String get labelMobile;
  String get labelWork;
  String get labelHome;
  String get labelOther;
  String get labelPersonal;
  String get colWork;
  String get colMet;
  String get colFavorite;
  String get colCreated;
  String get configureColumn;
  String get sort;
  String get addColumn;
  String get columns;
  String get cannotHideColumn;
  String get nameAlwaysFirst;
  String get reorderHint;
  String get newFieldEllipsis;
  String get typeText;
  String get typeMultiline;
  String get typeNumber;
  String get typeUrl;
  String get typeDate;
  String get typeSelect;
  String get typeCheckbox;
  String get sectionMain;
  String get sectionInterests;
  String get notes;
  String get emails;
  String get metDate;
  String deleteFieldTitle(String name);
  String get deleteFieldMessage;
  String get newField;
  String get fieldSettings;
  String get deleteField;
  String get title;
  String get fieldNamePlaceholder;
  String get fieldType;
  String get optionsLabel;
  String get newOption;
  String get section;
  String get icon;
  String get tableColumn;
  String get tableColumnHint;
  String deleteSectionTitle(String name);
  String get sectionEmptyNoLoss;
  String deleteSectionFields(int n);
  String get newSection;
  String get sectionSettings;
  String get builtInSectionNote;
  String get deleteSection;
  String get sectionName;
  String get sectionNamePlaceholder;
  String get dragToReorder;
  String get standardTag;
  String get builtInField;
  String get shownInTable;
  String get noFieldsInSection;
  String get addField;
  String get interestExists;
  String deleteInterestTitle(String name);
  String get deleteInterestUnused;
  String deleteInterestMessage(int n);
  String get interestsSubtitle;
  String get newInterestLabel;
  String get interestsPlaceholder;
  String get noInterests;
  String get nobody;
  String get deleteInterest;
  String get dateNotSet;
  String get prevMonth;
  String get nextMonth;
  String get today;
  String get spotlightPlaceholder;
  String noneFoundFor(String q);
  String get favoritesAndRecentCaps;
  String get contactsCaps;
  String get tagline;
  String get developer;
  String get design;
  String designCredit(String title, String author);
  String get figmaLayout;
  String license(String name);
  String get fonts;
  String get fontsLicense;
  String get settings;
  String get menuSettings;
  String get settingsGeneral;
  String get settingsSecurity;
  String get settingsData;
  String get languageHint;
  String get appearanceHint;
  String get interestsRowHint;
  String interestsCount(int n);
  String get fieldsRowHint;
  String get configureEllipsis;
  String trashRowHint(int d);
  String get pinRow;
  String get pinRowHint;
  String get changeEllipsis;
  String get recoveryRow;
  String get recoveryRowHint;
  String get showEllipsis;
  String get lockNow;
  String lockRowHint(String combo);
  String get importRowHint;
  String get exportRowHint;
  String get exportEllipsis;
  String get backupRow;
  String get backupRowHint;
  String get createEllipsis;
  String get restoreRow;
  String get restoreRowHint;
  String get restoreEllipsis;
  String get appFolder;
  String get showInFinder;
  String get showInExplorer;
  String get openFolderAction;
  String get settingsShortcuts;
  String get shortcutsIntro;
  String get shortcutsFixed;
  String get changeShort;
  String get pressKeys;
  String get resetDefault;
  String get resetAll;
  String needModifier(String first, String last);
  String reservedCombo(String c);
  String comboInUse(String c, String action);
  String get actQuickSearch;
  String actOpen(String s);
  String get actSelectAll;
  String get actMoveSelection;
  String get actMultiSelect;
  String get click;
  String get actEditSelected;
  String get actTrashSelected;
  String get actSaveEditor;
  String get actCloseWindow;
  String get onbSkip;
  String get onbNext;
  String get onbBack;
  String get onbStart;
  String get onbWelcomeTitle;
  String get onbWelcomeText;
  String get onbPeopleTitle;
  String get onbPeopleText;
  String get onbDatesTitle;
  String get onbDatesText;
  String get onbPrivacyTitle;
  String get onbPrivacyText;
  String get onbKeysText;
  String get onbChangeShortcuts;
  String get onbRow;
  String get onbRowHint;
  String get csvYes;

  // ── Производные: собираются из строк выше ──

  /// Тип поля по-человечески.
  String fieldTypeLabel(FieldType t) => switch (t) {
        FieldType.text => typeText,
        FieldType.multiline => typeMultiline,
        FieldType.number => typeNumber,
        FieldType.phone => phone,
        FieldType.email => email,
        FieldType.url => typeUrl,
        FieldType.date => typeDate,
        FieldType.select => typeSelect,
        FieldType.checkbox => typeCheckbox,
      };

  /// Подпись телефона или почты. В базе подписи хранятся по-русски
  /// («мобильный»…): так их понимают старые версии и импорт.
  String valueLabel(String stored) => switch (stored) {
        'мобильный' => labelMobile,
        'рабочий' => labelWork,
        'домашний' => labelHome,
        'другой' => labelOther,
        'личный' => labelPersonal,
        _ => stored,
      };

  /// Название стандартного раздела. Своё название пользователя не трогаем.
  String sectionTitle(FieldSection s) {
    if (!s.builtIn) return s.title;
    final original = BuiltIn.sections.where((d) => d.id == s.id).firstOrNull?.title;
    if (s.title.isNotEmpty && s.title != original) return s.title;
    return builtInSectionTitle(s.id) ?? s.title;
  }

  String? builtInSectionTitle(String id) => switch (id) {
        BuiltIn.main => sectionMain,
        BuiltIn.work => colWork,
        BuiltIn.meet => colMet,
        BuiltIn.interests => sectionInterests,
        BuiltIn.notes => notes,
        _ => null,
      };

  /// Встроенные поля разделов по ключу из [BuiltIn.fixedFields].
  String builtInFieldLabel(String key) => switch (key) {
        'name' => name,
        'phones' => phones,
        'telegram' => 'Telegram',
        'instagram' => 'Instagram',
        'emails' => emails,
        'position' => position,
        'company' => company,
        'whereMet' => whereMet,
        'metDate' => metDate,
        'birthday' => birthday,
        'interests' => interests,
        'notes' => notes,
        _ => key,
      };

  /// Заголовок столбца таблицы по ключу.
  String columnTitle(String key) => switch (key) {
        'name' => name,
        'phone' => phone,
        'work' => colWork,
        'met' => colMet,
        'interests' => interests,
        'birthday' => birthday,
        'created' => colCreated,
        'favorite' => colFavorite,
        _ => key,
      };

  /// Пн…Вс в языке интерфейса, неделя с понедельника.
  List<String> get weekdaysShort => [
        for (var i = 0; i < 7; i++) _capitalize(DateFormat.E(locale).format(DateTime(2024, 1, 1 + i))),
      ];

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  /// Заголовки CSV при экспорте. Импорт понимает их на любом языке.
  List<String> get csvHeaders => [
        name, phone, 'Telegram', 'Instagram', email, position, company,
        whereMet, metDate, birthday, interests, notes, colFavorite,
      ];
}
