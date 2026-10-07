// ignore_for_file: annotate_overrides
import 'strings.dart';

class Fr extends Strings {
  const Fr();

  String get locale => 'fr';
  String get languageName => 'Français';

  /// 0 et 1 — au singulier.
  String _p(int n, String one, String many) => n < 2 ? one : many;

  // ── Commun ──
  String get cancel => 'Annuler';
  String get done => 'Terminé';
  String get save => 'Enregistrer';
  String get delete => 'Supprimer';
  String get add => 'Ajouter';
  String get create => 'Créer';
  String get open => 'Ouvrir';
  String get show => 'Afficher';
  String get hide => 'Masquer';
  String get close => 'Fermer';
  String get closeEsc => 'Fermer (Échap)';
  String get clear => 'Effacer';
  String get copy => 'Copier';
  String get undo => 'Annuler';
  String get restore => 'Restaurer';
  String get edit => 'Modifier';
  String get continueAction => 'Continuer';
  String get checking => 'Vérification…';
  String get saving => 'Enregistrement…';
  String get creating => 'Création…';
  String get yes => 'Oui';
  String get no => 'Non';
  String get remove => 'Retirer';
  String get toFavorites => 'Ajouter aux favoris';
  String get removeFromFavorites => 'Retirer des favoris';
  String get toTrash => 'Mettre à la corbeille';
  String get toTrashKey => 'Mettre à la corbeille (⌫)';
  String get deleteForever => 'Supprimer définitivement';
  String get exportCsv => 'Exporter en CSV…';
  String contacts(int n) => '$n ${_p(n, 'contact', 'contacts')}';
  String people(int n) => '$n ${_p(n, 'personne', 'personnes')}';
  String days(int n) => '$n ${_p(n, 'jour', 'jours')}';
  String copied(String value) => 'Copié : $value';

  // ── Sections et tri ──
  String get segDashboard => 'Aperçu';
  String get segAll => 'Contacts';
  String get segFavorites => 'Favoris';
  String get segBirthdays => 'Anniversaires';
  String get segRecent => 'Nouveaux ce mois-ci';
  String get segTrash => 'Corbeille';
  String get sortNameAsc => 'Nom : A → Z';
  String get sortNameDesc => 'Nom : Z → A';
  String get sortNewest => 'Les plus récents d’abord';
  String get sortOldest => 'Les plus anciens d’abord';
  String get sortMetRecent => 'Rencontrés récemment';

  // ── Fenêtre principale ──
  String movedToTrashOne(String name) => '« $name » mis à la corbeille';
  String movedToTrashMany(int n) => 'Mis à la corbeille : ${contacts(n)}';
  String restoredMany(int n) => 'Restaurés : ${contacts(n)}';
  String purgeTitle(int n) => 'Supprimer définitivement ${contacts(n)} ?';
  String get purgeMessage => 'Les contacts et leurs photos seront supprimés sans possibilité de récupération.';
  String get nothingToExport => 'Rien à exporter';
  String savedContacts(int n) => 'Enregistrés : ${contacts(n)}';
  String saveFileFailed(Object e) => 'Impossible d’enregistrer le fichier : $e';
  String get searchPlaceholder => 'Rechercher un contact…';
  String get personalBase => 'Base personnelle';
  String get menuImport => 'Importer depuis CSV ou vCard…';
  String get menuBackup => 'Sauvegarde…';
  String get menuRestore => 'Restaurer une sauvegarde…';
  String get lock => 'Verrouiller';
  String get about => 'À propos';
  String get language => 'Langue';
  String get systemLanguage => 'Système';
  String get allInterests => 'Tous les centres d’intérêt';
  String get interestsHint => 'Centres d’intérêt : créer et supprimer';
  String get emptyTrash => 'Vider la corbeille';
  String get viewTable => 'Tableau';
  String get viewCards => 'Cartes';
  String get newShort => 'Nouveau';
  String get noContactsTitle => 'Aucun contact pour l’instant';
  String get noContactsSubtitle => 'Ajoutez une première personne ou importez des contacts depuis CSV ou vCard';
  String get importShort => 'Importer…';
  String get newContact => 'Nouveau contact';
  String get nothingFound => 'Aucun résultat';
  String nothingFoundFor(String q) => 'Aucun contact pour « $q »';
  String get trashEmpty => 'La corbeille est vide';
  String trashEmptySubtitle(int days) => 'Les contacts supprimés sont conservés ici ${this.days(days)}';
  String get favoritesEmpty => 'Aucun favori pour l’instant';
  String get favoritesEmptySubtitle => 'Ajoutez une étoile aux personnes qui comptent le plus pour vous';
  String get recentEmpty => 'Aucune nouvelle personne pour l’instant';
  String get recentEmptySubtitle => 'Les personnes ajoutées ces 30 derniers jours apparaîtront ici';
  String get birthdaysEmpty => 'Aucun anniversaire à venir';
  String get birthdaysEmptySubtitle => 'Les personnes dont l’anniversaire tombe dans les 30 prochains jours apparaîtront ici';
  String get segmentEmpty => 'Personne ici pour l’instant';
  String get segmentEmptySubtitle => 'Cette section ne contient aucun contact';
  String get noSelectionTitle => 'Aucun contact sélectionné';
  String noSelectionSubtitle(String mod, String shift) => 'Choisissez une personne dans la liste. Avec $mod ou $shift, plusieurs à la fois';
  String get interests => 'Centres d’intérêt';
  String get fieldsAndSections => 'Champs et sections';
  String selectedCount(int n) => 'Sélectionnés : ${contacts(n)}';

