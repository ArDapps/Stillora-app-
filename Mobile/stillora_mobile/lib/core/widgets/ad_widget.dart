import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';
import '../design/stillora_colors.dart';
import '../design/stillora_spacing.dart';
import '../platform/platform_info.dart';

/// Sponsored banner served by the Loopara ad network (public, no-auth,
/// CORS-enabled API).
///
/// Every slot fetches a Loopara campaign and follows the ad's IAB `format`
/// aspect ratio, rotates a fresh random ad every 10s, and reports the running OS
/// as `platform` for analytics. In-content banners (mobile + inside tabs) use
/// the default [AdConfig.looparaKey] pool, which serves the 320x100 "stillora"
/// banner; the desktop sidebar passes the square `stilloraside` campaign so a
/// 300x250 creative reads as a square-ish tile.
///
/// If the pool is empty or any request fails it renders nothing — an ad error is
/// never surfaced to the user. The [placement] is kept for call-site
/// compatibility.
class AdSlotWidget extends StatefulWidget {
  const AdSlotWidget({
    super.key,
    this.placement = '',
    this.campaignKey = AdConfig.looparaKey,
  });

  final String placement;

  /// Loopara campaign to fetch for this slot. Defaults to the shared banner pool
  /// ([AdConfig.looparaKey], which serves the "stillora" banner); the desktop
  /// sidebar overrides it with the square `stilloraside` campaign.
  final String campaignKey;

  @override
  State<AdSlotWidget> createState() => _AdSlotWidgetState();
}

