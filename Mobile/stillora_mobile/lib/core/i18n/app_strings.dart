import 'package:flutter/widgets.dart';

import 'app_locale.dart';

/// Stillora's UI copy in every shipped language.
///
/// Hand-written rather than generated: the catalogue is small, lives in one
/// file, and every public accessor below is a typed getter, so a missing or
/// misspelled key is a compile error at the call site rather than a runtime
/// blank. The stringly-typed lookup is contained entirely inside this file, and
/// any key absent from a translation falls back to English instead of showing
/// nothing.
class AppStrings {
  const AppStrings._(this.language, this._values);

  final AppLanguage language;
  final Map<String, String> _values;

  static AppStrings of(AppLanguage language) => AppStrings._(
    language,
    switch (language) {
      AppLanguage.english => _en,
      AppLanguage.arabic => _ar,
      AppLanguage.french => _fr,
    },
  );

  /// Nearest enclosing [AppStringsScope]; English if the app forgot to install
  /// one (only reachable in isolated widget tests).
  static AppStrings maybeOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppStringsScope>();
    return scope?.strings ?? AppStrings.of(AppLanguage.english);
  }

  String _(String key) => _values[key] ?? _en[key] ?? key;

  // ── Section names (mobile drawer + desktop sidebar + app bar titles) ───────
  String get create => _('create');
  String get library => _('library');
  String get html => _('html');
  String get settings => _('settings');
  String get loopImages => _('loopImages');
  String get removeSilence => _('removeSilence');
  String get watermark => _('watermark');
  String get speed => _('speed');
  String get convert => _('convert');
  String get text => _('text');
  String get compress => _('compress');
  String get pdfConverter => _('pdfConverter');

  // ── Desktop section subtitles ─────────────────────────────────────────────
  String get createSubtitle => _('createSubtitle');
  String get librarySubtitle => _('librarySubtitle');
  String get htmlSubtitle => _('htmlSubtitle');
  String get settingsSubtitle => _('settingsSubtitle');
  String get loopImagesSubtitle => _('loopImagesSubtitle');
  String get removeSilenceSubtitle => _('removeSilenceSubtitle');
  String get watermarkSubtitle => _('watermarkSubtitle');
  String get speedSubtitle => _('speedSubtitle');
  String get convertSubtitle => _('convertSubtitle');
  String get textSubtitle => _('textSubtitle');
  String get compressSubtitle => _('compressSubtitle');
  String get pdfConverterSubtitle => _('pdfConverterSubtitle');

  // ── Settings ──────────────────────────────────────────────────────────────
  String get appearance => _('appearance');
  String get theme => _('theme');
  String get themeSystem => _('themeSystem');
  String get themeLight => _('themeLight');
  String get themeDark => _('themeDark');
  String get languageLabel => _('language');
  String get defaults => _('defaults');
  String get defaultDuration => _('defaultDuration');
  String get defaultPreset => _('defaultPreset');
  String get defaultResizeMode => _('defaultResizeMode');
  String get storage => _('storage');
  String get clearTempFiles => _('clearTempFiles');
  String get clearTempFilesSubtitle => _('clearTempFilesSubtitle');
  String get about => _('about');
  String get privacyPolicy => _('privacyPolicy');
  String get termsOfService => _('termsOfService');
  String get account => _('account');
  String get logout => _('logout');
  String get deleteAccount => _('deleteAccount');
  String get deleteAccountTitle => _('deleteAccountTitle');
  String get deleteAccountBody => _('deleteAccountBody');
  String get cancel => _('cancel');
  String get delete => _('delete');

  /// "10 seconds" — Arabic and French both need the number inlined rather than
  /// concatenated, so this is a template.
  String secondsValue(int seconds) =>
      _('secondsValue').replaceFirst('{n}', '$seconds');

  // ── About / brand ─────────────────────────────────────────────────────────
  String get appTagline => _('appTagline');
  String get filesStayOnDevice => _('filesStayOnDevice');
  String get filesStayOnComputer => _('filesStayOnComputer');
  String get workspace => _('workspace');

  // ── Chrome ────────────────────────────────────────────────────────────────
  String get back => _('back');
  String get toggleSidebar => _('toggleSidebar');
  String get expandSidebar => _('expandSidebar');
  String get collapseSidebar => _('collapseSidebar');
}

