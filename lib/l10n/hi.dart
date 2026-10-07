// ignore_for_file: annotate_overrides
import 'strings.dart';

class Hi extends Strings {
  const Hi();

  String get locale => 'hi';
  String get languageName => 'हिन्दी';

  // ── सामान्य ──
  String get cancel => 'रद्द करें';
  String get done => 'हो गया';
  String get save => 'सहेजें';
  String get delete => 'हटाएँ';
  String get add => 'जोड़ें';
  String get create => 'बनाएँ';
  String get open => 'खोलें';
  String get show => 'दिखाएँ';
  String get hide => 'छिपाएँ';
  String get close => 'बंद करें';
  String get closeEsc => 'बंद करें (Esc)';
  String get clear => 'साफ़ करें';
  String get copy => 'कॉपी करें';
  String get undo => 'पूर्ववत करें';
  String get restore => 'पुनर्स्थापित करें';
  String get edit => 'बदलें';
  String get continueAction => 'जारी रखें';
  String get checking => 'जाँच हो रही है…';
  String get saving => 'सहेजा जा रहा है…';
  String get creating => 'बनाया जा रहा है…';
  String get yes => 'हाँ';
  String get no => 'नहीं';
  String get remove => 'हटाएँ';
  String get toFavorites => 'पसंदीदा में जोड़ें';
  String get removeFromFavorites => 'पसंदीदा से हटाएँ';
  String get toTrash => 'ट्रैश में डालें';
  String get toTrashKey => 'ट्रैश में डालें (⌫)';
  String get deleteForever => 'हमेशा के लिए हटाएँ';
  String get exportCsv => 'CSV में निर्यात करें…';
  String contacts(int n) => '$n संपर्क';
  String people(int n) => '$n लोग';
  String days(int n) => '$n दिन';
  String copied(String value) => 'कॉपी किया गया: $value';

  // ── अनुभाग और क्रम ──
  String get segDashboard => 'सारांश';
  String get segAll => 'संपर्क';
  String get segFavorites => 'पसंदीदा';
  String get segBirthdays => 'जन्मदिन';
  String get segRecent => 'इस महीने नए';
  String get segTrash => 'ट्रैश';
  String get sortNameAsc => 'नाम: A → Z';
  String get sortNameDesc => 'नाम: Z → A';
  String get sortNewest => 'नए पहले';
  String get sortOldest => 'पुराने पहले';
  String get sortMetRecent => 'हाल में मिले';