  // ── Aperçu ──
  String get goodNight => 'Bonne nuit';
  String get goodMorning => 'Bonjour';
  String get goodAfternoon => 'Bon après-midi';
  String get goodEvening => 'Bonsoir';
  String get totalContacts => 'Contacts au total';
  String get viewList => 'Voir la liste';

  // ── Apparence ──
  String get appearance => 'Apparence';
  String get themeLight => 'Clair';
  String get themeSystem => 'Système';
  String get themeDark => 'Sombre';

  // ── Import, export, sauvegardes ──
  String get contactsFileType => 'Contacts';
  String get imagesFileType => 'Images';
  String get backupFileType => 'Sauvegarde Orbit';
  String readFileFailed(Object e) => 'Impossible de lire le fichier : $e';
  String get noContactsInFile => 'Aucun contact trouvé dans le fichier';
  String allAlreadyExist(int n) => 'Les ${contacts(n)} du fichier sont déjà dans votre base';
  String importTitle(String file) => 'Importer depuis « $file »';
  String importMessage(int found, int dupes) =>
      '${contacts(found)} ${_p(found, 'trouvé', 'trouvés')}.'
      '${dupes > 0 ? ' ${contacts(dupes)} déjà dans votre base seront ignorés.' : ''}';
  String importConfirm(int n) => 'Importer $n';
  String imported(int n) => 'Importés : ${contacts(n)}';
  String get backupSaved => 'Sauvegarde enregistrée';
  String backupSaveFailed(Object e) => 'Impossible d’enregistrer la sauvegarde : $e';
  String get restoreTitle => 'Restaurer la sauvegarde ?';
  String restoreMessage(int n, String? date) =>
      'La sauvegarde contient ${contacts(n)}${date == null ? '' : ' du $date'}. '
      'Les nouvelles personnes seront ajoutées ; pour celles déjà présentes, la version la plus récente est conservée.';
  String get restoreNothingNew => 'Tout le contenu de la sauvegarde est déjà dans votre base';
  String restoreResult(int added, int updated) => 'Ajoutés : $added, mis à jour : $updated';
  String get notABackup => 'Ce n’est pas une sauvegarde Orbit';
  String get fileCorrupted => 'Le fichier est endommagé';
  String codeLength(int n) => 'Le code comporte $n caractères';
  String get codeNotForBackup => 'Ce code ne correspond pas à cette sauvegarde';
  String get needRecoveryTitle => 'Code de récupération requis';
  String get needRecoverySubtitle => 'La sauvegarde a été faite sur une autre installation d’Orbit';
  String get recoveryFromOtherInstall => 'Le code affiché par cette installation lors de la première configuration';
  String openFolderFailed(String path) => 'Impossible d’ouvrir le dossier : $path';

