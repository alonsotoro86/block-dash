# Plan de Desarrollo — BlockDash (réplica tipo "Block Blast!", Android + iOS)

## 0. Nombre y branding

**Nombre del juego: BlockDash**

- Corto, fácil de pronunciar/recordar en español e inglés, una sola palabra (bueno para ASO).
- "Dash" da una identidad propia y distinta de "Blast", reduciendo riesgo de confusión de marca con el original.
- Alternativas consideradas: CubeSnap, GridPop (descartadas por menor punch fonético).
- Pendiente antes de producción: verificar disponibilidad de nombre en App Store/Google Play, dominio y handles de redes, y viabilidad de trademark en la jurisdicción de publicación.

## 1. Análisis del juego original

**Género:** Puzzle de colocación de bloques ("block placement puzzle"), variante moderna de 1010!/Woodoku, con capa de meta-progresión tipo casual mobile.

**Mecánica core:**
- Tablero de **8x8 casillas**.
- Cada ronda se ofrecen **3 piezas** (poliominós de 1 a 5 celdas, ~40-50 formas distintas: líneas, cuadrados, L, T, Z, esquinas, etc.).
- El jugador arrastra cada pieza al tablero; al completar una **fila y/o columna** completa, esta se limpia y otorga puntos.
- Cuando se colocan las 3 piezas, se generan 3 nuevas (sistema de "bag" no siempre justo — hay heurísticas de dificultad dinámica).
- **Game over** cuando ninguna de las piezas disponibles cabe en el tablero.
- Sin límite de tiempo (modo clásico) → partidas de sesión corta (2-8 min), ideal para "just one more try".

**Sistemas de progresión/retención:**
- Puntuación acumulada + combos (limpiar varias líneas a la vez o en cadena da multiplicador).
- Monedas ganadas por partida, usadas para comprar **power-ups**: martillo (borra 1 bloque), bomba (borra área), intercambio de pieza, deshacer.
- Desbloqueo de **temas visuales** (skins de tablero/bloques) con monedas o logros.
- Racha diaria (daily login), misiones diarias, a veces "modos" adicionales (aventura por niveles con objetivos).
- Leaderboards (global/amigos) vía Game Center / Google Play Games.

**Monetización:**
- Anuncios **rewarded** (video a cambio de: continuar partida, monedas extra, power-up gratis).
- Anuncios **intersticiales** cada N partidas (frecuencia limitada para no frustrar).
- Banner opcional (poco usado en versiones modernas, daña UX).
- IAP: quitar anuncios, packs de monedas, "starter pack" con descuento, a veces pase VIP/battle pass estacional.

**Por qué engancha (loop de adicción):**
1. Sesiones cortas y de bajo compromiso cognitivo → se puede jugar en cualquier momento.
2. Casi-derrota constante ("por poco no entraba la pieza") → dopamina de alivio al encajar.
3. Feedback visual/sonoro muy "jugoso" (partículas, combos, sonido satisfactorio) en cada limpieza de línea.
4. Progresión de monedas/temas que da sensación de avance aunque el gameplay central no cambie.

## 2. Consideraciones legales e IP

- La **mecánica de juego** (grid + piezas + limpiar líneas) no es apropiable en sí — hay decenas de clones legítimos (1010!, Woodoku, Block Puzzle Jewel, etc.).
- **No se debe copiar**: el nombre "Block Blast!", su logo, paleta de marca, assets de arte, música o textos exactos — eso sí es infracción de copyright/trademark.
- Recomendado: nombre propio, identidad visual propia, formas de pieza y balance propios (pueden inspirarse pero no ser pixel-copy).
- Añadir política de privacidad y términos de uso (obligatorio para Apple/Google, más aún si hay ads/IAP/analytics).
- Si se usan SDKs de terceros (AdMob, Firebase) cumplir con GDPR/CCPA (consentimiento de datos) y **ATT de Apple** (iOS 14.5+, permiso de tracking).

## 3. Decisión tecnológica

