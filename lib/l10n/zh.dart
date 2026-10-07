// ignore_for_file: annotate_overrides
import 'strings.dart';

class Zh extends Strings {
  const Zh();

  String get locale => 'zh';
  String get languageName => '中文';

  // ── 通用 ──
  String get cancel => '取消';
  String get done => '完成';
  String get save => '保存';
  String get delete => '删除';
  String get add => '添加';
  String get create => '创建';
  String get open => '打开';
  String get show => '显示';
  String get hide => '隐藏';
  String get close => '关闭';
  String get closeEsc => '关闭 (Esc)';
  String get clear => '清除';
  String get copy => '复制';
  String get undo => '撤销';
  String get restore => '恢复';
  String get edit => '编辑';
  String get continueAction => '继续';
  String get checking => '正在检查…';
  String get saving => '正在保存…';
  String get creating => '正在创建…';
  String get yes => '是';
  String get no => '否';
  String get remove => '移除';
  String get toFavorites => '加入收藏';
  String get removeFromFavorites => '取消收藏';
  String get toTrash => '移到废纸篓';
  String get toTrashKey => '移到废纸篓 (⌫)';
  String get deleteForever => '永久删除';
  String get exportCsv => '导出为 CSV…';
  String contacts(int n) => '$n 位联系人';
  String people(int n) => '$n 人';
  String days(int n) => '$n 天';
  String copied(String value) => '已复制：$value';

  // ── 分区与排序 ──
  String get segDashboard => '概览';
  String get segAll => '联系人';
  String get segFavorites => '收藏';
  String get segBirthdays => '生日';
  String get segRecent => '本月新增';
  String get segTrash => '废纸篓';
  String get sortNameAsc => '姓名：A → Z';
  String get sortNameDesc => '姓名：Z → A';
  String get sortNewest => '最新优先';
  String get sortOldest => '最早优先';
  String get sortMetRecent => '最近认识';

  // ── 主窗口 ──
  String movedToTrashOne(String name) => '“$name”已移到废纸篓';
  String movedToTrashMany(int n) => '已移到废纸篓：${contacts(n)}';
  String restoredMany(int n) => '已恢复：${contacts(n)}';
  String purgeTitle(int n) => '永久删除 ${contacts(n)}？';
  String get purgeMessage => '联系人及其照片将被永久删除，无法恢复。';
  String get nothingToExport => '没有可导出的内容';
  String savedContacts(int n) => '已保存：${contacts(n)}';
  String saveFileFailed(Object e) => '无法保存文件：$e';
  String get searchPlaceholder => '搜索联系人…';
  String get personalBase => '个人通讯录';
  String get menuImport => '从 CSV 或 vCard 导入…';
  String get menuBackup => '备份…';
  String get menuRestore => '从备份恢复…';
  String get lock => '锁定';
  String get about => '关于';
  String get language => '语言';
  String get systemLanguage => '跟随系统';
  String get allInterests => '全部兴趣';
  String get interestsHint => '兴趣：创建和删除';
  String get emptyTrash => '清空废纸篓';
  String get viewTable => '表格';
  String get viewCards => '卡片';
  String get newShort => '新建';
  String get noContactsTitle => '还没有联系人';
  String get noContactsSubtitle => '添加第一位联系人，或从 CSV、vCard 导入';
  String get importShort => '导入…';
  String get newContact => '新建联系人';
  String get nothingFound => '未找到结果';
  String nothingFoundFor(String q) => '没有与“$q”匹配的联系人';
  String get trashEmpty => '废纸篓为空';
  String trashEmptySubtitle(int days) => '已删除的联系人会在这里保留 ${this.days(days)}';
  String get favoritesEmpty => '收藏里还没有人';
  String get favoritesEmptySubtitle => '为对你最重要的人加上星标';
  String get recentEmpty => '还没有新认识的人';
  String get recentEmptySubtitle => '最近 30 天添加的联系人会显示在这里';
  String get birthdaysEmpty => '近期没有生日';
  String get birthdaysEmptySubtitle => '未来 30 天内过生日的人会显示在这里';
  String get segmentEmpty => '这里还没有人';
  String get segmentEmptySubtitle => '此分区没有联系人';
  String get noSelectionTitle => '未选择联系人';
  String noSelectionSubtitle(String mod, String shift) => '在列表中选择一个人。按住 $mod 或 $shift 可多选';
  String get interests => '兴趣';
  String get fieldsAndSections => '字段与分区';
  String selectedCount(int n) => '已选择：${contacts(n)}';

