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

  static AppStrings of(AppLanguage language) =>
      AppStrings._(language, switch (language) {
        AppLanguage.english => _en,
        AppLanguage.arabic => _ar,
        AppLanguage.french => _fr,
      });

  /// Nearest enclosing [AppStringsScope]; English if the app forgot to install
  /// one (only reachable in isolated widget tests).
  static AppStrings maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStringsScope>();
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
  String get stilloraPro => _('stilloraPro');

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
  String get stilloraProSubtitle => _('stilloraProSubtitle');

  // ── Sidebar group headings ────────────────────────────────────────────────
  String get groupCreate => _('groupCreate');
  String get groupVideoTools => _('groupVideoTools');
  String get groupDocumentTools => _('groupDocumentTools');
  String get groupYourContent => _('groupYourContent');
  String get groupAccountApp => _('groupAccountApp');

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

  // ── PDF Converter ─────────────────────────────────────────────────────────
  String get pdfHeading => _('pdfHeading');
  String get pdfIntro => _('pdfIntro');
  String get pdfReorderHint => _('pdfReorderHint');
  String get pdfAddFiles => _('pdfAddFiles');
  String get pdfAddFilesHint => _('pdfAddFilesHint');
  String get pdfNoPages => _('pdfNoPages');
  String get pdfExport => _('pdfExport');
  String get pdfBuilding => _('pdfBuilding');
  String get pdfSaved => _('pdfSaved');
  String get pdfSaveFailed => _('pdfSaveFailed');
  String get pdfGone => _('pdfGone');
  String get pdfNeedsFileAccess => _('pdfNeedsFileAccess');
  String get pdfMoveUp => _('pdfMoveUp');
  String get pdfMoveDown => _('pdfMoveDown');
  String get pdfRotateLeft => _('pdfRotateLeft');
  String get pdfRotateRight => _('pdfRotateRight');
  String get pdfRemovePage => _('pdfRemovePage');
  String get pdfFromImages => _('pdfFromImages');
  String get pdfFromPdfs => _('pdfFromPdfs');
  String get pdfMatchImage => _('pdfMatchImage');
  String get pdfMatchImageHint => _('pdfMatchImageHint');
  String get pdfPages => _('pdfPages');
  String get pdfMixHint => _('pdfMixHint');
  String get pdfRotateAll => _('pdfRotateAll');
  String get pdfPageSize => _('pdfPageSize');
  String get pdfMargin => _('pdfMargin');
  String get pdfImportQuality => _('pdfImportQuality');
  String get pdfImportQualityHint => _('pdfImportQualityHint');
  String get pdfImportQualityNote => _('pdfImportQualityNote');
  String get pdfFileName => _('pdfFileName');
  String get pdfMarginNone => _('pdfMarginNone');
  String get pdfMarginSmall => _('pdfMarginSmall');
  String get pdfMarginWide => _('pdfMarginWide');
  String get startOver => _('startOver');
  String get startOverConfirm => _('startOverConfirm');
  String get livePreview => _('livePreview');

  /// "3 pages". Arabic does not have a single plural: 2 takes the dual, 3–10
  /// the broken plural, and 11+ reverts to the singular — so the form is picked
  /// per language rather than with a bare `n == 1`.
  String pdfPageCount(int n) =>
      _(_pluralKey('pdfPage', n)).replaceFirst('{n}', '$n');

  /// Picks `<base>One` / `<base>Two` / `<base>Few` / `<base>Many` for the
  /// active language. Only Arabic uses Two/Few; the others collapse to
  /// One/Many.
  String _pluralKey(String base, int n) {
    if (language != AppLanguage.arabic)
      return '$base${n == 1 ? 'One' : 'Many'}';
    if (n == 1) return '${base}One';
    if (n == 2) return '${base}Two';
    if (n % 100 >= 3 && n % 100 <= 10) return '${base}Few';
    return '${base}Many';
  }

  String pdfExportCount(int n) =>
      _(n == 1 ? 'pdfExportOne' : 'pdfExportMany').replaceFirst('{n}', '$n');

  // ── Loop Images ───────────────────────────────────────────────────────────
  String get loopHeading => _('loopHeading');
  String get loopIntro => _('loopIntro');
  String get loopBatchRender => _('loopBatchRender');
  String get loopAddImages => _('loopAddImages');
  String get loopAddMore => _('loopAddMore');
  String get loopClear => _('loopClear');
  String get loopClearWarning => _('loopClearWarning');
  String get loopDropHint => _('loopDropHint');
  String get loopDropSubtitle => _('loopDropSubtitle');
  String get loopOutputSize => _('loopOutputSize');
  String get loopImageMode => _('loopImageMode');
  String get loopDuration => _('loopDuration');
  String get loopQuality => _('loopQuality');
  String get loopEachOutput => _('loopEachOutput');
  String get loopEachClip => _('loopEachClip');
  String get loopTypeDuration => _('loopTypeDuration');
  String get loopConverting => _('loopConverting');
  String get loopRendering => _('loopRendering');
  String get loopFit => _('loopFit');
  String get loopFill => _('loopFill');
  String get loopStatusReady => _('loopStatusReady');
  String get loopStatusRendering => _('loopStatusRendering');
  String get loopStatusDone => _('loopStatusDone');
  String get loopStatusFailed => _('loopStatusFailed');
  String get loopShareVideo => _('loopShareVideo');
  String get loopEach => _('loopEach');
  String get pdfPortrait => _('pdfPortrait');
  String get pdfLandscape => _('pdfLandscape');
  String get pdfSheetA4Hint => _('pdfSheetA4Hint');
  String get pdfSheetLetterHint => _('pdfSheetLetterHint');

  /// Aspect-ratio names for the Loop output grid, keyed by [LoopSize.id].
  String loopSizeLabel(String id) => _('loopSize_$id');

  String loopConvertCount(int n) =>
      _(_pluralKey('loopConvert', n)).replaceFirst('{n}', '$n');
  String loopSavedCount(int done, int total) => _(
    'loopSavedCount',
  ).replaceFirst('{done}', '$done').replaceFirst('{total}', '$total');
  String loopImageCount(int n, int max) => _(
    'loopImageCount',
  ).replaceFirst('{n}', '$n').replaceFirst('{max}', '$max');

  // ── HTML → Video ──────────────────────────────────────────────────────────
  String get htmlHeading => _('htmlHeading');
  String get htmlIntro => _('htmlIntro');
  String get htmlNewRender => _('htmlNewRender');
  String get htmlSource => _('htmlSource');
  String get htmlPaste => _('htmlPaste');
  String get htmlFile => _('htmlFile');
  String get htmlUrl => _('htmlUrl');
  String get htmlDropFile => _('htmlDropFile');
  String get htmlDropFileHint => _('htmlDropFileHint');
  String get htmlLength => _('htmlLength');
  String get htmlDuration => _('htmlDuration');
  String get htmlFrameRate => _('htmlFrameRate');
  String get htmlAudio => _('htmlAudio');
  String get htmlAudioHint => _('htmlAudioHint');
  String get htmlRemoveAudio => _('htmlRemoveAudio');
  String get htmlRendering => _('htmlRendering');
  String get htmlClearWarning => _('htmlClearWarning');
  String get htmlNeedUrl => _('htmlNeedUrl');
  String get htmlNeedMarkup => _('htmlNeedMarkup');
  String get htmlNeedFile => _('htmlNeedFile');
  String get htmlCancelled => _('htmlCancelled');
  String get htmlFailed => _('htmlFailed');

  // ── Watermark ─────────────────────────────────────────────────────────────
  String get wmIntro => _('wmIntro');
  String get wmChooseVideo => _('wmChooseVideo');
  String get wmThenDrop => _('wmThenDrop');
  String get wmAddOverlay => _('wmAddOverlay');
  String get wmOverlays => _('wmOverlays');
  String get wmRemove => _('wmRemove');
  String get wmNoOverlays => _('wmNoOverlays');
  String get wmDragHint => _('wmDragHint');
  String get wmLoadVideoFirst => _('wmLoadVideoFirst');
  String get wmNeedVideoAndOverlay => _('wmNeedVideoAndOverlay');
  String get wmExportCancelled => _('wmExportCancelled');
  String get wmPlatformNote => _('wmPlatformNote');

  // ── Shared export controls (Watermark, Text) ──────────────────────────────
  String get exportResolution => _('exportResolution');
  String get exportOriginal => _('exportOriginal');
  String get exportReplace => _('exportReplace');
  String get exportReadingVideo => _('exportReadingVideo');
  String get exportMp4 => _('exportMp4');
  String get exportExporting => _('exportExporting');
  String get exportCancel => _('exportCancel');
  String get exportCancelling => _('exportCancelling');
  String get exportBaseVideo => _('exportBaseVideo');
  String get exportOutput => _('exportOutput');
  String get savedToLibrary => _('savedToLibrary');

  // ── Stillora Pro page ─────────────────────────────────────────────────────
  String get proTagline => _('proTagline');
  String get proPayOnce => _('proPayOnce');
  String get proPaidOnce => _('proPaidOnce');
  String get proActive => _('proActive');
  String get proUnlockedBody => _('proUnlockedBody');
  String get proRestore => _('proRestore');
  String get proOneTime => _('proOneTime');
  String get proContinueFree => _('proContinueFree');
  String get proFreeStaysFree => _('proFreeStaysFree');

  // ── Your plan (Info tab) ──────────────────────────────────────────────────
  String get yourPlan => _('yourPlan');
  String get planFree => _('planFree');
  String get planPro => _('planPro');
  String get planFreeBody => _('planFreeBody');
  String get planProBody => _('planProBody');
  String get planIncludesTools => _('planIncludesTools');
  String get planIncludesQuality => _('planIncludesQuality');
  String get planIncludesNoWatermark => _('planIncludesNoWatermark');
  String get planIncludesLocal => _('planIncludesLocal');
  String get planIncludesAds => _('planIncludesAds');
  String get planSeePro => _('planSeePro');
  String get proContacting => _('proContacting');
  String get proUnlockCta => _('proUnlockCta');
  String get proPrivacyBody => _('proPrivacyBody');
  String get proCompareTitle => _('proCompareTitle');
  String get proCompareFeature => _('proCompareFeature');
  String get proCompareFree => _('proCompareFree');
  String get proComparePro => _('proComparePro');
  String get proCompareFooter => _('proCompareFooter');

  // ── Remove Silence / Speed / Compress ─────────────────────────────────────
  String get toolSource => _('toolSource');
  String get toolOutput => _('toolOutput');
  String get toolQuality => _('toolQuality');
  String get toolAudio => _('toolAudio');
  String get toolSpeed => _('toolSpeed');
  String get toolSizeApprox => _('toolSizeApprox');
  String get silenceIntro => _('silenceIntro');
  String get silenceSensitivity => _('silenceSensitivity');
  String get silenceRemoveAudio => _('silenceRemoveAudio');
  String get silenceNewAudioNote => _('silenceNewAudioNote');
  String get speedIntro => _('speedIntro');
  String get speedMute => _('speedMute');
  String get speedNewAudioNote => _('speedNewAudioNote');
  String get compressIntro => _('compressIntro');
  String get compressLevel => _('compressLevel');
  String get compressMute => _('compressMute');
  String get compressBefore => _('compressBefore');
  String get compressAfter => _('compressAfter');
  String get compressSaving => _('compressSaving');

  // ── Preview / export result ───────────────────────────────────────────────
  String get previewComplete => _('previewComplete');
  String get previewReady => _('previewReady');
  String get previewShareTo => _('previewShareTo');
  String get previewMore => _('previewMore');
  String get previewAnother => _('previewAnother');
  String get previewNoVideo => _('previewNoVideo');
  String get previewCreateVideo => _('previewCreateVideo');

  // ── Misc chrome ───────────────────────────────────────────────────────────
  String get sponsored => _('sponsored');
  String get reset => _('reset');

  // ── Create / editor flow ──────────────────────────────────────────────────
  String get edUploadMedia => _('edUploadMedia');
  String get edUploadIntro => _('edUploadIntro');
  String get edTapToUpload => _('edTapToUpload');
  String get edPhotosOrClips => _('edPhotosOrClips');
  String get edFileTypes => _('edFileTypes');
  String get edContinue => _('edContinue');
  String get edEdit => _('edEdit');
  String get edSelectedMedia => _('edSelectedMedia');
  String get edSourceMedia => _('edSourceMedia');
  String get edChooseMedia => _('edChooseMedia');
  String get edDragToReorder => _('edDragToReorder');
  String get edSelectThenReorder => _('edSelectThenReorder');
  String get edAddMore => _('edAddMore');
  String get edReplace => _('edReplace');
  String get edChange => _('edChange');
  String get edChoosePreset => _('edChoosePreset');
  String get edChooseFormat => _('edChooseFormat');
  String get edPresets => _('edPresets');
  String get edResize => _('edResize');
  String get edEffect => _('edEffect');
  String get edTransition => _('edTransition');
  String get edStyleEffects => _('edStyleEffects');
  String get edDuration => _('edDuration');
  String get edTotalDuration => _('edTotalDuration');
  String get edSplitsEvenly => _('edSplitsEvenly');
  String get edLength => _('edLength');
  String get edClipLengthHint => _('edClipLengthHint');
  String get edClipVolumeHint => _('edClipVolumeHint');
  String get edDone => _('edDone');
  String get edSoundtrack => _('edSoundtrack');
  String get edSoundscape => _('edSoundscape');
  String get edSoundtrackIntro => _('edSoundtrackIntro');
  String get edRecordVoice => _('edRecordVoice');
  String get edUploadAudio => _('edUploadAudio');
  String get edVolume => _('edVolume');
  String get edAudioSecured => _('edAudioSecured');
  String get edMp4Preview => _('edMp4Preview');
  String get edPreviewMatches => _('edPreviewMatches');
  String get edUploadToBegin => _('edUploadToBegin');
  String get edCreateMp4 => _('edCreateMp4');
  String get edConvertToMp4 => _('edConvertToMp4');
  String get edExportMp4 => _('edExportMp4');
  String get edProjectSummary => _('edProjectSummary');
  String get edEstSize => _('edEstSize');
  String get edFileType => _('edFileType');
  String get edPreview => _('edPreview');
  String get edPreset => _('edPreset');
  String get edAssets => _('edAssets');
  String get edThreeSteps => _('edThreeSteps');
  String get edDesktopStudio => _('edDesktopStudio');
  String get edClearWarning => _('edClearWarning');
  String get edVoiceNarration => _('edVoiceNarration');
  String get edRecordYourVoice => _('edRecordYourVoice');
  String get edRecordHint => _('edRecordHint');
  String get edStartRecording => _('edStartRecording');
  String get edStop => _('edStop');
  String get edReRecord => _('edReRecord');
  String get edUseRecording => _('edUseRecording');
  String get edYourNarration => _('edYourNarration');
  String get edRemoveAudio => _('edRemoveAudio');
  String get edMicOff => _('edMicOff');
  String get edMicHint => _('edMicHint');
  String get edOpenSettings => _('edOpenSettings');
  String get edNarrationPrivacy => _('edNarrationPrivacy');
  String get edClearReel => _('edClearReel');
  String get edReel3d => _('edReel3d');
  String get edFormatExport => _('edFormatExport');

  // ── Library / gallery ─────────────────────────────────────────────────────
  String get galLocalLibrary => _('galLocalLibrary');
  String get galStoredHere => _('galStoredHere');
  String get galEmpty => _('galEmpty');
  String get galSelect => _('galSelect');
  String get galSelected => _('galSelected');
  String get galOpenFull => _('galOpenFull');
  String get galShare => _('galShare');
  String get galSavedLocally => _('galSavedLocally');
  String get galDeleteTitle => _('galDeleteTitle');
  String get galDeleteBody => _('galDeleteBody');
  String get galDeleteManyBody => _('galDeleteManyBody');
  String get galLoadMore => _('galLoadMore');
  String get galVideo => _('galVideo');

  // ── Colour correction ─────────────────────────────────────────────────────
  String get colTitle => _('colTitle');
  String get colBrightness => _('colBrightness');
  String get colContrast => _('colContrast');
  String get colExposure => _('colExposure');
  String get colSaturation => _('colSaturation');
  String get colSharpness => _('colSharpness');
  String get colTint => _('colTint');
  String get colVibrance => _('colVibrance');
  String get colWarmth => _('colWarmth');
  String get colLivePreview => _('colLivePreview');
  String get colOriginal => _('colOriginal');
  String get colVivid => _('colVivid');
  String get colWarm => _('colWarm');
  String get colCool => _('colCool');
  String get colBright => _('colBright');
  String get colVintage => _('colVintage');
  String get colCinematic => _('colCinematic');

  // ── Text overlay ──────────────────────────────────────────────────────────
  String get txtIntro => _('txtIntro');
  String get txtChooseVideo => _('txtChooseVideo');
  String get txtThenAdd => _('txtThenAdd');
  String get txtPlatformNote => _('txtPlatformNote');
  String get txtAddText => _('txtAddText');
  String get txtLayers => _('txtLayers');
  String get txtTimeline => _('txtTimeline');
  String get txtEditText => _('txtEditText');
  String get txtText => _('txtText');
  String get txtSize => _('txtSize');
  String get txtOpacity => _('txtOpacity');
  String get txtOutline => _('txtOutline');
  String get txtDropShadow => _('txtDropShadow');
  String get txtFadeIn => _('txtFadeIn');
  String get txtFadeOut => _('txtFadeOut');
  String get txtPickColour => _('txtPickColour');
  String get txtUseColour => _('txtUseColour');

  // ── Convert / export progress ─────────────────────────────────────────────
  String get cvIntro => _('cvIntro');
  String get cvConvertTo => _('cvConvertTo');
  String get cvExportTo => _('cvExportTo');
  String get cvEmpty => _('cvEmpty');
  String get cvSelectedCount => _('cvSelectedCount');
  String get exGenerating => _('exGenerating');
  String get exExport => _('exExport');

  // ── Pro highlights + comparison rows ──────────────────────────────────────
  String get proHiRes => _('proHiRes');
  String get proHiResBody => _('proHiResBody');
  String get proAdvTools => _('proAdvTools');
  String get proAdvToolsBody => _('proAdvToolsBody');
  String get proBatch => _('proBatch');
  String get proBatchBody => _('proBatchBody');
  String get proPresets => _('proPresets');
  String get proPresetsBody => _('proPresetsBody');
  String get proNoAds => _('proNoAds');
  String get proNoAdsBody => _('proNoAdsBody');
  String get proLocalBoth => _('proLocalBoth');
  String get proLocalBothBody => _('proLocalBothBody');
  String get proRowLocal => _('proRowLocal');
  String get proRowFilesStay => _('proRowFilesStay');
  String get proRowBasicTools => _('proRowBasicTools');
  String get proRowNoWatermark => _('proRowNoWatermark');
  String get proRowExport => _('proRowExport');
  String get proRowAdvanced => _('proRowAdvanced');
  String get proRowBatch => _('proRowBatch');
  String get proRowPresets => _('proRowPresets');
  String get proRowAds => _('proRowAds');
  String get proRowLifetime => _('proRowLifetime');
  String get proLimited => _('proLimited');
  String get proYes => _('proYes');
  String get proNo => _('proNo');
  String get proFreeTier => _('proFreeTier');

  // ── Onboarding ────────────────────────────────────────────────────────────
  String get obSkip => _('obSkip');
  String get obNext => _('obNext');
  String get obGetStarted => _('obGetStarted');
  String get obUploadTitle => _('obUploadTitle');
  String get obUploadBody => _('obUploadBody');
  String get obTimeTitle => _('obTimeTitle');
  String get obTimeBody => _('obTimeBody');
  String get obExportTitle => _('obExportTitle');
  String get obExportBody => _('obExportBody');

  // ── Preview / save & share ────────────────────────────────────────────────
  String get pvSaveShare => _('pvSaveShare');
  String get pvSaveRoll => _('pvSaveRoll');
  String get pvSaved => _('pvSaved');
  String get pvSaving => _('pvSaving');
  String get pvPreparing => _('pvPreparing');
  String get pvNeedPhotoAccess => _('pvNeedPhotoAccess');
  String get pvSaveFailed => _('pvSaveFailed');
  String get pvGone => _('pvGone');
  String get pvLoadToPreview => _('pvLoadToPreview');
  String get pvUploadToPreview => _('pvUploadToPreview');

  // ── Chrome ────────────────────────────────────────────────────────────────
  String get back => _('back');
  String get toggleSidebar => _('toggleSidebar');
  String get expandSidebar => _('expandSidebar');
  String get collapseSidebar => _('collapseSidebar');

  // ── Effects, transitions & presets ────────────────────────────────────────
  String get fxNone => _('fxNone');
  String get fxGlow => _('fxGlow');
  String get fxPanZoom => _('fxPanZoom');
  String get fxFloat => _('fxFloat');
  String get fxShake => _('fxShake');
  String get trFade => _('trFade');
  String get trSwipe => _('trSwipe');
  String get trZoom => _('trZoom');
  String get trSlideUp => _('trSlideUp');
  String get trSlideDown => _('trSlideDown');
  String get trGlitch => _('trGlitch');
  String get trFlash => _('trFlash');
  String get trPulse => _('trPulse');
  String get vpReels => _('vpReels');
  String get vpReelsShort => _('vpReelsShort');
  String get vpSquarePost => _('vpSquarePost');
  String get vpPortraitPost => _('vpPortraitPost');
  String get vpYoutube => _('vpYoutube');
  String get vpOriginalSize => _('vpOriginalSize');
  String get eqSmallestFile => _('eqSmallestFile');
  String get eqRecommended => _('eqRecommended');
  String get eqSharper => _('eqSharper');
  String get eqLargestFile => _('eqLargestFile');
  String get cmpHigh => _('cmpHigh');
  String get cmpHighNote => _('cmpHighNote');
  String get cmpBalanced => _('cmpBalanced');
  String get cmpBalancedNote => _('cmpBalancedNote');
  String get cmpSmall => _('cmpSmall');
  String get cmpSmallNote => _('cmpSmallNote');
  String get cmpTiny => _('cmpTiny');
  String get cmpTinyNote => _('cmpTinyNote');
  String get colBw => _('colBw');

  // ── Tool screens — shared export & audio wording ──────────────────────────
  String get exNothingToExport => _('exNothingToExport');
  String get exFailed => _('exFailed');
  String get exportCancelled => _('exportCancelled');
  String get toolUploadVideo => _('toolUploadVideo');
  String get toolOutputApprox => _('toolOutputApprox');
  String get audMuted => _('audMuted');
  String get audDropped => _('audDropped');
  String get audKept => _('audKept');
  String get audNewAudio => _('audNewAudio');
  String get audRemoveNewAudio => _('audRemoveNewAudio');
  String get audReplacedByNew => _('audReplacedByNew');
  String get cmpPreviewCaption => _('cmpPreviewCaption');
  String get cmpExporting => _('cmpExporting');
  String get cmpExportCta => _('cmpExportCta');
  String get spPreviewCaption => _('spPreviewCaption');
  String get spUploadToPreview => _('spUploadToPreview');
  String get spMuteNote => _('spMuteNote');
  String get spExportCta => _('spExportCta');
  String get spAtSpeed => _('spAtSpeed');
  String get slPreviewCaption => _('slPreviewCaption');
  String get slUploadToPreview => _('slUploadToPreview');
  String get slSourceHint => _('slSourceHint');
  String get slGentle => _('slGentle');
  String get slAggressive => _('slAggressive');
  String get slGentleNote => _('slGentleNote');
  String get slAggressiveNote => _('slAggressiveNote');
  String get slMuteNote => _('slMuteNote');
  String get slExporting => _('slExporting');
  String get slExportCta => _('slExportCta');

  // ── Editor rail, colour panel & shared controls ───────────────────────────
  String get edUpload => _('edUpload');
  String get edAudio => _('edAudio');
  String get edExport => _('edExport');
  String get colCustomApplied => _('colCustomApplied');
  String get colGradeFinal => _('colGradeFinal');
  String get startOverTabWarning => _('startOverTabWarning');

  // ── Convert & HTML render ─────────────────────────────────────────────────
  String get cvNothingConverted => _('cvNothingConverted');
  String get cvConvertedCount => _('cvConvertedCount');
  String get cvFailedCount => _('cvFailedCount');
  String get cvAddMoreImages => _('cvAddMoreImages');
  String get cvSelectImages => _('cvSelectImages');
  String get cvDefaultLocation => _('cvDefaultLocation');
  String get cvSavedToPhotos => _('cvSavedToPhotos');
  String get cvUseDefaultLocation => _('cvUseDefaultLocation');
  String get cvConvertTo2 => _('cvConvertTo2');
  String get cvTo => _('cvTo');
  String get htmlConvertCta => _('htmlConvertCta');
  String get htmlVideoSaved => _('htmlVideoSaved');
  String get htmlSavedToRoll => _('htmlSavedToRoll');
  String get htmlPhotosDenied => _('htmlPhotosDenied');
  String get htmlFileMissing => _('htmlFileMissing');
  String get htmlSaveFailed => _('htmlSaveFailed');
  String get htmlOutputSize => _('htmlOutputSize');
  String get htmlQuality => _('htmlQuality');

  // ── Library saving & text overlay ─────────────────────────────────────────
  String get galDownload => _('galDownload');
  String get galSave => _('galSave');
  String get galSavedToRoll => _('galSavedToRoll');
  String get galVideoGone => _('galVideoGone');
  String get galDeleteSelected => _('galDeleteSelected');
  String get galPickToPlay => _('galPickToPlay');
  String get galDeleteOneBody => _('galDeleteOneBody');
  String get galSaveToRoll => _('galSaveToRoll');
  String get openSettings => _('openSettings');
  String get txtDragHint => _('txtDragHint');
  String get txtLoadVideoFirst => _('txtLoadVideoFirst');
  String get txtNeedVideoAndLayer => _('txtNeedVideoAndLayer');
  String get txtEmptyText => _('txtEmptyText');
  String get txtMoveUp => _('txtMoveUp');
  String get txtMoveDown => _('txtMoveDown');
  String get txtDuplicate => _('txtDuplicate');
  String get txtRemove => _('txtRemove');
  String get txtWeight => _('txtWeight');
  String get txtAlignment => _('txtAlignment');
  String get txtTextColour => _('txtTextColour');
  String get txtBackground => _('txtBackground');
  String get txtOutlineColour => _('txtOutlineColour');
  String get txtRegular => _('txtRegular');
  String get txtMedium => _('txtMedium');
  String get txtYourTitle => _('txtYourTitle');
  String get txtYourSubtitle => _('txtYourSubtitle');
  String get txtTapToLearn => _('txtTapToLearn');
  String get txtYourText => _('txtYourText');
  String get txtSubtitleStyle => _('txtSubtitleStyle');
  String get txtCaptionStyle => _('txtCaptionStyle');
  String get fontDefault => _('fontDefault');

  // ── Type weights ──────────────────────────────────────────────────────────
  String get txtBold => _('txtBold');
  String get txtBlack => _('txtBlack');

  // ── Library & text overlay screens ────────────────────────────────────────
  String get galSelectAll => _('galSelectAll');
  String get galSelectNone => _('galSelectNone');
  String get galLoadMoreCount => _('galLoadMoreCount');
  String galDeleteCountTitle(String n) =>
      _('galDeleteCountTitle').replaceFirst('{n}', n);
  String get galDeleteOneTitle => _('galDeleteOneTitle');
  String get txtExportFailed => _('txtExportFailed');
  String get txtNoLayersYet => _('txtNoLayersYet');

  // ── Editor cards, reel & soundtrack ───────────────────────────────────────
  String get edAddSoundtrack => _('edAddSoundtrack');
  String get edSoundtrackOrNarration => _('edSoundtrackOrNarration');
  String get edTapToChange => _('edTapToChange');
  String get edSelectedTrack => _('edSelectedTrack');
  String get edRecordOrUpload => _('edRecordOrUpload');
  String get edOptionalAudio => _('edOptionalAudio');
  String get edAudioAttached => _('edAudioAttached');
  String get edKeepsOwnSoundMany => _('edKeepsOwnSoundMany');
  String get edKeepsOwnSoundOne => _('edKeepsOwnSoundOne');
  String get edUseAudioLength => _('edUseAudioLength');
  String get rlOutput => _('rlOutput');
  String get rlMatchesAudio => _('rlMatchesAudio');
  String get rlMatchesVideo => _('rlMatchesVideo');
  String get rlMeasuring => _('rlMeasuring');
  String get rlAudioAdded => _('rlAudioAdded');
  String get rlAddAudioOptional => _('rlAddAudioOptional');
  String get rlAddMedia => _('rlAddMedia');
  String get rlUploadAppVideo => _('rlUploadAppVideo');
  String get rlSimpleReel => _('rlSimpleReel');
  String get rlMockupHint => _('rlMockupHint');
  String get loopFormatsFooter => _('loopFormatsFooter');

  // ── Pro gate, sign-in & export progress ───────────────────────────────────
  String get proGate720p => _('proGate720p');
  String get proGateAdvanced => _('proGateAdvanced');
  String get proGateBatch => _('proGateBatch');
  String get proGatePresets => _('proGatePresets');
  String get proGateAds => _('proGateAds');
  String get proFeatureLabel => _('proFeatureLabel');
  String get authFailed => _('authFailed');
  String get authSigningIn => _('authSigningIn');
  String get authContinueApple => _('authContinueApple');
  String get authContinueGoogle => _('authContinueGoogle');
  String get authUnlockNarration => _('authUnlockNarration');
  String get authUnlockNarrationBody => _('authUnlockNarrationBody');
  String get authNotNow => _('authNotNow');
  String get authNarrationUnlocked => _('authNarrationUnlocked');
  String get authNarrationUnlockedBody => _('authNarrationUnlockedBody');
  String get authStartRecording => _('authStartRecording');
  String get exMediaFailed => _('exMediaFailed');
  String get exPreparingBody => _('exPreparingBody');
  String get exBackToEditor => _('exBackToEditor');
  String get exNotReady => _('exNotReady');
  String get exGeneratingVideo => _('exGeneratingVideo');
  String get edStep3 => _('edStep3');

  // ── Pro upsell reasons ────────────────────────────────────────────────────
  String get proGateOnboarding => _('proGateOnboarding');
  String get proGateReminder => _('proGateReminder');

  // ── Editor screens, clips & app toasts ────────────────────────────────────
  String get authLoginPitch => _('authLoginPitch');
  String get authTerms => _('authTerms');
  String get authPrivacy => _('authPrivacy');
  String get edMediaStaysLocal => _('edMediaStaysLocal');
  String get edRecordingHint => _('edRecordingHint');
  String get edPaused => _('edPaused');
  String get edRecording => _('edRecording');
  String get edResume => _('edResume');
  String get edPause => _('edPause');
  String get edRecordingFailed => _('edRecordingFailed');
  String get edVideoClip => _('edVideoClip');
  String get edPhotoClip => _('edPhotoClip');
  String get edClipDuration => _('edClipDuration');
  String get edUnmute => _('edUnmute');
  String get edMute => _('edMute');
  String get edVolumeLabel => _('edVolumeLabel');
  String get edReadyToExport => _('edReadyToExport');
  String get edSetUpExport => _('edSetUpExport');
  String get edReviewBeforeConvert => _('edReviewBeforeConvert');
  String get edChooseMediaToUnlock => _('edChooseMediaToUnlock');
  String get edNoneSelected => _('edNoneSelected');
  String get edSignedIn => _('edSignedIn');
  String get edGuest => _('edGuest');
  String get edMediaUnreadable => _('edMediaUnreadable');
  String get edExportFirstToShare => _('edExportFirstToShare');
  String get rlNeedAppVideo => _('rlNeedAppVideo');
  String get rlReplaceAppVideo => _('rlReplaceAppVideo');
  String get rlReplaceMedia => _('rlReplaceMedia');
  String get toastVideoReady => _('toastVideoReady');
  String get toastConversionFailed => _('toastConversionFailed');
  String get toastExportComplete => _('toastExportComplete');
  String get toastExportFailed => _('toastExportFailed');

  // ── Splash & share sheet ──────────────────────────────────────────────────
  String get splashTagline => _('splashTagline');
  String get shareSavePdf => _('shareSavePdf');
  String get shareSaveAudio => _('shareSaveAudio');
  String get shareSaveVideo => _('shareSaveVideo');

  // ── Reel mockups ──────────────────────────────────────────────────────────
  String get rlLayerReel => _('rlLayerReel');
  String get rlLayers => _('rlLayers');

  // ── Durations & player controls ───────────────────────────────────────────
  /// "5 min" — the chip label for a whole-minute duration.
  String durMinutes(int n) =>
      n == 1 ? _('durMinuteOne') : _('durMinutes').replaceFirst('{n}', '$n');
  String get pvRestart => _('pvRestart');
  String get pvBack5 => _('pvBack5');
  String get pvForward5 => _('pvForward5');
  String get pvPlay => _('pvPlay');

  // ── HTML render & sign-in errors ──────────────────────────────────────────
  String get htmlErrLocalRender => _('htmlErrLocalRender');
  String get htmlErrEmptyVideo => _('htmlErrEmptyVideo');
  String get htmlErrTimeout => _('htmlErrTimeout');
  String get htmlErrGateway => _('htmlErrGateway');
  String get htmlErrStatus => _('htmlErrStatus');
  String get htmlErrUnreachable => _('htmlErrUnreachable');
  String get htmlErrGeneric => _('htmlErrGeneric');

  // ── Sign-in failures ──────────────────────────────────────────────────────
  String get authGoogleCancelled => _('authGoogleCancelled');
  String get authGoogleFailed => _('authGoogleFailed');
  String get authGoogleRetry => _('authGoogleRetry');
  String get authGoogleMisconfigured => _('authGoogleMisconfigured');
  String get authVerifyFailedGoogle => _('authVerifyFailedGoogle');
  String get authVerifyFailedApple => _('authVerifyFailedApple');
  String get authAppleUnsupported => _('authAppleUnsupported');
  String get authAppleNeedsIos13 => _('authAppleNeedsIos13');
  String get authAppleFailed => _('authAppleFailed');
  String get authAppleRetry => _('authAppleRetry');
  String get authAppleCancelled => _('authAppleCancelled');
  String get authAppleUnavailable => _('authAppleUnavailable');
  String get authAppleConnection => _('authAppleConnection');

  // Store Screenshots
  String get storeShots => _('storeShots');
  String get storeShotsSubtitle => _('storeShotsSubtitle');
  String get ssEyebrow => _('ssEyebrow');
  String get ssHeading => _('ssHeading');
  String get ssIntro => _('ssIntro');
  String get ssSourceImages => _('ssSourceImages');
  String get ssAddImages => _('ssAddImages');
  String get ssAddMore => _('ssAddMore');
  String get ssClear => _('ssClear');
  String get ssEmpty => _('ssEmpty');
  String get ssDropHint => _('ssDropHint');
  String get ssSizes => _('ssSizes');
  String get ssRequiredOnly => _('ssRequiredOnly');
  String get ssRequired => _('ssRequired');
  String get ssPickSizes => _('ssPickSizes');
  String get ssLook => _('ssLook');
  String get ssFit => _('ssFit');
  String get ssFill => _('ssFill');
  String get ssBackground => _('ssBackground');
  String get ssBlack => _('ssBlack');
  String get ssWhite => _('ssWhite');
  String get ssMidnight => _('ssMidnight');
  String get ssFormat => _('ssFormat');
  String get ssOrientation => _('ssOrientation');
  String get ssPortrait => _('ssPortrait');
  String get ssLandscape => _('ssLandscape');
  String get ssNoAlphaNote => _('ssNoAlphaNote');
  String get ssZipLayout => _('ssZipLayout');
  String get ssExport => _('ssExport');
  String get ssExporting => _('ssExporting');
  String get ssNothing => _('ssNothing');
  String get ssAndroidPhone => _('ssAndroidPhone');
  String get ssAndroidTablet => _('ssAndroidTablet');
  String get ssPreviewCaption => _('ssPreviewCaption');
  String get ssClearWarning => _('ssClearWarning');
  String get ssSaveZip => _('ssSaveZip');
  String get ssSavedZip => _('ssSavedZip');
  String get ssSaveFailed => _('ssSaveFailed');
  String get ssGone => _('ssGone');

  /// "12 files - 3 sizes"
  String ssOutputCount(int files, int sizes) => _('ssOutputCount')
      .replaceFirst('{files}', '$files')
      .replaceFirst('{sizes}', '$sizes');

  /// "8 images"
  String ssImageCount(int count) =>
      _('ssImageCount').replaceFirst('{count}', '$count');

  /// "Rendering 4 / 12"
  String ssProgress(int done, int total) => _('ssProgress')
      .replaceFirst('{done}', '$done')
      .replaceFirst('{total}', '$total');
}

