// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For utsav, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:datastock/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MyApp smoke test', (WidgetTester tester) async {
    // Create mock services
    final mockAnalyticsService = null;
    final mockAnalyticsObserver = null; // Can be null for basic tests

    // Build our app and trigger a frame
    await tester.pumpWidget(
      MyApp(
        analyticsService: mockAnalyticsService,
        analyticsObserver: mockAnalyticsObserver,
      ),
    );

    // Wait for async operations to complete
    await tester.pumpAndSettle();

    // Verify that the app starts (adjust based on your actual UI)
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
