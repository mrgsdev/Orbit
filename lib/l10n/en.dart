// ignore_for_file: annotate_overrides
import 'strings.dart';

class En extends Strings {
  const En();

  String get locale => 'en';
  String get languageName => 'English';

  String _p(int n, String one, String many) => n == 1 ? one : many;

  // ── Common ──
  String get cancel => 'Cancel';
  String get done => 'Done';
  String get save => 'Save';
  String get delete => 'Delete';
  String get add => 'Add';
  String get create => 'Create';
  String get open => 'Open';
  String get show => 'Show';
  String get hide => 'Hide';
  String get close => 'Close';
  String get closeEsc => 'Close (Esc)';
  String get clear => 'Clear';
  String get copy => 'Copy';
  String get undo => 'Undo';
  String get restore => 'Restore';
  String get edit => 'Edit';
  String get continueAction => 'Continue';
  String get checking => 'Checking…';
  String get saving => 'Saving…';
  String get creating => 'Creating…';
  String get yes => 'Yes';
  String get no => 'No';
  String get remove => 'Remove';
  String get toFavorites => 'Add to favorites';
  String get removeFromFavorites => 'Remove from favorites';
  String get toTrash => 'Move to trash';
  String get toTrashKey => 'Move to trash (⌫)';
  String get deleteForever => 'Delete forever';
  String get exportCsv => 'Export to CSV…';
  String contacts(int n) => '$n ${_p(n, 'contact', 'contacts')}';
  String people(int n) => '$n ${_p(n, 'person', 'people')}';
  String days(int n) => '$n ${_p(n, 'day', 'days')}';
  String copied(String value) => 'Copied: $value';

  // ── Sections and sorting ──
  String get segDashboard => 'Overview';
  String get segAll => 'Contacts';
  String get segFavorites => 'Favorites';
  String get segBirthdays => 'Birthdays';
  String get segRecent => 'New this month';
  String get segTrash => 'Trash';
  String get sortNameAsc => 'Name: A → Z';
  String get sortNameDesc => 'Name: Z → A';
  String get sortNewest => 'Newest first';
  String get sortOldest => 'Oldest first';
  String get sortMetRecent => 'Recently met';

  // ── Main window ──
  String movedToTrashOne(String name) => '“$name” moved to trash';
  String movedToTrashMany(int n) => 'Moved to trash: ${contacts(n)}';
  String restoredMany(int n) => 'Restored: ${contacts(n)}';
  String purgeTitle(int n) => 'Delete ${contacts(n)} forever?';
  String get purgeMessage => 'The contacts and their photos will be deleted permanently.';
  String get nothingToExport => 'Nothing to export';
  String savedContacts(int n) => 'Saved: ${contacts(n)}';
  String saveFileFailed(Object e) => 'Couldn’t save the file: $e';
  String get searchPlaceholder => 'Search contacts…';
  String get personalBase => 'Personal base';
  String get menuImport => 'Import from CSV or vCard…';
  String get menuBackup => 'Backup…';
  String get menuRestore => 'Restore from backup…';
  String get lock => 'Lock';
  String get about => 'About';
  String get language => 'Language';
  String get systemLanguage => 'System';
  String get allInterests => 'All interests';
  String get interestsHint => 'Interests: create and delete';
  String get emptyTrash => 'Empty trash';
  String get viewTable => 'Table';
  String get viewCards => 'Cards';
  String get newShort => 'New';
  String get noContactsTitle => 'No contacts yet';
  String get noContactsSubtitle => 'Add your first person or import contacts from CSV or vCard';
  String get importShort => 'Import…';
  String get newContact => 'New contact';
  String get nothingFound => 'Nothing found';
  String nothingFoundFor(String q) => 'No contacts match “$q”';
  String get trashEmpty => 'Trash is empty';
  String trashEmptySubtitle(int days) => 'Deleted contacts are kept here for ${this.days(days)}';
  String get favoritesEmpty => 'No favorites yet';
  String get favoritesEmptySubtitle => 'Star the people who matter most to you';
  String get recentEmpty => 'No new people yet';
  String get recentEmptySubtitle => 'People added in the last 30 days will appear here';
  String get birthdaysEmpty => 'No upcoming birthdays';
  String get birthdaysEmptySubtitle => 'People with a birthday in the next 30 days will appear here';
  String get segmentEmpty => 'Nobody here yet';
  String get segmentEmptySubtitle => 'This section has no contacts';
  String get noSelectionTitle => 'No contact selected';
  String noSelectionSubtitle(String mod, String shift) => 'Pick a person in the list. Hold $mod or $shift to select several';
  String get interests => 'Interests';
  String get fieldsAndSections => 'Fields and sections';
  String selectedCount(int n) => 'Selected: ${contacts(n)}';

