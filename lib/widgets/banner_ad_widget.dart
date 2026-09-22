import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ads_service.dart';

/// An adaptive AdMob banner that loads itself and takes up no space at
/// all until (and unless) an ad actually loads — a failed/slow load never
/// leaves a blank gap or breaks layout.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bannerAd == null) _loadAd();
  }

  Future<void> _loadAd() async {
    final width = MediaQuery.of(context).size.width.truncate();
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width) ?? AdSize.banner;

    final ad = BannerAd(
      size: size,
      adUnitId: AdsService.bannerAdUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
    ad.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _bannerAd;
    if (!_isLoaded || ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
