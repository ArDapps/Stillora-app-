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

/// True on iOS specifically (not macOS). The Speed section works here because
/// its `removeSilence` engine is implemented in the iOS plugin.
bool get isIosPlatform {
  if (kIsWeb) {
    return false;
  }
  return defaultTargetPlatform == TargetPlatform.iOS;
}

/// True on the phone platforms — iOS and Android.
///
/// Used where a phone-sized screen cannot afford chrome a desktop window can:
/// the live-preview panel, for instance, stays hidden until there is something
/// to preview instead of parking an empty frame above every control.
bool get isMobilePlatform {
  if (kIsWeb) {
    return false;
  }
  return defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android;
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

/// Colour grading is baked as a post-process pass, implemented on every native
/// engine: macOS/iOS via CoreImage, Android via a GL shader, Windows/Linux via
/// ffmpeg. Only web (no native engine) is excluded.
bool get colorGradingSupported => !kIsWeb;

bool useDesktopLayout(BuildContext context) {
  return isDesktopPlatform && MediaQuery.sizeOf(context).width >= 900;
}