  // ── Overview ──
  String get goodNight => 'Good night';
  String get goodMorning => 'Good morning';
  String get goodAfternoon => 'Good afternoon';
  String get goodEvening => 'Good evening';
  String get totalContacts => 'Total contacts';
  String get viewList => 'View list';

  // ── Appearance ──
  String get appearance => 'Appearance';
  String get themeLight => 'Light';
  String get themeSystem => 'System';
  String get themeDark => 'Dark';

  // ── Import, export, backups ──
  String get contactsFileType => 'Contacts';
  String get imagesFileType => 'Images';
  String get backupFileType => 'Orbit backup';
  String readFileFailed(Object e) => 'Couldn’t read the file: $e';
  String get noContactsInFile => 'No contacts found in the file';
  String allAlreadyExist(int n) => 'All ${contacts(n)} from the file are already in your base';
  String importTitle(String file) => 'Import from “$file”';
  String importMessage(int found, int dupes) =>
      'Found ${contacts(found)}.${dupes > 0 ? ' ${contacts(dupes)} already in your base will be skipped.' : ''}';
  String importConfirm(int n) => 'Import $n';
  String imported(int n) => 'Imported: ${contacts(n)}';
  String get backupSaved => 'Backup saved';
  String backupSaveFailed(Object e) => 'Couldn’t save the backup: $e';
  String get restoreTitle => 'Restore from backup?';
  String restoreMessage(int n, String? date) =>
      'The backup has ${contacts(n)}${date == null ? '' : ' from $date'}. '
      'New people will be added; for those already here, the newer version is kept.';
  String get restoreNothingNew => 'Everything from the backup is already in your base';
  String restoreResult(int added, int updated) => 'Added: $added, updated: $updated';
  String get notABackup => 'This is not an Orbit backup';
  String get fileCorrupted => 'The file is damaged';
  String codeLength(int n) => 'The code has $n characters';
  String get codeNotForBackup => 'This code doesn’t match the backup';
  String get needRecoveryTitle => 'Recovery code needed';
  String get needRecoverySubtitle => 'The backup was made on another Orbit installation';
  String get recoveryFromOtherInstall => 'The code that installation showed during first setup';
  String openFolderFailed(String path) => 'Couldn’t open the folder: $path';