  // ── मुख्य विंडो ──
  String movedToTrashOne(String name) => '“$name” ट्रैश में डाला गया';
  String movedToTrashMany(int n) => 'ट्रैश में डाले गए: ${contacts(n)}';
  String restoredMany(int n) => 'पुनर्स्थापित: ${contacts(n)}';
  String purgeTitle(int n) => '${contacts(n)} हमेशा के लिए हटाएँ?';
  String get purgeMessage => 'संपर्क और उनकी फ़ोटो हमेशा के लिए हटा दी जाएँगी, उन्हें वापस नहीं लाया जा सकेगा।';
  String get nothingToExport => 'निर्यात करने के लिए कुछ नहीं है';
  String savedContacts(int n) => 'सहेजे गए: ${contacts(n)}';
  String saveFileFailed(Object e) => 'फ़ाइल सहेजी नहीं जा सकी: $e';
  String get searchPlaceholder => 'संपर्क खोजें…';
  String get personalBase => 'निजी डेटाबेस';
  String get menuImport => 'CSV या vCard से आयात करें…';
  String get menuBackup => 'बैकअप…';
  String get menuRestore => 'बैकअप से पुनर्स्थापित करें…';
  String get lock => 'लॉक करें';
  String get about => 'ऐप के बारे में';
  String get language => 'भाषा';
  String get systemLanguage => 'सिस्टम';
  String get allInterests => 'सभी रुचियाँ';
  String get interestsHint => 'रुचियाँ: बनाएँ और हटाएँ';
  String get emptyTrash => 'ट्रैश खाली करें';
  String get viewTable => 'तालिका';
  String get viewCards => 'कार्ड';
  String get newShort => 'नया';
  String get noContactsTitle => 'अभी कोई संपर्क नहीं है';
  String get noContactsSubtitle => 'पहला संपर्क जोड़ें या CSV या vCard से संपर्क आयात करें';
  String get importShort => 'आयात…';
  String get newContact => 'नया संपर्क';
  String get nothingFound => 'कुछ नहीं मिला';
  String nothingFoundFor(String q) => '“$q” से कोई संपर्क नहीं मिला';
  String get trashEmpty => 'ट्रैश खाली है';
  String trashEmptySubtitle(int days) => 'हटाए गए संपर्क यहाँ ${this.days(days)} तक रखे जाते हैं';
  String get favoritesEmpty => 'पसंदीदा में अभी कोई नहीं';
  String get favoritesEmptySubtitle => 'जो लोग आपके लिए सबसे ख़ास हैं, उन्हें स्टार से चिह्नित करें';
  String get recentEmpty => 'अभी कोई नए लोग नहीं';
  String get recentEmptySubtitle => 'पिछले 30 दिनों में जोड़े गए लोग यहाँ दिखेंगे';
  String get birthdaysEmpty => 'आने वाले जन्मदिन नहीं हैं';
  String get birthdaysEmptySubtitle => 'अगले 30 दिनों में जिनका जन्मदिन है, वे यहाँ दिखेंगे';
  String get segmentEmpty => 'यहाँ अभी कोई नहीं';
  String get segmentEmptySubtitle => 'इस अनुभाग में कोई संपर्क नहीं है';
  String get noSelectionTitle => 'कोई संपर्क चुना नहीं गया';
  String noSelectionSubtitle(String mod, String shift) => 'सूची में से किसी व्यक्ति को चुनें। $mod या $shift से एक साथ कई';
  String get interests => 'रुचियाँ';
  String get fieldsAndSections => 'फ़ील्ड और अनुभाग';
  String selectedCount(int n) => 'चुने गए: ${contacts(n)}';

  // ── सारांश ──
  String get goodNight => 'शुभ रात्रि';
  String get goodMorning => 'सुप्रभात';
  String get goodAfternoon => 'नमस्कार';
  String get goodEvening => 'शुभ संध्या';
  String get totalContacts => 'कुल संपर्क';
  String get viewList => 'सूची देखें';

  // ── रूप ──
  String get appearance => 'रूप';
  String get themeLight => 'हल्का';
  String get themeSystem => 'सिस्टम';
  String get themeDark => 'गहरा';

  // ── आयात, निर्यात, बैकअप ──
  String get contactsFileType => 'संपर्क';
  String get imagesFileType => 'चित्र';
  String get backupFileType => 'Orbit बैकअप';
  String readFileFailed(Object e) => 'फ़ाइल पढ़ी नहीं जा सकी: $e';
  String get noContactsInFile => 'फ़ाइल में कोई संपर्क नहीं मिला';
  String allAlreadyExist(int n) => 'फ़ाइल के सभी ${contacts(n)} पहले से डेटाबेस में हैं';
  String importTitle(String file) => '“$file” से आयात';
  String importMessage(int found, int dupes) =>
      '${contacts(found)} मिले।${dupes > 0 ? ' ${contacts(dupes)} पहले से डेटाबेस में हैं — उन्हें छोड़ दिया जाएगा।' : ''}';
  String importConfirm(int n) => '$n आयात करें';
  String imported(int n) => 'आयात किए गए: ${contacts(n)}';
  String get backupSaved => 'बैकअप सहेजा गया';
  String backupSaveFailed(Object e) => 'बैकअप सहेजा नहीं जा सका: $e';
  String get restoreTitle => 'बैकअप से पुनर्स्थापित करें?';
  String restoreMessage(int n, String? date) =>
      'बैकअप में ${contacts(n)} हैं${date == null ? '' : ' ($date)'}। '
      'नए लोग जोड़े जाएँगे, और जो पहले से हैं उनका नया संस्करण रखा जाएगा।';
  String get restoreNothingNew => 'बैकअप की सारी सामग्री पहले से डेटाबेस में है';
  String restoreResult(int added, int updated) => 'जोड़े गए: $added, अपडेट किए गए: $updated';
  String get notABackup => 'यह Orbit बैकअप नहीं है';
  String get fileCorrupted => 'फ़ाइल क्षतिग्रस्त है';
  String codeLength(int n) => 'कोड में $n अक्षर होते हैं';
  String get codeNotForBackup => 'यह कोड इस बैकअप से मेल नहीं खाता';
  String get needRecoveryTitle => 'रिकवरी कोड चाहिए';
  String get needRecoverySubtitle => 'यह बैकअप Orbit के किसी दूसरे इंस्टॉलेशन पर बनाया गया था';
  String get recoveryFromOtherInstall => 'वह कोड जो उस इंस्टॉलेशन ने पहली सेटिंग के समय दिखाया था';
  String openFolderFailed(String path) => 'फ़ोल्डर खोला नहीं जा सका: $path';