  // ── PIN et code de récupération ──
  String get pinChanged => 'Code PIN modifié';
  String get wrongCurrentPin => 'Code PIN actuel incorrect';
  String get wrongPin => 'Code PIN incorrect';
  String get changePinTitle => 'Changer le code PIN';
  String get changePinSubtitle => 'Le code de récupération reste le même';
  String get currentPin => 'Code PIN actuel';
  String get newPinOrPassword => 'Nouveau code PIN ou mot de passe';
  String get pinOrPassword => 'Code PIN ou mot de passe';
  String get repeat => 'Répétez';
  String minLength(int n) => 'Au moins $n caractères';
  String pinHint(int n) => 'Au moins $n caractères. Un long mot de passe est plus sûr qu’un court code PIN numérique.';
  String get pinsMismatch => 'Les codes PIN ne correspondent pas';
  String get regenerateTitle => 'Créer un nouveau code de récupération ?';
  String get regenerateMessage =>
      'L’ancien code n’ouvrira plus la base. Les sauvegardes faites auparavant ne s’ouvrent qu’avec l’ancien code : '
      'si vous l’avez, conservez-le avec elles.';
  String get revealIntro => 'Le code de récupération sert si vous oubliez votre code PIN, et pour ouvrir une sauvegarde sur un autre ordinateur. Saisissez votre code PIN pour l’afficher.';
  String get revealKeepSafe =>
      'Enregistrez le code dans un gestionnaire de mots de passe ou notez-le. Ne le gardez pas à côté des sauvegardes.';
  String get revealLegacy =>
      'Cette base a été configurée dans une version antérieure d’Orbit et le code de récupération n’a pas été conservé : '
      'impossible de l’afficher. Vous pouvez créer un nouveau code.';
  String get createNewCode => 'Créer un nouveau code';
  String get saveRecoveryTitle => 'Enregistrez le code de récupération';
  String get saveRecoverySubtitle => 'Il vous servira si vous oubliez votre code PIN, et pour restaurer une sauvegarde sur un autre ordinateur. Le code n’est affiché que maintenant.';
  String get savedCodeCheck => 'J’ai enregistré le code en lieu sûr';
  String get encrypting => 'Chiffrement de la base…';
  String get openOrbit => 'Ouvrir Orbit';
  String get protectTitle => 'Protégez votre base';
  String get protectExisting =>
      'Choisissez un code PIN ou un mot de passe : vos contacts et photos existants seront chiffrés sur le disque.';
  String get protectNew => 'Choisissez un code PIN ou un mot de passe : contacts et photos seront stockés chiffrés sur le disque.';
  String get creatingKeys => 'Création des clés…';
  String get codeCopied => 'Code de récupération copié';
  String get codeWrongCase => 'Le code ne correspond pas. Vérifiez les majuscules et minuscules';
  String get lockedTitle => 'Orbit est verrouillé';
  String get lockedSubtitle => 'Saisissez votre code PIN pour ouvrir la base';
  String tooManyAttempts(int s) => 'Trop de tentatives. Patientez $s s';
  String get forgotPin => 'Code PIN oublié ? Se connecter avec le code de récupération';
  String get recoveryLoginTitle => 'Connexion avec le code de récupération';
  String get recoveryLoginSubtitle =>
      'Saisissez le code qu’Orbit a affiché lors de la première configuration. Vous choisirez ensuite un nouveau code PIN.';
  String get backToPin => 'Retour au code PIN';
  String get newPinTitle => 'Nouveau code PIN';
  String get newPinSubtitle => 'Le code est correct. Choisissez un nouveau code PIN ; le code de récupération reste le même.';
  String get saveAndOpen => 'Enregistrer et ouvrir';

