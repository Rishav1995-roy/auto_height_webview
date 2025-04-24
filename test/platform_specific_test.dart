import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auto_height_webview/auto_height_webview.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'mock_webview_platform.dart';

// This test file focuses on platform-specific behavior tests

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    WebViewPlatform.instance = MockWebViewPlatform();
  });

  group('AutoHeightWebView Platform-Specific Tests', () {
    testWidgets('renders appropriate widget based on platform',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoHeightWebView(
              htmlContent: '<div>Test content</div>',
            ),
          ),
        ),
      );

      expect(find.byType(AutoHeightWebView), findsOneWidget);

      // Platform-specific assertions
      if (kIsWeb) {
        // Web implementation would use HtmlElementView
        // But since test environment doesn't fully simulate web,
        // we can mainly test that the widget renders
        expect(find.byType(AnimatedContainer), findsOneWidget);
      } else {
        // Mobile implementation uses AnimatedContainer with WebViewWidget inside
        expect(find.byType(AnimatedContainer), findsOneWidget);
      }
    });

    testWidgets('uses AnimatedContainer for height transitions',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoHeightWebView(
              htmlContent: '<div>Test content</div>',
              initialHeight: 150,
            ),
          ),
        ),
      );

      // Find and verify the AnimatedContainer properties
      final animatedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );

      // Check animation properties
      expect(animatedContainer.duration, const Duration(milliseconds: 300));
      expect(animatedContainer.curve, Curves.easeInOut);
    });
  });

  // This group tests the differences in implementation
  // between platforms (though we can't actually test iOS vs Android here)
  group('Platform Implementation Differences', () {
    testWidgets('mobile implementation handles height changes',
        (WidgetTester tester) async {
      if (kIsWeb) {
        // Skip this test on web platform
        return;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoHeightWebView(
              htmlContent: '<div>Test content</div>',
              initialHeight: 100,
              onHeightChanged: (height) {},
            ),
          ),
        ),
      );

      expect(find.byType(AutoHeightWebView), findsOneWidget);

      // We can't actually trigger height changes in the mock implementation,
      // but we can verify the widget structure
      expect(find.byType(AnimatedContainer), findsOneWidget);
    });
  });
}
