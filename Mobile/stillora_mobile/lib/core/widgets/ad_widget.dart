import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../constants/app_constants.dart';
import '../platform/platform_info.dart';

/// AdMob banner shown to everyone on iOS/Android. Collapses to nothing on
/// unsupported platforms (macOS/Windows/Linux/web). The [placement] is kept for
/// call-site compatibility but is not used by AdMob.
class AdSlotWidget extends StatefulWidget {
  const AdSlotWidget({super.key, this.placement = ''});

  final String placement;

  @override
  State<AdSlotWidget> createState() => _AdSlotWidgetState();
}

class _AdSlotWidgetState extends State<AdSlotWidget> {
  BannerAd? _banner;
  bool _loaded = false;

  static String get _unitId => isApplePlatform
      ? AdConfig.iosBannerUnitId
      : AdConfig.androidBannerUnitId;

  @override
  void initState() {
    super.initState();
    _maybeLoad();
  }

  void _maybeLoad() {
    if (!adsSupportedPlatform) return;
    final ad = BannerAd(
      adUnitId: _unitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    )..load();
    _banner = ad;
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _banner;
    if (!adsSupportedPlatform || !_loaded || ad == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
