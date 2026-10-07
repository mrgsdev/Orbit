// ignore_for_file: annotate_overrides
import 'strings.dart';

class Es extends Strings {
  const Es();

  String get locale => 'es';
  String get languageName => 'Español';

  String _p(int n, String one, String many) => n == 1 ? one : many;

  // ── Común ──
  String get cancel => 'Cancelar';
  String get done => 'Listo';
  String get save => 'Guardar';
  String get delete => 'Eliminar';
  String get add => 'Añadir';
  String get create => 'Crear';
  String get open => 'Abrir';
  String get show => 'Mostrar';
  String get hide => 'Ocultar';
  String get close => 'Cerrar';
  String get closeEsc => 'Cerrar (Esc)';
  String get clear => 'Borrar';
  String get copy => 'Copiar';
  String get undo => 'Deshacer';
  String get restore => 'Restaurar';
  String get edit => 'Editar';
  String get continueAction => 'Continuar';
  String get checking => 'Comprobando…';
  String get saving => 'Guardando…';
  String get creating => 'Creando…';
  String get yes => 'Sí';
  String get no => 'No';
  String get remove => 'Quitar';
  String get toFavorites => 'Añadir a favoritos';
  String get removeFromFavorites => 'Quitar de favoritos';
  String get toTrash => 'Mover a la papelera';
  String get toTrashKey => 'Mover a la papelera (⌫)';
  String get deleteForever => 'Eliminar para siempre';
  String get exportCsv => 'Exportar a CSV…';
  String contacts(int n) => '$n ${_p(n, 'contacto', 'contactos')}';
  String people(int n) => '$n ${_p(n, 'persona', 'personas')}';
  String days(int n) => '$n ${_p(n, 'día', 'días')}';
  String copied(String value) => 'Copiado: $value';

  // ── Secciones y orden ──
  String get segDashboard => 'Resumen';
  String get segAll => 'Contactos';
  String get segFavorites => 'Favoritos';
  String get segBirthdays => 'Cumpleaños';
  String get segRecent => 'Nuevos del mes';
  String get segTrash => 'Papelera';
  String get sortNameAsc => 'Nombre: A → Z';
  String get sortNameDesc => 'Nombre: Z → A';
  String get sortNewest => 'Más recientes primero';
  String get sortOldest => 'Más antiguos primero';
  String get sortMetRecent => 'Conocidos recientemente';

  // ── Ventana principal ──
  String movedToTrashOne(String name) => '«$name» se movió a la papelera';
  String movedToTrashMany(int n) => 'En la papelera: ${contacts(n)}';
  String restoredMany(int n) => 'Restaurados: ${contacts(n)}';
  String purgeTitle(int n) => '¿Eliminar ${contacts(n)} para siempre?';
  String get purgeMessage => 'Los contactos y sus fotos se eliminarán sin posibilidad de recuperarlos.';
  String get nothingToExport => 'No hay nada que exportar';
  String savedContacts(int n) => 'Guardados: ${contacts(n)}';
  String saveFileFailed(Object e) => 'No se pudo guardar el archivo: $e';
  String get searchPlaceholder => 'Buscar contactos…';
  String get personalBase => 'Base personal';
  String get menuImport => 'Importar desde CSV o vCard…';
  String get menuBackup => 'Copia de seguridad…';
  String get menuRestore => 'Restaurar desde copia…';
  String get lock => 'Bloquear';
  String get about => 'Acerca de';
  String get language => 'Idioma';
  String get systemLanguage => 'Del sistema';
  String get allInterests => 'Todos los intereses';
  String get interestsHint => 'Intereses: crear y eliminar';
  String get emptyTrash => 'Vaciar papelera';
  String get viewTable => 'Tabla';
  String get viewCards => 'Tarjetas';
  String get newShort => 'Nuevo';
  String get noContactsTitle => 'Aún no hay contactos';
  String get noContactsSubtitle => 'Añade a la primera persona o importa contactos desde CSV o vCard';
  String get importShort => 'Importar…';
  String get newContact => 'Nuevo contacto';
  String get nothingFound => 'No se encontró nada';
  String nothingFoundFor(String q) => 'Ningún contacto coincide con «$q»';
  String get trashEmpty => 'La papelera está vacía';
  String trashEmptySubtitle(int days) => 'Los contactos eliminados se guardan aquí ${this.days(days)}';
  String get favoritesEmpty => 'Aún no hay favoritos';
  String get favoritesEmptySubtitle => 'Marca con una estrella a quienes más te importan';
  String get recentEmpty => 'Aún no hay personas nuevas';
  String get recentEmptySubtitle => 'Aquí aparecerán las personas añadidas en los últimos 30 días';
  String get birthdaysEmpty => 'No hay cumpleaños próximos';
  String get birthdaysEmptySubtitle => 'Aquí aparecerán quienes cumplan años en los próximos 30 días';
  String get segmentEmpty => 'Aún no hay nadie aquí';
  String get segmentEmptySubtitle => 'Esta sección no tiene contactos';
  String get noSelectionTitle => 'Ningún contacto seleccionado';
  String noSelectionSubtitle(String mod, String shift) => 'Elige a una persona en la lista. Con $mod o $shift, varias a la vez';
  String get interests => 'Intereses';
  String get fieldsAndSections => 'Campos y secciones';
  String selectedCount(int n) => 'Seleccionados: ${contacts(n)}';