  // ── 概览 ──
  String get goodNight => '晚安';
  String get goodMorning => '早上好';
  String get goodAfternoon => '下午好';
  String get goodEvening => '晚上好';
  String get totalContacts => '联系人总数';
  String get viewList => '查看列表';

  // ── 外观 ──
  String get appearance => '外观';
  String get themeLight => '浅色';
  String get themeSystem => '跟随系统';
  String get themeDark => '深色';

  // ── 导入、导出、备份 ──
  String get contactsFileType => '联系人';
  String get imagesFileType => '图片';
  String get backupFileType => 'Orbit 备份';
  String readFileFailed(Object e) => '无法读取文件：$e';
  String get noContactsInFile => '文件中没有找到联系人';
  String allAlreadyExist(int n) => '文件中的 ${contacts(n)}都已在通讯录中';
  String importTitle(String file) => '从“$file”导入';
  String importMessage(int found, int dupes) =>
      '找到 ${contacts(found)}。${dupes > 0 ? '其中 ${contacts(dupes)}已在通讯录中，将被跳过。' : ''}';
  String importConfirm(int n) => '导入 $n 位';
  String imported(int n) => '已导入：${contacts(n)}';
  String get backupSaved => '备份已保存';
  String backupSaveFailed(Object e) => '无法保存备份：$e';
  String get restoreTitle => '从备份恢复？';
  String restoreMessage(int n, String? date) =>
      '备份中有 ${contacts(n)}${date == null ? '' : '（$date）'}。'
      '新联系人将被添加；已存在的联系人保留较新的版本。';
  String get restoreNothingNew => '备份中的内容都已在通讯录中';
  String restoreResult(int added, int updated) => '新增：$added，更新：$updated';
  String get notABackup => '这不是 Orbit 备份';
  String get fileCorrupted => '文件已损坏';
  String codeLength(int n) => '恢复码共 $n 个字符';
  String get codeNotForBackup => '此恢复码与该备份不匹配';
  String get needRecoveryTitle => '需要恢复码';
  String get needRecoverySubtitle => '该备份来自另一台设备上的 Orbit';
  String get recoveryFromOtherInstall => '那台设备首次设置时显示的恢复码';
  String openFolderFailed(String path) => '无法打开文件夹：$path';

  // ── PIN 码与恢复码 ──
  String get pinChanged => 'PIN 码已更改';
  String get wrongCurrentPin => '当前 PIN 码不正确';
  String get wrongPin => 'PIN 码不正确';
  String get changePinTitle => '更改 PIN 码';
  String get changePinSubtitle => '恢复码保持不变';
  String get currentPin => '当前 PIN 码';
  String get newPinOrPassword => '新的 PIN 码或密码';
  String get pinOrPassword => 'PIN 码或密码';
  String get repeat => '再次输入';
  String minLength(int n) => '至少 $n 个字符';
  String pinHint(int n) => '至少 $n 个字符。长密码比简短的数字 PIN 码更安全。';
  String get pinsMismatch => '两次输入的 PIN 码不一致';
  String get regenerateTitle => '创建新的恢复码？';
  String get regenerateMessage => '旧恢复码将无法再打开通讯录。之前创建的备份仍然只能用旧恢复码打开——如果你还保存着它，请和备份放在一起。';
  String get revealIntro => '忘记 PIN 码时，或在另一台电脑上打开备份时，需要用到恢复码。输入 PIN 码即可显示。';
  String get revealKeepSafe => '请把恢复码保存到密码管理器或抄写下来。不要和备份放在一起。';
  String get revealLegacy => '此通讯录是在较早版本的 Orbit 中设置的，没有保存恢复码，因此无法显示。你可以创建新的恢复码。';
  String get createNewCode => '创建新恢复码';
  String get saveRecoveryTitle => '请保存恢复码';
  String get saveRecoverySubtitle => '忘记 PIN 码时，或在另一台电脑上恢复备份时需要它。恢复码只显示这一次。';
  String get savedCodeCheck => '我已把恢复码保存在安全的地方';
  String get encrypting => '正在加密通讯录…';
  String get openOrbit => '打开 Orbit';
  String get protectTitle => '保护你的通讯录';
  String get protectExisting => '设置 PIN 码或密码——现有的联系人和照片将在磁盘上加密。';
  String get protectNew => '设置 PIN 码或密码——联系人和照片将以加密形式保存在磁盘上。';
  String get creatingKeys => '正在生成密钥…';
  String get codeCopied => '恢复码已复制';
  String get codeWrongCase => '恢复码不正确。请检查字母大小写';
  String get lockedTitle => 'Orbit 已锁定';
  String get lockedSubtitle => '输入 PIN 码以打开通讯录';
  String tooManyAttempts(int s) => '尝试次数过多。请等待 $s 秒';
  String get forgotPin => '忘记 PIN 码？使用恢复码登录';
  String get recoveryLoginTitle => '使用恢复码登录';
  String get recoveryLoginSubtitle => '输入 Orbit 首次设置时显示的恢复码。之后需要设置新的 PIN 码。';
  String get backToPin => '返回 PIN 码';
  String get newPinTitle => '新的 PIN 码';
  String get newPinSubtitle => '恢复码正确。请设置新的 PIN 码——恢复码保持不变。';
  String get saveAndOpen => '保存并打开';