  // ── PIN और रिकवरी कोड ──
  String get pinChanged => 'PIN बदल दिया गया';
  String get wrongCurrentPin => 'वर्तमान PIN गलत है';
  String get wrongPin => 'PIN गलत है';
  String get changePinTitle => 'PIN बदलें';
  String get changePinSubtitle => 'रिकवरी कोड वही रहेगा';
  String get currentPin => 'वर्तमान PIN';
  String get newPinOrPassword => 'नया PIN या पासवर्ड';
  String get pinOrPassword => 'PIN या पासवर्ड';
  String get repeat => 'दोबारा दर्ज करें';
  String minLength(int n) => 'कम से कम $n अक्षर';
  String pinHint(int n) => 'कम से कम $n अक्षर। लंबा पासवर्ड छोटे अंकों वाले PIN से ज़्यादा सुरक्षित है।';
  String get pinsMismatch => 'PIN मेल नहीं खाते';
  String get regenerateTitle => 'नया रिकवरी कोड बनाएँ?';
  String get regenerateMessage =>
      'पुराना कोड अब डेटाबेस नहीं खोलेगा। पहले बनाए गए बैकअप अब भी केवल पुराने कोड से खुलेंगे — '
      'अगर वह आपके पास है, तो उसे बैकअप के साथ सहेज कर रखें।';
  String get revealIntro => 'PIN भूल जाने पर और किसी दूसरे कंप्यूटर पर बैकअप खोलने के लिए रिकवरी कोड चाहिए। इसे देखने के लिए PIN दर्ज करें।';
  String get revealKeepSafe => 'कोड को पासवर्ड मैनेजर में सहेजें या लिख लें। इसे बैकअप के पास न रखें।';
  String get revealLegacy =>
      'यह डेटाबेस Orbit के पुराने संस्करण में सेट किया गया था और इसमें रिकवरी कोड सहेजा नहीं गया — '
      'इसलिए इसे दिखाया नहीं जा सकता। आप नया कोड बना सकते हैं।';
  String get createNewCode => 'नया कोड बनाएँ';
  String get saveRecoveryTitle => 'रिकवरी कोड सहेजें';
  String get saveRecoverySubtitle => 'PIN भूल जाने पर और किसी दूसरे कंप्यूटर पर बैकअप पुनर्स्थापित करने के लिए यह चाहिए। कोड केवल अभी दिखाया जा रहा है।';
  String get savedCodeCheck => 'मैंने कोड सुरक्षित जगह पर सहेज लिया है';
  String get encrypting => 'डेटाबेस एन्क्रिप्ट हो रहा है…';
  String get openOrbit => 'Orbit खोलें';
  String get protectTitle => 'अपने डेटाबेस को सुरक्षित करें';
  String get protectExisting => 'PIN या पासवर्ड चुनें — मौजूदा संपर्क और फ़ोटो डिस्क पर एन्क्रिप्ट किए जाएँगे।';
  String get protectNew => 'PIN या पासवर्ड चुनें — संपर्क और फ़ोटो डिस्क पर एन्क्रिप्टेड रूप में रखे जाएँगे।';
  String get creatingKeys => 'कुंजियाँ बनाई जा रही हैं…';
  String get codeCopied => 'रिकवरी कोड कॉपी किया गया';
  String get codeWrongCase => 'कोड मेल नहीं खाता। बड़े और छोटे अक्षर जाँचें';
  String get lockedTitle => 'Orbit लॉक है';
  String get lockedSubtitle => 'डेटाबेस खोलने के लिए PIN दर्ज करें';
  String tooManyAttempts(int s) => 'बहुत ज़्यादा प्रयास। $s सेकंड रुकें';
  String get forgotPin => 'PIN भूल गए? रिकवरी कोड से लॉग इन करें';
  String get recoveryLoginTitle => 'रिकवरी कोड से लॉग इन';
  String get recoveryLoginSubtitle => 'वह कोड दर्ज करें जो Orbit ने पहली सेटिंग के समय दिखाया था। इसके बाद नया PIN चुनना होगा।';
  String get backToPin => 'PIN पर वापस जाएँ';
  String get newPinTitle => 'नया PIN';
  String get newPinSubtitle => 'कोड सही है। नया PIN चुनें — रिकवरी कोड वही रहेगा।';
  String get saveAndOpen => 'सहेजें और खोलें';

