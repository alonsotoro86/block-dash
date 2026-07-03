import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:block_dash/main.dart';

void main() {
  testWidgets('App boots to the home screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const BlockDashApp());

    // Let the AppState.init() future (storage load) resolve, then settle
    // the resulting frame — bounded pumps instead of pumpAndSettle, since
    // the daily-streak reward flow isn't a finite animation.
    for (var i = 0; i < 10 && find.text('JUGAR').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('BlockDash'), findsOneWidget);
    expect(find.text('JUGAR'), findsOneWidget);
  });
}
