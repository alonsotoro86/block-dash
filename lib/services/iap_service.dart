/// Product catalog for in-app purchases.
enum IapProduct {
  removeAds,
  coins500,
  coins1500,
  coins4000,
}

extension IapProductInfo on IapProduct {
  String get storeId => switch (this) {
        IapProduct.removeAds => 'block_dash_remove_ads',
        IapProduct.coins500 => 'block_dash_coins_500',
        IapProduct.coins1500 => 'block_dash_coins_1500',
        IapProduct.coins4000 => 'block_dash_coins_4000',
      };

  String get displayName => switch (this) {
        IapProduct.removeAds => 'Quitar anuncios',
        IapProduct.coins500 => '500 monedas',
        IapProduct.coins1500 => '1500 monedas',
        IapProduct.coins4000 => '4000 monedas + bono 20%',
      };

  String get mockPriceLabel => switch (this) {
        IapProduct.removeAds => '\$3.99',
        IapProduct.coins500 => '\$1.99',
        IapProduct.coins1500 => '\$4.99',
        IapProduct.coins4000 => '\$9.99',
      };

  int get coinAmount => switch (this) {
        IapProduct.removeAds => 0,
        IapProduct.coins500 => 500,
        IapProduct.coins1500 => 1500,
        IapProduct.coins4000 => 4000,
      };
}

/// Abstraction over store purchases.
///
/// SWAP POINT: replace [MockIapService] with the `in_app_purchase` plugin,
/// wired to real product IDs configured in App Store Connect and Google
/// Play Console. Server-side receipt validation is strongly recommended
/// before granting entitlements in production.
abstract class IapService {
  Future<void> init();
  Future<bool> buy(IapProduct product);
}

class MockIapService implements IapService {
  @override
  Future<void> init() async {}

  @override
  Future<bool> buy(IapProduct product) async {
    // Simulates a store purchase sheet + processing delay.
    await Future.delayed(const Duration(milliseconds: 500));
    return true; // Always "succeeds" locally; wire real receipts for prod.
  }
}