const _en = <String, String>{
  'create': 'Create',
  'library': 'Library',
  'html': 'HTML',
  'settings': 'Info',
  'loopImages': 'Loop images',
  'removeSilence': 'Remove Silence',
  'watermark': 'Watermark',
  'speed': 'Speed',
  'convert': 'Reformat Image',
  'text': 'Text',
  'compress': 'Compress',
  'pdfConverter': 'PDF Converter',
  'stilloraPro': 'Stillora Pro',

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
  'stilloraProSubtitle': 'Pay once, unlock the full toolkit',

  'groupCreate': 'Create',
  'groupVideoTools': 'Video Tools',
  'groupDocumentTools': 'Document Tools',
  'groupYourContent': 'Your Content',
  'groupAccountApp': 'Account / App',

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

  'pdfHeading': 'Images & PDFs → one PDF',
  'pdfIntro':
      'Add photos, scans and existing PDFs, order the pages, rotate the '
      'crooked ones, and export the whole set as a single file.',
  'pdfReorderHint':
      'Drag the handle to reorder — page 1 at the top. Everything stays on '
      'this device.',
  'pdfAddFiles': 'Add images or PDFs',
  'pdfAddFilesHint': 'JPG · PNG · WebP · HEIC · PDF',
  'pdfNoPages': 'No pages yet',
  'pdfExport': 'Export PDF',
  'pdfBuilding': 'Building PDF…',
  'pdfSaved': 'PDF saved.',
  'pdfSaveFailed': 'Could not save the PDF. Please try again.',
  'pdfGone': 'The exported PDF is no longer available.',
  'pdfNeedsFileAccess': 'Allow file access to save the PDF.',
  'pdfMoveUp': 'Move up',
  'pdfMoveDown': 'Move down',
  'pdfRotateLeft': 'Rotate left',
  'pdfRotateRight': 'Rotate right',
  'pdfRemovePage': 'Remove page',
  'pdfFromImages': 'from images',
  'pdfFromPdfs': 'from PDFs',
  'pdfMatchImage': 'Match image',
  'pdfMatchImageHint': 'Every page takes the shape of its own image',
  'pdfPageMany': '{n} pages',
  'pdfExportOne': 'Export {n} page as PDF',
  'pdfExportMany': 'Export {n} pages as PDF',

  'loopHeading': 'Loop images to videos',
  'loopIntro':
      'Add images, pick one size and one duration. Each image becomes its own '
      'MP4 of that length — they are not merged.',
  'loopBatchRender': 'Batch render',
  'loopAddImages': 'Add images',
  'loopAddMore': 'Add more',
  'loopClear': 'Clear',
  'loopClearWarning':
      'This clears the queued images and the size, duration and quality '
      'choices. This cannot be undone.',
  'loopDropHint': 'Drop images or click to add',
  'loopDropSubtitle': 'JPG · PNG · WebP — each becomes its own MP4',
  'loopOutputSize': 'Output size',
  'loopImageMode': 'Image mode',
  'loopDuration': 'Duration',
  'loopQuality': 'Quality',
  'loopEachOutput': 'Each output',
  'loopEachClip': 'each clip',
  'loopTypeDuration': 'type any duration',
  'loopConverting': 'Converting…',
  'loopRendering': 'Rendering…',
  'loopFit': 'Fit',
  'loopFill': 'Fill',
  'loopStatusReady': 'Ready',
  'loopStatusRendering': 'Rendering',
  'loopStatusDone': 'Done',
  'loopStatusFailed': 'Failed',
  'loopShareVideo': 'Share video',
  'loopConvertOne': 'Convert {n} image',
  'loopConvertTwo': 'Convert {n} images',
  'loopConvertFew': 'Convert {n} images',
  'loopConvertMany': 'Convert {n} images',
  'loopSavedCount': '{done} of {total} saved to Library',
  'loopImageCount': '{n}/{max} images',

  'pdfPageOne': '{n} page',
  'pdfPageTwo': '{n} pages',
  'pdfPageFew': '{n} pages',
  'pdfPages': 'Pages',
  'pdfMixHint':
      'Images and PDFs mix freely — a PDF adds one page per page it has.',
  'pdfRotateAll': 'Rotate all',
  'pdfPageSize': 'Page size',
  'pdfMargin': 'Margin',
  'pdfImportQuality': 'PDF import quality',
  'pdfImportQualityHint':
      'Imported PDF pages are re-drawn as pictures so they can be rotated.',
  'pdfImportQualityNote': 'Applies to PDFs added from now on.',
  'pdfFileName': 'File name',
  'pdfMarginNone': 'None',
  'pdfMarginSmall': 'Small',
  'pdfMarginWide': 'Wide',
  'startOver': 'Start over',
  'startOverConfirm': 'Start over?',
  'livePreview': 'Live preview',

  'loopEach': 'each',
  'loopSize_vertical': 'Vertical',
  'loopSize_square': 'Square',
  'loopSize_portrait': 'Portrait',
  'loopSize_landscape': 'Landscape',

  'pdfSheetA4Hint': '21 × 29.7 cm · pages turn landscape to fit wide images',
  'pdfSheetLetterHint': '8.5 × 11 in · pages turn landscape to fit wide images',

  'pdfPortrait': 'portrait',
  'pdfLandscape': 'landscape',

  'htmlHeading': 'HTML to share-ready video',
  'htmlIntro':
      'Paste markup, drop an .html file, or enter a URL — pick a size and '
      'duration, export a clean MP4 in seconds.',
  'htmlNewRender': 'New render',
  'htmlSource': 'Source',
  'htmlPaste': 'Paste',
  'htmlFile': 'File',
  'htmlUrl': 'URL',
  'htmlDropFile': 'Drop an .html file',
  'htmlDropFileHint': 'or click to browse · .html .htm',
  'htmlLength': 'Length',
  'htmlDuration': 'Duration',
  'htmlFrameRate': 'Frame rate',
  'htmlAudio': 'Audio',
  'htmlAudioHint':
      'Voice-over or music mixed onto the video · trimmed to its length',
  'htmlRemoveAudio': 'Remove audio',
  'htmlRendering': 'Rendering…',
  'htmlClearWarning':
      'This clears the HTML/URL, audio, output settings and the last render. '
      'This cannot be undone.',
  'htmlNeedUrl': 'Enter a URL to render.',
  'htmlNeedMarkup': 'Paste some HTML first.',
  'htmlNeedFile': 'Pick an .html file first.',
  'htmlCancelled': 'Conversion cancelled',
  'htmlFailed': 'Something went wrong. Try again.',

  'wmIntro':
      'Add a logo, image, or video on top of your clip. Drag to place it, '
      'resize it, and set when it appears. Your video keeps its own sound.',
  'wmChooseVideo': 'Choose a video to watermark',
  'wmThenDrop': 'Then drop your logo, image, or another video on top.',
  'wmAddOverlay': 'Add logo, image, or video',
  'wmOverlays': 'Overlays',
  'wmRemove': 'Remove',
  'wmNoOverlays':
      'No overlays yet. Add a logo, image, or video to place on the clip.',
  'wmDragHint': 'Drag an overlay to place it — this is what gets exported',
  'wmLoadVideoFirst': 'Load a video to stack overlays on it',
  'wmNeedVideoAndOverlay': 'Add a video and at least one overlay first.',
  'wmExportCancelled': 'Export cancelled',
  'wmPlatformNote':
      'Watermark export runs on macOS and Windows/Linux today. '
      'iPhone & Android export is coming next.',

  'exportResolution': 'Resolution',
  'exportOriginal': 'Original',
  'exportReplace': 'Replace',
  'exportReadingVideo': 'Reading video…',
  'exportMp4': 'Export MP4',
  'exportExporting': 'Exporting…',
  'exportCancel': 'Cancel export',
  'exportCancelling': 'Cancelling…',
  'exportBaseVideo': 'Base video',
  'exportOutput': 'Output',
  'savedToLibrary': 'Saved to Library',

  'proTagline': 'Unlock the full power of your private media toolkit.',
  'proPayOnce': 'Pay once. Use forever.',
  'proPaidOnce': 'Paid once. Yours forever, on this device.',
  'proActive': 'ACTIVE',
  'proUnlockedBody':
      'Lifetime Pro is unlocked. Every export tier, every advanced control, '
      'no ads — with nothing left to renew.',
  'proRestore': 'Restore Purchase',
  'proOneTime': 'One-time purchase. No subscription.',
  'proContinueFree': 'Continue with Free',
  'proFreeStaysFree':
      'Nothing is locked away. Every tool stays usable on Free, with no '
      'watermark and exports up to 720p.',
  'yourPlan': 'Your plan',
  'planFree': 'Free',
  'planPro': 'Pro — Lifetime',
  'planFreeBody': 'You are on the free plan. This is what it includes:',
  'planProBody': 'Lifetime Pro is active on this device.',
  'planIncludesTools': 'Every tool, unlimited use',
  'planIncludesQuality': 'Exports up to 720p',
  'planIncludesNoWatermark': 'No Stillora watermark',
  'planIncludesLocal': 'Files stay on this device',
  'planIncludesAds': 'Includes sponsored content',
  'planSeePro': 'See what Pro adds',
  'proContacting': 'Contacting the store…',
  'proUnlockCta': 'Unlock Lifetime Pro',
  'proPrivacyBody':
      'Free and Pro both process everything locally. Pro buys you higher '
      'quality, more control and faster workflows — never access to your own '
      'files, and never your privacy.',
  'proCompareTitle': 'Free vs Pro Lifetime',
  'proCompareFeature': 'Feature',
  'proCompareFree': 'Free',
  'proComparePro': 'Pro Lifetime',
  'proCompareFooter':
      'Pro is higher quality, more control, faster workflows and no ads — '
      'not basic access to your own files.',

  'toolSource': 'Source',
  'toolOutput': 'Output',
  'toolQuality': 'Quality',
  'toolAudio': 'Audio',
  'toolSpeed': 'Speed',
  'toolSizeApprox': 'Size ≈',
  'silenceIntro':
      'Upload a video, and Stillora removes the silent gaps where no one is '
      'speaking.',
  'silenceSensitivity': 'Sensitivity',
  'silenceRemoveAudio': 'Remove original audio',
  'silenceNewAudioNote':
      'New audio plays at normal speed; the video loops to match it.',
  'speedIntro':
      'Upload a video and speed it up. Add a soundtrack and the sped video '
      'loops to match it.',
  'speedMute': 'Mute (remove original audio)',
  'speedNewAudioNote':
      'New audio plays at normal speed; the sped video loops to match it.',
  'compressIntro':
      'Upload a video and shrink it to a smaller MP4 at the same resolution.',
  'compressLevel': 'Compression',
  'compressMute': 'Mute (drop audio for a smaller file)',
  'compressBefore': 'Before',
  'compressAfter': 'After ≈',
  'compressSaving': 'Saving',

  'previewComplete': 'Export complete',
  'previewReady': 'Your video is ready to share.',
  'previewShareTo': 'Share to',
  'previewMore': 'More',
  'previewAnother': 'Create another video',
  'previewNoVideo': 'No video yet',
  'previewCreateVideo': 'Create a video',

  'sponsored': 'Sponsored',
  'reset': 'Reset',

  'edUploadMedia': 'Upload media',
  'edUploadIntro': 'Add photos, images, or a short clip to get started.',
  'edTapToUpload': 'Tap to upload\nor drag and drop',
  'edPhotosOrClips': 'Photos, images, or short clips',
  'edFileTypes': 'JPG, PNG, HEIC, MOV, MP4',
  'edContinue': 'Continue',
  'edEdit': 'Edit',
  'edSelectedMedia': 'Selected media',
  'edSourceMedia': 'Source media',
  'edChooseMedia': 'Choose photos or videos',
  'edDragToReorder': 'Drag to reorder after selecting media.',
  'edSelectThenReorder': 'Select photos and videos, then drag to reorder.',
  'edAddMore': 'Add more',
  'edReplace': 'Replace',
  'edChange': 'Change',
  'edChoosePreset': 'Choose preset',
  'edChooseFormat': 'Choose format',
  'edPresets': 'Presets',
  'edResize': 'Resize',
  'edEffect': 'Effect',
  'edTransition': 'Transition',
  'edStyleEffects': 'Style & effects',
  'edDuration': 'Duration',
  'edTotalDuration': 'Total duration',
  'edSplitsEvenly':
      'Splits evenly across all clips. Tap a clip above to set its own time.',
  'edLength': 'Length',
  'edClipLengthHint': 'Set how long this clip plays in the final video.',
  'edClipVolumeHint':
      'Controls this video clip\u2019s own sound in the export.',
  'edDone': 'Done',
  'edSoundtrack': 'Add soundtrack (optional)',
  'edSoundscape': 'Soundscape',
  'edSoundtrackIntro':
      'Record your voice or upload an audio file to play with your video.',
  'edRecordVoice': 'Record voice',
  'edUploadAudio': 'Upload audio',
  'edVolume': 'Volume',
  'edAudioSecured': 'Your audio is secured and used only for this conversion.',
  'edMp4Preview': 'MP4 preview',
  'edPreviewMatches': 'The preview matches your final video frame.',
  'edUploadToBegin': 'Upload media to begin',
  'edCreateMp4': 'Create MP4',
  'edConvertToMp4': 'Convert to MP4',
  'edExportMp4': 'Export MP4',
  'edProjectSummary': 'Project summary',
  'edEstSize': 'Est. size',
  'edFileType': 'File type',
  'edPreview': 'Preview',
  'edPreset': 'Preset',
  'edAssets': 'Assets',
  'edThreeSteps':
      'Transform static memories into social videos in three simple steps.',
  'edDesktopStudio': 'Desktop Studio · Build your MP4 with full file access.',
  'edClearWarning':
      'This clears your media, audio, and settings. This cannot be undone.',
  'edVoiceNarration': 'Voice narration',
  'edRecordYourVoice': 'Record your voice',
  'edRecordHint':
      'Tap the button and start speaking. You can pause, re-record, or remove it.',
  'edStartRecording': 'Start recording',
  'edStop': 'Stop',
  'edReRecord': 'Re-record',
  'edUseRecording': 'Use this recording',
  'edYourNarration': 'Your narration',
  'edRemoveAudio': 'Remove audio',
  'edMicOff': 'Microphone access is off',
  'edMicHint': 'Stillora needs microphone access to record your narration.',
  'edOpenSettings': 'Open Settings',
  'edNarrationPrivacy':
      'Your recording stays on your device and is used only to create your video.',
  'edClearReel': 'Clear reel',
  'edReel3d': '3D video reel',
  'edFormatExport': 'Format & export',

  'galLocalLibrary': 'Local library',
  'galStoredHere':
      'Exports are stored on this device. Nothing here depends on cloud storage.',
  'galEmpty': 'Videos you make on this device will appear here.',
  'galSelect': 'Select',
  'galSelected': 'selected',
  'galOpenFull': 'Open full screen',
  'galShare': 'Share',
  'galSavedLocally': 'Saved locally',
  'galDeleteTitle': 'Delete local video?',
  'galDeleteBody':
      'This removes the video from your Stillora library and deletes the local file from this device.',
  'galDeleteManyBody': 'This permanently removes them from this device.',
  'galLoadMore': 'Load more',
  'galVideo': 'Video',

  'colTitle': 'Colour correction',
  'colBrightness': 'Brightness',
  'colContrast': 'Contrast',
  'colExposure': 'Exposure',
  'colSaturation': 'Saturation',
  'colSharpness': 'Sharpness',
  'colTint': 'Tint',
  'colVibrance': 'Vibrance',
  'colWarmth': 'Warmth',
  'colLivePreview': 'Live preview — how the exported video will look',
  'colOriginal': 'Original',
  'colVivid': 'Vivid',
  'colWarm': 'Warm',
  'colCool': 'Cool',
  'colBright': 'Bright',
  'colVintage': 'Vintage',
  'colCinematic': 'Cinematic',

  'txtIntro':
      'Add animated text on top of your clip. Type it, drag it anywhere, and set when it appears.',
  'txtChooseVideo': 'Choose a video to caption',
  'txtThenAdd': 'Then add animated text and drag it into place.',
  'txtPlatformNote':
      'Text export runs on iPhone, macOS and Windows/Linux today.',
  'txtAddText': 'Add text',
  'txtLayers': 'Layers',
  'txtTimeline': 'Timeline',
  'txtEditText': 'Edit text',
  'txtText': 'Text',
  'txtSize': 'Size',
  'txtOpacity': 'Opacity',
  'txtOutline': 'Outline',
  'txtDropShadow': 'Drop shadow',
  'txtFadeIn': 'Fade in',
  'txtFadeOut': 'Fade out',
  'txtPickColour': 'Pick a colour',
  'txtUseColour': 'Use colour',

  'cvIntro':
      'Pick images in any format (HEIC, WebP, TIFF, BMP…) and convert them.',
  'cvConvertTo': 'Convert to',
  'cvExportTo': 'Export to',
  'cvEmpty': 'Select images to see them here',
  'cvSelectedCount': 'selected',
  'exGenerating': 'Generating',
  'exExport': 'Export',

  'proHiRes': 'Higher Resolution Exports',
  'proHiResBody': '1080p, 2K and 4K where the platform supports them',
  'proAdvTools': 'Advanced Media Tools',
  'proAdvToolsBody': 'Bitrate, thresholds, custom speeds and file-size targets',
  'proBatch': 'Batch Processing',
  'proBatchBody': 'Run a whole folder through a tool in one pass',
  'proPresets': 'Premium Controls & Presets',
  'proPresetsBody': 'Saved presets, extra transitions and effects',
  'proNoAds': 'Remove Ads Forever',
  'proNoAdsBody': 'Sponsored content disappears the moment you unlock',
  'proLocalBoth': 'Local Processing — Free and Pro',
  'proLocalBothBody':
      'No cloud upload required, and no Stillora watermark on either tier',
  'proRowLocal': 'Local Processing',
  'proRowFilesStay': 'Files Stay on Device',
  'proRowBasicTools': 'Basic Media Tools',
  'proRowNoWatermark': 'No Stillora Watermark',
  'proRowExport': 'Export',
  'proRowAdvanced': 'Advanced Controls',
  'proRowBatch': 'Batch Processing',
  'proRowPresets': 'Premium Presets',
  'proRowAds': 'Ads / Sponsored Content',
  'proRowLifetime': 'Lifetime Access',
  'proLimited': 'Limited',
  'proYes': 'Yes',
  'proNo': 'No',
  'proFreeTier': 'Free tier',

  'obSkip': 'Skip',
  'obNext': 'Next',
  'obGetStarted': 'Get started',
  'obUploadTitle': 'Upload your media',
  'obUploadBody':
      'Pick one or many photos and videos. Drag to reorder them into the perfect sequence.',
  'obTimeTitle': 'Time each clip',
  'obTimeBody':
      'Set how long the whole video runs, or tap any clip to give it its own duration.',
  'obExportTitle': 'Add sound & export',
  'obExportBody':
      'Drop in an optional soundtrack, choose a format, and export a ready-to-share MP4.',

  'pvSaveShare': 'Save & share',
  'pvSaveRoll': 'Save to Photos',
  'pvSaved': 'Saved to your photo library.',
  'pvSaving': 'Saving…',
  'pvPreparing': 'Preparing…',
  'pvNeedPhotoAccess': 'Allow photo access to save your video.',
  'pvSaveFailed': 'Could not save the video. Please try again.',
  'pvGone': 'That video is no longer available. Please export again.',
  'pvLoadToPreview': 'Load a video to preview it here',
  'pvUploadToPreview': 'Upload a video to preview it here',

  'back': 'Back',
  'toggleSidebar': 'Toggle sidebar',
  'expandSidebar': 'Expand sidebar',
  'collapseSidebar': 'Collapse sidebar',

  'fxNone': 'None',
  'fxGlow': 'Glow',
  'fxPanZoom': 'Pan & Zoom',
  'fxFloat': 'Float',
  'fxShake': 'Shake',
  'trFade': 'Fade',
  'trSwipe': 'Swipe',
  'trZoom': 'Zoom',
  'trSlideUp': 'Slide Up',
  'trSlideDown': 'Slide Down',
  'trGlitch': 'Glitch',
  'trFlash': 'Flash',
  'trPulse': 'Pulse',
  'vpReels': 'Reels / Shorts / TikTok',
  'vpReelsShort': 'Reels',
  'vpSquarePost': 'Square Post',
  'vpPortraitPost': 'Portrait Post',
  'vpYoutube': 'YouTube Landscape',
  'vpOriginalSize': 'Original Size',
  'eqSmallestFile': 'Smallest file',
  'eqRecommended': 'Recommended',
  'eqSharper': 'Sharper',
  'eqLargestFile': 'Largest file',
  'cmpHigh': 'High quality',
  'cmpHighNote': 'Barely visible loss',
  'cmpBalanced': 'Balanced',
  'cmpBalancedNote': 'Best size / quality trade',
  'cmpSmall': 'Small',
  'cmpSmallNote': 'Fine for sharing',
  'cmpTiny': 'Tiny',
  'cmpTinyNote': 'Smallest — lower quality',
  'colBw': 'B&W',

  'exNothingToExport': 'Nothing to export.',
  'exFailed': 'Failed',
  'exportCancelled': 'Export cancelled',
  'toolUploadVideo': 'Upload video',
  'toolOutputApprox': 'Output ≈',
  'audMuted': 'Muted',
  'audDropped': 'Dropped',
  'audKept': 'Kept',
  'audNewAudio': 'New audio',
  'audRemoveNewAudio': 'Remove new audio',
  'audReplacedByNew': 'Replaced by your new audio',
  'cmpPreviewCaption':
      'Same frame, smaller file — quality drops as the level rises',
  'cmpExporting': 'Compressing…',
  'cmpExportCta': 'Compress & export',
  'spPreviewCaption': 'How the exported video will look',
  'spUploadToPreview': 'Upload a video to preview the speed-up here',
  'spMuteNote': 'Export the sped video with no sound',
  'spExportCta': 'Speed up & export',
  'spAtSpeed': 'at',
  'slPreviewCaption': 'How the exported cut will look',
  'slUploadToPreview': 'Upload a video with speech to preview it here',
  'slSourceHint': 'MP4 / MOV with speech',
  'slGentle': 'Gentle',
  'slAggressive': 'Aggressive',
  'slGentleNote': 'Gentle — only clear silence is cut',
  'slAggressiveNote': 'Aggressive — trims quiet pauses too',
  'slMuteNote': 'Export the trimmed video with no sound',
  'slExporting': 'Removing silence…',
  'slExportCta': 'Remove silence & export',

  'edUpload': 'Upload',
  'edAudio': 'Audio',
  'edExport': 'Export',
  'colCustomApplied': 'Custom grade applied',
  'colGradeFinal': 'Grade the final video',
  'startOverTabWarning':
      'This clears the media and settings on this tab. This cannot be undone.',

  'cvNothingConverted': 'Nothing converted.',
  'cvConvertedCount': 'Converted',
  'cvFailedCount': 'failed',
  'cvAddMoreImages': 'Add more images',
  'cvSelectImages': 'Select images',
  'cvDefaultLocation': 'Default location',
  'cvSavedToPhotos': 'Saved to Photos',
  'cvUseDefaultLocation': 'Use default location',
  'cvConvertTo2': 'Convert',
  'cvTo': 'to',
  'htmlConvertCta': 'Convert to MP4',
  'htmlVideoSaved': 'Video saved.',
  'htmlSavedToRoll': 'Saved to your camera roll.',
  'htmlPhotosDenied': 'Photos permission was denied.',
  'htmlFileMissing': 'The video file is missing.',
  'htmlSaveFailed': 'Could not save the video.',
  'htmlOutputSize': 'Output size',
  'htmlQuality': 'Quality',

  'galDownload': 'Download',
  'galSave': 'Save',
  'galSavedToRoll': 'Saved to your Camera Roll.',
  'galVideoGone': 'That video is no longer available.',
  'galDeleteSelected': 'Delete selected',
  'galPickToPlay': 'Pick a render to play it here',
  'galDeleteOneBody':
      'This removes the video from your Stillora library and deletes the local file from this device.',
  'galSaveToRoll': 'Save to Camera Roll',
  'openSettings': 'Settings',
  'txtDragHint': 'Drag a layer to place it — this is what gets exported',
  'txtLoadVideoFirst': 'Load a video to place text on it',
  'txtNeedVideoAndLayer': 'Add a video and at least one text layer first.',
  'txtEmptyText': 'Empty text',
  'txtMoveUp': 'Move up',
  'txtMoveDown': 'Move down',
  'txtDuplicate': 'Duplicate',
  'txtRemove': 'Remove',
  'txtWeight': 'Weight',
  'txtAlignment': 'Alignment',
  'txtTextColour': 'Text colour',
  'txtBackground': 'Background',
  'txtOutlineColour': 'Outline colour',
  'txtRegular': 'Regular',
  'txtMedium': 'Medium',
  'txtYourTitle': 'Your Title',
  'txtYourSubtitle': 'Your subtitle here',
  'txtTapToLearn': 'Tap to learn more',
  'txtYourText': 'Your text',
  'txtSubtitleStyle': 'Subtitle',
  'txtCaptionStyle': 'Caption',
  'fontDefault': 'Default',

  'txtBold': 'Bold',
  'txtBlack': 'Black',

  'galSelectAll': 'All',
  'galSelectNone': 'None',
  'galLoadMoreCount': 'Load more',
  'galDeleteCountTitle': 'Delete {n} videos?',
  'galDeleteOneTitle': 'Delete 1 video?',
  'txtExportFailed': 'Export failed',
  'txtNoLayersYet':
      'No text yet. Tap “Add text” (or a preset) to drop a layer onto the clip.',

  'edAddSoundtrack': 'Add Soundtrack',
  'edSoundtrackOrNarration': 'Soundtrack or voice narration',
  'edTapToChange': 'Tap to change',
  'edSelectedTrack': 'Selected Track',
  'edRecordOrUpload':
      'Record your voice or upload an audio file to play with your video.',
  'edOptionalAudio': 'Optional Audio',
  'edAudioAttached': 'Audio Attached',
  'edKeepsOwnSoundMany':
      'Your videos keep their own sound. Add audio to play alongside them.',
  'edKeepsOwnSoundOne':
      'Your video keeps its own sound. Add audio to play alongside it.',
  'edUseAudioLength': 'Use audio',
  'rlOutput': 'Output',
  'rlMatchesAudio': 'matches audio',
  'rlMatchesVideo': 'matches app video',
  'rlMeasuring': 'Measuring length…',
  'rlAudioAdded': 'Audio added — sets reel length',
  'rlAddAudioOptional': 'Add audio (optional)',
  'rlAddMedia': 'Add video or image',
  'rlUploadAppVideo': 'Upload app video',
  'rlSimpleReel': 'Create a simple reel from your media.',
  'rlMockupHint':
      'Your screen recording is placed inside the selected 3D device.',
  'loopFormatsFooter': 'Reels · TikTok · Stories · YouTube',

  'proGate720p': 'Exports above 720p are part of Stillora Pro.',
  'proGateAdvanced': 'Advanced controls are part of Stillora Pro.',
  'proGateBatch': 'Batch processing is part of Stillora Pro.',
  'proGatePresets': 'Premium presets are part of Stillora Pro.',
  'proGateAds': 'Remove sponsored content for good with Stillora Pro.',
  'proFeatureLabel': 'Stillora Pro feature',
  'authFailed': 'Sign-in failed. Please try again.',
  'authSigningIn': 'Signing in…',
  'authContinueApple': 'Continue with Apple',
  'authContinueGoogle': 'Continue with Google',
  'authUnlockNarration': 'Unlock Voice Narration',
  'authUnlockNarrationBody':
      'Sign in to record your voice and add a personal narration to your videos.',
  'authNotNow': 'Not Now',
  'authNarrationUnlocked': 'Voice Narration Unlocked',
  'authNarrationUnlockedBody':
      'You can now record your voice and use it in your next video.',
  'authStartRecording': 'Start Recording',
  'exMediaFailed': 'The selected media could not be exported.',
  'exPreparingBody':
      'Preparing media, generating video, merging audio, and saving locally.',
  'exBackToEditor': 'Back to editor',
  'exNotReady': 'Export not ready yet',
  'exGeneratingVideo': 'Generating video…',
  'edStep3': 'Step 3',

  'proGateOnboarding':
      'Every tool you just saw is free. Pro adds 4K exports, advanced controls and no ads.',
  'proGateReminder':
      'Still on Free? Pro adds 4K exports, advanced controls and no ads — one payment, no subscription.',

  'authLoginPitch':
      'Sign in to unlock Voice Narration. Basic videos stay free, no account needed.',
  'authTerms': 'Terms',
  'authPrivacy': 'Privacy',
  'edMediaStaysLocal':
      'Your media stays on your device and is only used to create your video.',
  'edRecordingHint':
      'Tap the button and start speaking. You can pause, re-record, or keep the take you like.',
  'edPaused': 'Paused',
  'edRecording': 'Recording…',
  'edResume': 'Resume',
  'edPause': 'Pause',
  'edRecordingFailed': 'Recording could not start',
  'edVideoClip': 'Video',
  'edPhotoClip': 'Photo',
  'edClipDuration': 'duration',
  'edUnmute': 'Unmute',
  'edMute': 'Mute',
  'edVolumeLabel': 'Volume',
  'edReadyToExport': 'Ready to export',
  'edSetUpExport': 'Set up export',
  'edReviewBeforeConvert': 'Review the desktop preview before converting.',
  'edChooseMediaToUnlock': 'Choose media to unlock conversion.',
  'edNoneSelected': 'None selected',
  'edSignedIn': 'Signed in',
  'edGuest': 'Guest',
  'edMediaUnreadable':
      'Stillora could not read the selected media. Please choose the file again.',
  'edExportFirstToShare': 'Export first to share',
  'rlNeedAppVideo': 'Add an app video before exporting.',
  'rlReplaceAppVideo': 'Replace app video',
  'rlReplaceMedia': 'Replace media',
  'toastVideoReady': 'Your video is ready ✓',
  'toastConversionFailed': 'Conversion failed. Please try again.',
  'toastExportComplete': 'Export complete ✓',
  'toastExportFailed': 'Export failed. Please try again.',

  'splashTagline': 'Turn images into videos in seconds.',
  'shareSavePdf': 'Save PDF',
  'shareSaveAudio': 'Save audio',
  'shareSaveVideo': 'Save video',

  'rlLayerReel': 'Layer reel',
  'rlLayers': 'Layers',

  'durMinuteOne': '1 min',
  'durMinutes': '{n} min',
  'pvRestart': 'Restart',
  'pvBack5': 'Back 5 seconds',
  'pvForward5': 'Forward 5 seconds',
  'pvPlay': 'Play',

  'htmlErrLocalRender': 'Could not render the HTML on this device.',
  'htmlErrEmptyVideo': 'The server returned an empty video.',
  'htmlErrTimeout': 'The render took too long. Try a shorter duration or lower fps.',
  'htmlErrGateway': 'The server took too long to render this page. Try a shorter duration, a lower fps, a smaller size, or a simpler page.',
  'htmlErrStatus': 'The server couldn’t render this page. Please try again.',
  'htmlErrUnreachable': 'Couldn’t reach the server. Check your connection and try again.',
  'htmlErrGeneric': 'Could not convert the HTML. Check your connection and try again.',

  'authGoogleCancelled': 'Google sign-in was cancelled.',
  'authGoogleFailed': 'Google sign-in failed.',
  'authGoogleRetry': 'Google sign-in failed. Please try again.',
  'authGoogleMisconfigured': 'Google sign-in is not configured correctly for this app.',
  'authVerifyFailedGoogle': 'Stillora could not verify your Google account.',
  'authVerifyFailedApple': 'Stillora could not verify your Apple account.',
  'authAppleUnsupported': 'Sign in with Apple is not supported on this platform yet.',
  'authAppleNeedsIos13': 'Sign in with Apple requires iOS 13 or later.',
  'authAppleFailed': 'Sign in with Apple failed.',
  'authAppleRetry': 'Sign in with Apple failed. Please try again.',
  'authAppleCancelled': 'Sign in with Apple was cancelled.',
  'authAppleUnavailable': 'Sign in with Apple is unavailable right now. Please try again.',
  'authAppleConnection': 'Sign in with Apple failed. Please check your connection and try again.',
  // Store Screenshots
  'storeShots': 'Store Screenshots',
  'storeShotsSubtitle': 'App Store & Play sizes, exported as one zip',
  'ssEyebrow': 'STORE EXPORT',
  'ssHeading': 'App Store & Play screenshots',
  'ssIntro':
      'Add your screens once, pick the sizes each store asks for, and export '
      'a single zip with every render in its own folder.',
  'ssSourceImages': 'Source images',
  'ssAddImages': 'Add screenshots',
  'ssAddMore': 'Add more',
  'ssClear': 'Clear',
  'ssEmpty': 'Add screenshots to see them here',
  'ssDropHint': 'Add your app screens',
  'ssSizes': 'Sizes',
  'ssRequiredOnly': 'Required only',
  'ssRequired': 'required',
  'ssPickSizes': 'Pick at least one size',
  'ssLook': 'How images fit',
  'ssFit': 'Fit',
  'ssFill': 'Fill',
  'ssBackground': 'Background',
  'ssBlack': 'Black',
  'ssWhite': 'White',
  'ssMidnight': 'Midnight',
  'ssFormat': 'Format',
  'ssOrientation': 'Orientation',
  'ssPortrait': 'Portrait',
  'ssLandscape': 'Landscape',
  'ssNoAlphaNote':
      'Both stores reject transparency, so every render is flattened onto '
      'the background colour.',
  'ssZipLayout': 'Zipped as Store / size / 01-name',
  'ssExport': 'Export zip',
  'ssExporting': 'Rendering...',
  'ssNothing': 'Nothing was rendered.',
  'ssAndroidPhone': 'Android phone',
  'ssAndroidTablet': 'Android tablet',
  'ssPreviewCaption': 'Every image is rendered at every selected size',
  'ssClearWarning': 'This removes every image and resets the sizes.',
  'ssSaveZip': 'Save zip',
  'ssSavedZip': 'Zip saved',
  'ssSaveFailed': 'Could not save the zip.',
  'ssGone': 'The zip is no longer available.',
  'ssOutputCount': '{files} files \u00b7 {sizes} sizes',
  'ssImageCount': '{count} images',
  'ssProgress': 'Rendering {done} / {total}',
};