| Opción | Pros | Contras |
|---|---|---|
| **Unity (C#, 2D)** ✅ recomendado | Un solo código para iOS/Android, SDKs maduros de ads/IAP/analytics, gran soporte de animación/juice (DOTween), fácil encontrar devs | Build algo pesado (~40-60MB), curva de aprendizaje si no se conoce Unity |
| Flutter + Flame | Muy liviano, mismo lenguaje que apps normales, buen rendimiento 2D | Ecosistema de ads/IAP menos maduro que Unity, menos "juice" out-of-the-box |
| React Native + Skia/Canvas | Reutilizable si ya hay equipo RN | No es lo ideal para juegos con física/animación intensiva |
| Nativo (Swift + Kotlin por separado) | Máximo rendimiento y control | Duplica todo el trabajo (2 codebases), tiempo/coste x2 |

**Recomendación: Unity.** Es el estándar de facto para casual mobile puzzle games, con mediación de anuncios (AppLovin MAX / LevelPlay), Unity IAP, Unity Gaming Services (Cloud Save, Analytics, Remote Config) todo integrado.

## 4. Arquitectura técnica

- **Patrón:** MVC/MVVM ligero — `BoardModel` (estado lógico del grid) separado de `BoardView` (render), controlado por `GameController`.
- **Datos de piezas:** `ScriptableObject` por cada forma (matriz booleana NxN), librería de ~40-50 piezas con pesos de probabilidad configurables.
- **Algoritmo de generación de piezas:** sistema de "bag" ponderado que evita imposibilidad temprana y ajusta dificultad dinámica (más piezas grandes si el tablero está despejado, más pequeñas si está saturado — igual que el juego original).
- **Detección de líneas:** al colocar una pieza, verificar filas/columnas completas → animar limpieza → recalcular combo/score.
- **Detección de game over:** tras generar 3 piezas nuevas, comprobar si *alguna* cabe en *algún* espacio libre (bitmask + convolución simple es suficiente para 8x8).
- **Object pooling** para celdas y partículas (evitar GC spikes en dispositivos gama baja).
- **Guardado local:** JSON en `PersistentDataPath` (estado de partida, monedas, desbloqueos) + **cloud save** vía Google Play Games / Game Center o Firebase, para continuidad entre dispositivos.
- **Backend (mínimo viable):** Firebase — Auth anónima, Firestore para leaderboards y misiones diarias, Remote Config (tuning de dificultad/ads sin re-publicar), Analytics, Crashlytics, Cloud Messaging (notificaciones push de racha/energía).

## 5. Diseño del juego (resumen del GDD)

- **Modos:** Clásico (infinito), Diario (semilla fija, comparar puntaje con amigos), y opcionalmente "Aventura" por niveles con objetivos (fase 2, post-MVP).
- **Power-ups** (comprables con monedas o vía anuncio recompensado): Martillo, Bomba, Intercambiar piezas, Deshacer último movimiento.
- **Scoring:** puntos base por celda colocada + bonus por línea + multiplicador por combo (líneas simultáneas/cadena).
- **Economía:** monedas por partida y logros; tienda con temas de tablero/bloques; sin "energía" limitante (el original no la usa, mantiene sesiones libres — clave para retención).
- **Anti-frustración:** nunca generar una mano de piezas que garantice game over inmediato salvo que el tablero ya esté casi lleno (esto ya ocurre de forma natural con buen diseño de bag).

## 6. Arte y audio

- Estilo **flat / minimalista**, colores saturados, alto contraste para legibilidad en pantallas pequeñas.
- 3-5 temas de bloques desbloqueables desde el día 1 del roadmap (frutas, neón, madera, espacio...).
- Animaciones clave: squash & stretch al soltar pieza, partículas + screen-shake sutil al limpiar línea, popups de combo ("Nice!", "Great!", "Amazing!"), confetti en high score.
- Audio: SFX de encaje, de limpieza (tono ascendente en combos), música de fondo loop relajante, **haptic feedback** en ambas plataformas.

## 7. Monetización y LiveOps

- Rewarded video: continuar partida tras game over (1 vez), monedas x2, power-up gratis diario.
- Interstitial: cada 3-4 partidas terminadas, nunca interrumpiendo mitad de partida.
- IAP: "Quitar anuncios" (~$3.99), packs de monedas (3 tiers), starter pack único con descuento agresivo.
- Mediación de anuncios vía **AppLovin MAX** o **AdMob mediation** para maximizar eCPM.
- Remote Config para A/B testing de frecuencia de ads, precios y curva de dificultad sin re-publicar la app.
- Eventos estacionales (temas navideños, halloween, etc.) para reactivar usuarios.

## 8. Roadmap por fases

| Fase | Contenido | Duración estimada |
|---|---|---|
| 0. Preproducción | GDD final, wireframes, setup de repos/proyecto Unity, elección definitiva de stack | 1-2 semanas |
| 1. Prototipo jugable | Grid 8x8, drag&drop, colocación, limpieza de líneas, score básico | 2-3 semanas |
| 2. Core loop completo | Algoritmo de bag de piezas, detección de game over, UI de partida, animaciones básicas | 3-4 semanas |
| 3. Meta sistemas | Monedas, tienda, power-ups, temas, logros, pantalla de perfil | 3-4 semanas |
| 4. Monetización | Integración de ads (rewarded/intersticial), IAP, remote config | 2 semanas |
| 5. Backend & LiveOps | Firebase (save en la nube, leaderboards, misiones diarias, push notifications) | 2 semanas |
| 6. Pulido y QA | Juice final, sonido, testing en múltiples dispositivos/resoluciones, optimización rendimiento | 3-4 semanas |
| 7. Soft launch | Lanzamiento en 1-2 mercados pequeños, medir retención D1/D7/D30, iterar | 2-4 semanas |
| 8. Lanzamiento global | Publicación mundial + calendario de LiveOps post-lanzamiento | continuo |

**Total estimado:** ~4-5 meses (equipo pequeño part-time) o ~2.5-3 meses (1 dev full-time + 1 artista freelance).

## 9. Equipo recomendado

- 1 Desarrollador Unity/C# (full-stack del juego).
- 1 Artista 2D / UI-UX (puede ser freelance por entregables).
- 1 Diseñador de sonido (o asset packs de audio con licencia).
- QA: el propio equipo + grupo de beta testers (TestFlight / Play Internal Testing).

## 10. Publicación en tiendas

- **Apple Developer Program:** $99/año. Requiere: ATT prompt (si hay tracking de ads), política de privacidad, clasificación de edad, capturas y video preview, cumplimiento de guidelines de App Review (especial cuidado con similitud excesiva a apps existentes — nombre/ícono/branding deben ser claramente distintos).
- **Google Play Console:** $25 pago único. Requiere: política de privacidad, formulario de seguridad de datos, clasificación de contenido (IARC), target API level vigente.
- Testing pre-lanzamiento: **TestFlight** (iOS) y **Internal/Closed testing track** (Android).

## 11. KPIs a monitorear post-lanzamiento

- Retención: D1 (objetivo >35-40%), D7 (>12-15%), D30 (>5%) — benchmarks típicos de puzzle casual.
- ARPDAU, eCPM efectivo, sesiones/día, duración media de sesión.
- Funnel de tutorial → primera partida completa → primera compra/ad view.

## 12. Riesgos y mitigaciones

- **Mercado saturado** (cientos de clones similares) → diferenciarse en arte, temas y pulido de UX, no solo en mecánica.
- **Rechazo en review** por parecido excesivo al original → asegurar nombre, ícono y branding claramente distintos; no usar assets ni textos copiados.
- **Rendimiento en gama baja** → pooling de objetos, evitar overdraw, testear en dispositivos Android de gama baja real (no solo emulador).

## Próximos pasos sugeridos

1. Confirmar stack (recomendado: Unity 2D).
2. Definir nombre/branding propio del juego.
3. Crear prototipo jugable de la Fase 1 (grid + drag&drop + limpieza de líneas) para validar la sensación de juego antes de invertir en arte/meta-sistemas.
