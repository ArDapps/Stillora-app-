import '../../core/i18n/app_strings.dart';

/// Which store a size belongs to.
enum StoreKind { appStore, googlePlay }

extension StoreKindMeta on StoreKind {
  String get label => switch (this) {
    StoreKind.appStore => 'App Store',
    StoreKind.googlePlay => 'Google Play',
  };

  /// Top-level folder inside the exported zip.
  String get folder => switch (this) {
    StoreKind.appStore => 'AppStore',
    StoreKind.googlePlay => 'GooglePlay',
  };
}

/// Device family, used to group the picker and to decide whether a size can be
/// rendered landscape.
enum StoreFamily {
  iPhone,
  iPad,
  mac,
  watch,
  appleTv,
  visionPro,
  androidPhone,
  androidTablet;

  String label(AppStrings s) => switch (this) {
    StoreFamily.iPhone => 'iPhone',
    StoreFamily.iPad => 'iPad',
    StoreFamily.mac => 'Mac',
    StoreFamily.watch => 'Apple Watch',
    StoreFamily.appleTv => 'Apple TV',
    StoreFamily.visionPro => 'Vision Pro',
    StoreFamily.androidPhone => s.ssAndroidPhone,
    StoreFamily.androidTablet => s.ssAndroidTablet,
  };

  StoreKind get store => switch (this) {
    StoreFamily.androidPhone ||
    StoreFamily.androidTablet => StoreKind.googlePlay,
    _ => StoreKind.appStore,
  };

  /// Watch faces and the fixed-resolution platforms have exactly one
  /// orientation; asking for a landscape Apple Watch screenshot is meaningless
  /// and App Store Connect would reject the dimensions.
  bool get allowsLandscape => switch (this) {
    StoreFamily.watch => false,
    StoreFamily.mac || StoreFamily.appleTv || StoreFamily.visionPro => false,
    _ => true,
  };

  /// Mac/TV/Vision sizes are quoted landscape; everything else portrait.
  bool get isNativeLandscape => switch (this) {
    StoreFamily.mac || StoreFamily.appleTv || StoreFamily.visionPro => true,
    _ => false,
  };
}

/// One output size the exporter can render to.
///
/// [width]/[height] are the dimensions exactly as the store publishes them —
/// portrait for phones, tablets and watches, landscape for Mac/TV/Vision.
class StoreTarget {
  const StoreTarget({
    required this.id,
    required this.family,
    required this.label,
    required this.width,
    required this.height,
    this.required = false,
    this.devices,
  });

  /// Stable slug — also the folder name inside the zip, so renaming a label
  /// never changes an export's layout.
  final String id;
  final StoreFamily family;

  /// What the store calls this size, e.g. `6.9"`.
  final String label;

  final int width;
  final int height;

  /// The store demands at least one screenshot at this size.
  final bool required;

  /// Example devices, shown as a subtitle.
  final String? devices;

  StoreKind get store => family.store;

  String get dimensionLabel => '$width × $height';

  /// The size as rendered, honouring a landscape request where the family
  /// supports one.
  ({int width, int height}) resolve({required bool landscape}) {
    if (!family.allowsLandscape) return (width: width, height: height);
    final wantLandscape = landscape;
    final isLandscape = width > height;
    if (wantLandscape == isLandscape) return (width: width, height: height);
    return (width: height, height: width);
  }
}