  // ── Fiche contact ──
  String get editContact => 'Modifier le contact';
  String formShortcuts(String save) => '$save — enregistrer, Échap — annuler';
  String get enterName => 'Saisissez un nom';
  String get badEmail => 'E-mail non valide';
  String get addOwnSection => 'Ajouter une section';
  String get choosePhoto => 'Choisir une photo';
  String get photo => 'Photo';
  String get chooseEllipsis => 'Choisir…';
  String get replaceEllipsis => 'Remplacer…';
  String get fieldButton => 'Champ';
  String get configureSection => 'Réglages de la section';
  String get emptySectionHint => 'Section vide — ajoutez un champ avec le bouton « Champ »';
  String get name => 'Nom';
  String get namePlaceholder => 'Prénom et nom';
  String get handlePlaceholder => '@pseudo ou lien';
  String get position => 'Poste';
  String get positionPlaceholder => 'Designer';
  String get company => 'Entreprise';
  String get companyPlaceholder => 'Où il ou elle travaille';
  String get whereMet => 'Lieu de rencontre';
  String get whereMetPlaceholder => 'Conférence, par des amis, …';
  String get where => 'Où';
  String get when => 'Quand';
  String get birthday => 'Anniversaire';
  String get notesPlaceholder => 'Tout ce qui mérite d’être retenu sur cette personne';
  String get phone => 'Téléphone';
  String get phones => 'Téléphones';
  String get email => 'E-mail';
  String get mail => 'Mail';
  String get phonePlaceholder => '+33 6 00 00 00 00';
  String get addPhone => 'Ajouter un téléphone';
  String get addEmail => 'Ajouter un e-mail';
  String get chooseOrCreate => 'Choisir ou créer';
  String get interest => 'Centre d’intérêt';
  String get configureField => 'Réglages du champ';
  String get noOptions => 'Aucune option — ajoutez-en dans les réglages du champ';
  String get notSelected => 'Non choisi';
  String get findOrCreate => 'Chercher ou créer…';
  String createNamed(String q) => 'Créer « $q »';
  String get noInterestsCreate => 'Aucun centre d’intérêt — saisissez un nom pour en créer un';
  String get manageInterests => 'Gérer les centres d’intérêt…';
  String get birthdayToday => '🎂 Anniversaire aujourd’hui';
  String birthdayIn(int n) => '🎂 Anniversaire dans ${days(n)}';
  String addedChanged(String added, String changed) => 'Ajouté le $added\nModifié le $changed';
  String get trashTomorrow => 'Dans la corbeille · supprimé demain';
  String trashIn(int n) => 'Dans la corbeille · supprimé dans ${days(n)}';
  String notSpecified(String what) => '$what : non renseigné';

  // ── Libellés des téléphones et e-mails ──
  String get labelMobile => 'mobile';
  String get labelWork => 'travail';
  String get labelHome => 'domicile';
  String get labelOther => 'autre';
  String get labelPersonal => 'personnel';

  // ── Tableau ──
  String get colWork => 'Travail';
  String get colMet => 'Rencontre';
  String get colFavorite => 'Favori';
  String get colCreated => 'Ajouté';
  String get configureColumn => 'Réglages de la colonne';
  String get sort => 'Trier';
  String get addColumn => 'Ajouter une colonne';
  String get columns => 'Colonnes';
  String get cannotHideColumn => 'Cette colonne ne peut pas être masquée';
  String get nameAlwaysFirst => 'Le nom est toujours en premier et ne peut pas être masqué';
  String get reorderHint => 'Glissez pour réordonner avec ';
  String get newFieldEllipsis => 'Nouveau champ…';

  // ── Champs et sections ──
  String get typeText => 'Texte';
  String get typeMultiline => 'Texte long';
  String get typeNumber => 'Nombre';
  String get typeUrl => 'Lien';
  String get typeDate => 'Date';
  String get typeSelect => 'Liste';
  String get typeCheckbox => 'Oui / non';
  String get sectionMain => 'Principal';
  String get sectionInterests => 'Centres d’intérêt';
  String get notes => 'Notes';
  String get emails => 'Adresses e-mail';
  String get metDate => 'Date de rencontre';
  String deleteFieldTitle(String name) => 'Supprimer le champ « $name » ?';
  String get deleteFieldMessage => 'Les valeurs de ce champ seront supprimées de tous les contacts.';
  String get newField => 'Nouveau champ';
  String get fieldSettings => 'Réglages du champ';
  String get deleteField => 'Supprimer le champ';
  String get title => 'Nom';
  String get fieldNamePlaceholder => 'Par exemple : Ville, Café préféré';
  String get fieldType => 'Type de champ';
  String get optionsLabel => 'Options · Entrée ou virgule pour ajouter';
  String get newOption => 'Nouvelle option';
  String get section => 'Section';
  String get icon => 'Icône';
  String get tableColumn => 'Colonne du tableau';
  String get tableColumnHint => 'Afficher ce champ dans la liste des contacts';
  String deleteSectionTitle(String name) => 'Supprimer la section « $name » ?';
  String get sectionEmptyNoLoss => 'La section est vide, rien ne sera perdu.';
  String deleteSectionFields(int n) =>
      'Avec la section, $n ${_p(n, 'champ sera supprimé', 'champs seront supprimés')}, ainsi que leurs valeurs dans tous les contacts.';
  String get newSection => 'Nouvelle section';
  String get sectionSettings => 'Réglages de la section';
  String get builtInSectionNote => 'Une section standard peut être renommée, mais pas supprimée';
  String get deleteSection => 'Supprimer la section';
  String get sectionName => 'Nom de la section';
  String get sectionNamePlaceholder => 'Par exemple : Réseaux, Famille, Projets';
  String get dragToReorder => 'Glissez par ⠿ pour changer l’ordre';
  String get standardTag => 'standard';
  String get builtInField => 'Champ intégré';
  String get shownInTable => 'Affiché dans le tableau';
  String get noFieldsInSection => 'Aucun champ dans cette section pour l’instant';
  String get addField => 'Ajouter un champ';

