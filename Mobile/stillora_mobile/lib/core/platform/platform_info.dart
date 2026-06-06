import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

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

bool useDesktopLayout(BuildContext context) {
  return isDesktopPlatform && MediaQuery.sizeOf(context).width >= 900;
}
