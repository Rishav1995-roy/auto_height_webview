import 'package:auto_height_webview/src/auto_height_webview_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auto_height_webview/auto_height_webview.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'mock_webview_platform.dart';

// Helper method to create either the real or mock widget
Widget createAutoHeightWebView({
  required String htmlContent,
  double? initialHeight,
  double? minHeight,
  double? maxHeight,
  BoxDecoration? decoration,
  Function(double)? onHeightChanged,
  String? customScript,
  bool enableJavaScript = true,
  bool useMock = true,
}) {
  if (useMock) {
    return MockAutoHeightWebView(
      htmlContent: htmlContent,
      initialHeight: initialHeight,
      minHeight: minHeight,
      maxHeight: maxHeight,
      decoration: decoration,
      onHeightChanged: onHeightChanged,
      customScript: customScript,
      enableJavaScript: enableJavaScript,
    );
  } else {
    return AutoHeightWebView(
      htmlContent: htmlContent,
      initialHeight: initialHeight,
      minHeight: minHeight,
      maxHeight: maxHeight,
      decoration: decoration,
      onHeightChanged: onHeightChanged,
      customScript: customScript,
      enableJavaScript: enableJavaScript,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    WebViewPlatform.instance = MockWebViewPlatform();
  });

  group('AutoHeightWebView Edge Cases', () {
    testWidgets('handles empty HTML content', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoHeightWebView(
              htmlContent: '',
            ),
          ),
        ),
      );

      // Should render without errors
      expect(find.byType(AutoHeightWebView), findsOneWidget);
    });

    testWidgets('handles extremely large HTML content',
        (WidgetTester tester) async {
      // Generate a large HTML string
      final largeHtml = '<div>${'Test content<br>' * 1000}</div>';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoHeightWebView(
              htmlContent: largeHtml,
            ),
          ),
        ),
      );

      // Should render without errors
      expect(find.byType(AutoHeightWebView), findsOneWidget);
    });

    testWidgets('handles zero initial height', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoHeightWebView(
              htmlContent: '<div>Test</div>',
              initialHeight: 0,
            ),
          ),
        ),
      );

      // Find the AnimatedContainer and check if it handles zero height
      final animatedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );

      // Default min height should be applied instead of zero
      expect(animatedContainer.constraints!.minHeight, 50.0);
    });

    testWidgets('handles JavaScript errors gracefully',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoHeightWebView(
              htmlContent: '<div>Test</div>',
              customScript: 'thisWillCauseAnError();', // Invalid JS
            ),
          ),
        ),
      );

      // Should still render without crashing
      expect(find.byType(AutoHeightWebView), findsOneWidget);
    });

    testWidgets('handles rapid rebuilds without error',
        (WidgetTester tester) async {
      // This test attempts to simulate hot reload or rapid state changes

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoHeightWebView(
              htmlContent: '<div>Test 1</div>',
            ),
          ),
        ),
      );

      // Force a rebuild with different content
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoHeightWebView(
              htmlContent: '<div>Test 2</div>',
            ),
          ),
        ),
      );

      // And again
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoHeightWebView(
              htmlContent: '<div>Test 3</div>',
            ),
          ),
        ),
      );

      // Should handle multiple rebuilds without errors
      expect(find.byType(AutoHeightWebView), findsOneWidget);
    });
  });

  group('AutoHeightWebView Null Safety Tests', () {
    testWidgets('handles null decoration gracefully',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoHeightWebView(
              htmlContent: '<div>Test</div>',
              decoration: null,
            ),
          ),
        ),
      );

      // Should use default transparent decoration
      expect(find.byType(AutoHeightWebView), findsOneWidget);
      expect(find.byType(AnimatedContainer), findsOneWidget);
    });

    testWidgets('handles null onHeightChanged callback',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoHeightWebView(
              htmlContent: '<div>Test</div>',
              onHeightChanged: null,
            ),
          ),
        ),
      );

      // Should render without errors
      expect(find.byType(AutoHeightWebView), findsOneWidget);
    });

    testWidgets('handles null customScript', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoHeightWebView(
              htmlContent: '<div>Test</div>',
              customScript: null,
            ),
          ),
        ),
      );

      // Should render without errors
      expect(find.byType(AutoHeightWebView), findsOneWidget);
    });
  });
}