const _en = <String, String>{
  'create': 'Create',
  'library': 'Library',
  'html': 'HTML',
  'settings': 'Settings',
  'loopImages': 'Loop images',
  'removeSilence': 'Remove Silence',
  'watermark': 'Watermark',
  'speed': 'Speed',
  'convert': 'Convert',
  'text': 'Text',
  'compress': 'Compress',
  'pdfConverter': 'PDF Converter',

  'createSubtitle': 'Turn images into video, on this device',
  'librarySubtitle': "Every render you've made",
  'htmlSubtitle': 'Capture any web page as a clip',
  'settingsSubtitle': 'Appearance, language & account',
  'loopImagesSubtitle': 'Batch loops & slideshows',
  'removeSilenceSubtitle': 'Auto-cut the quiet gaps from a video',
  'watermarkSubtitle': 'Add a logo or overlay onto a video',
  'speedSubtitle': 'Speed up a video 1x–4x, mute or add audio',
  'convertSubtitle': 'Batch-convert HEIC & others to JPEG/PNG',
  'textSubtitle': 'Add animated captions & titles onto a video',
  'compressSubtitle': 'Shrink a video to a smaller MP4',
  'pdfConverterSubtitle': 'Combine images and PDFs into one PDF',

  'appearance': 'Appearance',
  'theme': 'Theme',
  'themeSystem': 'System default',
  'themeLight': 'Light',
  'themeDark': 'Dark',
  'language': 'Language',
  'defaults': 'Defaults',
  'defaultDuration': 'Default video duration',
  'defaultPreset': 'Default video preset',
  'defaultResizeMode': 'Default resize mode',
  'storage': 'Storage',
  'clearTempFiles': 'Clear temporary files',
  'clearTempFilesSubtitle': 'Video engine cleanup will run here.',
  'about': 'About',
  'privacyPolicy': 'Privacy Policy',
  'termsOfService': 'Terms of Service',
  'account': 'Account',
  'logout': 'Logout',
  'deleteAccount': 'Delete Account',
  'deleteAccountTitle': 'Delete account?',
  'deleteAccountBody':
      'This will permanently delete your account and all associated data. '
      'This action cannot be undone.',
  'cancel': 'Cancel',
  'delete': 'Delete',
  'secondsValue': '{n} seconds',

  'appTagline':
      'No account needed — every video is made locally on your device.',
  'filesStayOnDevice': 'Files stay on this device.',
  'filesStayOnComputer': 'Files stay on this computer.',
  'workspace': 'Workspace',

  'back': 'Back',
  'toggleSidebar': 'Toggle sidebar',
  'expandSidebar': 'Expand sidebar',
  'collapseSidebar': 'Collapse sidebar',
};

const _ar = <String, String>{
  'create': 'إنشاء',
  'library': 'المكتبة',
  'html': 'HTML',
  'settings': 'الإعدادات',
  'loopImages': 'تكرار الصور',
  'removeSilence': 'إزالة الصمت',
  'watermark': 'علامة مائية',
  'speed': 'السرعة',
  'convert': 'تحويل',
  'text': 'نص',
  'compress': 'ضغط',
  'pdfConverter': 'محوّل PDF',

  'createSubtitle': 'حوّل الصور إلى فيديو على هذا الجهاز',
  'librarySubtitle': 'كل ما أنشأته من مقاطع',
  'htmlSubtitle': 'التقط أي صفحة ويب كمقطع فيديو',
  'settingsSubtitle': 'المظهر واللغة والحساب',
  'loopImagesSubtitle': 'حلقات وعروض شرائح دفعة واحدة',
  'removeSilenceSubtitle': 'قص فترات الصمت من الفيديو تلقائيًا',
  'watermarkSubtitle': 'أضف شعارًا أو طبقة فوق الفيديو',
  'speedSubtitle': 'سرّع الفيديو من 1x إلى 4x، أو اكتم الصوت أو أضف صوتًا',
  'convertSubtitle': 'حوّل HEIC وغيرها دفعة واحدة إلى JPEG أو PNG',
  'textSubtitle': 'أضف تعليقات وعناوين متحركة إلى الفيديو',
  'compressSubtitle': 'صغّر حجم الفيديو إلى ملف MP4 أخف',
  'pdfConverterSubtitle': 'ادمج الصور وملفات PDF في ملف PDF واحد',

  'appearance': 'المظهر',
  'theme': 'السمة',
  'themeSystem': 'حسب النظام',
  'themeLight': 'فاتح',
  'themeDark': 'داكن',
  'language': 'اللغة',
  'defaults': 'الإعدادات الافتراضية',
  'defaultDuration': 'مدة الفيديو الافتراضية',
  'defaultPreset': 'نمط الفيديو الافتراضي',
  'defaultResizeMode': 'وضع التحجيم الافتراضي',
  'storage': 'التخزين',
  'clearTempFiles': 'مسح الملفات المؤقتة',
  'clearTempFilesSubtitle': 'سيُجرى تنظيف محرك الفيديو هنا.',
  'about': 'حول التطبيق',
  'privacyPolicy': 'سياسة الخصوصية',
  'termsOfService': 'شروط الخدمة',
  'account': 'الحساب',
  'logout': 'تسجيل الخروج',
  'deleteAccount': 'حذف الحساب',
  'deleteAccountTitle': 'حذف الحساب؟',
  'deleteAccountBody':
      'سيؤدي هذا إلى حذف حسابك وجميع البيانات المرتبطة به نهائيًا. '
      'لا يمكن التراجع عن هذا الإجراء.',
  'cancel': 'إلغاء',
  'delete': 'حذف',
  'secondsValue': '{n} ثانية',

  'appTagline': 'لا حاجة إلى حساب — يُنشأ كل فيديو محليًا على جهازك.',
  'filesStayOnDevice': 'تبقى ملفاتك على هذا الجهاز.',
  'filesStayOnComputer': 'تبقى ملفاتك على هذا الكمبيوتر.',
  'workspace': 'مساحة العمل',

  'back': 'رجوع',
  'toggleSidebar': 'إظهار أو إخفاء الشريط الجانبي',
  'expandSidebar': 'توسيع الشريط الجانبي',
  'collapseSidebar': 'طي الشريط الجانبي',
};