  // ── संपर्क कार्ड ──
  String get editContact => 'संपर्क बदलें';
  String formShortcuts(String save) => '$save — सहेजें, Esc — रद्द करें';
  String get enterName => 'नाम दर्ज करें';
  String get badEmail => 'ईमेल सही नहीं है';
  String get addOwnSection => 'अपना अनुभाग जोड़ें';
  String get choosePhoto => 'फ़ोटो चुनें';
  String get photo => 'फ़ोटो';
  String get chooseEllipsis => 'चुनें…';
  String get replaceEllipsis => 'बदलें…';
  String get fieldButton => 'फ़ील्ड';
  String get configureSection => 'अनुभाग सेटिंग';
  String get emptySectionHint => 'खाली अनुभाग — “फ़ील्ड” बटन से फ़ील्ड जोड़ें';
  String get name => 'नाम';
  String get namePlaceholder => 'नाम और उपनाम';
  String get handlePlaceholder => '@यूज़रनेम या लिंक';
  String get position => 'पद';
  String get positionPlaceholder => 'डिज़ाइनर';
  String get company => 'कंपनी';
  String get companyPlaceholder => 'कहाँ काम करते हैं';
  String get whereMet => 'कहाँ मिले';
  String get whereMetPlaceholder => 'कॉन्फ़्रेंस, दोस्तों के ज़रिए, …';
  String get where => 'कहाँ';
  String get when => 'कब';
  String get birthday => 'जन्मदिन';
  String get notesPlaceholder => 'इस व्यक्ति के बारे में याद रखने लायक हर बात';
  String get phone => 'फ़ोन';
  String get phones => 'फ़ोन';
  String get email => 'ईमेल';
  String get mail => 'मेल';
  String get phonePlaceholder => '+91 98765 43210';
  String get addPhone => 'फ़ोन जोड़ें';
  String get addEmail => 'ईमेल जोड़ें';
  String get chooseOrCreate => 'चुनें या बनाएँ';
  String get interest => 'रुचि';
  String get configureField => 'फ़ील्ड सेटिंग';
  String get noOptions => 'कोई विकल्प नहीं — फ़ील्ड सेटिंग में जोड़ें';
  String get notSelected => 'चुना नहीं गया';
  String get findOrCreate => 'खोजें या बनाएँ…';
  String createNamed(String q) => '“$q” बनाएँ';
  String get noInterestsCreate => 'अभी कोई रुचि नहीं — बनाने के लिए नाम लिखें';
  String get manageInterests => 'रुचियाँ प्रबंधित करें…';
  String get birthdayToday => '🎂 आज जन्मदिन है';
  String birthdayIn(int n) => '🎂 ${days(n)} में जन्मदिन';
  String addedChanged(String added, String changed) => 'जोड़ा गया $added\nबदला गया $changed';
  String get trashTomorrow => 'ट्रैश में · कल हटा दिया जाएगा';
  String trashIn(int n) => 'ट्रैश में · ${days(n)} में हटा दिया जाएगा';
  String notSpecified(String what) => '$what नहीं दिया गया';