const _ar = <String, String>{
  'create': 'إنشاء',
  'library': 'المكتبة',
  'html': 'HTML',
  'settings': 'معلومات',
  'loopImages': 'تكرار الصور',
  'removeSilence': 'إزالة الصمت',
  'watermark': 'علامة مائية',
  'speed': 'السرعة',
  'convert': 'إعادة تنسيق الصور',
  'text': 'نص',
  'compress': 'ضغط',
  'pdfConverter': 'محوّل PDF',
  'stilloraPro': 'Stillora Pro',

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
  'stilloraProSubtitle': 'ادفع مرة واحدة وافتح كل الأدوات',

  'groupCreate': 'الإنشاء',
  'groupVideoTools': 'أدوات الفيديو',
  'groupDocumentTools': 'أدوات المستندات',
  'groupYourContent': 'محتواك',
  'groupAccountApp': 'الحساب / التطبيق',

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

  'pdfHeading': 'صور وملفات PDF ← ملف PDF واحد',
  'pdfIntro':
      'أضف الصور والمستندات الممسوحة وملفات PDF الموجودة، ورتّب الصفحات، '
      'وصحّح المائل منها، ثم صدّر المجموعة كلها في ملف واحد.',
  'pdfReorderHint':
      'اسحب المقبض لإعادة الترتيب — الصفحة الأولى في الأعلى. كل شيء يبقى على '
      'هذا الجهاز.',
  'pdfAddFiles': 'أضف صورًا أو ملفات PDF',
  'pdfAddFilesHint': 'JPG · PNG · WebP · HEIC · PDF',
  'pdfNoPages': 'لا توجد صفحات بعد',
  'pdfExport': 'تصدير PDF',
  'pdfBuilding': 'جارٍ إنشاء ملف PDF…',
  'pdfSaved': 'تم حفظ ملف PDF.',
  'pdfSaveFailed': 'تعذّر حفظ ملف PDF. حاول مرة أخرى.',
  'pdfGone': 'ملف PDF المُصدَّر لم يعد متاحًا.',
  'pdfNeedsFileAccess': 'اسمح بالوصول إلى الملفات لحفظ ملف PDF.',
  'pdfMoveUp': 'تحريك لأعلى',
  'pdfMoveDown': 'تحريك لأسفل',
  'pdfRotateLeft': 'تدوير لليسار',
  'pdfRotateRight': 'تدوير لليمين',
  'pdfRemovePage': 'إزالة الصفحة',
  'pdfFromImages': 'من الصور',
  'pdfFromPdfs': 'من ملفات PDF',
  'pdfMatchImage': 'مطابقة الصورة',
  'pdfMatchImageHint': 'كل صفحة تأخذ شكل صورتها',
  'pdfExportOne': 'تصدير صفحة واحدة بصيغة PDF',
  'pdfExportMany': 'تصدير {n} صفحات بصيغة PDF',

  'loopHeading': 'تحويل الصور إلى مقاطع فيديو',
  'loopIntro':
      'أضف الصور واختر مقاسًا واحدًا ومدة واحدة. كل صورة تصبح ملف MP4 مستقلًا '
      'بهذه المدة — ولا تُدمج معًا.',
  'loopBatchRender': 'معالجة دفعة',
  'loopAddImages': 'أضف صورًا',
  'loopAddMore': 'أضف المزيد',
  'loopClear': 'مسح',
  'loopClearWarning':
      'سيؤدي هذا إلى مسح الصور المنتظرة وخيارات المقاس والمدة والجودة. '
      'لا يمكن التراجع عن هذا الإجراء.',
  'loopDropHint': 'أفلِت الصور أو انقر للإضافة',
  'loopDropSubtitle': 'JPG · PNG · WebP — كل صورة تصبح ملف MP4 مستقلًا',
  'loopOutputSize': 'مقاس الإخراج',
  'loopImageMode': 'وضع الصورة',
  'loopDuration': 'المدة',
  'loopQuality': 'الجودة',
  'loopEachOutput': 'كل ملف',
  'loopEachClip': 'لكل مقطع',
  'loopTypeDuration': 'اكتب أي مدة',
  'loopConverting': 'جارٍ التحويل…',
  'loopRendering': 'جارٍ المعالجة…',
  'loopFit': 'احتواء',
  'loopFill': 'ملء',
  'loopStatusReady': 'جاهز',
  'loopStatusRendering': 'قيد المعالجة',
  'loopStatusDone': 'تم',
  'loopStatusFailed': 'فشل',
  'loopShareVideo': 'مشاركة الفيديو',
  'loopConvertOne': 'تحويل صورة واحدة',
  'loopConvertTwo': 'تحويل صورتين',
  'loopConvertFew': 'تحويل {n} صور',
  'loopConvertMany': 'تحويل {n} صورة',
  'loopSavedCount': 'تم حفظ {done} من {total} في المكتبة',
  'loopImageCount': '{n}/{max} صورة',

  'pdfPageOne': 'صفحة واحدة',
  'pdfPageTwo': 'صفحتان',
  'pdfPageFew': '{n} صفحات',
  'pdfPageMany': '{n} صفحة',
  'pdfPages': 'الصفحات',
  'pdfMixHint':
      'يمكن مزج الصور وملفات PDF بحرية — كل ملف PDF يضيف صفحة لكل صفحة فيه.',
  'pdfRotateAll': 'تدوير الكل',
  'pdfPageSize': 'مقاس الصفحة',
  'pdfMargin': 'الهامش',
  'pdfImportQuality': 'جودة استيراد PDF',
  'pdfImportQualityHint':
      'تُعاد رسم صفحات PDF المستوردة كصور حتى يمكن تدويرها.',
  'pdfImportQualityNote': 'ينطبق على ملفات PDF المضافة من الآن فصاعدًا.',
  'pdfFileName': 'اسم الملف',
  'pdfMarginNone': 'بلا',
  'pdfMarginSmall': 'صغير',
  'pdfMarginWide': 'واسع',
  'startOver': 'البدء من جديد',
  'startOverConfirm': 'البدء من جديد؟',
  'livePreview': 'معاينة مباشرة',

  'loopEach': 'لكل ملف',
  'loopSize_vertical': 'عمودي',
  'loopSize_square': 'مربّع',
  'loopSize_portrait': 'طولي',
  'loopSize_landscape': 'أفقي',

  'pdfSheetA4Hint': '21 × 29.7 سم · تدور الصفحات أفقيًا لتناسب الصور العريضة',
  'pdfSheetLetterHint':
      '8.5 × 11 بوصة · تدور الصفحات أفقيًا لتناسب الصور العريضة',

  'pdfPortrait': 'طولي',
  'pdfLandscape': 'أفقي',

  'htmlHeading': 'من HTML إلى فيديو جاهز للنشر',
  'htmlIntro':
      'الصق الشيفرة، أو أفلِت ملف ‎.html، أو أدخل رابطًا — اختر المقاس والمدة، '
      'وصدّر ملف MP4 نظيفًا في ثوانٍ.',
  'htmlNewRender': 'معالجة جديدة',
  'htmlSource': 'المصدر',
  'htmlPaste': 'لصق',
  'htmlFile': 'ملف',
  'htmlUrl': 'رابط',
  'htmlDropFile': 'أفلِت ملف ‎.html',
  'htmlDropFileHint': 'أو انقر للاستعراض · ‎.html .htm',
  'htmlLength': 'الطول',
  'htmlDuration': 'المدة',
  'htmlFrameRate': 'معدل الإطارات',
  'htmlAudio': 'الصوت',
  'htmlAudioHint': 'تعليق صوتي أو موسيقى تُمزج مع الفيديو · تُقتطع بطوله',
  'htmlRemoveAudio': 'إزالة الصوت',
  'htmlRendering': 'جارٍ المعالجة…',
  'htmlClearWarning':
      'سيؤدي هذا إلى مسح شيفرة HTML أو الرابط والصوت وإعدادات الإخراج وآخر '
      'معالجة. لا يمكن التراجع عن هذا الإجراء.',
  'htmlNeedUrl': 'أدخل رابطًا للمعالجة.',
  'htmlNeedMarkup': 'الصق بعض شيفرة HTML أولًا.',
  'htmlNeedFile': 'اختر ملف ‎.html أولًا.',
  'htmlCancelled': 'أُلغي التحويل',
  'htmlFailed': 'حدث خطأ ما. حاول مرة أخرى.',

  'wmIntro':
      'أضف شعارًا أو صورة أو فيديو فوق مقطعك. اسحبه لتحديد موضعه، وغيّر حجمه، '
      'وحدّد وقت ظهوره. يحتفظ الفيديو بصوته الأصلي.',
  'wmChooseVideo': 'اختر فيديو لإضافة العلامة المائية',
  'wmThenDrop': 'ثم أفلِت شعارك أو صورتك أو فيديو آخر فوقه.',
  'wmAddOverlay': 'أضف شعارًا أو صورة أو فيديو',
  'wmOverlays': 'الطبقات',
  'wmRemove': 'إزالة',
  'wmNoOverlays':
      'لا توجد طبقات بعد. أضف شعارًا أو صورة أو فيديو لوضعه على المقطع.',
  'wmDragHint': 'اسحب الطبقة لتحديد موضعها — هذا ما سيُصدَّر',
  'wmLoadVideoFirst': 'حمّل فيديو لتكديس الطبقات فوقه',
  'wmNeedVideoAndOverlay': 'أضف فيديو وطبقة واحدة على الأقل أولًا.',
  'wmExportCancelled': 'أُلغي التصدير',
  'wmPlatformNote':
      'يعمل تصدير العلامة المائية حاليًا على macOS و Windows/Linux. '
      'التصدير على iPhone و Android قادم قريبًا.',

  'exportResolution': 'الدقة',
  'exportOriginal': 'الأصلي',
  'exportReplace': 'استبدال',
  'exportReadingVideo': 'جارٍ قراءة الفيديو…',
  'exportMp4': 'تصدير MP4',
  'exportExporting': 'جارٍ التصدير…',
  'exportCancel': 'إلغاء التصدير',
  'exportCancelling': 'جارٍ الإلغاء…',
  'exportBaseVideo': 'الفيديو الأساسي',
  'exportOutput': 'الإخراج',
  'savedToLibrary': 'حُفظ في المكتبة',

  'proTagline': 'أطلق القوة الكاملة لمجموعة أدواتك الخاصة.',
  'proPayOnce': 'ادفع مرة واحدة. استخدمه إلى الأبد.',
  'proPaidOnce': 'دفعت مرة واحدة. لك إلى الأبد على هذا الجهاز.',
  'proActive': 'مفعّل',
  'proUnlockedBody':
      'تم تفعيل Pro مدى الحياة. كل مستويات التصدير وكل التحكمات المتقدمة، '
      'بلا إعلانات — ولا شيء يحتاج إلى تجديد.',
  'proRestore': 'استعادة الشراء',
  'proOneTime': 'شراء لمرة واحدة. بلا اشتراك.',
  'proContinueFree': 'المتابعة بالنسخة المجانية',
  'proFreeStaysFree':
      'لا شيء محجوب. تبقى كل الأدوات متاحة في النسخة المجانية، بدون علامة '
      'مائية وبتصدير حتى 720p.',
  'yourPlan': 'خطتك',
  'planFree': 'مجاني',
  'planPro': 'Pro — مدى الحياة',
  'planFreeBody': 'أنت على الخطة المجانية. هذا ما تتضمنه:',
  'planProBody': 'Pro مدى الحياة مفعّل على هذا الجهاز.',
  'planIncludesTools': 'كل الأدوات، استخدام بلا حدود',
  'planIncludesQuality': 'تصدير حتى 720p',
  'planIncludesNoWatermark': 'بدون علامة Stillora المائية',
  'planIncludesLocal': 'تبقى الملفات على هذا الجهاز',
  'planIncludesAds': 'يتضمن محتوى برعاية',
  'planSeePro': 'اطّلع على ما يضيفه Pro',
  'proContacting': 'جارٍ الاتصال بالمتجر…',
  'proUnlockCta': 'فعّل Pro مدى الحياة',
  'proPrivacyBody':
      'تعالج النسختان المجانية وPro كل شيء محليًا. ما تشتريه في Pro هو جودة '
      'أعلى وتحكم أكبر وسير عمل أسرع — لا الوصول إلى ملفاتك، ولا خصوصيتك.',
  'proCompareTitle': 'المجاني مقابل Pro مدى الحياة',
  'proCompareFeature': 'الميزة',
  'proCompareFree': 'المجاني',
  'proComparePro': 'Pro مدى الحياة',
  'proCompareFooter':
      'Pro يعني جودة أعلى وتحكمًا أكبر وسير عمل أسرع وبلا إعلانات — '
      'وليس مجرد الوصول إلى ملفاتك.',

  'toolSource': 'المصدر',
  'toolOutput': 'الإخراج',
  'toolQuality': 'الجودة',
  'toolAudio': 'الصوت',
  'toolSpeed': 'السرعة',
  'toolSizeApprox': 'الحجم ≈',
  'silenceIntro':
      'ارفع فيديو، وسيزيل Stillora فترات الصمت التي لا يتحدث فيها أحد.',
  'silenceSensitivity': 'الحساسية',
  'silenceRemoveAudio': 'إزالة الصوت الأصلي',
  'silenceNewAudioNote':
      'يُشغَّل الصوت الجديد بسرعته العادية، ويتكرر الفيديو ليطابقه.',
  'speedIntro':
      'ارفع فيديو وسرّعه. أضف مقطعًا صوتيًا وسيتكرر الفيديو المُسرَّع ليطابقه.',
  'speedMute': 'كتم (إزالة الصوت الأصلي)',
  'speedNewAudioNote':
      'يُشغَّل الصوت الجديد بسرعته العادية، ويتكرر الفيديو المُسرَّع ليطابقه.',
  'compressIntro': 'ارفع فيديو وصغّره إلى ملف MP4 أخف بالدقة نفسها.',
  'compressLevel': 'الضغط',
  'compressMute': 'كتم (إزالة الصوت لملف أصغر)',
  'compressBefore': 'قبل',
  'compressAfter': 'بعد ≈',
  'compressSaving': 'التوفير',

  'previewComplete': 'اكتمل التصدير',
  'previewReady': 'فيديوك جاهز للمشاركة.',
  'previewShareTo': 'مشاركة إلى',
  'previewMore': 'المزيد',
  'previewAnother': 'أنشئ فيديو آخر',
  'previewNoVideo': 'لا يوجد فيديو بعد',
  'previewCreateVideo': 'أنشئ فيديو',

  'sponsored': 'إعلان',
  'reset': 'إعادة تعيين',

  'edUploadMedia': 'رفع الوسائط',
  'edUploadIntro': 'أضف صورًا أو مقطعًا قصيرًا للبدء.',
  'edTapToUpload': 'انقر للرفع\nأو أفلِت الملفات',
  'edPhotosOrClips': 'صور أو مقاطع قصيرة',
  'edFileTypes': 'JPG · PNG · HEIC · MOV · MP4',
  'edContinue': 'متابعة',
  'edEdit': 'تعديل',
  'edSelectedMedia': 'الوسائط المحددة',
  'edSourceMedia': 'وسائط المصدر',
  'edChooseMedia': 'اختر صورًا أو مقاطع فيديو',
  'edDragToReorder': 'اسحب لإعادة الترتيب بعد اختيار الوسائط.',
  'edSelectThenReorder': 'اختر الصور والفيديوهات، ثم اسحب لإعادة الترتيب.',
  'edAddMore': 'أضف المزيد',
  'edReplace': 'استبدال',
  'edChange': 'تغيير',
  'edChoosePreset': 'اختر النمط',
  'edChooseFormat': 'اختر التنسيق',
  'edPresets': 'الأنماط',
  'edResize': 'التحجيم',
  'edEffect': 'التأثير',
  'edTransition': 'الانتقال',
  'edStyleEffects': 'الأسلوب والتأثيرات',
  'edDuration': 'المدة',
  'edTotalDuration': 'المدة الإجمالية',
  'edSplitsEvenly':
      'تُوزَّع بالتساوي على كل المقاطع. انقر مقطعًا بالأعلى لتحديد مدته الخاصة.',
  'edLength': 'الطول',
  'edClipLengthHint': 'حدّد مدة تشغيل هذا المقطع في الفيديو النهائي.',
  'edClipVolumeHint': 'يتحكم في صوت هذا المقطع داخل التصدير.',
  'edDone': 'تم',
  'edSoundtrack': 'أضف موسيقى (اختياري)',
  'edSoundscape': 'المشهد الصوتي',
  'edSoundtrackIntro': 'سجّل صوتك أو ارفع ملفًا صوتيًا ليُشغَّل مع الفيديو.',
  'edRecordVoice': 'سجّل صوتك',
  'edUploadAudio': 'ارفع ملفًا صوتيًا',
  'edVolume': 'مستوى الصوت',
  'edAudioSecured': 'صوتك محمي ويُستخدم لهذا التحويل فقط.',
  'edMp4Preview': 'معاينة MP4',
  'edPreviewMatches': 'تطابق المعاينة إطار الفيديو النهائي.',
  'edUploadToBegin': 'ارفع وسائط للبدء',
  'edCreateMp4': 'أنشئ MP4',
  'edConvertToMp4': 'حوّل إلى MP4',
  'edExportMp4': 'تصدير MP4',
  'edProjectSummary': 'ملخص المشروع',
  'edEstSize': 'الحجم التقديري',
  'edFileType': 'نوع الملف',
  'edPreview': 'معاينة',
  'edPreset': 'النمط',
  'edAssets': 'العناصر',
  'edThreeSteps': 'حوّل ذكرياتك الثابتة إلى فيديوهات اجتماعية في ثلاث خطوات.',
  'edDesktopStudio': 'استوديو سطح المكتب · أنشئ ملف MP4 بوصول كامل للملفات.',
  'edClearWarning':
      'سيؤدي هذا إلى مسح الوسائط والصوت والإعدادات. لا يمكن التراجع عن هذا.',
  'edVoiceNarration': 'التعليق الصوتي',
  'edRecordYourVoice': 'سجّل صوتك',
  'edRecordHint':
      'انقر الزر وابدأ الحديث. يمكنك الإيقاف المؤقت أو إعادة التسجيل أو الحذف.',
  'edStartRecording': 'ابدأ التسجيل',
  'edStop': 'إيقاف',
  'edReRecord': 'إعادة التسجيل',
  'edUseRecording': 'استخدم هذا التسجيل',
  'edYourNarration': 'تعليقك الصوتي',
  'edRemoveAudio': 'إزالة الصوت',
  'edMicOff': 'الوصول إلى الميكروفون معطّل',
  'edMicHint': 'يحتاج Stillora إلى الميكروفون لتسجيل تعليقك الصوتي.',
  'edOpenSettings': 'افتح الإعدادات',
  'edNarrationPrivacy':
      'يبقى تسجيلك على جهازك ويُستخدم فقط لإنشاء الفيديو الخاص بك.',
  'edClearReel': 'مسح الريل',
  'edReel3d': 'ريل فيديو ثلاثي الأبعاد',
  'edFormatExport': 'التنسيق والتصدير',

  'galLocalLibrary': 'المكتبة المحلية',
  'galStoredHere':
      'تُحفظ الملفات المصدَّرة على هذا الجهاز. لا شيء هنا يعتمد على السحابة.',
  'galEmpty': 'ستظهر هنا الفيديوهات التي تنشئها على هذا الجهاز.',
  'galSelect': 'تحديد',
  'galSelected': 'محدد',
  'galOpenFull': 'فتح بملء الشاشة',
  'galShare': 'مشاركة',
  'galSavedLocally': 'محفوظ محليًا',
  'galDeleteTitle': 'حذف الفيديو المحلي؟',
  'galDeleteBody':
      'يزيل هذا الفيديو من مكتبة Stillora ويحذف الملف المحلي من هذا الجهاز.',
  'galDeleteManyBody': 'سيؤدي هذا إلى إزالتها نهائيًا من هذا الجهاز.',
  'galLoadMore': 'تحميل المزيد',
  'galVideo': 'فيديو',

  'colTitle': 'تصحيح الألوان',
  'colBrightness': 'السطوع',
  'colContrast': 'التباين',
  'colExposure': 'التعريض',
  'colSaturation': 'التشبع',
  'colSharpness': 'الحدة',
  'colTint': 'الصبغة',
  'colVibrance': 'الحيوية',
  'colWarmth': 'الدفء',
  'colLivePreview': 'معاينة مباشرة — كيف سيبدو الفيديو المصدَّر',
  'colOriginal': 'الأصلي',
  'colVivid': 'زاهٍ',
  'colWarm': 'دافئ',
  'colCool': 'بارد',
  'colBright': 'ساطع',
  'colVintage': 'كلاسيكي',
  'colCinematic': 'سينمائي',

  'txtIntro':
      'أضف نصًا متحركًا فوق مقطعك. اكتبه واسحبه أينما شئت وحدّد وقت ظهوره.',
  'txtChooseVideo': 'اختر فيديو لإضافة النص',
  'txtThenAdd': 'ثم أضف نصًا متحركًا واسحبه إلى مكانه.',
  'txtPlatformNote': 'يعمل تصدير النص حاليًا على iPhone، macOS، Windows/Linux.',
  'txtAddText': 'أضف نصًا',
  'txtLayers': 'الطبقات',
  'txtTimeline': 'المسار الزمني',
  'txtEditText': 'تحرير النص',
  'txtText': 'النص',
  'txtSize': 'الحجم',
  'txtOpacity': 'الشفافية',
  'txtOutline': 'الحد الخارجي',
  'txtDropShadow': 'ظل',
  'txtFadeIn': 'ظهور تدريجي',
  'txtFadeOut': 'اختفاء تدريجي',
  'txtPickColour': 'اختر لونًا',
  'txtUseColour': 'استخدم اللون',

  'cvIntro': 'اختر صورًا بأي صيغة (HEIC، WebP، TIFF، BMP…) وحوّلها.',
  'cvConvertTo': 'التحويل إلى',
  'cvExportTo': 'التصدير إلى',
  'cvEmpty': 'اختر صورًا لعرضها هنا',
  'cvSelectedCount': 'محدد',
  'exGenerating': 'جارٍ الإنشاء',
  'exExport': 'تصدير',

  'proHiRes': 'تصدير بدقة أعلى',
  'proHiResBody': '1080p، 2K، 4K حيث تدعمها المنصة',
  'proAdvTools': 'أدوات وسائط متقدمة',
  'proAdvToolsBody': 'معدل البت والعتبات والسرعات المخصصة وحجم الملف المستهدف',
  'proBatch': 'المعالجة بالدفعات',
  'proBatchBody': 'مرّر مجلدًا كاملًا عبر أداة واحدة في مرة واحدة',
  'proPresets': 'تحكمات وأنماط مميزة',
  'proPresetsBody': 'أنماط محفوظة وانتقالات وتأثيرات إضافية',
  'proNoAds': 'إزالة الإعلانات نهائيًا',
  'proNoAdsBody': 'يختفي المحتوى المموّل فور التفعيل',
  'proLocalBoth': 'معالجة محلية — في النسختين',
  'proLocalBothBody':
      'لا حاجة إلى رفع سحابي، وبلا علامة Stillora في أي من النسختين',
  'proRowLocal': 'معالجة محلية',
  'proRowFilesStay': 'الملفات تبقى على الجهاز',
  'proRowBasicTools': 'أدوات وسائط أساسية',
  'proRowNoWatermark': 'بلا علامة Stillora',
  'proRowExport': 'تصدير',
  'proRowAdvanced': 'تحكمات متقدمة',
  'proRowBatch': 'المعالجة بالدفعات',
  'proRowPresets': 'أنماط مميزة',
  'proRowAds': 'إعلانات / محتوى مموّل',
  'proRowLifetime': 'وصول مدى الحياة',
  'proLimited': 'محدود',
  'proYes': 'نعم',
  'proNo': 'لا',
  'proFreeTier': 'النسخة المجانية',

  'obSkip': 'تخطٍ',
  'obNext': 'التالي',
  'obGetStarted': 'ابدأ الآن',
  'obUploadTitle': 'ارفع وسائطك',
  'obUploadBody':
      'اختر صورة أو عدة صور ومقاطع. اسحبها لترتيبها بالتسلسل المثالي.',
  'obTimeTitle': 'حدّد مدة كل مقطع',
  'obTimeBody': 'حدّد مدة الفيديو كاملًا، أو انقر أي مقطع لتمنحه مدته الخاصة.',
  'obExportTitle': 'أضف الصوت وصدّر',
  'obExportBody':
      'أضف مقطعًا صوتيًا اختياريًا، واختر تنسيقًا، وصدّر ملف MP4 جاهزًا للمشاركة.',

  'pvSaveShare': 'حفظ ومشاركة',
  'pvSaveRoll': 'حفظ في الصور',
  'pvSaved': 'حُفظ في مكتبة صورك.',
  'pvSaving': 'جارٍ الحفظ…',
  'pvPreparing': 'جارٍ التحضير…',
  'pvNeedPhotoAccess': 'اسمح بالوصول إلى الصور لحفظ الفيديو.',
  'pvSaveFailed': 'تعذّر حفظ الفيديو. حاول مرة أخرى.',
  'pvGone': 'هذا الفيديو لم يعد متاحًا. أعد التصدير.',
  'pvLoadToPreview': 'حمّل فيديو لمعاينته هنا',
  'pvUploadToPreview': 'ارفع فيديو لمعاينته هنا',

  'back': 'رجوع',
  'toggleSidebar': 'إظهار أو إخفاء الشريط الجانبي',
  'expandSidebar': 'توسيع الشريط الجانبي',
  'collapseSidebar': 'طي الشريط الجانبي',

  'fxNone': 'بدون',
  'fxGlow': 'توهّج',
  'fxPanZoom': 'تحريك وتقريب',
  'fxFloat': 'تعويم',
  'fxShake': 'اهتزاز',
  'trFade': 'تلاشٍ',
  'trSwipe': 'تمرير',
  'trZoom': 'تقريب',
  'trSlideUp': 'انزلاق للأعلى',
  'trSlideDown': 'انزلاق للأسفل',
  'trGlitch': 'تشويش',
  'trFlash': 'ومضة',
  'trPulse': 'نبض',
  'vpReels': 'ريلز / شورتس / تيك توك',
  'vpReelsShort': 'ريلز',
  'vpSquarePost': 'منشور مربّع',
  'vpPortraitPost': 'منشور طولي',
  'vpYoutube': 'يوتيوب أفقي',
  'vpOriginalSize': 'الحجم الأصلي',
  'eqSmallestFile': 'أصغر ملف',
  'eqRecommended': 'موصى به',
  'eqSharper': 'أوضح',
  'eqLargestFile': 'أكبر ملف',
  'cmpHigh': 'جودة عالية',
  'cmpHighNote': 'فقدان شبه غير مرئي',
  'cmpBalanced': 'متوازن',
  'cmpBalancedNote': 'أفضل موازنة بين الحجم والجودة',
  'cmpSmall': 'صغير',
  'cmpSmallNote': 'مناسب للمشاركة',
  'cmpTiny': 'صغير جدًا',
  'cmpTinyNote': 'الأصغر — جودة أقل',
  'colBw': 'أبيض وأسود',

  'exNothingToExport': 'لا يوجد ما يمكن تصديره.',
  'exFailed': 'فشل',
  'exportCancelled': 'تم إلغاء التصدير',
  'toolUploadVideo': 'رفع فيديو',
  'toolOutputApprox': 'الناتج ≈',
  'audMuted': 'صامت',
  'audDropped': 'محذوف',
  'audKept': 'محتفظ به',
  'audNewAudio': 'صوت جديد',
  'audRemoveNewAudio': 'إزالة الصوت الجديد',
  'audReplacedByNew': 'مُستبدل بالصوت الجديد',
  'cmpPreviewCaption': 'نفس الإطار بحجم أصغر — تقل الجودة كلما زاد المستوى',
  'cmpExporting': 'جارٍ الضغط…',
  'cmpExportCta': 'ضغط وتصدير',
  'spPreviewCaption': 'كيف سيبدو الفيديو بعد التصدير',
  'spUploadToPreview': 'ارفع فيديو لمعاينة التسريع هنا',
  'spMuteNote': 'تصدير الفيديو المسرّع بدون صوت',
  'spExportCta': 'تسريع وتصدير',
  'spAtSpeed': 'بسرعة',
  'slPreviewCaption': 'كيف ستبدو النسخة بعد القص',
  'slUploadToPreview': 'ارفع فيديو يحتوي على كلام لمعاينته هنا',
  'slSourceHint': 'MP4 / MOV يحتوي على كلام',
  'slGentle': 'لطيف',
  'slAggressive': 'قوي',
  'slGentleNote': 'لطيف — يُقص الصمت الواضح فقط',
  'slAggressiveNote': 'قوي — يقص الوقفات الهادئة أيضًا',
  'slMuteNote': 'تصدير الفيديو المقصوص بدون صوت',
  'slExporting': 'جارٍ إزالة الصمت…',
  'slExportCta': 'إزالة الصمت وتصدير',

  'edUpload': 'رفع',
  'edAudio': 'الصوت',
  'edExport': 'تصدير',
  'colCustomApplied': 'تم تطبيق تدرّج مخصّص',
  'colGradeFinal': 'تدرّج ألوان الفيديو النهائي',
  'startOverTabWarning':
      'سيؤدي هذا إلى مسح الوسائط والإعدادات في هذا القسم. لا يمكن التراجع.',

  'cvNothingConverted': 'لم يتم تحويل أي ملف.',
  'cvConvertedCount': 'تم تحويل',
  'cvFailedCount': 'فشل',
  'cvAddMoreImages': 'إضافة المزيد من الصور',
  'cvSelectImages': 'اختر الصور',
  'cvDefaultLocation': 'الموقع الافتراضي',
  'cvSavedToPhotos': 'محفوظ في الصور',
  'cvUseDefaultLocation': 'استخدام الموقع الافتراضي',
  'cvConvertTo2': 'تحويل',
  'cvTo': 'إلى',
  'htmlConvertCta': 'التحويل إلى MP4',
  'htmlVideoSaved': 'تم حفظ الفيديو.',
  'htmlSavedToRoll': 'تم الحفظ في ألبوم الكاميرا.',
  'htmlPhotosDenied': 'تم رفض إذن الصور.',
  'htmlFileMissing': 'ملف الفيديو غير موجود.',
  'htmlSaveFailed': 'تعذّر حفظ الفيديو.',
  'htmlOutputSize': 'مقاس الإخراج',
  'htmlQuality': 'الجودة',

  'galDownload': 'تنزيل',
  'galSave': 'حفظ',
  'galSavedToRoll': 'تم الحفظ في ألبوم الكاميرا.',
  'galVideoGone': 'هذا الفيديو لم يعد متاحًا.',
  'galDeleteSelected': 'حذف المحدد',
  'galPickToPlay': 'اختر ملفًا لتشغيله هنا',
  'galDeleteOneBody':
      'سيؤدي هذا إلى إزالة الفيديو من مكتبة Stillora وحذف الملف من هذا الجهاز.',
  'galSaveToRoll': 'الحفظ في ألبوم الكاميرا',
  'openSettings': 'الإعدادات',
  'txtDragHint': 'اسحب الطبقة لتحديد مكانها — هذا ما سيتم تصديره',
  'txtLoadVideoFirst': 'حمّل فيديو لإضافة نص عليه',
  'txtNeedVideoAndLayer': 'أضف فيديو وطبقة نص واحدة على الأقل أولًا.',
  'txtEmptyText': 'نص فارغ',
  'txtMoveUp': 'تحريك لأعلى',
  'txtMoveDown': 'تحريك لأسفل',
  'txtDuplicate': 'تكرار',
  'txtRemove': 'إزالة',
  'txtWeight': 'سماكة الخط',
  'txtAlignment': 'المحاذاة',
  'txtTextColour': 'لون النص',
  'txtBackground': 'الخلفية',
  'txtOutlineColour': 'لون الحدود',
  'txtRegular': 'عادي',
  'txtMedium': 'متوسط',
  'txtYourTitle': 'عنوانك',
  'txtYourSubtitle': 'العنوان الفرعي هنا',
  'txtTapToLearn': 'اضغط لمعرفة المزيد',
  'txtYourText': 'نصّك',
  'txtSubtitleStyle': 'ترجمة',
  'txtCaptionStyle': 'تعليق',
  'fontDefault': 'الافتراضي',

  'txtBold': 'عريض',
  'txtBlack': 'أسود عريض',

  'galSelectAll': 'الكل',
  'galSelectNone': 'لا شيء',
  'galLoadMoreCount': 'تحميل المزيد',
  'galDeleteCountTitle': 'حذف {n} فيديو؟',
  'galDeleteOneTitle': 'حذف فيديو واحد؟',
  'txtExportFailed': 'فشل التصدير',
  'txtNoLayersYet':
      'لا يوجد نص بعد. اضغط «إضافة نص» (أو اختر نمطًا) لإضافة طبقة على المقطع.',

  'edAddSoundtrack': 'إضافة موسيقى',
  'edSoundtrackOrNarration': 'موسيقى أو تعليق صوتي',
  'edTapToChange': 'اضغط للتغيير',
  'edSelectedTrack': 'المقطع المختار',
  'edRecordOrUpload': 'سجّل صوتك أو ارفع ملفًا صوتيًا ليُشغَّل مع الفيديو.',
  'edOptionalAudio': 'صوت اختياري',
  'edAudioAttached': 'تم إرفاق صوت',
  'edKeepsOwnSoundMany': 'تحتفظ مقاطعك بصوتها الأصلي. أضف صوتًا ليُشغَّل معها.',
  'edKeepsOwnSoundOne': 'يحتفظ الفيديو بصوته الأصلي. أضف صوتًا ليُشغَّل معه.',
  'edUseAudioLength': 'استخدام طول الصوت',
  'rlOutput': 'الناتج',
  'rlMatchesAudio': 'مطابق للصوت',
  'rlMatchesVideo': 'مطابق لفيديو التطبيق',
  'rlMeasuring': 'جارٍ قياس المدة…',
  'rlAudioAdded': 'تمت إضافة الصوت — يحدد مدة الريل',
  'rlAddAudioOptional': 'إضافة صوت (اختياري)',
  'rlAddMedia': 'إضافة فيديو أو صورة',
  'rlUploadAppVideo': 'رفع فيديو التطبيق',
  'rlSimpleReel': 'أنشئ ريلًا بسيطًا من وسائطك.',
  'rlMockupHint': 'يوضع تسجيل الشاشة داخل الجهاز ثلاثي الأبعاد المختار.',
  'loopFormatsFooter': 'ريلز · تيك توك · ستوريز · يوتيوب',

  'proGate720p': 'التصدير بجودة أعلى من 720p متاح في Stillora Pro.',
  'proGateAdvanced': 'عناصر التحكم المتقدمة متاحة في Stillora Pro.',
  'proGateBatch': 'المعالجة الجماعية متاحة في Stillora Pro.',
  'proGatePresets': 'الإعدادات المسبقة المميزة متاحة في Stillora Pro.',
  'proGateAds': 'تخلّص من المحتوى المموّل نهائيًا مع Stillora Pro.',
  'proFeatureLabel': 'ميزة Stillora Pro',
  'authFailed': 'فشل تسجيل الدخول. حاول مرة أخرى.',
  'authSigningIn': 'جارٍ تسجيل الدخول…',
  'authContinueApple': 'المتابعة باستخدام Apple',
  'authContinueGoogle': 'المتابعة باستخدام Google',
  'authUnlockNarration': 'فتح التعليق الصوتي',
  'authUnlockNarrationBody':
      'سجّل الدخول لتسجيل صوتك وإضافة تعليق شخصي إلى مقاطعك.',
  'authNotNow': 'ليس الآن',
  'authNarrationUnlocked': 'تم فتح التعليق الصوتي',
  'authNarrationUnlockedBody':
      'يمكنك الآن تسجيل صوتك واستخدامه في الفيديو التالي.',
  'authStartRecording': 'ابدأ التسجيل',
  'exMediaFailed': 'تعذّر تصدير الوسائط المختارة.',
  'exPreparingBody': 'تجهيز الوسائط وإنشاء الفيديو ودمج الصوت والحفظ محليًا.',
  'exBackToEditor': 'العودة إلى المحرّر',
  'exNotReady': 'التصدير غير جاهز بعد',
  'exGeneratingVideo': 'جارٍ إنشاء الفيديو…',
  'edStep3': 'الخطوة ٣',

  'proGateOnboarding':
      'كل أداة رأيتها للتو مجانية. يضيف Pro تصديرًا بدقة 4K وعناصر تحكم متقدمة وبدون إعلانات.',
  'proGateReminder':
      'ما زلت على النسخة المجانية؟ يضيف Pro تصديرًا بدقة 4K وعناصر تحكم متقدمة وبدون إعلانات — دفعة واحدة بلا اشتراك.',

  'authLoginPitch':
      'سجّل الدخول لفتح التعليق الصوتي. تظل مقاطع الفيديو الأساسية مجانية بدون حساب.',
  'authTerms': 'الشروط',
  'authPrivacy': 'الخصوصية',
  'edMediaStaysLocal': 'تبقى وسائطك على جهازك وتُستخدم فقط لإنشاء الفيديو.',
  'edRecordingHint':
      'اضغط الزر وابدأ التحدث. يمكنك الإيقاف المؤقت أو إعادة التسجيل أو الاحتفاظ بالتسجيل الذي يعجبك.',
  'edPaused': 'متوقف مؤقتًا',
  'edRecording': 'جارٍ التسجيل…',
  'edResume': 'متابعة',
  'edPause': 'إيقاف مؤقت',
  'edRecordingFailed': 'تعذّر بدء التسجيل',
  'edVideoClip': 'فيديو',
  'edPhotoClip': 'صورة',
  'edClipDuration': 'المدة',
  'edUnmute': 'إلغاء الكتم',
  'edMute': 'كتم',
  'edVolumeLabel': 'مستوى الصوت',
  'edReadyToExport': 'جاهز للتصدير',
  'edSetUpExport': 'إعداد التصدير',
  'edReviewBeforeConvert': 'راجع المعاينة قبل التحويل.',
  'edChooseMediaToUnlock': 'اختر وسائط لتفعيل التحويل.',
  'edNoneSelected': 'لم يتم اختيار شيء',
  'edSignedIn': 'مسجّل الدخول',
  'edGuest': 'زائر',
  'edMediaUnreadable':
      'تعذّر على Stillora قراءة الوسائط المختارة. الرجاء اختيار الملف مرة أخرى.',
  'edExportFirstToShare': 'صدّر أولًا للمشاركة',
  'rlNeedAppVideo': 'أضف فيديو التطبيق قبل التصدير.',
  'rlReplaceAppVideo': 'استبدال فيديو التطبيق',
  'rlReplaceMedia': 'استبدال الوسائط',
  'toastVideoReady': 'فيديوك جاهز ✓',
  'toastConversionFailed': 'فشل التحويل. حاول مرة أخرى.',
  'toastExportComplete': 'اكتمل التصدير ✓',
  'toastExportFailed': 'فشل التصدير. حاول مرة أخرى.',

  'splashTagline': 'حوّل صورك إلى فيديو في ثوانٍ.',
  'shareSavePdf': 'حفظ PDF',
  'shareSaveAudio': 'حفظ الصوت',
  'shareSaveVideo': 'حفظ الفيديو',

  'rlLayerReel': 'ريل بالطبقات',
  'rlLayers': 'طبقات',

  'durMinuteOne': 'دقيقة',
  'durMinutes': '{n} دقيقة',
  'pvRestart': 'إعادة التشغيل',
  'pvBack5': 'رجوع ٥ ثوانٍ',
  'pvForward5': 'تقديم ٥ ثوانٍ',
  'pvPlay': 'تشغيل',

  'htmlErrLocalRender': 'تعذّر عرض HTML على هذا الجهاز.',
  'htmlErrEmptyVideo': 'أعاد الخادم فيديو فارغًا.',
  'htmlErrTimeout': 'استغرق العرض وقتًا طويلًا. جرّب مدة أقصر أو معدل إطارات أقل.',
  'htmlErrGateway': 'استغرق الخادم وقتًا طويلًا لعرض هذه الصفحة. جرّب مدة أقصر أو معدل إطارات أقل أو مقاسًا أصغر أو صفحة أبسط.',
  'htmlErrStatus': 'تعذّر على الخادم عرض هذه الصفحة. حاول مرة أخرى.',
  'htmlErrUnreachable': 'تعذّر الوصول إلى الخادم. تحقّق من اتصالك وحاول مرة أخرى.',
  'htmlErrGeneric': 'تعذّر تحويل HTML. تحقّق من اتصالك وحاول مرة أخرى.',

  'authGoogleCancelled': 'تم إلغاء تسجيل الدخول عبر Google.',
  'authGoogleFailed': 'فشل تسجيل الدخول عبر Google.',
  'authGoogleRetry': 'فشل تسجيل الدخول عبر Google. حاول مرة أخرى.',
  'authGoogleMisconfigured': 'تسجيل الدخول عبر Google غير مُهيّأ بشكل صحيح لهذا التطبيق.',
  'authVerifyFailedGoogle': 'تعذّر على Stillora التحقق من حساب Google الخاص بك.',
  'authVerifyFailedApple': 'تعذّر على Stillora التحقق من حساب Apple الخاص بك.',
  'authAppleUnsupported': 'تسجيل الدخول عبر Apple غير مدعوم على هذه المنصة بعد.',
  'authAppleNeedsIos13': 'يتطلب تسجيل الدخول عبر Apple نظام iOS 13 أو أحدث.',
  'authAppleFailed': 'فشل تسجيل الدخول عبر Apple.',
  'authAppleRetry': 'فشل تسجيل الدخول عبر Apple. حاول مرة أخرى.',
  'authAppleCancelled': 'تم إلغاء تسجيل الدخول عبر Apple.',
  'authAppleUnavailable': 'تسجيل الدخول عبر Apple غير متاح حاليًا. حاول مرة أخرى.',
  'authAppleConnection': 'فشل تسجيل الدخول عبر Apple. تحقّق من اتصالك وحاول مرة أخرى.',
  // Store Screenshots
  'storeShots': 'لقطات المتاجر',
  'storeShotsSubtitle': 'مقاسات App Store وGoogle Play في ملف مضغوط واحد',
  'ssEyebrow': 'تصدير للمتاجر',
  'ssHeading': 'لقطات App Store وGoogle Play',
  'ssIntro':
      'أضف لقطات تطبيقك مرة واحدة، واختر المقاسات التي يطلبها كل متجر، '
      'ثم صدّر ملفًا مضغوطًا واحدًا يضم كل المقاسات في مجلدات منفصلة.',
  'ssSourceImages': 'الصور المصدر',
  'ssAddImages': 'أضف لقطات',
  'ssAddMore': 'أضف المزيد',
  'ssClear': 'مسح',
  'ssEmpty': 'أضف لقطات لعرضها هنا',
  'ssDropHint': 'أضف شاشات تطبيقك',
  'ssSizes': 'المقاسات',
  'ssRequiredOnly': 'المطلوبة فقط',
  'ssRequired': 'مطلوب',
  'ssPickSizes': 'اختر مقاسًا واحدًا على الأقل',
  'ssLook': 'طريقة ملاءمة الصور',
  'ssFit': 'احتواء',
  'ssFill': 'ملء',
  'ssBackground': 'الخلفية',
  'ssBlack': 'أسود',
  'ssWhite': 'أبيض',
  'ssMidnight': 'أزرق داكن',
  'ssFormat': 'الصيغة',
  'ssOrientation': 'الاتجاه',
  'ssPortrait': 'طولي',
  'ssLandscape': 'عرضي',
  'ssNoAlphaNote': 'يرفض المتجران الشفافية، لذا تُدمج كل صورة فوق لون الخلفية.',
  'ssZipLayout': 'يُضغط بترتيب: المتجر / المقاس / 01-الاسم',
  'ssExport': 'تصدير ملف مضغوط',
  'ssExporting': 'جارٍ التحويل...',
  'ssNothing': 'لم يتم إنشاء أي ملف.',
  'ssAndroidPhone': 'هاتف أندرويد',
  'ssAndroidTablet': 'جهاز أندرويد اللوحي',
  'ssPreviewCaption': 'تُنشأ كل صورة بكل المقاسات المحددة',
  'ssClearWarning': 'سيؤدي هذا إلى حذف كل الصور وإعادة ضبط المقاسات.',
  'ssSaveZip': 'حفظ الملف المضغوط',
  'ssSavedZip': 'تم حفظ الملف المضغوط',
  'ssSaveFailed': 'تعذّر حفظ الملف المضغوط.',
  'ssGone': 'الملف المضغوط لم يعد متاحًا.',
  'ssOutputCount': '{files} ملفًا \u00b7 {sizes} مقاسًا',
  'ssImageCount': '{count} صورة',
  'ssProgress': 'جارٍ التحويل {done} / {total}',
};

