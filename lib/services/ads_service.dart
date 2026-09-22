import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Centralizes every AdMob ad unit ID used in the app.
///
/// Currently set to Google's official TEST ad unit IDs — these always
/// serve real test creatives and are safe to ship while developing (no
/// risk of invalid-traffic policy violations from clicking your own ads).
/// Before a real release, replace [bannerAdUnitId] below with the ad unit
/// ID(s) from your own AdMob account (Ads units > your banner unit), and
/// replace the `com.google.android.gms.ads.APPLICATION_ID` meta-data in
/// android/app/src/main/AndroidManifest.xml and the
/// `GADApplicationIdentifier` key in ios/Runner/Info.plist with your real
/// AdMob App IDs.
class AdsService {
  AdsService._();

  static Future<void> initialize() => MobileAds.instance.initialize();

  /// Google's public test banner ad unit ID (same value for every app
  /// during development — swap for your own before release).
  static String get bannerAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/6300978111';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/2934735716';
    throw UnsupportedError('Ads are only supported on Android and iOS.');
  }
}
