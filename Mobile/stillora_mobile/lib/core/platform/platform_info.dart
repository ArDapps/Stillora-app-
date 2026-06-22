import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// True on iOS and macOS — the platforms that use the App Store / RevenueCat
/// Apple SDK key.
bool get isApplePlatform {
  if (kIsWeb) {
    return false;
  }
  return defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

/// AdMob only ships on iOS and Android. Everywhere else (macOS/Windows/Linux/web)
/// the banner widgets render nothing.
bool get adsSupportedPlatform {
  if (kIsWeb) {
    return false;
  }
  return defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android;
}

bool get isDesktopPlatform {
  if (kIsWeb) {
    return false;
  }
  return switch (defaultTargetPlatform) {
    TargetPlatform.linux ||
    TargetPlatform.macOS ||
    TargetPlatform.windows => true,
    _ => false,
  };
}

bool get useFfmpegDesktopExport {
  if (kIsWeb) {
    return false;
  }
  return switch (defaultTargetPlatform) {
    TargetPlatform.linux || TargetPlatform.windows => true,
    _ => false,
  };
}

bool useDesktopLayout(BuildContext context) {
  return isDesktopPlatform && MediaQuery.sizeOf(context).width >= 900;
}
