import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design/stillora_colors.dart';

const _adApiBase = 'https://md.loopara.app';

typedef _Campaign = ({String id, String title, String imageUrl});

/// Fetches and displays a single sponsored ad for [placement].
/// Silently hides itself if no campaign is active.
class AdSlotWidget extends StatefulWidget {
  const AdSlotWidget({super.key, required this.placement});

  /// e.g. 'HOME_BANNER' or 'USER_DASHBOARD_LEFT'
  final String placement;

  @override
  State<AdSlotWidget> createState() => _AdSlotWidgetState();
}

class _AdSlotWidgetState extends State<AdSlotWidget> {
  _Campaign? _campaign;
  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _dio.close();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await _dio
          .get('$_adApiBase/api/campaigns?placement=${widget.placement}');
      final campaigns = (res.data as Map<String, dynamic>)['campaigns'] as List?;
      if (campaigns == null || campaigns.isEmpty) return;
      final c = campaigns.first as Map<String, dynamic>;
      final rawImageUrl = c['imageUrl'] as String;
      final campaign = (
        id: c['id'] as String,
        title: c['title'] as String,
        imageUrl: rawImageUrl.startsWith('/')
            ? '$_adApiBase$rawImageUrl'
            : rawImageUrl,
      );
      if (!mounted) return;
      setState(() => _campaign = campaign);
      _dio
          .post('$_adApiBase/api/campaigns/${campaign.id}/impression')
          .ignore();
    } catch (_) {}
  }

  Future<void> _onTap() async {
    final campaign = _campaign;
    if (campaign == null) return;
    final url = Uri.parse('$_adApiBase/api/campaigns/${campaign.id}/click');
    if (await canLaunchUrl(url)) {
      launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final campaign = _campaign;
    if (campaign == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _onTap,
      child: Opacity(
        opacity: 0.62,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2e8b5cf6),
                blurRadius: 14,
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  campaign.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
                Positioned(
                  bottom: 4,
                  right: 6,
                  child: Text(
                    'Sponsored',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0x99ffffff),
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