const _fr = <String, String>{
  'create': 'Créer',
  'library': 'Bibliothèque',
  'html': 'HTML',
  'settings': 'Infos',
  'loopImages': 'Boucle d’images',
  'removeSilence': 'Supprimer les silences',
  'watermark': 'Filigrane',
  'speed': 'Vitesse',
  'convert': 'Reformater l’image',
  'text': 'Texte',
  'compress': 'Compresser',
  'pdfConverter': 'Convertisseur PDF',
  'stilloraPro': 'Stillora Pro',

  'createSubtitle': 'Transformez vos images en vidéo, sur cet appareil',
  'librarySubtitle': 'Tous les rendus que vous avez créés',
  'htmlSubtitle': 'Capturez n’importe quelle page web en vidéo',
  'settingsSubtitle': 'Apparence, langue et compte',
  'loopImagesSubtitle': 'Boucles et diaporamas par lots',
  'removeSilenceSubtitle': 'Coupez automatiquement les silences d’une vidéo',
  'watermarkSubtitle': 'Ajoutez un logo ou un calque sur une vidéo',
  'speedSubtitle': 'Accélérez une vidéo de 1x à 4x, coupez ou ajoutez du son',
  'convertSubtitle': 'Convertissez HEIC et autres en JPEG/PNG par lots',
  'textSubtitle': 'Ajoutez des sous-titres et titres animés à une vidéo',
  'compressSubtitle': 'Réduisez une vidéo en un MP4 plus léger',
  'pdfConverterSubtitle': 'Réunissez images et PDF en un seul PDF',
  'stilloraProSubtitle': 'Payez une fois, débloquez toute la boîte à outils',

  'groupCreate': 'Créer',
  'groupVideoTools': 'Outils vidéo',
  'groupDocumentTools': 'Outils documents',
  'groupYourContent': 'Vos contenus',
  'groupAccountApp': 'Compte / Application',

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
  'clearTempFilesSubtitle': 'Le nettoyage du moteur vidéo s’exécutera ici.',
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

  'pdfHeading': 'Images et PDF → un seul PDF',
  'pdfIntro':
      'Ajoutez photos, scans et PDF existants, ordonnez les pages, redressez '
      'celles qui penchent, puis exportez l\'ensemble en un seul fichier.',
  'pdfReorderHint':
      'Faites glisser la poignée pour réordonner — page 1 en haut. Tout reste '
      'sur cet appareil.',
  'pdfAddFiles': 'Ajouter des images ou des PDF',
  'pdfAddFilesHint': 'JPG · PNG · WebP · HEIC · PDF',
  'pdfNoPages': 'Aucune page pour le moment',
  'pdfExport': 'Exporter le PDF',
  'pdfBuilding': 'Création du PDF…',
  'pdfSaved': 'PDF enregistré.',
  'pdfSaveFailed': 'Impossible d\'enregistrer le PDF. Réessayez.',
  'pdfGone': 'Le PDF exporté n\'est plus disponible.',
  'pdfNeedsFileAccess':
      'Autorisez l\'accès aux fichiers pour enregistrer le PDF.',
  'pdfMoveUp': 'Monter',
  'pdfMoveDown': 'Descendre',
  'pdfRotateLeft': 'Pivoter à gauche',
  'pdfRotateRight': 'Pivoter à droite',
  'pdfRemovePage': 'Supprimer la page',
  'pdfFromImages': 'depuis des images',
  'pdfFromPdfs': 'depuis des PDF',
  'pdfMatchImage': 'Adapter à l\'image',
  'pdfMatchImageHint': 'Chaque page prend la forme de son image',
  'pdfPageMany': '{n} pages',
  'pdfExportOne': 'Exporter {n} page en PDF',
  'pdfExportMany': 'Exporter {n} pages en PDF',

  'loopHeading': 'Transformer des images en vidéos',
  'loopIntro':
      'Ajoutez des images, choisissez une taille et une durée. Chaque image '
      'devient son propre MP4 de cette durée — elles ne sont pas fusionnées.',
  'loopBatchRender': 'Rendu par lot',
  'loopAddImages': 'Ajouter des images',
  'loopAddMore': 'Ajouter d\'autres',
  'loopClear': 'Effacer',
  'loopClearWarning':
      'Ceci efface les images en file d\'attente ainsi que les choix de '
      'taille, de durée et de qualité. Action irréversible.',
  'loopDropHint': 'Déposez des images ou cliquez pour ajouter',
  'loopDropSubtitle': 'JPG · PNG · WebP — chacune devient son propre MP4',
  'loopOutputSize': 'Taille de sortie',
  'loopImageMode': 'Mode image',
  'loopDuration': 'Durée',
  'loopQuality': 'Qualité',
  'loopEachOutput': 'Chaque sortie',
  'loopEachClip': 'par clip',
  'loopTypeDuration': 'saisissez une durée',
  'loopConverting': 'Conversion…',
  'loopRendering': 'Rendu…',
  'loopFit': 'Ajuster',
  'loopFill': 'Remplir',
  'loopStatusReady': 'Prêt',
  'loopStatusRendering': 'Rendu',
  'loopStatusDone': 'Terminé',
  'loopStatusFailed': 'Échec',
  'loopShareVideo': 'Partager la vidéo',
  'loopConvertOne': 'Convertir {n} image',
  'loopConvertTwo': 'Convertir {n} images',
  'loopConvertFew': 'Convertir {n} images',
  'loopConvertMany': 'Convertir {n} images',
  'loopSavedCount': '{done} sur {total} enregistrées dans la Bibliothèque',
  'loopImageCount': '{n}/{max} images',

  'pdfPageOne': '{n} page',
  'pdfPageTwo': '{n} pages',
  'pdfPageFew': '{n} pages',
  'pdfPages': 'Pages',
  'pdfMixHint':
      'Images et PDF se mélangent librement — un PDF ajoute une page par page.',
  'pdfRotateAll': 'Tout pivoter',
  'pdfPageSize': 'Taille de page',
  'pdfMargin': 'Marge',
  'pdfImportQuality': 'Qualité d\'import PDF',
  'pdfImportQualityHint':
      'Les pages PDF importées sont redessinées en images pour pouvoir pivoter.',
  'pdfImportQualityNote': 'S\'applique aux PDF ajoutés à partir de maintenant.',
  'pdfFileName': 'Nom du fichier',
  'pdfMarginNone': 'Aucune',
  'pdfMarginSmall': 'Petite',
  'pdfMarginWide': 'Large',
  'startOver': 'Recommencer',
  'startOverConfirm': 'Recommencer ?',
  'livePreview': 'Aperçu en direct',

  'loopEach': 'chacun',
  'loopSize_vertical': 'Vertical',
  'loopSize_square': 'Carré',
  'loopSize_portrait': 'Portrait',
  'loopSize_landscape': 'Paysage',

  'pdfSheetA4Hint': '21 × 29,7 cm · les pages pivotent pour les images larges',
  'pdfSheetLetterHint':
      '8,5 × 11 po · les pages pivotent pour les images larges',

  'pdfPortrait': 'portrait',
  'pdfLandscape': 'paysage',

  'htmlHeading': 'Du HTML à une vidéo prête à publier',
  'htmlIntro':
      'Collez du balisage, déposez un fichier .html ou saisissez une URL — '
      'choisissez taille et durée, exportez un MP4 net en quelques secondes.',
  'htmlNewRender': 'Nouveau rendu',
  'htmlSource': 'Source',
  'htmlPaste': 'Coller',
  'htmlFile': 'Fichier',
  'htmlUrl': 'URL',
  'htmlDropFile': 'Déposez un fichier .html',
  'htmlDropFileHint': 'ou cliquez pour parcourir · .html .htm',
  'htmlLength': 'Longueur',
  'htmlDuration': 'Durée',
  'htmlFrameRate': 'Fréquence d\'images',
  'htmlAudio': 'Audio',
  'htmlAudioHint':
      'Voix off ou musique mixée sur la vidéo · ajustée à sa durée',
  'htmlRemoveAudio': 'Supprimer l\'audio',
  'htmlRendering': 'Rendu…',
  'htmlClearWarning':
      'Ceci efface le HTML/l\'URL, l\'audio, les réglages de sortie et le '
      'dernier rendu. Action irréversible.',
  'htmlNeedUrl': 'Saisissez une URL à rendre.',
  'htmlNeedMarkup': 'Collez d\'abord du HTML.',
  'htmlNeedFile': 'Choisissez d\'abord un fichier .html.',
  'htmlCancelled': 'Conversion annulée',
  'htmlFailed': 'Une erreur est survenue. Réessayez.',

  'wmIntro':
      'Ajoutez un logo, une image ou une vidéo par-dessus votre clip. Faites '
      'glisser pour le placer, redimensionnez-le et définissez quand il '
      'apparaît. Votre vidéo garde son propre son.',
  'wmChooseVideo': 'Choisir une vidéo à filigraner',
  'wmThenDrop': 'Déposez ensuite votre logo, image ou une autre vidéo dessus.',
  'wmAddOverlay': 'Ajouter un logo, une image ou une vidéo',
  'wmOverlays': 'Calques',
  'wmRemove': 'Supprimer',
  'wmNoOverlays':
      'Aucun calque. Ajoutez un logo, une image ou une vidéo à placer sur le clip.',
  'wmDragHint':
      'Faites glisser un calque pour le placer — c\'est ce qui sera exporté',
  'wmLoadVideoFirst': 'Chargez une vidéo pour y empiler des calques',
  'wmNeedVideoAndOverlay': 'Ajoutez d\'abord une vidéo et au moins un calque.',
  'wmExportCancelled': 'Export annulé',
  'wmPlatformNote':
      'L\'export de filigrane fonctionne aujourd\'hui sur macOS et '
      'Windows/Linux. L\'export iPhone et Android arrive bientôt.',

  'exportResolution': 'Résolution',
  'exportOriginal': 'Originale',
  'exportReplace': 'Remplacer',
  'exportReadingVideo': 'Lecture de la vidéo…',
  'exportMp4': 'Exporter en MP4',
  'exportExporting': 'Export…',
  'exportCancel': 'Annuler l\'export',
  'exportCancelling': 'Annulation…',
  'exportBaseVideo': 'Vidéo de base',
  'exportOutput': 'Sortie',
  'savedToLibrary': 'Enregistré dans la Bibliothèque',

  'proTagline': 'Libérez toute la puissance de votre boîte à outils privée.',
  'proPayOnce': 'Payez une fois. Utilisez pour toujours.',
  'proPaidOnce': 'Payé une fois. À vous pour toujours, sur cet appareil.',
  'proActive': 'ACTIF',
  'proUnlockedBody':
      'Pro à vie est débloqué. Tous les niveaux d\'export, tous les contrôles '
      'avancés, sans publicité — et rien à renouveler.',
  'proRestore': 'Restaurer l\'achat',
  'proOneTime': 'Achat unique. Sans abonnement.',
  'proContinueFree': 'Continuer en version gratuite',
  'proFreeStaysFree':
      'Rien n\'est verrouillé. Tous les outils restent utilisables en version '
      'gratuite, sans filigrane et avec des exports jusqu\'à 720p.',
  'yourPlan': 'Votre formule',
  'planFree': 'Gratuit',
  'planPro': 'Pro — à vie',
  'planFreeBody': 'Vous êtes sur la formule gratuite. Elle comprend :',
  'planProBody': 'Pro à vie est actif sur cet appareil.',
  'planIncludesTools': 'Tous les outils, sans limite',
  'planIncludesQuality': 'Exports jusqu\'à 720p',
  'planIncludesNoWatermark': 'Aucun filigrane Stillora',
  'planIncludesLocal': 'Les fichiers restent sur cet appareil',
  'planIncludesAds': 'Contient du contenu sponsorisé',
  'planSeePro': 'Voir ce qu\'apporte Pro',
  'proContacting': 'Connexion à la boutique…',
  'proUnlockCta': 'Débloquer Pro à vie',
  'proPrivacyBody':
      'Le gratuit comme Pro traitent tout localement. Pro vous offre une '
      'meilleure qualité, plus de contrôle et des flux plus rapides — jamais '
      'l\'accès à vos propres fichiers, ni votre confidentialité.',
  'proCompareTitle': 'Gratuit vs Pro à vie',
  'proCompareFeature': 'Fonctionnalité',
  'proCompareFree': 'Gratuit',
  'proComparePro': 'Pro à vie',
  'proCompareFooter':
      'Pro, c\'est plus de qualité, de contrôle, de rapidité et aucune '
      'publicité — pas l\'accès de base à vos propres fichiers.',

  'toolSource': 'Source',
  'toolOutput': 'Sortie',
  'toolQuality': 'Qualité',
  'toolAudio': 'Audio',
  'toolSpeed': 'Vitesse',
  'toolSizeApprox': 'Taille ≈',
  'silenceIntro':
      'Importez une vidéo et Stillora supprime les silences où personne ne parle.',
  'silenceSensitivity': 'Sensibilité',
  'silenceRemoveAudio': 'Supprimer l\'audio d\'origine',
  'silenceNewAudioNote':
      'Le nouvel audio joue à vitesse normale ; la vidéo boucle pour s\'y ajuster.',
  'speedIntro':
      'Importez une vidéo et accélérez-la. Ajoutez une bande-son et la vidéo '
      'accélérée boucle pour s\'y ajuster.',
  'speedMute': 'Muet (supprimer l\'audio d\'origine)',
  'speedNewAudioNote':
      'Le nouvel audio joue à vitesse normale ; la vidéo accélérée boucle pour '
      's\'y ajuster.',
  'compressIntro':
      'Importez une vidéo et réduisez-la en un MP4 plus léger, à la même résolution.',
  'compressLevel': 'Compression',
  'compressMute': 'Muet (retirer l\'audio pour un fichier plus léger)',
  'compressBefore': 'Avant',
  'compressAfter': 'Après ≈',
  'compressSaving': 'Gain',

  'previewComplete': 'Export terminé',
  'previewReady': 'Votre vidéo est prête à être partagée.',
  'previewShareTo': 'Partager vers',
  'previewMore': 'Plus',
  'previewAnother': 'Créer une autre vidéo',
  'previewNoVideo': 'Aucune vidéo',
  'previewCreateVideo': 'Créer une vidéo',

  'sponsored': 'Sponsorisé',
  'reset': 'Réinitialiser',

  'edUploadMedia': 'Importer des médias',
  'edUploadIntro':
      'Ajoutez des photos, des images ou un court clip pour commencer.',
  'edTapToUpload': 'Appuyez pour importer\nou glissez-déposez',
  'edPhotosOrClips': 'Photos, images ou courts clips',
  'edFileTypes': 'JPG, PNG, HEIC, MOV, MP4',
  'edContinue': 'Continuer',
  'edEdit': 'Modifier',
  'edSelectedMedia': 'Médias sélectionnés',
  'edSourceMedia': 'Médias source',
  'edChooseMedia': 'Choisir des photos ou vidéos',
  'edDragToReorder': 'Glissez pour réordonner après la sélection.',
  'edSelectThenReorder':
      'Sélectionnez photos et vidéos, puis glissez pour réordonner.',
  'edAddMore': 'Ajouter',
  'edReplace': 'Remplacer',
  'edChange': 'Changer',
  'edChoosePreset': 'Choisir un préréglage',
  'edChooseFormat': 'Choisir un format',
  'edPresets': 'Préréglages',
  'edResize': 'Redimensionner',
  'edEffect': 'Effet',
  'edTransition': 'Transition',
  'edStyleEffects': 'Style et effets',
  'edDuration': 'Durée',
  'edTotalDuration': 'Durée totale',
  'edSplitsEvenly':
      'Répartie également entre les clips. Touchez un clip ci-dessus pour sa propre durée.',
  'edLength': 'Longueur',
  'edClipLengthHint': 'Définissez la durée de ce clip dans la vidéo finale.',
  'edClipVolumeHint': 'Contrôle le son propre de ce clip à l\'export.',
  'edDone': 'Terminé',
  'edSoundtrack': 'Ajouter une bande-son (facultatif)',
  'edSoundscape': 'Ambiance sonore',
  'edSoundtrackIntro':
      'Enregistrez votre voix ou importez un fichier audio pour accompagner la vidéo.',
  'edRecordVoice': 'Enregistrer la voix',
  'edUploadAudio': 'Importer un audio',
  'edVolume': 'Volume',
  'edAudioSecured':
      'Votre audio est protégé et utilisé uniquement pour cette conversion.',
  'edMp4Preview': 'Aperçu MP4',
  'edPreviewMatches': 'L\'aperçu correspond à l\'image finale de votre vidéo.',
  'edUploadToBegin': 'Importez des médias pour commencer',
  'edCreateMp4': 'Créer un MP4',
  'edConvertToMp4': 'Convertir en MP4',
  'edExportMp4': 'Exporter en MP4',
  'edProjectSummary': 'Résumé du projet',
  'edEstSize': 'Taille est.',
  'edFileType': 'Type de fichier',
  'edPreview': 'Aperçu',
  'edPreset': 'Préréglage',
  'edAssets': 'Éléments',
  'edThreeSteps':
      'Transformez vos souvenirs en vidéos sociales en trois étapes simples.',
  'edDesktopStudio':
      'Studio bureau · Créez votre MP4 avec un accès complet aux fichiers.',
  'edClearWarning':
      'Ceci efface vos médias, l\'audio et les réglages. Action irréversible.',
  'edVoiceNarration': 'Narration vocale',
  'edRecordYourVoice': 'Enregistrez votre voix',
  'edRecordHint':
      'Appuyez et parlez. Vous pouvez mettre en pause, réenregistrer ou supprimer.',
  'edStartRecording': 'Démarrer l\'enregistrement',
  'edStop': 'Arrêter',
  'edReRecord': 'Réenregistrer',
  'edUseRecording': 'Utiliser cet enregistrement',
  'edYourNarration': 'Votre narration',
  'edRemoveAudio': 'Supprimer l\'audio',
  'edMicOff': 'L\'accès au microphone est désactivé',
  'edMicHint':
      'Stillora a besoin du microphone pour enregistrer votre narration.',
  'edOpenSettings': 'Ouvrir les Réglages',
  'edNarrationPrivacy':
      'Votre enregistrement reste sur votre appareil et sert uniquement à créer votre vidéo.',
  'edClearReel': 'Effacer le reel',
  'edReel3d': 'Reel vidéo 3D',
  'edFormatExport': 'Format et export',

  'galLocalLibrary': 'Bibliothèque locale',
  'galStoredHere':
      'Les exports sont stockés sur cet appareil. Rien ici ne dépend du cloud.',
  'galEmpty': 'Les vidéos créées sur cet appareil apparaîtront ici.',
  'galSelect': 'Sélectionner',
  'galSelected': 'sélectionné(s)',
  'galOpenFull': 'Plein écran',
  'galShare': 'Partager',
  'galSavedLocally': 'Enregistré localement',
  'galDeleteTitle': 'Supprimer la vidéo locale ?',
  'galDeleteBody':
      'Ceci retire la vidéo de votre bibliothèque Stillora et supprime le fichier local de cet appareil.',
  'galDeleteManyBody': 'Ceci les supprime définitivement de cet appareil.',
  'galLoadMore': 'Charger plus',
  'galVideo': 'Vidéo',

  'colTitle': 'Correction des couleurs',
  'colBrightness': 'Luminosité',
  'colContrast': 'Contraste',
  'colExposure': 'Exposition',
  'colSaturation': 'Saturation',
  'colSharpness': 'Netteté',
  'colTint': 'Teinte',
  'colVibrance': 'Vibrance',
  'colWarmth': 'Chaleur',
  'colLivePreview': 'Aperçu en direct — le rendu de la vidéo exportée',
  'colOriginal': 'Original',
  'colVivid': 'Éclatant',
  'colWarm': 'Chaud',
  'colCool': 'Froid',
  'colBright': 'Lumineux',
  'colVintage': 'Vintage',
  'colCinematic': 'Cinématique',

  'txtIntro':
      'Ajoutez du texte animé sur votre clip. Tapez-le, déplacez-le et définissez quand il apparaît.',
  'txtChooseVideo': 'Choisir une vidéo à sous-titrer',
  'txtThenAdd': 'Ajoutez ensuite du texte animé et placez-le.',
  'txtPlatformNote':
      'L\'export de texte fonctionne aujourd\'hui sur iPhone, macOS et Windows/Linux.',
  'txtAddText': 'Ajouter du texte',
  'txtLayers': 'Calques',
  'txtTimeline': 'Chronologie',
  'txtEditText': 'Modifier le texte',
  'txtText': 'Texte',
  'txtSize': 'Taille',
  'txtOpacity': 'Opacité',
  'txtOutline': 'Contour',
  'txtDropShadow': 'Ombre portée',
  'txtFadeIn': 'Fondu entrant',
  'txtFadeOut': 'Fondu sortant',
  'txtPickColour': 'Choisir une couleur',
  'txtUseColour': 'Utiliser la couleur',

  'cvIntro':
      'Choisissez des images dans n\'importe quel format (HEIC, WebP, TIFF, BMP…) et convertissez-les.',
  'cvConvertTo': 'Convertir en',
  'cvExportTo': 'Exporter vers',
  'cvEmpty': 'Sélectionnez des images pour les voir ici',
  'cvSelectedCount': 'sélectionné(s)',
  'exGenerating': 'Génération',
  'exExport': 'Export',

  'proHiRes': 'Exports en haute résolution',
  'proHiResBody': '1080p, 2K et 4K là où la plateforme le permet',
  'proAdvTools': 'Outils multimédias avancés',
  'proAdvToolsBody': 'Débit, seuils, vitesses personnalisées et taille cible',
  'proBatch': 'Traitement par lot',
  'proBatchBody': 'Passez un dossier entier dans un outil en une fois',
  'proPresets': 'Contrôles et préréglages premium',
  'proPresetsBody':
      'Préréglages enregistrés, transitions et effets supplémentaires',
  'proNoAds': 'Supprimer les publicités',
  'proNoAdsBody': 'Le contenu sponsorisé disparaît dès le déblocage',
  'proLocalBoth': 'Traitement local — gratuit et Pro',
  'proLocalBothBody':
      'Aucun envoi cloud requis, et aucun filigrane Stillora dans les deux cas',
  'proRowLocal': 'Traitement local',
  'proRowFilesStay': 'Fichiers conservés sur l\'appareil',
  'proRowBasicTools': 'Outils multimédias de base',
  'proRowNoWatermark': 'Aucun filigrane Stillora',
  'proRowExport': 'Export',
  'proRowAdvanced': 'Contrôles avancés',
  'proRowBatch': 'Traitement par lot',
  'proRowPresets': 'Préréglages premium',
  'proRowAds': 'Publicités / contenu sponsorisé',
  'proRowLifetime': 'Accès à vie',
  'proLimited': 'Limité',
  'proYes': 'Oui',
  'proNo': 'Non',
  'proFreeTier': 'Version gratuite',

  'obSkip': 'Passer',
  'obNext': 'Suivant',
  'obGetStarted': 'Commencer',
  'obUploadTitle': 'Importez vos médias',
  'obUploadBody':
      'Choisissez une ou plusieurs photos et vidéos. Glissez pour les ordonner.',
  'obTimeTitle': 'Minutez chaque clip',
  'obTimeBody':
      'Définissez la durée totale, ou touchez un clip pour lui donner la sienne.',
  'obExportTitle': 'Ajoutez le son et exportez',
  'obExportBody':
      'Ajoutez une bande-son facultative, choisissez un format et exportez un MP4 prêt à partager.',

  'pvSaveShare': 'Enregistrer et partager',
  'pvSaveRoll': 'Enregistrer dans Photos',
  'pvSaved': 'Enregistré dans votre photothèque.',
  'pvSaving': 'Enregistrement…',
  'pvPreparing': 'Préparation…',
  'pvNeedPhotoAccess':
      'Autorisez l\'accès aux photos pour enregistrer votre vidéo.',
  'pvSaveFailed': 'Impossible d\'enregistrer la vidéo. Réessayez.',
  'pvGone': 'Cette vidéo n\'est plus disponible. Exportez à nouveau.',
  'pvLoadToPreview': 'Chargez une vidéo pour l\'aperçu',
  'pvUploadToPreview': 'Importez une vidéo pour l\'aperçu',

  'back': 'Retour',
  'toggleSidebar': 'Afficher ou masquer la barre latérale',
  'expandSidebar': 'Développer la barre latérale',
  'collapseSidebar': 'Réduire la barre latérale',

  'fxNone': 'Aucun',
  'fxGlow': 'Lueur',
  'fxPanZoom': 'Panoramique et zoom',
  'fxFloat': 'Flottement',
  'fxShake': 'Secousse',
  'trFade': 'Fondu',
  'trSwipe': 'Balayage',
  'trZoom': 'Zoom',
  'trSlideUp': 'Glissement haut',
  'trSlideDown': 'Glissement bas',
  'trGlitch': 'Glitch',
  'trFlash': 'Flash',
  'trPulse': 'Pulsation',
  'vpReels': 'Reels / Shorts / TikTok',
  'vpReelsShort': 'Reels',
  'vpSquarePost': 'Publication carrée',
  'vpPortraitPost': 'Publication portrait',
  'vpYoutube': 'YouTube paysage',
  'vpOriginalSize': 'Taille d’origine',
  'eqSmallestFile': 'Fichier le plus léger',
  'eqRecommended': 'Recommandé',
  'eqSharper': 'Plus net',
  'eqLargestFile': 'Fichier le plus lourd',
  'cmpHigh': 'Haute qualité',
  'cmpHighNote': 'Perte à peine visible',
  'cmpBalanced': 'Équilibré',
  'cmpBalancedNote': 'Meilleur compromis taille/qualité',
  'cmpSmall': 'Petit',
  'cmpSmallNote': 'Parfait pour le partage',
  'cmpTiny': 'Minuscule',
  'cmpTinyNote': 'Le plus petit — qualité réduite',
  'colBw': 'N&B',

  'exNothingToExport': 'Rien à exporter.',
  'exFailed': 'Échec',
  'exportCancelled': 'Export annulé',
  'toolUploadVideo': 'Importer une vidéo',
  'toolOutputApprox': 'Sortie ≈',
  'audMuted': 'Muet',
  'audDropped': 'Supprimé',
  'audKept': 'Conservé',
  'audNewAudio': 'Nouvel audio',
  'audRemoveNewAudio': 'Supprimer le nouvel audio',
  'audReplacedByNew': 'Remplacé par votre nouvel audio',
  'cmpPreviewCaption':
      'Même image, fichier plus léger — la qualité baisse à mesure que le niveau monte',
  'cmpExporting': 'Compression…',
  'cmpExportCta': 'Compresser et exporter',
  'spPreviewCaption': 'L’aspect de la vidéo exportée',
  'spUploadToPreview':
      'Importez une vidéo pour prévisualiser l’accélération ici',
  'spMuteNote': 'Exporter la vidéo accélérée sans son',
  'spExportCta': 'Accélérer et exporter',
  'spAtSpeed': 'à',
  'slPreviewCaption': 'L’aspect du montage exporté',
  'slUploadToPreview': 'Importez une vidéo parlée pour la prévisualiser ici',
  'slSourceHint': 'MP4 / MOV avec parole',
  'slGentle': 'Doux',
  'slAggressive': 'Agressif',
  'slGentleNote': 'Doux — seuls les silences nets sont coupés',
  'slAggressiveNote': 'Agressif — coupe aussi les pauses discrètes',
  'slMuteNote': 'Exporter la vidéo découpée sans son',
  'slExporting': 'Suppression des silences…',
  'slExportCta': 'Supprimer les silences et exporter',

  'edUpload': 'Importer',
  'edAudio': 'Audio',
  'edExport': 'Exporter',
  'colCustomApplied': 'Étalonnage personnalisé appliqué',
  'colGradeFinal': 'Étalonner la vidéo finale',
  'startOverTabWarning':
      'Cela efface les médias et les réglages de cet onglet. Action irréversible.',

  'cvNothingConverted': 'Aucun fichier converti.',
  'cvConvertedCount': 'Converti',
  'cvFailedCount': 'échec',
  'cvAddMoreImages': 'Ajouter d’autres images',
  'cvSelectImages': 'Sélectionner des images',
  'cvDefaultLocation': 'Emplacement par défaut',
  'cvSavedToPhotos': 'Enregistré dans Photos',
  'cvUseDefaultLocation': 'Utiliser l’emplacement par défaut',
  'cvConvertTo2': 'Convertir',
  'cvTo': 'en',
  'htmlConvertCta': 'Convertir en MP4',
  'htmlVideoSaved': 'Vidéo enregistrée.',
  'htmlSavedToRoll': 'Enregistrée dans votre pellicule.',
  'htmlPhotosDenied': 'L’accès aux photos a été refusé.',
  'htmlFileMissing': 'Le fichier vidéo est introuvable.',
  'htmlSaveFailed': 'Impossible d’enregistrer la vidéo.',
  'htmlOutputSize': 'Taille de sortie',
  'htmlQuality': 'Qualité',

  'galDownload': 'Télécharger',
  'galSave': 'Enregistrer',
  'galSavedToRoll': 'Enregistrée dans votre pellicule.',
  'galVideoGone': 'Cette vidéo n’est plus disponible.',
  'galDeleteSelected': 'Supprimer la sélection',
  'galPickToPlay': 'Choisissez un rendu pour le lire ici',
  'galDeleteOneBody':
      'La vidéo est retirée de votre bibliothèque Stillora et le fichier local est supprimé de cet appareil.',
  'galSaveToRoll': 'Enregistrer dans la pellicule',
  'openSettings': 'Réglages',
  'txtDragHint':
      'Faites glisser un calque pour le placer — c’est ce qui sera exporté',
  'txtLoadVideoFirst': 'Chargez une vidéo pour y placer du texte',
  'txtNeedVideoAndLayer':
      'Ajoutez d’abord une vidéo et au moins un calque de texte.',
  'txtEmptyText': 'Texte vide',
  'txtMoveUp': 'Monter',
  'txtMoveDown': 'Descendre',
  'txtDuplicate': 'Dupliquer',
  'txtRemove': 'Supprimer',
  'txtWeight': 'Graisse',
  'txtAlignment': 'Alignement',
  'txtTextColour': 'Couleur du texte',
  'txtBackground': 'Arrière-plan',
  'txtOutlineColour': 'Couleur du contour',
  'txtRegular': 'Normal',
  'txtMedium': 'Moyen',
  'txtYourTitle': 'Votre titre',
  'txtYourSubtitle': 'Votre sous-titre ici',
  'txtTapToLearn': 'Touchez pour en savoir plus',
  'txtYourText': 'Votre texte',
  'txtSubtitleStyle': 'Sous-titre',
  'txtCaptionStyle': 'Légende',
  'fontDefault': 'Par défaut',

  'txtBold': 'Gras',
  'txtBlack': 'Extra-gras',

  'galSelectAll': 'Tout',
  'galSelectNone': 'Aucun',
  'galLoadMoreCount': 'Charger plus',
  'galDeleteCountTitle': 'Supprimer {n} vidéos ?',
  'galDeleteOneTitle': 'Supprimer 1 vidéo ?',
  'txtExportFailed': 'Échec de l’export',
  'txtNoLayersYet':
      'Aucun texte pour l’instant. Touchez « Ajouter du texte » (ou un préréglage) pour poser un calque sur le clip.',

  'edAddSoundtrack': 'Ajouter une bande-son',
  'edSoundtrackOrNarration': 'Bande-son ou narration',
  'edTapToChange': 'Touchez pour modifier',
  'edSelectedTrack': 'Piste sélectionnée',
  'edRecordOrUpload':
      'Enregistrez votre voix ou importez un fichier audio à jouer avec votre vidéo.',
  'edOptionalAudio': 'Audio facultatif',
  'edAudioAttached': 'Audio ajouté',
  'edKeepsOwnSoundMany':
      'Vos vidéos gardent leur son. Ajoutez un audio pour l’accompagner.',
  'edKeepsOwnSoundOne':
      'Votre vidéo garde son son. Ajoutez un audio pour l’accompagner.',
  'edUseAudioLength': 'Utiliser l’audio',
  'rlOutput': 'Sortie',
  'rlMatchesAudio': 'cale sur l’audio',
  'rlMatchesVideo': 'cale sur la vidéo',
  'rlMeasuring': 'Mesure de la durée…',
  'rlAudioAdded': 'Audio ajouté — définit la durée du reel',
  'rlAddAudioOptional': 'Ajouter un audio (facultatif)',
  'rlAddMedia': 'Ajouter une vidéo ou une image',
  'rlUploadAppVideo': 'Importer la vidéo de l’app',
  'rlSimpleReel': 'Créez un reel simple à partir de vos médias.',
  'rlMockupHint': 'Votre capture d’écran est placée dans l’appareil 3D choisi.',
  'loopFormatsFooter': 'Reels · TikTok · Stories · YouTube',

  'proGate720p': 'Les exports au-delà de 720p font partie de Stillora Pro.',
  'proGateAdvanced': 'Les réglages avancés font partie de Stillora Pro.',
  'proGateBatch': 'Le traitement par lot fait partie de Stillora Pro.',
  'proGatePresets': 'Les préréglages premium font partie de Stillora Pro.',
  'proGateAds':
      'Supprimez définitivement le contenu sponsorisé avec Stillora Pro.',
  'proFeatureLabel': 'Fonctionnalité Stillora Pro',
  'authFailed': 'Échec de la connexion. Veuillez réessayer.',
  'authSigningIn': 'Connexion…',
  'authContinueApple': 'Continuer avec Apple',
  'authContinueGoogle': 'Continuer avec Google',
  'authUnlockNarration': 'Débloquer la narration vocale',
  'authUnlockNarrationBody':
      'Connectez-vous pour enregistrer votre voix et ajouter une narration personnelle à vos vidéos.',
  'authNotNow': 'Plus tard',
  'authNarrationUnlocked': 'Narration vocale débloquée',
  'authNarrationUnlockedBody':
      'Vous pouvez maintenant enregistrer votre voix et l’utiliser dans votre prochaine vidéo.',
  'authStartRecording': 'Commencer l’enregistrement',
  'exMediaFailed': 'Impossible d’exporter les médias sélectionnés.',
  'exPreparingBody':
      'Préparation des médias, génération de la vidéo, fusion de l’audio et enregistrement local.',
  'exBackToEditor': 'Retour à l’éditeur',
  'exNotReady': 'Export pas encore prêt',
  'exGeneratingVideo': 'Génération de la vidéo…',
  'edStep3': 'Étape 3',

  'proGateOnboarding':
      'Tous les outils que vous venez de voir sont gratuits. Pro ajoute l’export 4K, les réglages avancés et zéro publicité.',
  'proGateReminder':
      'Toujours en version gratuite ? Pro ajoute l’export 4K, les réglages avancés et zéro publicité — un seul paiement, sans abonnement.',

  'authLoginPitch':
      'Connectez-vous pour débloquer la narration vocale. Les vidéos de base restent gratuites, sans compte.',
  'authTerms': 'Conditions',
  'authPrivacy': 'Confidentialité',
  'edMediaStaysLocal':
      'Vos médias restent sur votre appareil et servent uniquement à créer votre vidéo.',
  'edRecordingHint':
      'Touchez le bouton et parlez. Vous pouvez mettre en pause, réenregistrer ou garder la prise qui vous plaît.',
  'edPaused': 'En pause',
  'edRecording': 'Enregistrement…',
  'edResume': 'Reprendre',
  'edPause': 'Pause',
  'edRecordingFailed': 'Impossible de démarrer l’enregistrement',
  'edVideoClip': 'Vidéo',
  'edPhotoClip': 'Photo',
  'edClipDuration': 'durée',
  'edUnmute': 'Réactiver le son',
  'edMute': 'Couper le son',
  'edVolumeLabel': 'Volume',
  'edReadyToExport': 'Prêt à exporter',
  'edSetUpExport': 'Configurer l’export',
  'edReviewBeforeConvert': 'Vérifiez l’aperçu avant de convertir.',
  'edChooseMediaToUnlock': 'Choisissez des médias pour activer la conversion.',
  'edNoneSelected': 'Aucune sélection',
  'edSignedIn': 'Connecté',
  'edGuest': 'Invité',
  'edMediaUnreadable':
      'Stillora n’a pas pu lire les médias sélectionnés. Veuillez choisir le fichier à nouveau.',
  'edExportFirstToShare': 'Exportez d’abord pour partager',
  'rlNeedAppVideo': 'Ajoutez une vidéo de l’app avant d’exporter.',
  'rlReplaceAppVideo': 'Remplacer la vidéo de l’app',
  'rlReplaceMedia': 'Remplacer les médias',
  'toastVideoReady': 'Votre vidéo est prête ✓',
  'toastConversionFailed': 'Échec de la conversion. Veuillez réessayer.',
  'toastExportComplete': 'Export terminé ✓',
  'toastExportFailed': 'Échec de l’export. Veuillez réessayer.',

  'splashTagline': 'Transformez vos images en vidéos en quelques secondes.',
  'shareSavePdf': 'Enregistrer le PDF',
  'shareSaveAudio': 'Enregistrer l’audio',
  'shareSaveVideo': 'Enregistrer la vidéo',

  'rlLayerReel': 'Reel en calques',
  'rlLayers': 'Calques',

  'durMinuteOne': '1 min',
  'durMinutes': '{n} min',
  'pvRestart': 'Recommencer',
  'pvBack5': 'Reculer de 5 secondes',
  'pvForward5': 'Avancer de 5 secondes',
  'pvPlay': 'Lecture',

  'htmlErrLocalRender': 'Impossible de générer le HTML sur cet appareil.',
  'htmlErrEmptyVideo': 'Le serveur a renvoyé une vidéo vide.',
  'htmlErrTimeout': 'Le rendu a pris trop de temps. Essayez une durée plus courte ou moins d’ips.',
  'htmlErrGateway': 'Le serveur a mis trop de temps à rendre cette page. Essayez une durée plus courte, moins d’ips, une taille réduite ou une page plus simple.',
  'htmlErrStatus': 'Le serveur n’a pas pu rendre cette page. Veuillez réessayer.',
  'htmlErrUnreachable': 'Serveur injoignable. Vérifiez votre connexion et réessayez.',
  'htmlErrGeneric': 'Impossible de convertir le HTML. Vérifiez votre connexion et réessayez.',

  'authGoogleCancelled': 'Connexion Google annulée.',
  'authGoogleFailed': 'Échec de la connexion Google.',
  'authGoogleRetry': 'Échec de la connexion Google. Veuillez réessayer.',
  'authGoogleMisconfigured': 'La connexion Google n’est pas correctement configurée pour cette application.',
  'authVerifyFailedGoogle': 'Stillora n’a pas pu vérifier votre compte Google.',
  'authVerifyFailedApple': 'Stillora n’a pas pu vérifier votre compte Apple.',
  'authAppleUnsupported': 'La connexion avec Apple n’est pas encore prise en charge sur cette plateforme.',
  'authAppleNeedsIos13': 'La connexion avec Apple nécessite iOS 13 ou version ultérieure.',
  'authAppleFailed': 'Échec de la connexion Apple.',
  'authAppleRetry': 'Échec de la connexion Apple. Veuillez réessayer.',
  'authAppleCancelled': 'Connexion Apple annulée.',
  'authAppleUnavailable': 'La connexion Apple est indisponible pour le moment. Veuillez réessayer.',
  'authAppleConnection': 'Échec de la connexion Apple. Vérifiez votre connexion et réessayez.',
  // Store Screenshots
  'storeShots': 'Captures des stores',
  'storeShotsSubtitle': 'Tailles App Store et Play, exportées en un seul zip',
  'ssEyebrow': 'EXPORT STORES',
  'ssHeading': 'Captures App Store et Play',
  'ssIntro':
      'Ajoutez vos écrans une fois, choisissez les tailles demandées par '
      'chaque store, puis exportez un seul zip contenant chaque rendu dans '
      'son dossier.',
  'ssSourceImages': 'Images source',
  'ssAddImages': 'Ajouter des captures',
  'ssAddMore': 'Ajouter',
  'ssClear': 'Effacer',
  'ssEmpty': 'Ajoutez des captures pour les voir ici',
  'ssDropHint': 'Ajoutez les écrans de votre app',
  'ssSizes': 'Tailles',
  'ssRequiredOnly': 'Obligatoires seulement',
  'ssRequired': 'obligatoire',
  'ssPickSizes': 'Choisissez au moins une taille',
  'ssLook': 'Ajustement des images',
  'ssFit': 'Ajuster',
  'ssFill': 'Remplir',
  'ssBackground': 'Arrière-plan',
  'ssBlack': 'Noir',
  'ssWhite': 'Blanc',
  'ssMidnight': 'Minuit',
  'ssFormat': 'Format',
  'ssOrientation': 'Orientation',
  'ssPortrait': 'Portrait',
  'ssLandscape': 'Paysage',
  'ssNoAlphaNote':
      'Les deux stores refusent la transparence : chaque rendu est aplati '
      'sur la couleur d’arrière-plan.',
  'ssZipLayout': 'Zip organisé en Store / taille / 01-nom',
  'ssExport': 'Exporter le zip',
  'ssExporting': 'Rendu en cours...',
  'ssNothing': 'Aucun fichier généré.',
  'ssAndroidPhone': 'Téléphone Android',
  'ssAndroidTablet': 'Tablette Android',
  'ssPreviewCaption':
      'Chaque image est rendue dans toutes les tailles choisies',
  'ssClearWarning':
      'Cela supprime toutes les images et réinitialise les tailles.',
  'ssSaveZip': 'Enregistrer le zip',
  'ssSavedZip': 'Zip enregistré',
  'ssSaveFailed': 'Impossible d’enregistrer le zip.',
  'ssGone': 'Le zip n’est plus disponible.',
  'ssOutputCount': '{files} fichiers \u00b7 {sizes} tailles',
  'ssImageCount': '{count} images',
  'ssProgress': 'Rendu {done} / {total}',
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