  // ── PIN and recovery code ──
  String get pinChanged => 'PIN changed';
  String get wrongCurrentPin => 'Wrong current PIN';
  String get wrongPin => 'Wrong PIN';
  String get changePinTitle => 'Change PIN';
  String get changePinSubtitle => 'Your recovery code stays the same';
  String get currentPin => 'Current PIN';
  String get newPinOrPassword => 'New PIN or password';
  String get pinOrPassword => 'PIN or password';
  String get repeat => 'Repeat';
  String minLength(int n) => 'At least $n characters';
  String pinHint(int n) => 'At least $n characters. A long password is safer than a short numeric PIN.';
  String get pinsMismatch => 'PINs don’t match';
  String get regenerateTitle => 'Create a new recovery code?';
  String get regenerateMessage =>
      'The old code will no longer open your base. Backups made earlier still open only with the old code — '
      'if you have it, keep it together with them.';
  String get revealIntro => 'You need the recovery code if you forget your PIN, and to open a backup on another computer. Enter your PIN to show it.';
  String get revealKeepSafe => 'Save the code in a password manager or write it down. Don’t keep it next to your backups.';
  String get revealLegacy =>
      'This base was set up in an earlier version of Orbit, and the recovery code wasn’t stored — '
      'it can’t be shown. You can create a new code.';
  String get createNewCode => 'Create new code';
  String get saveRecoveryTitle => 'Save your recovery code';
  String get saveRecoverySubtitle => 'You need it if you forget your PIN, and to restore a backup on another computer. The code is shown only now.';
  String get savedCodeCheck => 'I saved the code in a safe place';
  String get encrypting => 'Encrypting your base…';
  String get openOrbit => 'Open Orbit';
  String get protectTitle => 'Protect your base';
  String get protectExisting => 'Choose a PIN or password — your existing contacts and photos will be encrypted on disk.';
  String get protectNew => 'Choose a PIN or password — contacts and photos will be stored encrypted on disk.';
  String get creatingKeys => 'Creating keys…';
  String get codeCopied => 'Recovery code copied';
  String get codeWrongCase => 'The code doesn’t match. Check upper and lower case';
  String get lockedTitle => 'Orbit is locked';
  String get lockedSubtitle => 'Enter your PIN to open the base';
  String tooManyAttempts(int s) => 'Too many attempts. Wait $s s';
  String get forgotPin => 'Forgot your PIN? Sign in with recovery code';
  String get recoveryLoginTitle => 'Sign in with recovery code';
  String get recoveryLoginSubtitle => 'Enter the code Orbit showed during first setup. Then you’ll choose a new PIN.';
  String get backToPin => 'Back to PIN';
  String get newPinTitle => 'New PIN';
  String get newPinSubtitle => 'The code matched. Choose a new PIN — your recovery code stays the same.';
  String get saveAndOpen => 'Save and open';

  // ── Contact card ──
  String get editContact => 'Edit contact';
  String formShortcuts(String save) => '$save — save, Esc — cancel';
  String get enterName => 'Enter a name';
  String get badEmail => 'Invalid email';
  String get addOwnSection => 'Add your own section';
  String get choosePhoto => 'Choose photo';
  String get photo => 'Photo';
  String get chooseEllipsis => 'Choose…';
  String get replaceEllipsis => 'Replace…';
  String get fieldButton => 'Field';
  String get configureSection => 'Section settings';
  String get emptySectionHint => 'Empty section — add a field with the “Field” button';
  String get name => 'Name';
  String get namePlaceholder => 'First and last name';
  String get handlePlaceholder => '@handle or link';
  String get position => 'Job title';
  String get positionPlaceholder => 'Designer';
  String get company => 'Company';
  String get companyPlaceholder => 'Where they work';
  String get whereMet => 'Where we met';
  String get whereMetPlaceholder => 'Conference, through friends, …';
  String get where => 'Where';
  String get when => 'When';
  String get birthday => 'Birthday';
  String get notesPlaceholder => 'Anything worth remembering about this person';
  String get phone => 'Phone';
  String get phones => 'Phones';
  String get email => 'Email';
  String get mail => 'Mail';
  String get phonePlaceholder => '+1 555 000 0000';
  String get addPhone => 'Add phone';
  String get addEmail => 'Add email';
  String get chooseOrCreate => 'Choose or create';
  String get interest => 'Interest';
  String get configureField => 'Field settings';
  String get noOptions => 'No options — add them in the field settings';
  String get notSelected => 'Not selected';
  String get findOrCreate => 'Find or create…';
  String createNamed(String q) => 'Create “$q”';
  String get noInterestsCreate => 'No interests yet — type a name to create one';
  String get manageInterests => 'Manage interests…';
  String get birthdayToday => '🎂 Birthday today';
  String birthdayIn(int n) => '🎂 Birthday in ${days(n)}';
  String addedChanged(String added, String changed) => 'Added $added\nEdited $changed';
  String get trashTomorrow => 'In trash · deleted tomorrow';
  String trashIn(int n) => 'In trash · deleted in ${days(n)}';
  String notSpecified(String what) => '$what not set';

  // ── Phone and email labels ──
  String get labelMobile => 'mobile';
  String get labelWork => 'work';
  String get labelHome => 'home';
  String get labelOther => 'other';
  String get labelPersonal => 'personal';

