import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/iap_service.dart';
import '../../state/app_state.dart';
import '../../theme/block_themes.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  static const _powerUpCosts = {'hammer': 80, 'bomb': 150, 'swap': 60, 'undo': 100};
  static const _powerUpLabels = {
    'hammer': 'Martillo',
    'bomb': 'Bomba',
    'swap': 'Intercambiar',
    'undo': 'Deshacer',
  };
  static const _powerUpIcons = {
    'hammer': Icons.hardware,
    'bomb': Icons.circle,
    'swap': Icons.swap_horiz,
    'undo': Icons.undo,
  };

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tienda'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amberAccent, size: 20),
                  const SizedBox(width: 4),
                  Text('${appState.data.coins}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionTitle('Power-ups'),
          ..._powerUpCosts.entries.map(
            (e) => _PowerUpTile(
              id: e.key,
              cost: e.value,
              label: _powerUpLabels[e.key]!,
              icon: _powerUpIcons[e.key]!,
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Temas'),
          ...BlockThemes.all.map((t) => _ThemeTile(theme: t)),
          const SizedBox(height: 24),
          const _SectionTitle('Tienda de monedas'),
          if (!appState.data.adsRemoved) _IapTile(product: IapProduct.removeAds),
          _IapTile(product: IapProduct.coins500),
          _IapTile(product: IapProduct.coins1500),
          _IapTile(product: IapProduct.coins4000),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}

class _PowerUpTile extends StatelessWidget {
  final String id;
  final int cost;
  final String label;
  final IconData icon;
  const _PowerUpTile({required this.id, required this.cost, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final owned = appState.powerUpCount(id);
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text('Tienes: $owned'),
        trailing: ElevatedButton(
          onPressed: appState.data.coins >= cost
              ? () async {
                  final ok = await appState.spendCoins(cost);
                  if (ok) await appState.grantPowerUp(id);
                }
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on, size: 16),
              const SizedBox(width: 4),
              Text('$cost'),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final BlockTheme theme;
  const _ThemeTile({required this.theme});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final unlocked = appState.isThemeUnlocked(theme.id);
    final selected = appState.data.currentThemeId == theme.id;

    return Card(
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: theme.blockColors
              .take(3)
              .map((c) => Container(
                    margin: const EdgeInsets.only(right: 2),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                  ))
              .toList(),
        ),
        title: Text(theme.name),
        trailing: unlocked
            ? (selected
                ? const Icon(Icons.check_circle, color: Colors.greenAccent)
                : OutlinedButton(
                    onPressed: () => appState.selectTheme(theme.id),
                    child: const Text('Usar'),
                  ))
            : ElevatedButton(
                onPressed: appState.data.coins >= theme.unlockCost
                    ? () => appState.unlockTheme(theme)
                    : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_open, size: 16),
                    const SizedBox(width: 4),
                    Text('${theme.unlockCost}'),
                  ],
                ),
              ),
      ),
    );
  }
}

class _IapTile extends StatelessWidget {
  final IapProduct product;
  const _IapTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Card(
      child: ListTile(
        leading: const Icon(Icons.shopping_bag),
        title: Text(product.displayName),
        trailing: ElevatedButton(
          onPressed: () => appState.buyProduct(product),
          child: Text(product.mockPriceLabel),
        ),
      ),
    );
  }
}
