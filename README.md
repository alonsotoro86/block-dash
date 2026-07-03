# BlockDash

Réplica jugable tipo *Block Blast!* — puzzle de colocación de bloques en un tablero 8x8, hecho en Flutter + Flame para Android e iOS. Ver [PLAN_DESARROLLO.md](PLAN_DESARROLLO.md) para el análisis del juego original y el plan completo por fases.

## Qué está implementado

- **Núcleo del juego** (`lib/game/`, `lib/models/`): tablero 8x8, ~30 formas de pieza, bag ponderado anti-frustración, drag&drop con preview de colocación válida/inválida, limpieza de líneas con combos, detección de game over.
- **Meta-sistemas** (`lib/state/`, `lib/ui/screens/shop_screen.dart`): monedas, 4 power-ups (martillo, bomba, swap, deshacer), temas desbloqueables, racha diaria, guardado local persistente.
- **Monetización y backend**: `lib/services/ads_service.dart`, `iap_service.dart`, `leaderboard_service.dart` son interfaces abstractas con una implementación **mock local** funcional (sin necesidad de cuentas externas para desarrollar/probar). Ver la sección de swap points más abajo.
- **Tests**: `test/board_test.dart` cubre la lógica pura (colocación, límpieza de líneas/columnas, combos, power-ups, generación de piezas). `test/widget_test.dart` es un smoke test de arranque.

Verificado en vivo (build web): navegación completa, compra en tienda, desbloqueo de temas, persistencia de monedas tras recargar. El **drag & drop de piezas sobre el tablero (canvas de Flame) no pudo probarse de forma automatizada** en este entorno porque el canvas no expone selectores CSS ni árbol de accesibilidad — se validó por lógica (tests unitarios) y por inspección visual del render. Recomendado: probar manualmente en un emulador/dispositivo real antes de publicar.

## Cómo correrlo

```bash
flutter pub get
flutter run -d chrome        # web, la forma más rápida de iterar
flutter run                  # Android/iOS conectado o emulador
flutter test                 # suite de tests
```

## Pendiente antes de publicar (requiere tus propias cuentas/decisiones)

Esto es lo que **no puede automatizarse** — requiere tus cuentas, pagos y decisiones de negocio:

### 1. Branding y legal
- [ ] Confirmar disponibilidad del nombre "BlockDash" en App Store / Google Play / dominio.
- [ ] Reemplazar los íconos placeholder (`android/app/src/main/res/mipmap-*`, `ios/Runner/Assets.xcassets/AppIcon.appiconset`, `web/icons/`) con arte final.
- [ ] Redactar política de privacidad y términos de uso (obligatorio por los SDKs de ads/analytics).

### 2. Ads reales (reemplazar `MockAdsService`)
- [ ] Crear cuenta de AdMob (o AppLovin MAX/LevelPlay) y obtener App ID + unit IDs.
- [ ] Agregar el plugin `google_mobile_ads` y configurar `AndroidManifest.xml` / `Info.plist` con el App ID.
- [ ] Implementar el ATT prompt de iOS (App Tracking Transparency, obligatorio en iOS 14.5+).
- [ ] Escribir una implementación real de `AdsService` (`lib/services/ads_service.dart`) y sustituirla en `lib/main.dart`.

### 3. Compras in-app reales (reemplazar `MockIapService`)
- [ ] Configurar los productos (`block_dash_remove_ads`, `block_dash_coins_500`, etc. — IDs ya definidos en `lib/services/iap_service.dart`) en App Store Connect y Google Play Console.
- [ ] Integrar el plugin `in_app_purchase` con validación de recibos en servidor.

### 4. Backend / cloud save (reemplazar `LocalLeaderboardService` y extender `StorageService`)
- [ ] Crear proyecto Firebase (Auth anónima, Firestore para leaderboards/misiones diarias, Remote Config, Analytics, Crashlytics, Cloud Messaging) — o usar Game Center / Google Play Games para leaderboards nativos.
- [ ] Agregar `google-services.json` (Android) y `GoogleService-Info.plist` (iOS) — **no comitear estos archivos**, ya están en `.gitignore`.

### 5. Builds de plataforma
- [ ] **Android**: `flutter build apk` / `flutter build appbundle` funciona directamente en Windows (ya probado: `android/gradlew` incluido en el repo).
- [ ] **iOS**: requiere una Mac con Xcode (no es posible compilar/firmar iOS desde Windows). Alternativas: Mac física, o un servicio de CI en la nube (Codemagic, GitHub Actions con runner macOS, Ionic Appflow).
- [ ] Cuenta de Apple Developer Program ($99/año) y Google Play Console ($25 pago único).

### 6. Publicación
- [ ] TestFlight (iOS) / Internal testing track (Android) antes del lanzamiento público.
- [ ] Formulario de seguridad de datos (Google Play) y clasificación de contenido (IARC).
- [ ] Soft launch en 1-2 mercados pequeños antes del lanzamiento global (ver Fase 7 del plan).
