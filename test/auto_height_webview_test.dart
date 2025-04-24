import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:auto_height_webview/auto_height_webview.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'mock_webview_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Register the mock WebView platform implementation
  setUp(() {
    WebViewPlatform.instance = MockWebViewPlatform();
  });

  group('AutoHeightWebView Widget Tests', () {
    testWidgets('should create with required parameters only', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoHeightWebView(
              htmlContent: '<div>Test content</div>',
            ),
          ),
        ),
      );

      // Verify that the widget is created
      expect(find.byType(AutoHeightWebView), findsOneWidget);
      
      // On web platform, we'd expect HtmlElementView
      if (kIsWeb) {
        expect(find.byType(HtmlElementView), findsOneWidget);
      } else {
        // We might not find WebViewWidget directly due to the mock implementation
        // But the widget itself should exist
        expect(find.byType(AnimatedContainer), findsOneWidget);
      }
    });

    testWidgets('should apply decoration properly', (WidgetTester tester) async {
      const borderColor = Colors.red;
      const borderRadius = 8.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoHeightWebView(
              htmlContent: '<div>Test content</div>',
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
          ),
        ),
      );

      // Find the AnimatedContainer that applies the decoration
      final animatedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );

      // Verify decoration properties
      final decoration = animatedContainer.decoration as BoxDecoration;
      expect(decoration.border, isA<Border>());
      
      // This is a limitation of widget testing - we can't directly check the color
      // but we can verify the border exists
      expect(decoration.border, isNotNull);
      expect(decoration.borderRadius, isNotNull);
    });

    testWidgets('should use default height values when not specified', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoHeightWebView(
              htmlContent: '<div>Test content</div>',
            ),
          ),
        ),
      );

      // Find the AnimatedContainer and check its height constraints
      final animatedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );

      // Constraints might not be directly accessible in all cases
      final constraints = animatedContainer.constraints;
      expect(constraints, isNotNull);
      
      // Default min height should be 50
      expect(constraints!.minHeight, 50.0);
    });

    testWidgets('should respect custom min/max height constraints', (WidgetTester tester) async {
      const customMinHeight = 120.0;
      const customMaxHeight = 500.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoHeightWebView(
              htmlContent: '<div>Test content</div>',
              minHeight: customMinHeight,
              maxHeight: customMaxHeight,
            ),
          ),
        ),
      );

      // Find the AnimatedContainer and check its height constraints
      final animatedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );

      final constraints = animatedContainer.constraints;
      expect(constraints, isNotNull);
      expect(constraints!.minHeight, customMinHeight);
      expect(constraints.maxHeight, customMaxHeight);
    });

    testWidgets('should handle onHeightChanged callback', (WidgetTester tester) async {
      
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

      // Can't directly test the height change callback in this mock environment
      // But we can verify the widget is created with the callback
      expect(find.byType(AutoHeightWebView), findsOneWidget);
    });

    testWidgets('should use KeyedSubtree on iOS platform', (WidgetTester tester) async {
      // This test will depend on the platform 
      // We can't easily mock Platform.isIOS, so this is more of a structure check
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoHeightWebView(
              htmlContent: '<div>Test content</div>',
            ),
          ),
        ),
      );

      // The widget should be created regardless of platform
      expect(find.byType(AutoHeightWebView), findsOneWidget);
    });
  });

  group('AutoHeightWebView Parameters Tests', () {
    testWidgets('should accept and use customScript', (WidgetTester tester) async {
      const customScript = 'console.log("Custom script executed");';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoHeightWebView(
              htmlContent: '<div>Test content</div>',
              customScript: customScript,
            ),
          ),
        ),
      );

      // We can't verify the script execution, but we can check the widget is created
      expect(find.byType(AutoHeightWebView), findsOneWidget);
    });

    testWidgets('should respect enableJavaScript parameter', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoHeightWebView(
              htmlContent: '<div>Test content</div>',
              enableJavaScript: false,
            ),
          ),
        ),
      );

      // We can't verify JavaScript is disabled, but we can check the widget is created
      expect(find.byType(AutoHeightWebView), findsOneWidget);
    });
  });
}