  // ── Resumen ──
  String get goodNight => 'Buenas noches';
  String get goodMorning => 'Buenos días';
  String get goodAfternoon => 'Buenas tardes';
  String get goodEvening => 'Buenas noches';
  String get totalContacts => 'Contactos en total';
  String get viewList => 'Ver la lista';

  // ── Apariencia ──
  String get appearance => 'Apariencia';
  String get themeLight => 'Claro';
  String get themeSystem => 'Sistema';
  String get themeDark => 'Oscuro';

  // ── Importar, exportar, copias ──
  String get contactsFileType => 'Contactos';
  String get imagesFileType => 'Imágenes';
  String get backupFileType => 'Copia de seguridad de Orbit';
  String readFileFailed(Object e) => 'No se pudo leer el archivo: $e';
  String get noContactsInFile => 'No se encontraron contactos en el archivo';
  String allAlreadyExist(int n) => 'Los ${contacts(n)} del archivo ya están en tu base';
  String importTitle(String file) => 'Importar desde «$file»';
  String importMessage(int found, int dupes) =>
      'Se encontraron ${contacts(found)}.${dupes > 0 ? ' ${contacts(dupes)} ya están en tu base y se omitirán.' : ''}';
  String importConfirm(int n) => 'Importar $n';
  String imported(int n) => 'Importados: ${contacts(n)}';
  String get backupSaved => 'Copia de seguridad guardada';
  String backupSaveFailed(Object e) => 'No se pudo guardar la copia: $e';
  String get restoreTitle => '¿Restaurar desde la copia?';
  String restoreMessage(int n, String? date) =>
      'La copia tiene ${contacts(n)}${date == null ? '' : ' del $date'}. '
      'Se añadirán las personas nuevas; de las que ya existen se conservará la versión más reciente.';
  String get restoreNothingNew => 'Todo lo de la copia ya está en tu base';
  String restoreResult(int added, int updated) => 'Añadidos: $added, actualizados: $updated';
  String get notABackup => 'Esto no es una copia de seguridad de Orbit';
  String get fileCorrupted => 'El archivo está dañado';
  String codeLength(int n) => 'El código tiene $n caracteres';
  String get codeNotForBackup => 'El código no corresponde a esta copia';
  String get needRecoveryTitle => 'Se necesita el código de recuperación';
  String get needRecoverySubtitle => 'La copia se hizo en otra instalación de Orbit';
  String get recoveryFromOtherInstall => 'El código que esa instalación mostró en la configuración inicial';
  String openFolderFailed(String path) => 'No se pudo abrir la carpeta: $path';