  // ── फ़ोन और ईमेल लेबल ──
  String get labelMobile => 'मोबाइल';
  String get labelWork => 'काम';
  String get labelHome => 'घर';
  String get labelOther => 'अन्य';
  String get labelPersonal => 'निजी';

  // ── तालिका ──
  String get colWork => 'काम';
  String get colMet => 'मुलाक़ात';
  String get colFavorite => 'पसंदीदा';
  String get colCreated => 'जोड़ा गया';
  String get configureColumn => 'कॉलम सेटिंग';
  String get sort => 'क्रमबद्ध करें';
  String get addColumn => 'कॉलम जोड़ें';
  String get columns => 'कॉलम';
  String get cannotHideColumn => 'यह कॉलम छिपाया नहीं जा सकता';
  String get nameAlwaysFirst => 'नाम हमेशा पहले रहता है और छिपाया नहीं जा सकता';
  String get reorderHint => 'क्रम बदलने के लिए खींचें: ';
  String get newFieldEllipsis => 'नया फ़ील्ड…';

  // ── फ़ील्ड और अनुभाग ──
  String get typeText => 'टेक्स्ट';
  String get typeMultiline => 'लंबा टेक्स्ट';
  String get typeNumber => 'संख्या';
  String get typeUrl => 'लिंक';
  String get typeDate => 'तारीख़';
  String get typeSelect => 'सूची';
  String get typeCheckbox => 'हाँ / नहीं';
  String get sectionMain => 'मुख्य';
  String get sectionInterests => 'रुचि के क्षेत्र';
  String get notes => 'नोट्स';
  String get emails => 'ईमेल पते';
  String get metDate => 'मुलाक़ात की तारीख़';
  String deleteFieldTitle(String name) => 'फ़ील्ड “$name” हटाएँ?';
  String get deleteFieldMessage => 'इस फ़ील्ड के मान सभी संपर्कों से हटा दिए जाएँगे।';
  String get newField => 'नया फ़ील्ड';
  String get fieldSettings => 'फ़ील्ड सेटिंग';
  String get deleteField => 'फ़ील्ड हटाएँ';
  String get title => 'नाम';
  String get fieldNamePlaceholder => 'उदाहरण: शहर, पसंदीदा कॉफ़ी';
  String get fieldType => 'फ़ील्ड का प्रकार';
  String get optionsLabel => 'विकल्प · जोड़ने के लिए Enter या अल्पविराम';
  String get newOption => 'नया विकल्प';
  String get section => 'अनुभाग';
  String get icon => 'आइकन';
  String get tableColumn => 'तालिका में कॉलम';
  String get tableColumnHint => 'इस फ़ील्ड को संपर्क सूची में दिखाएँ';
  String deleteSectionTitle(String name) => 'अनुभाग “$name” हटाएँ?';
  String get sectionEmptyNoLoss => 'अनुभाग खाली है, कुछ भी नहीं खोएगा।';
  String deleteSectionFields(int n) => 'अनुभाग के साथ $n फ़ील्ड और सभी संपर्कों में उनके मान भी हटा दिए जाएँगे।';
  String get newSection => 'नया अनुभाग';
  String get sectionSettings => 'अनुभाग सेटिंग';
  String get builtInSectionNote => 'मानक अनुभाग का नाम बदला जा सकता है, पर उसे हटाया नहीं जा सकता';
  String get deleteSection => 'अनुभाग हटाएँ';
  String get sectionName => 'अनुभाग का नाम';
  String get sectionNamePlaceholder => 'उदाहरण: सोशल मीडिया, परिवार, प्रोजेक्ट';
  String get dragToReorder => 'क्रम बदलने के लिए ⠿ से खींचें';
  String get standardTag => 'मानक';
  String get builtInField => 'अंतर्निहित फ़ील्ड';
  String get shownInTable => 'तालिका में दिखता है';
  String get noFieldsInSection => 'इस अनुभाग में अभी कोई फ़ील्ड नहीं है';
  String get addField => 'फ़ील्ड जोड़ें';

