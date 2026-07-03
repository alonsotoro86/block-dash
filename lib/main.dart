import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/ads_service.dart';
import 'services/iap_service.dart';
import 'services/leaderboard_service.dart';
import 'services/storage_service.dart';
import 'state/app_state.dart';
import 'ui/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BlockDashApp());
}

class BlockDashApp extends StatefulWidget {
  const BlockDashApp({super.key});

  @override
  State<BlockDashApp> createState() => _BlockDashAppState();
}

class _BlockDashAppState extends State<BlockDashApp> {
  late final AppState appState;
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    appState = AppState(
      storage: StorageService(),
      ads: MockAdsService(),
      iap: MockIapService(),
      leaderboard: LocalLeaderboardService(),
    );
    _initFuture = appState.init();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: appState,
      child: MaterialApp(
        title: 'BlockDash',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF1B1F3B),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF42A5F5),
            brightness: Brightness.dark,
          ),
        ),
        home: FutureBuilder<void>(
          future: _initFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const _SplashScreen();
            }
            return const HomeScreen();
          },
        ),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'BlockDash',
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