class _AdSlotWidgetState extends State<AdSlotWidget>
    with SingleTickerProviderStateMixin {
  static final _dio = Dio();

  // All ads returned for this slot's campaign, and the one currently shown.
  List<_Promo> _ads = const [];
  _Promo? _promo;

  // Rotates the visible ad every 10s.
  Timer? _rotate;

  // Drives the pulsing glow border around the banner.
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  // Campaign key used for the fetch and reported as the attribution source.
  String get _source => widget.campaignKey;

  @override
  void initState() {
    super.initState();
    _glow.repeat(reverse: true);
    // Re-fetch the pool on every load; never cache ad IDs across sessions.
    _load();
  }

  @override
  void dispose() {
    _rotate?.cancel();
    _glow.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await _dio.get<List<dynamic>>(
        '${AdConfig.looparaBaseUrl}/api/promos',
        queryParameters: {'key': widget.campaignKey},
      );
      final ads = res.data;
      if (ads == null || ads.isEmpty) return;

      final parsed = <_Promo>[];
      for (final raw in ads) {
        if (raw is Map) {
          final promo = _Promo.fromMap(raw.cast<String, dynamic>());
          if (promo != null) parsed.add(promo);
        }
      }
      if (parsed.isEmpty) return;

      // Pick one ad at random to show first.
      final first = parsed[Random().nextInt(parsed.length)];

      if (!mounted) return;
      setState(() {
        _ads = parsed;
        _promo = first;
      });
      _trackImpression(first.id);

      // Rotate a fresh random ad every 10s when the campaign has more than one.
      if (parsed.length > 1) {
        _rotate = Timer.periodic(const Duration(seconds: 10), (_) => _swap());
      }
    } catch (_) {
      // Never surface ad errors to the user.
    }
  }

  /// Swap in a different random ad and report an impression.
  void _swap() {
    if (!mounted || _ads.length < 2) return;
    final current = _promo;
    _Promo next = _ads[Random().nextInt(_ads.length)];
    // Avoid immediately repeating the same creative.
    var guard = 0;
    while (current != null && next.id == current.id && guard < 5) {
      next = _ads[Random().nextInt(_ads.length)];
      guard++;
    }
    setState(() => _promo = next);
    _trackImpression(next.id);
  }

  /// Report exactly one impression for the displayed ad.
  Future<void> _trackImpression(String id) async {
    try {
      await _dio.post(
        '${AdConfig.looparaBaseUrl}/api/promos/track',
        data: {
          'id': id,
          'type': 'impression',
          'source': _source,
          'platform': _platformName(),
        },
        options: Options(contentType: Headers.jsonContentType),
      );
    } catch (_) {
      // Impression tracking is best-effort.
    }
  }

  /// Open the tracking click endpoint, which records the click and 302-redirects
  /// to the ad's real destination. Never open the raw `link` directly.
  Future<void> _onTap(String id) async {
    final uri = Uri.parse(
      '${AdConfig.looparaBaseUrl}/api/promos/click'
      '?id=${Uri.encodeQueryComponent(id)}'
      '&source=${Uri.encodeQueryComponent(_source)}'
      '&platform=${Uri.encodeQueryComponent(_platformName())}',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Ignore launch failures.
    }
  }

  // The OS this app runs on, as Loopara expects it. Native apps can't be
  // detected server-side, so this is how the platform shows up in analytics.
  String _platformName() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  String _resolveUrl(String image) {
    if (image.isEmpty) return '';
    return image.startsWith('http')
        ? image
        : '${AdConfig.looparaBaseUrl}$image';
  }

  @override
  Widget build(BuildContext context) {
    final promo = _promo;
    if (promo == null) return const SizedBox.shrink();

    final imageUrl = _resolveUrl(promo.image);
    final isDesktop = useDesktopLayout(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        // Reserve the slot at the ad's IAB `format` aspect, responsive down.
        // Desktop caps at the format's native width so the tile never gets
        // oversized (the square sidebar tile and in-tab banners alike); mobile
        // fills the content width.
        final aspect = promo.aspect;
        final bannerWidth = isDesktop
            ? min(available, promo.nativeWidth)
            : available - 2 * StilloraSpacing.mobileMargin;
        final bannerHeight = bannerWidth / aspect;

        return _buildBanner(
          context,
          promo,
          imageUrl,
          bannerWidth,
          bannerHeight,
        );
      },
    );
  }

  Widget _buildBanner(
    BuildContext context,
    _Promo promo,
    String imageUrl,
    double bannerWidth,
    double bannerHeight,
  ) {
    final imageFit = BoxFit.cover;
    final radius = BorderRadius.circular(StilloraRadius.md);
    final banner = ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              fit: imageFit,
              // If the image fails, fall back to the text banner.
              errorBuilder: (context, error, stack) =>
                  _textBanner(context, promo),
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : _textBanner(context, promo),
            )
          else
            _textBanner(context, promo),
          // "Sponsored" label.
          Positioned(
            bottom: 2,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(StilloraRadius.sm),
              ),
              child: const Text(
                'Sponsored',
                style: TextStyle(fontSize: 9, color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: () => _onTap(promo.id),
      child: Center(
        child: AnimatedBuilder(
          animation: _glow,
          builder: (context, child) {
            final t = _glow.value; // 0..1, ping-pongs
            // Sweep the glow hue between the brand violet and cyan as it pulses.
            final glow = Color.lerp(
              StilloraColors.brandViolet,
              StilloraColors.brandCyan,
              t,
            )!;
            return Container(
              width: bannerWidth,
              height: bannerHeight,
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: glow.withValues(alpha: 0.85),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: glow.withValues(alpha: 0.30 + 0.35 * t),
                    blurRadius: 8 + 12 * t,
                    spreadRadius: 0.5 + 1.5 * t,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: banner,
        ),
      ),
    );
  }

  /// Styled text banner used when the ad has no image (or it fails to load).
  Widget _textBanner(BuildContext context, _Promo promo) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: StilloraSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            StilloraColors.accent.withValues(alpha: 0.30),
            StilloraColors.secondary.withValues(alpha: 0.30),
          ],
        ),
      ),
      child: Text(
        promo.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: StilloraColors.onSurface,
        ),
      ),
    );
  }
}

class _Promo {
  const _Promo({
    required this.id,
    required this.name,
    required this.image,
    required this.link,
    required this.nativeWidth,
    required this.nativeHeight,
  });

  final String id;
  final String name;
  final String image;
  final String link;

  // Parsed from the ad's IAB `format` (e.g. "300x250"); drives dedicated-slot
  // sizing. Falls back to the 320x100 banner if `format` is missing/invalid.
  final double nativeWidth;
  final double nativeHeight;

  double get aspect => nativeWidth / nativeHeight;

  static _Promo? fromMap(Map<String, dynamic> map) {
    final id = map['id'];
    if (id is! String || id.isEmpty) return null;
    final (w, h) = _parseFormat(map['format'] as String?);
    return _Promo(
      id: id,
      name: (map['name'] as String?) ?? '',
      image: (map['image'] as String?) ?? '',
      link: (map['link'] as String?) ?? '',
      nativeWidth: w,
      nativeHeight: h,
    );
  }

  /// Parse an IAB "WIDTHxHEIGHT" format string; defaults to 320x100.
  static (double, double) _parseFormat(String? format) {
    if (format != null) {
      final parts = format.toLowerCase().split('x');
      if (parts.length == 2) {
        final w = double.tryParse(parts[0].trim());
        final h = double.tryParse(parts[1].trim());
        if (w != null && h != null && w > 0 && h > 0) return (w, h);
      }
    }
    return (320, 100);
  }
}