  // ── 联系人卡片 ──
  String get editContact => '编辑联系人';
  String formShortcuts(String save) => '$save 保存，Esc 取消';
  String get enterName => '请输入姓名';
  String get badEmail => '邮箱格式不正确';
  String get addOwnSection => '添加自定义分区';
  String get choosePhoto => '选择照片';
  String get photo => '照片';
  String get chooseEllipsis => '选择…';
  String get replaceEllipsis => '更换…';
  String get fieldButton => '字段';
  String get configureSection => '分区设置';
  String get emptySectionHint => '空分区——用“字段”按钮添加字段';
  String get name => '姓名';
  String get namePlaceholder => '姓名';
  String get handlePlaceholder => '@用户名或链接';
  String get position => '职位';
  String get positionPlaceholder => '设计师';
  String get company => '公司';
  String get companyPlaceholder => '在哪里工作';
  String get whereMet => '认识地点';
  String get whereMetPlaceholder => '会议、朋友介绍……';
  String get where => '地点';
  String get when => '时间';
  String get birthday => '生日';
  String get notesPlaceholder => '关于这个人值得记住的一切';
  String get phone => '电话';
  String get phones => '电话';
  String get email => '邮箱';
  String get mail => '邮件';
  String get phonePlaceholder => '+86 138 0000 0000';
  String get addPhone => '添加电话';
  String get addEmail => '添加邮箱';
  String get chooseOrCreate => '选择或创建';
  String get interest => '兴趣';
  String get configureField => '字段设置';
  String get noOptions => '没有选项——请在字段设置中添加';
  String get notSelected => '未选择';
  String get findOrCreate => '查找或创建…';
  String createNamed(String q) => '创建“$q”';
  String get noInterestsCreate => '还没有兴趣——输入名称即可创建';
  String get manageInterests => '管理兴趣…';
  String get birthdayToday => '🎂 今天生日';
  String birthdayIn(int n) => '🎂 ${days(n)}后生日';
  String addedChanged(String added, String changed) => '添加于 $added\n修改于 $changed';
  String get trashTomorrow => '在废纸篓中 · 明天删除';
  String trashIn(int n) => '在废纸篓中 · ${days(n)}后删除';
  String notSpecified(String what) => '未填写$what';

  // ── 电话和邮箱标签 ──
  String get labelMobile => '手机';
  String get labelWork => '工作';
  String get labelHome => '住宅';
  String get labelOther => '其他';
  String get labelPersonal => '个人';