/// Every size Stillora can export, transcribed from the stores' own reference
/// pages. Keep this list in sync with them — it is the whole point of the
/// section, and a stale number here is a rejected submission.
///
/// App Store sizes: Apple, "Screenshot specifications", App Store Connect Help
/// (developer.apple.com/help/app-store-connect/reference/screenshot-specifications).
/// Both stores forbid an alpha channel, which is why the exporter always
/// flattens onto an opaque background — see `StoreScreenshotsController`.
const storeTargets = <StoreTarget>[
  // ── App Store · iPhone ────────────────────────────────────────────────────
  // 6.9" is the one Apple requires for an iPhone app; 6.5" is accepted in its
  // place. Everything below is optional — Apple scales those from the sizes
  // that were supplied.
  StoreTarget(
    id: 'iphone-6-9',
    family: StoreFamily.iPhone,
    label: '6.9"',
    width: 1320,
    height: 2868,
    required: true,
    devices: 'iPhone 17 Pro Max, 16 Pro Max, Air',
  ),
  StoreTarget(
    id: 'iphone-6-5',
    family: StoreFamily.iPhone,
    label: '6.5"',
    width: 1284,
    height: 2778,
    devices: 'iPhone 14 Plus, 13 Pro Max, 11',
  ),
  StoreTarget(
    id: 'iphone-6-3',
    family: StoreFamily.iPhone,
    label: '6.3"',
    width: 1206,
    height: 2622,
    devices: 'iPhone 17 Pro, 16 Pro, 15 Pro',
  ),
  StoreTarget(
    id: 'iphone-6-1',
    family: StoreFamily.iPhone,
    label: '6.1"',
    width: 1170,
    height: 2532,
    devices: 'iPhone 16e, 14, 13, 12',
  ),
  StoreTarget(
    id: 'iphone-5-5',
    family: StoreFamily.iPhone,
    label: '5.5"',
    width: 1242,
    height: 2208,
    devices: 'iPhone 8 Plus, 7 Plus',
  ),
  StoreTarget(
    id: 'iphone-4-7',
    family: StoreFamily.iPhone,
    label: '4.7"',
    width: 750,
    height: 1334,
    devices: 'iPhone SE (2nd/3rd gen), 8, 7',
  ),

  // ── App Store · iPad ──────────────────────────────────────────────────────
  StoreTarget(
    id: 'ipad-13',
    family: StoreFamily.iPad,
    label: '13"',
    width: 2064,
    height: 2752,
    required: true,
    devices: 'iPad Pro (M4/M5), iPad Air (M2+)',
  ),
  StoreTarget(
    id: 'ipad-12-9',
    family: StoreFamily.iPad,
    label: '12.9"',
    width: 2048,
    height: 2732,
    devices: 'iPad Pro (2nd gen)',
  ),
  StoreTarget(
    id: 'ipad-11',
    family: StoreFamily.iPad,
    label: '11"',
    width: 1668,
    height: 2420,
    devices: 'iPad Pro 11", Air, iPad mini',
  ),
  StoreTarget(
    id: 'ipad-9-7',
    family: StoreFamily.iPad,
    label: '9.7"',
    width: 1536,
    height: 2048,
    devices: 'iPad, iPad Air 2, mini 4',
  ),

  // ── App Store · Mac ───────────────────────────────────────────────────────
  // Quoted landscape, all 16:10.
  StoreTarget(
    id: 'mac-1280',
    family: StoreFamily.mac,
    label: '1280 × 800',
    width: 1280,
    height: 800,
    required: true,
  ),
  StoreTarget(
    id: 'mac-1440',
    family: StoreFamily.mac,
    label: '1440 × 900',
    width: 1440,
    height: 900,
  ),
  StoreTarget(
    id: 'mac-2560',
    family: StoreFamily.mac,
    label: '2560 × 1600',
    width: 2560,
    height: 1600,
  ),
  StoreTarget(
    id: 'mac-2880',
    family: StoreFamily.mac,
    label: '2880 × 1800',
    width: 2880,
    height: 1800,
  ),

  // ── App Store · Apple Watch ───────────────────────────────────────────────
  StoreTarget(
    id: 'watch-ultra-3',
    family: StoreFamily.watch,
    label: 'Ultra 3',
    width: 422,
    height: 514,
    required: true,
  ),
  StoreTarget(
    id: 'watch-ultra-2',
    family: StoreFamily.watch,
    label: 'Ultra 2 / Ultra',
    width: 410,
    height: 502,
  ),
  StoreTarget(
    id: 'watch-series-10',
    family: StoreFamily.watch,
    label: 'Series 11 / 10',
    width: 416,
    height: 496,
  ),
  StoreTarget(
    id: 'watch-series-7',
    family: StoreFamily.watch,
    label: 'Series 9 / 8 / 7',
    width: 396,
    height: 484,
  ),
  StoreTarget(
    id: 'watch-series-4',
    family: StoreFamily.watch,
    label: 'Series 6 / 5 / 4 / SE',
    width: 368,
    height: 448,
  ),

  // ── App Store · Apple TV & Vision Pro ─────────────────────────────────────
  StoreTarget(
    id: 'appletv-1080',
    family: StoreFamily.appleTv,
    label: '1920 × 1080',
    width: 1920,
    height: 1080,
    required: true,
  ),
  StoreTarget(
    id: 'appletv-4k',
    family: StoreFamily.appleTv,
    label: '3840 × 2160',
    width: 3840,
    height: 2160,
  ),
  StoreTarget(
    id: 'visionpro-4k',
    family: StoreFamily.visionPro,
    label: '3840 × 2160',
    width: 3840,
    height: 2160,
    required: true,
  ),

  // ── Google Play ───────────────────────────────────────────────────────────
  // Play does not publish per-device pixel sizes the way Apple does: it accepts
  // 320–3840px per side with the long side at most twice the short side, and
  // asks for 16:9 / 9:16 at 1080p or better to qualify for promotion. These are
  // those recommended renders.
  StoreTarget(
    id: 'play-phone',
    family: StoreFamily.androidPhone,
    label: 'Phone',
    width: 1080,
    height: 1920,
    required: true,
    devices: '9:16 · at least 2 required',
  ),
  StoreTarget(
    id: 'play-tablet-7',
    family: StoreFamily.androidTablet,
    label: '7-inch',
    width: 1200,
    height: 1920,
  ),
  StoreTarget(
    id: 'play-tablet-10',
    family: StoreFamily.androidTablet,
    label: '10-inch',
    width: 1600,
    height: 2560,
  ),
];

/// The sizes each store actually demands — the default selection, so a user who
/// changes nothing still gets a submittable set.
final defaultTargetIds = <String>{
  for (final target in storeTargets)
    if (target.required && target.family != StoreFamily.visionPro)
      if (target.family != StoreFamily.appleTv) target.id,
};

StoreTarget targetById(String id) =>
    storeTargets.firstWhere((target) => target.id == id);

/// Targets grouped by family, in declaration order.
Map<StoreFamily, List<StoreTarget>> targetsByFamily() {
  final grouped = <StoreFamily, List<StoreTarget>>{};
  for (final target in storeTargets) {
    grouped.putIfAbsent(target.family, () => []).add(target);
  }
  return grouped;
}

/// Google Play refuses anything outside 320–3840px per side, or with the long
/// side more than twice the short side. Every size in [storeTargets] satisfies
/// this, and a test asserts it — but an export path that ever computes its own
/// dimensions should check here first.
bool isValidPlaySize(int width, int height) {
  const minSide = 320;
  const maxSide = 3840;
  if (width < minSide || height < minSide) return false;
  if (width > maxSide || height > maxSide) return false;
  final long = width > height ? width : height;
  final short = width > height ? height : width;
  return long <= short * 2;
}
