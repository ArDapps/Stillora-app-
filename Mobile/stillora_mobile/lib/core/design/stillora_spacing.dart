/// Spacing scale (4-pt based). Use these instead of raw pixel SizedBox/EdgeInsets.
class StilloraSpacing {
  const StilloraSpacing._();

  static const base = 4.0;
  static const xs = 8.0;
  static const sm = 16.0;
  static const md = 24.0;
  static const lg = 40.0;
  static const xl = 64.0;

  /// Tight 12-pt gap that sits between xs (8) and sm (16) — common for control
  /// padding and inline rows.
  static const snug = 12.0;

  static const gutter = 24.0;
  static const mobileMargin = 16.0;

  // Desktop / macOS chrome.
  static const desktopSidebarWidth = 212.0;
  static const desktopTopBarHeight = 56.0;
  static const desktopNavItemHeight = 42.0;
  static const desktopContentMaxWidth = 1080.0;
}

/// Corner-radius scale. `card` is the default for panels/buttons/glass so the
/// whole app shares one rounding language; `pill` is for fully-rounded chips.
class StilloraRadius {
  const StilloraRadius._();

  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;

  /// Default control/card rounding used across the app.
  static const card = 16.0;

  /// Fully rounded (chips, badges, segmented controls).
  static const pill = 999.0;

  // Legacy aliases kept so existing call-sites compile; mapped onto the new
  // scale so everything rounds consistently.
  static const base = 12.0;
  static const full = 16.0;
}