  // ── 表格 ──
  String get colWork => '工作';
  String get colMet => '相识';
  String get colFavorite => '收藏';
  String get colCreated => '添加时间';
  String get configureColumn => '列设置';
  String get sort => '排序';
  String get addColumn => '添加列';
  String get columns => '列';
  String get cannotHideColumn => '此列无法隐藏';
  String get nameAlwaysFirst => '姓名始终在第一列，无法隐藏';
  String get reorderHint => '拖动以调整顺序：';
  String get newFieldEllipsis => '新字段…';

  // ── 字段与分区 ──
  String get typeText => '文本';
  String get typeMultiline => '长文本';
  String get typeNumber => '数字';
  String get typeUrl => '链接';
  String get typeDate => '日期';
  String get typeSelect => '列表';
  String get typeCheckbox => '是 / 否';
  String get sectionMain => '基本信息';
  String get sectionInterests => '兴趣领域';
  String get notes => '备注';
  String get emails => '邮箱地址';
  String get metDate => '认识日期';
  String deleteFieldTitle(String name) => '删除字段“$name”？';
  String get deleteFieldMessage => '所有联系人中此字段的值都将被删除。';
  String get newField => '新字段';
  String get fieldSettings => '字段设置';
  String get deleteField => '删除字段';
  String get title => '名称';
  String get fieldNamePlaceholder => '例如：城市、喜欢的咖啡';
  String get fieldType => '字段类型';
  String get optionsLabel => '选项 · 按 Enter 或逗号添加';
  String get newOption => '新选项';
  String get section => '分区';
  String get icon => '图标';
  String get tableColumn => '表格列';
  String get tableColumnHint => '在联系人列表中显示此字段';
  String deleteSectionTitle(String name) => '删除分区“$name”？';
  String get sectionEmptyNoLoss => '分区为空，不会丢失任何内容。';
  String deleteSectionFields(int n) => '分区中的 $n 个字段及其在所有联系人中的值将一并删除。';
  String get newSection => '新分区';
  String get sectionSettings => '分区设置';
  String get builtInSectionNote => '标准分区可以重命名，但不能删除';
  String get deleteSection => '删除分区';
  String get sectionName => '分区名称';
  String get sectionNamePlaceholder => '例如：社交账号、家人、项目';
  String get dragToReorder => '拖动 ⠿ 调整顺序';
  String get standardTag => '标准';
  String get builtInField => '内置字段';
  String get shownInTable => '显示在表格中';
  String get noFieldsInSection => '此分区还没有字段';
  String get addField => '添加字段';

  // ── 兴趣 ──
  String get interestExists => '该兴趣已存在';
  String deleteInterestTitle(String name) => '删除兴趣“$name”？';
  String get deleteInterestUnused => '没有联系人带有此兴趣。';
  String deleteInterestMessage(int n) => '${contacts(n)}带有此兴趣。删除后，它会从对应的卡片中消失，按兴趣快速筛选也将找不到这些联系人。';
  String get interestsSubtitle => '提前创建好，之后就能在联系人卡片中选择';
  String get newInterestLabel => '新兴趣 · 可用逗号分隔多个';
  String get interestsPlaceholder => '例如：设计、跑步、读书';
  String get noInterests => '还没有兴趣';
  String get nobody => '无人';
  String get deleteInterest => '删除兴趣';

  // ── 日历 ──
  String get dateNotSet => '未填写';
  String get prevMonth => '上个月';
  String get nextMonth => '下个月';
  String get today => '今天';

  // ── 快速搜索 ──
  String get spotlightPlaceholder => '输入姓名…';
  String noneFoundFor(String q) => '没有找到与“$q”匹配的人';
  String get favoritesAndRecentCaps => '收藏与最近';
  String get contactsCaps => '联系人';

  // ── 关于 ──
  String get tagline => '个人通讯录';
  String get developer => '开发者';
  String get design => '设计';
  String designCredit(String title, String author) => '灵感来自 $author 的“$title”（Figma Community）。界面由 mrgsdev 重新设计和修改。';
  String get figmaLayout => 'Figma 设计稿';
  String license(String name) => '许可协议 $name';
  String get fonts => '字体';
  String get fontsLicense => 'Montserrat 与 Marck Script — SIL Open Font License 1.1';