  // ── PIN y código de recuperación ──
  String get pinChanged => 'PIN cambiado';
  String get wrongCurrentPin => 'El PIN actual es incorrecto';
  String get wrongPin => 'PIN incorrecto';
  String get changePinTitle => 'Cambiar PIN';
  String get changePinSubtitle => 'El código de recuperación no cambia';
  String get currentPin => 'PIN actual';
  String get newPinOrPassword => 'Nuevo PIN o contraseña';
  String get pinOrPassword => 'PIN o contraseña';
  String get repeat => 'Repítelo';
  String minLength(int n) => 'Al menos $n caracteres';
  String pinHint(int n) => 'Al menos $n caracteres. Una contraseña larga es más segura que un PIN numérico corto.';
  String get pinsMismatch => 'Los PIN no coinciden';
  String get regenerateTitle => '¿Crear un nuevo código de recuperación?';
  String get regenerateMessage =>
      'El código anterior dejará de abrir la base. Las copias hechas antes solo se abren con el código anterior: '
      'si lo tienes, guárdalo junto con ellas.';
  String get revealIntro => 'El código de recuperación sirve si olvidas el PIN y para abrir una copia en otro ordenador. Introduce el PIN para mostrarlo.';
  String get revealKeepSafe => 'Guarda el código en un gestor de contraseñas o anótalo. No lo guardes junto a las copias.';
  String get revealLegacy =>
      'Esta base se configuró en una versión anterior de Orbit y el código de recuperación no se guardó: '
      'no se puede mostrar. Puedes crear un código nuevo.';
  String get createNewCode => 'Crear código nuevo';
  String get saveRecoveryTitle => 'Guarda el código de recuperación';
  String get saveRecoverySubtitle => 'Lo necesitarás si olvidas el PIN y para restaurar una copia en otro ordenador. El código solo se muestra ahora.';
  String get savedCodeCheck => 'He guardado el código en un lugar seguro';
  String get encrypting => 'Cifrando la base…';
  String get openOrbit => 'Abrir Orbit';
  String get protectTitle => 'Protege tu base';
  String get protectExisting => 'Elige un PIN o una contraseña: los contactos y fotos existentes se cifrarán en el disco.';
  String get protectNew => 'Elige un PIN o una contraseña: los contactos y fotos se guardarán cifrados en el disco.';
  String get creatingKeys => 'Creando claves…';
  String get codeCopied => 'Código de recuperación copiado';
  String get codeWrongCase => 'El código no es correcto. Revisa mayúsculas y minúsculas';
  String get lockedTitle => 'Orbit está bloqueado';
  String get lockedSubtitle => 'Introduce el PIN para abrir la base';
  String tooManyAttempts(int s) => 'Demasiados intentos. Espera $s s';
  String get forgotPin => '¿Olvidaste el PIN? Entra con el código de recuperación';
  String get recoveryLoginTitle => 'Entrar con el código de recuperación';
  String get recoveryLoginSubtitle => 'Introduce el código que Orbit mostró en la configuración inicial. Después elegirás un PIN nuevo.';
  String get backToPin => 'Volver al PIN';
  String get newPinTitle => 'Nuevo PIN';
  String get newPinSubtitle => 'El código es correcto. Elige un PIN nuevo; el código de recuperación no cambia.';
  String get saveAndOpen => 'Guardar y abrir';