  // ── Table ──
  String get colWork => 'Work';
  String get colMet => 'Meeting';
  String get colFavorite => 'Favorite';
  String get colCreated => 'Added';
  String get configureColumn => 'Column settings';
  String get sort => 'Sort';
  String get addColumn => 'Add column';
  String get columns => 'Columns';
  String get cannotHideColumn => 'This column can’t be hidden';
  String get nameAlwaysFirst => 'Name is always first and can’t be hidden';
  String get reorderHint => 'Drag to reorder by ';
  String get newFieldEllipsis => 'New field…';

  // ── Fields and sections ──
  String get typeText => 'Text';
  String get typeMultiline => 'Long text';
  String get typeNumber => 'Number';
  String get typeUrl => 'Link';
  String get typeDate => 'Date';
  String get typeSelect => 'List';
  String get typeCheckbox => 'Yes / no';
  String get sectionMain => 'Main';
  String get sectionInterests => 'Interests';
  String get notes => 'Notes';
  String get emails => 'Email addresses';
  String get metDate => 'Date met';
  String deleteFieldTitle(String name) => 'Delete field “$name”?';
  String get deleteFieldMessage => 'Values of this field will be deleted from all contacts.';
  String get newField => 'New field';
  String get fieldSettings => 'Field settings';
  String get deleteField => 'Delete field';
  String get title => 'Name';
  String get fieldNamePlaceholder => 'For example: City, Favorite coffee';
  String get fieldType => 'Field type';
  String get optionsLabel => 'Options · Enter or comma to add';
  String get newOption => 'New option';
  String get section => 'Section';
  String get icon => 'Icon';
  String get tableColumn => 'Table column';
  String get tableColumnHint => 'Show this field in the contact list';
  String deleteSectionTitle(String name) => 'Delete section “$name”?';
  String get sectionEmptyNoLoss => 'The section is empty, nothing will be lost.';
  String deleteSectionFields(int n) =>
      'This will also delete $n ${_p(n, 'field', 'fields')} and their values from all contacts.';
  String get newSection => 'New section';
  String get sectionSettings => 'Section settings';
  String get builtInSectionNote => 'A standard section can be renamed but not deleted';
  String get deleteSection => 'Delete section';
  String get sectionName => 'Section name';
  String get sectionNamePlaceholder => 'For example: Social, Family, Projects';
  String get dragToReorder => 'Drag by ⠿ to change the order';
  String get standardTag => 'standard';
  String get builtInField => 'Built-in field';
  String get shownInTable => 'Shown in the table';
  String get noFieldsInSection => 'No fields in this section yet';
  String get addField => 'Add field';

  // ── Interests ──
  String get interestExists => 'This interest already exists';
  String deleteInterestTitle(String name) => 'Delete interest “$name”?';
  String get deleteInterestUnused => 'None of your contacts has this interest.';
  String deleteInterestMessage(int n) =>
      '${contacts(n)} ${_p(n, 'has', 'have')} this interest. If you delete it, it will disappear from '
      '${_p(n, 'their card', 'their cards')}, and quick filtering by interest will no longer find '
      '${_p(n, 'this contact', 'these contacts')}.';
  String get interestsSubtitle => 'Create them in advance — then pick them in a contact card';
  String get newInterestLabel => 'New interest · several separated by commas';
  String get interestsPlaceholder => 'For example: Design, Running, Books';
  String get noInterests => 'No interests yet';
  String get nobody => 'nobody';
  String get deleteInterest => 'Delete interest';

  // ── Calendar ──
  String get dateNotSet => 'Not set';
  String get prevMonth => 'Previous month';
  String get nextMonth => 'Next month';
  String get today => 'Today';

  // ── Quick search ──
  String get spotlightPlaceholder => 'Person’s name…';
  String noneFoundFor(String q) => 'Nobody found for “$q”';
  String get favoritesAndRecentCaps => 'FAVORITES AND RECENT';
  String get contactsCaps => 'CONTACTS';

  // ── About ──
  String get tagline => 'Personal contacts base';
  String get developer => 'Developer';
  String get design => 'Design';
  String designCredit(String title, String author) =>
      'Inspired by “$title” by $author (Figma Community). The interface was reworked and changed by mrgsdev.';
  String get figmaLayout => 'Design in Figma';
  String license(String name) => 'License $name';
  String get fonts => 'Fonts';
  String get fontsLicense => 'Montserrat and Marck Script — SIL Open Font License 1.1';