  // ── Centres d’intérêt ──
  String get interestExists => 'Ce centre d’intérêt existe déjà';
  String deleteInterestTitle(String name) => 'Supprimer le centre d’intérêt « $name » ?';
  String get deleteInterestUnused => 'Aucun contact n’a ce centre d’intérêt.';
  String deleteInterestMessage(int n) =>
      'Ce centre d’intérêt est indiqué pour ${contacts(n)}. Si vous le supprimez, il disparaîtra '
      '${_p(n, 'de sa fiche', 'de leurs fiches')} et le filtre rapide par centre d’intérêt ne trouvera plus '
      '${_p(n, 'ce contact', 'ces contacts')}.';
  String get interestsSubtitle => 'Créez-les à l’avance — vous pourrez ensuite les choisir dans la fiche d’un contact';
  String get newInterestLabel => 'Nouveau centre d’intérêt · plusieurs séparés par des virgules';
  String get interestsPlaceholder => 'Par exemple : Design, Course, Livres';
  String get noInterests => 'Aucun centre d’intérêt pour l’instant';
  String get nobody => 'personne';
  String get deleteInterest => 'Supprimer le centre d’intérêt';

  // ── Calendrier ──
  String get dateNotSet => 'Non renseignée';
  String get prevMonth => 'Mois précédent';
  String get nextMonth => 'Mois suivant';
  String get today => 'Aujourd’hui';

  // ── Recherche rapide ──
  String get spotlightPlaceholder => 'Nom de la personne…';
  String noneFoundFor(String q) => 'Personne trouvé pour « $q »';
  String get favoritesAndRecentCaps => 'FAVORIS ET RÉCENTS';
  String get contactsCaps => 'CONTACTS';

  // ── À propos ──
  String get tagline => 'Base personnelle de contacts';
  String get developer => 'Développeur';
  String get design => 'Design';
  String designCredit(String title, String author) =>
      'Inspiré de la maquette « $title » de $author (Figma Community). L’interface a été retravaillée et modifiée par mrgsdev.';
  String get figmaLayout => 'Maquette dans Figma';
  String license(String name) => 'Licence $name';
  String get fonts => 'Polices';
  String get fontsLicense => 'Montserrat et Marck Script — SIL Open Font License 1.1';