  // ── Ficha de contacto ──
  String get editContact => 'Editar contacto';
  String formShortcuts(String save) => '$save — guardar, Esc — cancelar';
  String get enterName => 'Escribe un nombre';
  String get badEmail => 'Correo no válido';
  String get addOwnSection => 'Añadir una sección propia';
  String get choosePhoto => 'Elegir foto';
  String get photo => 'Foto';
  String get chooseEllipsis => 'Elegir…';
  String get replaceEllipsis => 'Cambiar…';
  String get fieldButton => 'Campo';
  String get configureSection => 'Ajustes de la sección';
  String get emptySectionHint => 'Sección vacía: añade un campo con el botón «Campo»';
  String get name => 'Nombre';
  String get namePlaceholder => 'Nombre y apellidos';
  String get handlePlaceholder => '@usuario o enlace';
  String get position => 'Cargo';
  String get positionPlaceholder => 'Diseñador';
  String get company => 'Empresa';
  String get companyPlaceholder => 'Dónde trabaja';
  String get whereMet => 'Dónde nos conocimos';
  String get whereMetPlaceholder => 'Congreso, por amigos, …';
  String get where => 'Dónde';
  String get when => 'Cuándo';
  String get birthday => 'Cumpleaños';
  String get notesPlaceholder => 'Todo lo que vale la pena recordar de esta persona';
  String get phone => 'Teléfono';
  String get phones => 'Teléfonos';
  String get email => 'Correo';
  String get mail => 'Correo';
  String get phonePlaceholder => '+34 600 000 000';
  String get addPhone => 'Añadir teléfono';
  String get addEmail => 'Añadir correo';
  String get chooseOrCreate => 'Elegir o crear';
  String get interest => 'Interés';
  String get configureField => 'Ajustes del campo';
  String get noOptions => 'No hay opciones: añádelas en los ajustes del campo';
  String get notSelected => 'Sin elegir';
  String get findOrCreate => 'Buscar o crear…';
  String createNamed(String q) => 'Crear «$q»';
  String get noInterestsCreate => 'Aún no hay intereses: escribe un nombre para crear uno';
  String get manageInterests => 'Gestionar intereses…';
  String get birthdayToday => '🎂 Cumpleaños hoy';
  String birthdayIn(int n) => '🎂 Cumpleaños en ${days(n)}';
  String addedChanged(String added, String changed) => 'Añadido $added\nModificado $changed';
  String get trashTomorrow => 'En la papelera · se eliminará mañana';
  String trashIn(int n) => 'En la papelera · se eliminará en ${days(n)}';
  String notSpecified(String what) => '$what: sin indicar';

  // ── Etiquetas de teléfono y correo ──
  String get labelMobile => 'móvil';
  String get labelWork => 'trabajo';
  String get labelHome => 'casa';
  String get labelOther => 'otro';
  String get labelPersonal => 'personal';

  // ── Tabla ──
  String get colWork => 'Trabajo';
  String get colMet => 'Cómo nos conocimos';
  String get colFavorite => 'Favorito';
  String get colCreated => 'Añadido';
  String get configureColumn => 'Ajustes de la columna';
  String get sort => 'Ordenar';
  String get addColumn => 'Añadir columna';
  String get columns => 'Columnas';
  String get cannotHideColumn => 'Esta columna no se puede ocultar';
  String get nameAlwaysFirst => 'El nombre siempre va primero y no se oculta';
  String get reorderHint => 'Arrastra para reordenar con ';
  String get newFieldEllipsis => 'Nuevo campo…';

  // ── Campos y secciones ──
  String get typeText => 'Texto';
  String get typeMultiline => 'Texto largo';
  String get typeNumber => 'Número';
  String get typeUrl => 'Enlace';
  String get typeDate => 'Fecha';
  String get typeSelect => 'Lista';
  String get typeCheckbox => 'Sí / no';
  String get sectionMain => 'Principal';
  String get sectionInterests => 'Intereses';
  String get notes => 'Notas';
  String get emails => 'Correos electrónicos';
  String get metDate => 'Fecha en que nos conocimos';
  String deleteFieldTitle(String name) => '¿Eliminar el campo «$name»?';
  String get deleteFieldMessage => 'Los valores de este campo se eliminarán de todos los contactos.';
  String get newField => 'Nuevo campo';
  String get fieldSettings => 'Ajustes del campo';
  String get deleteField => 'Eliminar campo';
  String get title => 'Nombre';
  String get fieldNamePlaceholder => 'Por ejemplo: Ciudad, Café favorito';
  String get fieldType => 'Tipo de campo';
  String get optionsLabel => 'Opciones · Enter o coma para añadir';
  String get newOption => 'Nueva opción';
  String get section => 'Sección';
  String get icon => 'Icono';
  String get tableColumn => 'Columna en la tabla';
  String get tableColumnHint => 'Mostrar este campo en la lista de contactos';
  String deleteSectionTitle(String name) => '¿Eliminar la sección «$name»?';
  String get sectionEmptyNoLoss => 'La sección está vacía, no se perderá nada.';
  String deleteSectionFields(int n) =>
      'Junto con la sección se eliminarán $n ${_p(n, 'campo', 'campos')} y sus valores en todos los contactos.';
  String get newSection => 'Nueva sección';
  String get sectionSettings => 'Ajustes de la sección';
  String get builtInSectionNote => 'Una sección estándar se puede renombrar, pero no eliminar';
  String get deleteSection => 'Eliminar sección';
  String get sectionName => 'Nombre de la sección';
  String get sectionNamePlaceholder => 'Por ejemplo: Redes, Familia, Proyectos';
  String get dragToReorder => 'Arrastra desde ⠿ para cambiar el orden';
  String get standardTag => 'estándar';
  String get builtInField => 'Campo integrado';
  String get shownInTable => 'Se muestra en la tabla';
  String get noFieldsInSection => 'Esta sección aún no tiene campos';
  String get addField => 'Añadir campo';