  // ── रुचियाँ ──
  String get interestExists => 'यह रुचि पहले से मौजूद है';
  String deleteInterestTitle(String name) => 'रुचि “$name” हटाएँ?';
  String get deleteInterestUnused => 'किसी भी संपर्क में यह रुचि नहीं है।';
  String deleteInterestMessage(int n) =>
      'यह रुचि ${contacts(n)} में दी गई है। इसे हटाने पर यह उनके कार्ड से गायब हो जाएगी '
      'और रुचि के अनुसार तेज़ खोज इन संपर्कों को नहीं ढूँढ पाएगी।';
  String get interestsSubtitle => 'पहले से बना लें — फिर उन्हें संपर्क कार्ड में चुना जा सकता है';
  String get newInterestLabel => 'नई रुचि · अल्पविराम से कई जोड़ सकते हैं';
  String get interestsPlaceholder => 'उदाहरण: डिज़ाइन, दौड़, किताबें';
  String get noInterests => 'अभी कोई रुचि नहीं';
  String get nobody => 'किसी के पास नहीं';
  String get deleteInterest => 'रुचि हटाएँ';

  // ── कैलेंडर ──
  String get dateNotSet => 'नहीं दी गई';
  String get prevMonth => 'पिछला महीना';
  String get nextMonth => 'अगला महीना';
  String get today => 'आज';

  // ── त्वरित खोज ──
  String get spotlightPlaceholder => 'व्यक्ति का नाम…';
  String noneFoundFor(String q) => '“$q” के लिए कोई नहीं मिला';
  String get favoritesAndRecentCaps => 'पसंदीदा और हाल के';
  String get contactsCaps => 'संपर्क';

  // ── ऐप के बारे में ──
  String get tagline => 'निजी संपर्क डेटाबेस';
  String get developer => 'डेवलपर';
  String get design => 'डिज़ाइन';
  String designCredit(String title, String author) =>
      '$author के “$title” (Figma Community) से प्रेरित। इंटरफ़ेस को mrgsdev ने दोबारा बनाया और बदला है।';
  String get figmaLayout => 'Figma में डिज़ाइन';
  String license(String name) => 'लाइसेंस $name';
  String get fonts => 'फ़ॉन्ट';
  String get fontsLicense => 'Montserrat और Marck Script — SIL Open Font License 1.1';

  // ── सेटिंग्स ──
  String get settings => 'सेटिंग्स';
  String get menuSettings => 'सेटिंग्स…';
  String get settingsGeneral => 'सामान्य';
  String get settingsSecurity => 'सुरक्षा';
  String get settingsData => 'डेटा';
  String get languageHint => 'मेन्यू, बटन और संदेशों की भाषा';
  String get appearanceHint => 'हल्का, गहरा या सिस्टम जैसा';
  String get interestsRowHint => 'लोगों को जल्दी छाँटने के लिए';
  String interestsCount(int n) => '$n रुचियाँ';
  String get fieldsRowHint => 'संपर्क कार्ड में अपने फ़ील्ड और अनुभाग';
  String get configureEllipsis => 'सेट करें…';
  String trashRowHint(int d) => 'हटाए गए संपर्क ${days(d)} तक रखे जाते हैं, फिर मिट जाते हैं';
  String get pinRow => 'PIN';
  String get pinRowHint => 'ऐप खुलने पर डेटाबेस खोलता है';
  String get changeEllipsis => 'बदलें…';
  String get recoveryRow => 'रिकवरी कोड';
  String get recoveryRowHint => 'PIN भूलने पर और दूसरे कंप्यूटर पर बैकअप के लिए ज़रूरी';
  String get showEllipsis => 'दिखाएँ…';
  String get lockNow => 'अभी लॉक करें';
  String lockRowHint(String combo) => 'या कभी भी $combo दबाएँ';
  String get importRowHint => 'CSV (Google, Excel, Orbit निर्यात) और vCard';
  String get exportRowHint => 'सभी संपर्क एक CSV फ़ाइल में';
  String get exportEllipsis => 'निर्यात…';
  String get backupRow => 'बैकअप';
  String get backupRowHint => 'सभी संपर्कों और फ़ोटो वाली एन्क्रिप्टेड .orbit फ़ाइल';
  String get createEllipsis => 'बनाएँ…';
  String get restoreRow => 'पुनर्स्थापना';
  String get restoreRowHint => 'बैकअप से संपर्क जोड़ें';
  String get restoreEllipsis => 'पुनर्स्थापित करें…';
  String get appFolder => 'ऐप फ़ोल्डर';
  String get showInFinder => 'Finder में दिखाएँ';
  String get showInExplorer => 'एक्सप्लोरर में दिखाएँ';
  String get openFolderAction => 'फ़ोल्डर खोलें';