  // ── Réglages ──
  String get settings => 'Réglages';
  String get menuSettings => 'Réglages…';
  String get settingsGeneral => 'Général';
  String get settingsSecurity => 'Sécurité';
  String get settingsData => 'Données';
  String get languageHint => 'Langue des menus, boutons et messages';
  String get appearanceHint => 'Clair, sombre ou comme le système';
  String get interestsRowHint => 'Pour filtrer rapidement les personnes';
  String interestsCount(int n) => '$n ${_p(n, 'centre d’intérêt', 'centres d’intérêt')}';
  String get fieldsRowHint => 'Vos propres champs et sections dans la fiche contact';
  String get configureEllipsis => 'Configurer…';
  String trashRowHint(int d) => 'Les contacts supprimés sont conservés ${days(d)}, puis disparaissent';
  String get pinRow => 'Code PIN';
  String get pinRowHint => 'Ouvre la base au lancement';
  String get changeEllipsis => 'Modifier…';
  String get recoveryRow => 'Code de récupération';
  String get recoveryRowHint => 'Nécessaire si vous oubliez le code PIN et pour les sauvegardes sur un autre ordinateur';
  String get showEllipsis => 'Afficher…';
  String get lockNow => 'Verrouiller maintenant';
  String lockRowHint(String combo) => 'Ou $combo à tout moment';
  String get importRowHint => 'CSV (Google, Excel, export Orbit) et vCard';
  String get exportRowHint => 'Tous les contacts dans un fichier CSV';
  String get exportEllipsis => 'Exporter…';
  String get backupRow => 'Sauvegarde';
  String get backupRowHint => 'Fichier .orbit chiffré avec tous les contacts et photos';
  String get createEllipsis => 'Créer…';
  String get restoreRow => 'Restauration';
  String get restoreRowHint => 'Ajouter des contacts depuis une sauvegarde';
  String get restoreEllipsis => 'Restaurer…';
  String get appFolder => 'Dossier de l’app';
  String get showInFinder => 'Afficher dans le Finder';
  String get showInExplorer => 'Afficher dans l’Explorateur';
  String get openFolderAction => 'Ouvrir le dossier';

  // ── Raccourcis clavier ──
  String get settingsShortcuts => 'Raccourcis clavier';
  String get shortcutsIntro => 'Cliquez sur « Modifier », puis appuyez sur la nouvelle combinaison. Échap annule.';
  String get shortcutsFixed => 'Intégrés';
  String get changeShort => 'Modifier';
  String get pressKeys => 'Appuyez sur les touches…';
  String get resetDefault => 'Rétablir par défaut';
  String get resetAll => 'Tout réinitialiser';
  String needModifier(String first, String last) => 'Ajoutez $first ou $last';
  String reservedCombo(String c) => '$c est réservé par le système';
  String comboInUse(String c, String action) => '$c est déjà utilisé pour « $action »';
  String get actQuickSearch => 'Recherche rapide';
  String actOpen(String s) => 'Ouvrir « $s »';
  String get actSelectAll => 'Tout sélectionner';
  String get actMoveSelection => 'Parcourir la liste';
  String get actMultiSelect => 'Sélectionner plusieurs';
  String get click => 'clic';
  String get actEditSelected => 'Modifier le contact sélectionné';
  String get actTrashSelected => 'Mettre la sélection à la corbeille';
  String get actSaveEditor => 'Enregistrer dans l’éditeur';
  String get actCloseWindow => 'Fermer une fenêtre ou désélectionner';
  // ── Présentation ──
  String get onbSkip => 'Passer';
  String get onbNext => 'Suivant';
  String get onbBack => 'Retour';
  String get onbStart => 'Commencer';
  String get onbWelcomeTitle => 'Bienvenue dans Orbit';
  String get onbWelcomeText => 'Une base personnelle des personnes qui comptent pour vous : contacts, centres d’intérêt, anniversaires et notes au même endroit.';
  String get onbPeopleTitle => 'Tout le monde à portée de main';
  String get onbPeopleText => 'Plusieurs téléphones et e-mails, Telegram et Instagram, vos propres champs. Ajoutez des centres d’intérêt pour trouver vite les bonnes personnes.';
  String get onbDatesTitle => 'N’oubliez rien';
  String get onbDatesText => 'L’aperçu montre les anniversaires à venir et les rencontres du mois. Ajoutez une étoile aux plus importants.';
  String get onbPrivacyTitle => 'Uniquement sur votre ordinateur';
  String get onbPrivacyText => 'La base et les photos sont chiffrées et restent sur cet ordinateur. Le code PIN ouvre la base, le code de récupération vous aide si vous l’oubliez. Les sauvegardes sont aussi chiffrées.';
  String get onbKeysText => 'Les actions essentielles sont au clavier. Vous pouvez les modifier dans Réglages → Raccourcis clavier.';
  String get onbChangeShortcuts => 'Modifier les raccourcis';
  String get onbRow => 'Découvrir Orbit';
  String get onbRowHint => 'Une courte présentation des fonctions et raccourcis';

  // ── CSV ──
  String get csvYes => 'oui';
}
