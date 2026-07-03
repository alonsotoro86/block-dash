/// Abstraction over rewarded/interstitial ads.
///
/// SWAP POINT: replace [MockAdsService] with a real implementation backed by
/// `google_mobile_ads` (AdMob) or an AppLovin MAX / LevelPlay mediation SDK.
/// The rest of the app only talks to this interface, so no other file needs
/// to change when real ad units are wired in. Remember to add the AdMob App
/// ID to AndroidManifest.xml / Info.plist and implement the ATT prompt on
/// iOS before going live.
abstract class AdsService {
  Future<void> init();

  /// Shows a rewarded video ad. Calls [onReward] only if the user watched it
  /// to completion. Returns normally (without calling onReward) if the ad
  /// failed to load or the user closed it early.
  Future<void> showRewarded({required Future<void> Function() onReward});

  /// Shows an interstitial ad, if one is loaded and the frequency cap
  /// allows it. Safe to call opportunistically (e.g. after game over).
  Future<void> maybeShowInterstitial();
}

class MockAdsService implements AdsService {
  int _gamesSinceLastInterstitial = 0;
  static const _interstitialEvery = 3;

  @override
  Future<void> init() async {}

  @override
  Future<void> showRewarded({required Future<void> Function() onReward}) async {
    // Simulates network + playback delay of a real rewarded ad.
    await Future.delayed(const Duration(milliseconds: 600));
    await onReward();
  }

  @override
  Future<void> maybeShowInterstitial() async {
    _gamesSinceLastInterstitial++;
    if (_gamesSinceLastInterstitial >= _interstitialEvery) {
      _gamesSinceLastInterstitial = 0;
      await Future.delayed(const Duration(milliseconds: 300));
      // Real implementation would call interstitialAd.show() here.
    }
  }
}