  // ── कीबोर्ड शॉर्टकट ──
  String get settingsShortcuts => 'कीबोर्ड शॉर्टकट';
  String get shortcutsIntro => '“बदलें” दबाएँ, फिर नया कुंजी संयोजन दबाएँ। Esc से रद्द करें।';
  String get shortcutsFixed => 'अंतर्निहित';
  String get changeShort => 'बदलें';
  String get pressKeys => 'कुंजियाँ दबाएँ…';
  String get resetDefault => 'डिफ़ॉल्ट पर लौटाएँ';
  String get resetAll => 'सभी रीसेट करें';
  String needModifier(String first, String last) => '$first या $last जोड़ें';
  String reservedCombo(String c) => '$c सिस्टम द्वारा आरक्षित है';
  String comboInUse(String c, String action) => '$c पहले से “$action” के लिए है';
  String get actQuickSearch => 'त्वरित खोज';
  String actOpen(String s) => '“$s” खोलें';
  String get actSelectAll => 'सभी चुनें';
  String get actMoveSelection => 'सूची में ऊपर-नीचे जाएँ';
  String get actMultiSelect => 'कई चुनें';
  String get click => 'क्लिक';
  String get actEditSelected => 'चुना हुआ संपर्क बदलें';
  String get actTrashSelected => 'चुने हुए ट्रैश में डालें';
  String get actSaveEditor => 'एडिटर में सहेजें';
  String get actCloseWindow => 'विंडो बंद करें या चयन हटाएँ';
  // ── परिचय ──
  String get onbSkip => 'छोड़ें';
  String get onbNext => 'आगे';
  String get onbBack => 'पीछे';
  String get onbStart => 'शुरू करें';
  String get onbWelcomeTitle => 'Orbit में आपका स्वागत है';
  String get onbWelcomeText => 'आपके ख़ास लोगों का निजी डेटाबेस। संपर्क, रुचियाँ, जन्मदिन और नोट्स सब एक जगह।';
  String get onbPeopleTitle => 'सब लोग एक जगह';
  String get onbPeopleText => 'कई फ़ोन और ईमेल, Telegram और Instagram, अपने फ़ील्ड। रुचियाँ जोड़ें और सही लोगों को जल्दी खोजें।';
  String get onbDatesTitle => 'कुछ भी न भूलें';
  String get onbDatesText => 'सारांश में आने वाले जन्मदिन और इस महीने मिले लोग दिखते हैं। सबसे ख़ास लोगों को स्टार दें।';
  String get onbPrivacyTitle => 'सिर्फ़ आपके कंप्यूटर पर';
  String get onbPrivacyText => 'डेटाबेस और फ़ोटो एन्क्रिप्ट होकर सिर्फ़ इसी कंप्यूटर पर रहते हैं। PIN से डेटाबेस खुलता है, भूलने पर रिकवरी कोड काम आता है। बैकअप भी एन्क्रिप्टेड होते हैं।';
  String get onbKeysText => 'ज़रूरी काम कीबोर्ड से। इन्हें सेटिंग्स → कीबोर्ड शॉर्टकट में बदला जा सकता है।';
  String get onbChangeShortcuts => 'शॉर्टकट बदलें';
  String get onbRow => 'Orbit का परिचय';
  String get onbRowHint => 'सुविधाओं और शॉर्टकट का छोटा परिचय';

  // ── CSV ──
  String get csvYes => 'हाँ';
}