  // ── 设置 ──
  String get settings => '设置';
  String get menuSettings => '设置…';
  String get settingsGeneral => '通用';
  String get settingsSecurity => '安全';
  String get settingsData => '数据';
  String get languageHint => '菜单、按钮和提示所用的语言';
  String get appearanceHint => '浅色、深色或跟随系统';
  String get interestsRowHint => '用于快速筛选联系人';
  String interestsCount(int n) => '$n 个兴趣';
  String get fieldsRowHint => '联系人卡片中的自定义字段和分区';
  String get configureEllipsis => '设置…';
  String trashRowHint(int d) => '已删除的联系人保留 ${days(d)}，之后自动清除';
  String get pinRow => 'PIN 码';
  String get pinRowHint => '启动时用于打开通讯录';
  String get changeEllipsis => '更改…';
  String get recoveryRow => '恢复码';
  String get recoveryRowHint => '忘记 PIN 码或在另一台电脑上使用备份时需要';
  String get showEllipsis => '显示…';
  String get lockNow => '立即锁定';
  String lockRowHint(String combo) => '也可随时按 $combo';
  String get importRowHint => 'CSV（Google、Excel、Orbit 导出）和 vCard';
  String get exportRowHint => '将所有联系人导出到一个 CSV 文件';
  String get exportEllipsis => '导出…';
  String get backupRow => '备份';
  String get backupRowHint => '包含全部联系人和照片的加密 .orbit 文件';
  String get createEllipsis => '创建…';
  String get restoreRow => '恢复';
  String get restoreRowHint => '从备份中添加联系人';
  String get restoreEllipsis => '恢复…';
  String get appFolder => '应用文件夹';
  String get showInFinder => '在访达中显示';
  String get showInExplorer => '在文件资源管理器中显示';
  String get openFolderAction => '打开文件夹';

  // ── 键盘快捷键 ──
  String get settingsShortcuts => '键盘快捷键';
  String get shortcutsIntro => '点击“更改”，然后按下新的组合键。按 Esc 取消。';
  String get shortcutsFixed => '内置';
  String get changeShort => '更改';
  String get pressKeys => '请按组合键…';
  String get resetDefault => '恢复默认';
  String get resetAll => '全部重置';
  String needModifier(String first, String last) => '请加上 $first 或 $last';
  String reservedCombo(String c) => '$c 已被系统占用';
  String comboInUse(String c, String action) => '$c 已用于“$action”';
  String get actQuickSearch => '快速搜索';
  String actOpen(String s) => '打开“$s”';
  String get actSelectAll => '全选';
  String get actMoveSelection => '在列表中移动';
  String get actMultiSelect => '多选';
  String get click => '点击';
  String get actEditSelected => '编辑所选联系人';
  String get actTrashSelected => '将所选移到废纸篓';
  String get actSaveEditor => '在编辑器中保存';
  String get actCloseWindow => '关闭窗口或取消选择';
  // ── 新手引导 ──
  String get onbSkip => '跳过';
  String get onbNext => '下一步';
  String get onbBack => '上一步';
  String get onbStart => '开始使用';
  String get onbWelcomeTitle => '欢迎使用 Orbit';
  String get onbWelcomeText => '记录对你重要的人：联系人、兴趣、生日和备注，尽在一处。';
  String get onbPeopleTitle => '所有人一目了然';
  String get onbPeopleText => '多个电话和邮箱、Telegram 和 Instagram，还有自定义字段。为联系人标记兴趣，快速找到想找的人。';
  String get onbDatesTitle => '不错过重要日子';
  String get onbDatesText => '概览中显示即将到来的生日和本月新认识的人。为最重要的人加上星标。';
  String get onbPrivacyTitle => '只保存在你的电脑上';
  String get onbPrivacyText => '通讯录和照片均已加密，只保存在这台电脑上。PIN 码用于打开通讯录，忘记时可用恢复码。备份同样经过加密。';
  String get onbKeysText => '常用操作一键直达。可在“设置 → 键盘快捷键”中更改。';
  String get onbChangeShortcuts => '更改快捷键';
  String get onbRow => 'Orbit 导览';
  String get onbRowHint => '简要介绍功能和快捷键';

  // ── CSV ──
  String get csvYes => '是';
}