  // ── Settings ──
  String get settings => 'Settings';
  String get menuSettings => 'Settings…';
  String get settingsGeneral => 'General';
  String get settingsSecurity => 'Security';
  String get settingsData => 'Data';
  String get languageHint => 'Language of menus, buttons and messages';
  String get appearanceHint => 'Light, dark, or match the system';
  String get interestsRowHint => 'For quick filtering of people';
  String interestsCount(int n) => '$n ${_p(n, 'interest', 'interests')}';
  String get fieldsRowHint => 'Your own fields and sections in the contact card';
  String get configureEllipsis => 'Configure…';
  String trashRowHint(int d) => 'Deleted contacts are kept for ${days(d)}, then removed';
  String get pinRow => 'PIN';
  String get pinRowHint => 'Opens your base at launch';
  String get changeEllipsis => 'Change…';
  String get recoveryRow => 'Recovery code';
  String get recoveryRowHint => 'Needed if you forget your PIN and for backups on another computer';
  String get showEllipsis => 'Show…';
  String get lockNow => 'Lock now';
  String lockRowHint(String combo) => 'Or press $combo at any time';
  String get importRowHint => 'CSV (Google, Excel, Orbit export) and vCard';
  String get exportRowHint => 'All contacts into one CSV file';
  String get exportEllipsis => 'Export…';
  String get backupRow => 'Backup';
  String get backupRowHint => 'Encrypted .orbit file with all contacts and photos';
  String get createEllipsis => 'Create…';
  String get restoreRow => 'Restore';
  String get restoreRowHint => 'Add contacts from a backup';
  String get restoreEllipsis => 'Restore…';
  String get appFolder => 'App folder';
  String get showInFinder => 'Show in Finder';
  String get showInExplorer => 'Show in Explorer';
  String get openFolderAction => 'Open folder';

  // ── Keyboard shortcuts ──
  String get settingsShortcuts => 'Keyboard shortcuts';
  String get shortcutsIntro => 'Click “Change”, then press the new key combination. Esc cancels.';
  String get shortcutsFixed => 'Built-in';
  String get changeShort => 'Change';
  String get pressKeys => 'Press keys…';
  String get resetDefault => 'Restore default';
  String get resetAll => 'Reset all';
  String needModifier(String first, String last) => 'Add $first or $last';
  String reservedCombo(String c) => '$c is reserved by the system';
  String comboInUse(String c, String action) => '$c is already used for “$action”';
  String get actQuickSearch => 'Quick search';
  String actOpen(String s) => 'Open “$s”';
  String get actSelectAll => 'Select all';
  String get actMoveSelection => 'Move through the list';
  String get actMultiSelect => 'Select several';
  String get click => 'click';
  String get actEditSelected => 'Edit the selected contact';
  String get actTrashSelected => 'Move the selected to trash';
  String get actSaveEditor => 'Save in the editor';
  String get actCloseWindow => 'Close a window or clear the selection';
  // ── Onboarding ──
  String get onbSkip => 'Skip';
  String get onbNext => 'Next';
  String get onbBack => 'Back';
  String get onbStart => 'Get started';
  String get onbWelcomeTitle => 'Welcome to Orbit';
  String get onbWelcomeText => 'A personal base of the people who matter to you: contacts, interests, birthdays and notes in one place.';
  String get onbPeopleTitle => 'Everyone at hand';
  String get onbPeopleText => 'Several phones and emails, Telegram and Instagram, your own fields. Tag interests to find the right people fast.';
  String get onbDatesTitle => 'Never miss a date';
  String get onbDatesText => 'The overview shows upcoming birthdays and people you met this month. Star the most important ones.';
  String get onbPrivacyTitle => 'Only on your computer';
  String get onbPrivacyText => 'Your base and photos are encrypted and stay on this computer. The PIN opens the base; the recovery code helps if you forget it. Backups are encrypted too.';
  String get onbKeysText => 'The most useful actions are a keystroke away. You can change them in Settings → Keyboard shortcuts.';
  String get onbChangeShortcuts => 'Change shortcuts';
  String get onbRow => 'Orbit tour';
  String get onbRowHint => 'A short tour of features and shortcuts';

  // ── CSV ──
  String get csvYes => 'yes';
}