  // ── Intereses ──
  String get interestExists => 'Ese interés ya existe';
  String deleteInterestTitle(String name) => '¿Eliminar el interés «$name»?';
  String get deleteInterestUnused => 'Ningún contacto tiene este interés.';
  String deleteInterestMessage(int n) =>
      'Este interés lo tienen ${contacts(n)}. Si lo eliminas, desaparecerá de '
      '${_p(n, 'su ficha', 'sus fichas')} y el filtro rápido por interés dejará de encontrar '
      '${_p(n, 'este contacto', 'estos contactos')}.';
  String get interestsSubtitle => 'Créalos de antemano y luego elígelos en la ficha del contacto';
  String get newInterestLabel => 'Nuevo interés · varios separados por comas';
  String get interestsPlaceholder => 'Por ejemplo: Diseño, Correr, Libros';
  String get noInterests => 'Aún no hay intereses';
  String get nobody => 'nadie';
  String get deleteInterest => 'Eliminar interés';

  // ── Calendario ──
  String get dateNotSet => 'Sin indicar';
  String get prevMonth => 'Mes anterior';
  String get nextMonth => 'Mes siguiente';
  String get today => 'Hoy';

  // ── Búsqueda rápida ──
  String get spotlightPlaceholder => 'Nombre de la persona…';
  String noneFoundFor(String q) => 'No se encontró a nadie con «$q»';
  String get favoritesAndRecentCaps => 'FAVORITOS Y RECIENTES';
  String get contactsCaps => 'CONTACTOS';

  // ── Acerca de ──
  String get tagline => 'Base personal de contactos';
  String get developer => 'Desarrollador';
  String get design => 'Diseño';
  String designCredit(String title, String author) =>
      'Inspirado en «$title» de $author (Figma Community). La interfaz fue rehecha y modificada por mrgsdev.';
  String get figmaLayout => 'Diseño en Figma';
  String license(String name) => 'Licencia $name';
  String get fonts => 'Tipografías';
  String get fontsLicense => 'Montserrat y Marck Script — SIL Open Font License 1.1';