const _fr = <String, String>{
  'create': 'Créer',
  'library': 'Bibliothèque',
  'html': 'HTML',
  'settings': 'Paramètres',
  'loopImages': 'Boucle d’images',
  'removeSilence': 'Supprimer les silences',
  'watermark': 'Filigrane',
  'speed': 'Vitesse',
  'convert': 'Convertir',
  'text': 'Texte',
  'compress': 'Compresser',
  'pdfConverter': 'Convertisseur PDF',

  'createSubtitle': 'Transformez vos images en vidéo, sur cet appareil',
  'librarySubtitle': 'Tous les rendus que vous avez créés',
  'htmlSubtitle': 'Capturez n’importe quelle page web en vidéo',
  'settingsSubtitle': 'Apparence, langue et compte',
  'loopImagesSubtitle': 'Boucles et diaporamas par lots',
  'removeSilenceSubtitle':
      'Coupez automatiquement les silences d’une vidéo',
  'watermarkSubtitle': 'Ajoutez un logo ou un calque sur une vidéo',
  'speedSubtitle':
      'Accélérez une vidéo de 1x à 4x, coupez ou ajoutez du son',
  'convertSubtitle': 'Convertissez HEIC et autres en JPEG/PNG par lots',
  'textSubtitle': 'Ajoutez des sous-titres et titres animés à une vidéo',
  'compressSubtitle': 'Réduisez une vidéo en un MP4 plus léger',
  'pdfConverterSubtitle': 'Réunissez images et PDF en un seul PDF',

  'appearance': 'Apparence',
  'theme': 'Thème',
  'themeSystem': 'Réglage du système',
  'themeLight': 'Clair',
  'themeDark': 'Sombre',
  'language': 'Langue',
  'defaults': 'Valeurs par défaut',
  'defaultDuration': 'Durée vidéo par défaut',
  'defaultPreset': 'Préréglage vidéo par défaut',
  'defaultResizeMode': 'Mode de redimensionnement par défaut',
  'storage': 'Stockage',
  'clearTempFiles': 'Effacer les fichiers temporaires',
  'clearTempFilesSubtitle':
      'Le nettoyage du moteur vidéo s’exécutera ici.',
  'about': 'À propos',
  'privacyPolicy': 'Politique de confidentialité',
  'termsOfService': 'Conditions d’utilisation',
  'account': 'Compte',
  'logout': 'Se déconnecter',
  'deleteAccount': 'Supprimer le compte',
  'deleteAccountTitle': 'Supprimer le compte ?',
  'deleteAccountBody':
      'Cette action supprimera définitivement votre compte et toutes les '
      'données associées. Elle est irréversible.',
  'cancel': 'Annuler',
  'delete': 'Supprimer',
  'secondsValue': '{n} secondes',

  'appTagline':
      'Aucun compte requis — chaque vidéo est créée localement sur votre '
      'appareil.',
  'filesStayOnDevice': 'Vos fichiers restent sur cet appareil.',
  'filesStayOnComputer': 'Vos fichiers restent sur cet ordinateur.',
  'workspace': 'Espace de travail',

  'back': 'Retour',
  'toggleSidebar': 'Afficher ou masquer la barre latérale',
  'expandSidebar': 'Développer la barre latérale',
  'collapseSidebar': 'Réduire la barre latérale',
};

/// Publishes the active [AppStrings] to the widget tree. Installed once in
/// `MaterialApp.builder` so every screen can read `context.strings`.
class AppStringsScope extends InheritedWidget {
  const AppStringsScope({
    super.key,
    required this.strings,
    required super.child,
  });

  final AppStrings strings;

  @override
  bool updateShouldNotify(AppStringsScope oldWidget) =>
      oldWidget.strings.language != strings.language;
}

extension AppStringsX on BuildContext {
  /// The active translation. Reading this subscribes the widget to language
  /// changes, so switching language rebuilds it.
  AppStrings get strings => AppStrings.maybeOf(this);
}
