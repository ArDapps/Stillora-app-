import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';
import '../design/stillora_colors.dart';
import '../design/stillora_spacing.dart';
import '../platform/platform_info.dart';

/// Sponsored banner served by the Loopara ad network (public, no-auth,
/// CORS-enabled API). Replaces the previous Google AdMob banner. The same
/// [AdConfig.appKey] is sent for the fetch, the click URL and the impression so
/// all traffic is attributed to this app.
///
/// If the pool is empty or any request fails it renders nothing — an ad error is
/// never surfaced to the user. The [placement] is kept for call-site
/// compatibility; the Loopara pool is always fetched with `placement=app`.
class AdSlotWidget extends StatefulWidget {
  const AdSlotWidget({super.key, this.placement = ''});

  final String placement;

  @override
  State<AdSlotWidget> createState() => _AdSlotWidgetState();
}

class _AdSlotWidgetState extends State<AdSlotWidget>
    with SingleTickerProviderStateMixin {
  static final _dio = Dio();
  _Promo? _promo;

  // Drives the pulsing glow border around the banner.
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  @override
  void initState() {
    super.initState();
    _glow.repeat(reverse: true);
    // Re-fetch the pool on every load; never cache ad IDs across sessions.
    _load();
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await _dio.get<List<dynamic>>(
        '${AdConfig.looparaBaseUrl}/api/promos',
        queryParameters: {'key': AdConfig.looparaKey},
      );
      final ads = res.data;
      if (ads == null || ads.isEmpty) return;

      // Pick one ad at random.
      final raw = ads[Random().nextInt(ads.length)];
      if (raw is! Map) return;
      final promo = _Promo.fromMap(raw.cast<String, dynamic>());
      if (promo == null) return;

      if (!mounted) return;
      setState(() => _promo = promo);
      _trackImpression(promo.id);
    } catch (_) {
      // Never surface ad errors to the user.
    }
  }

  /// Report exactly one impression for the displayed ad.
  Future<void> _trackImpression(String id) async {
    try {
      await _dio.post(
        '${AdConfig.looparaBaseUrl}/api/promos/track',
        data: {'id': id, 'type': 'impression', 'source': AdConfig.appKey},
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
      '&source=${Uri.encodeQueryComponent(AdConfig.appKey)}',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Ignore launch failures.
    }
  }

  @override
  Widget build(BuildContext context) {
    final promo = _promo;
    if (promo == null) return const SizedBox.shrink();

    // Image paths come back relative (e.g. "/api/uploads/…"); resolve them
    // against the Loopara base URL so the banner loads.
    final imageUrl = promo.image.isEmpty
        ? ''
        : (promo.image.startsWith('http')
            ? promo.image
            : '${AdConfig.looparaBaseUrl}${promo.image}');

    final isDesktop = useDesktopLayout(context);
    // Desktop caps at the native 320x100 banner. On mobile the banner spans the
    // full content width (matching the primary buttons' margins) so there are no
    // black side gaps. The image aspect-fills (BoxFit.cover), cropping as needed.
    final bannerWidth = isDesktop
        ? _bannerWidth
        : MediaQuery.sizeOf(context).width - 2 * StilloraSpacing.mobileMargin;
    final bannerHeight = isDesktop ? _bannerHeight : 64.0;

    final radius = BorderRadius.circular(StilloraRadius.md);
    final banner = ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
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

  // Standard "large banner" dimensions served by Loopara (IAB 320x100).
  static const double _bannerWidth = 320;
  static const double _bannerHeight = 100;

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
  });

  final String id;
  final String name;
  final String image;
  final String link;

  static _Promo? fromMap(Map<String, dynamic> map) {
    final id = map['id'];
    if (id is! String || id.isEmpty) return null;
    return _Promo(
      id: id,
      name: (map['name'] as String?) ?? '',
      image: (map['image'] as String?) ?? '',
      link: (map['link'] as String?) ?? '',
    );
  }
}