  // ── Ajustes ──
  String get settings => 'Ajustes';
  String get menuSettings => 'Ajustes…';
  String get settingsGeneral => 'General';
  String get settingsSecurity => 'Seguridad';
  String get settingsData => 'Datos';
  String get languageHint => 'Idioma de menús, botones y mensajes';
  String get appearanceHint => 'Claro, oscuro o como en el sistema';
  String get interestsRowHint => 'Para filtrar personas rápidamente';
  String interestsCount(int n) => '$n ${_p(n, 'interés', 'intereses')}';
  String get fieldsRowHint => 'Campos y secciones propios en la ficha de contacto';
  String get configureEllipsis => 'Configurar…';
  String trashRowHint(int d) => 'Los contactos eliminados se guardan ${days(d)} y luego desaparecen';
  String get pinRow => 'PIN';
  String get pinRowHint => 'Abre la base al iniciar';
  String get changeEllipsis => 'Cambiar…';
  String get recoveryRow => 'Código de recuperación';
  String get recoveryRowHint => 'Lo necesitas si olvidas el PIN y para copias en otro ordenador';
  String get showEllipsis => 'Mostrar…';
  String get lockNow => 'Bloquear ahora';
  String lockRowHint(String combo) => 'O pulsa $combo en cualquier momento';
  String get importRowHint => 'CSV (Google, Excel, exportación de Orbit) y vCard';
  String get exportRowHint => 'Todos los contactos en un archivo CSV';
  String get exportEllipsis => 'Exportar…';
  String get backupRow => 'Copia de seguridad';
  String get backupRowHint => 'Archivo .orbit cifrado con todos los contactos y fotos';
  String get createEllipsis => 'Crear…';
  String get restoreRow => 'Restauración';
  String get restoreRowHint => 'Añadir contactos desde una copia';
  String get restoreEllipsis => 'Restaurar…';
  String get appFolder => 'Carpeta de la app';
  String get showInFinder => 'Mostrar en Finder';
  String get showInExplorer => 'Mostrar en el Explorador';
  String get openFolderAction => 'Abrir carpeta';

  // ── Atajos de teclado ──
  String get settingsShortcuts => 'Atajos de teclado';
  String get shortcutsIntro => 'Pulsa «Cambiar» y luego la nueva combinación de teclas. Esc cancela.';
  String get shortcutsFixed => 'Integrados';
  String get changeShort => 'Cambiar';
  String get pressKeys => 'Pulsa las teclas…';
  String get resetDefault => 'Restablecer';
  String get resetAll => 'Restablecer todo';
  String needModifier(String first, String last) => 'Añade $first o $last';
  String reservedCombo(String c) => '$c está reservado por el sistema';
  String comboInUse(String c, String action) => '$c ya se usa para «$action»';
  String get actQuickSearch => 'Búsqueda rápida';
  String actOpen(String s) => 'Abrir «$s»';
  String get actSelectAll => 'Seleccionar todo';
  String get actMoveSelection => 'Moverse por la lista';
  String get actMultiSelect => 'Seleccionar varios';
  String get click => 'clic';
  String get actEditSelected => 'Editar el contacto seleccionado';
  String get actTrashSelected => 'Mover los seleccionados a la papelera';
  String get actSaveEditor => 'Guardar en el editor';
  String get actCloseWindow => 'Cerrar una ventana o quitar la selección';
  // ── Introducción ──
  String get onbSkip => 'Omitir';
  String get onbNext => 'Siguiente';
  String get onbBack => 'Atrás';
  String get onbStart => 'Empezar';
  String get onbWelcomeTitle => 'Te damos la bienvenida a Orbit';
  String get onbWelcomeText => 'Una base personal de las personas que te importan: contactos, intereses, cumpleaños y notas en un solo lugar.';
  String get onbPeopleTitle => 'Todos a mano';
  String get onbPeopleText => 'Varios teléfonos y correos, Telegram e Instagram, campos propios. Marca intereses para encontrar rápido a quien buscas.';
  String get onbDatesTitle => 'No olvides nada';
  String get onbDatesText => 'El resumen muestra los próximos cumpleaños y a quienes conociste este mes. Marca con una estrella a los más importantes.';
  String get onbPrivacyTitle => 'Solo en tu ordenador';
  String get onbPrivacyText => 'La base y las fotos se cifran y se quedan en este ordenador. El PIN abre la base y el código de recuperación te ayuda si lo olvidas. Las copias también van cifradas.';
  String get onbKeysText => 'Las acciones más útiles, a una pulsación. Puedes cambiarlas en Ajustes → Atajos de teclado.';
  String get onbChangeShortcuts => 'Cambiar atajos';
  String get onbRow => 'Recorrido por Orbit';
  String get onbRowHint => 'Un breve recorrido por las funciones y los atajos';

  // ── CSV ──
  String get csvYes => 'sí';
}
