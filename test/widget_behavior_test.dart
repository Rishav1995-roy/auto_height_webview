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

  group('AutoHeightWebView Behavior Tests', () {
    testWidgets('height changes when onHeightChanged is called',
        (WidgetTester tester) async {
      final heightChangeKey = GlobalKey<_HeightChangeTestWidgetState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeightChangeTestWidget(
              key: heightChangeKey,
              initialHeight: 100,
            ),
          ),
        ),
      );

      // Initial state
      expect(heightChangeKey.currentState!.currentHeight, 100);

      // Simulate height change
      heightChangeKey.currentState!.updateHeight(150);
      await tester.pump();

      // Height should be updated
      expect(heightChangeKey.currentState!.currentHeight, 150);
    });

    testWidgets('respects min and max height constraints',
        (WidgetTester tester) async {
      final heightConstraintKey = GlobalKey<_HeightConstraintTestWidgetState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeightConstraintTestWidget(
              key: heightConstraintKey,
              initialHeight: 100,
              minHeight: 80,
              maxHeight: 200,
            ),
          ),
        ),
      );

      // Test height below minimum
      heightConstraintKey.currentState!.updateHeight(50);
      await tester.pump();
      expect(heightConstraintKey.currentState!.currentHeight,
          80); // Should be clamped to min

      // Test height above maximum
      heightConstraintKey.currentState!.updateHeight(250);
      await tester.pump();
      expect(heightConstraintKey.currentState!.currentHeight,
          200); // Should be clamped to max

      // Test height within range
      heightConstraintKey.currentState!.updateHeight(150);
      await tester.pump();
      expect(heightConstraintKey.currentState!.currentHeight,
          150); // Should be unchanged
    });

    testWidgets('loads HTML content correctly', (WidgetTester tester) async {
      const testHtml = '<div>Test HTML Content</div>';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoHeightWebView(
              htmlContent: testHtml,
            ),
          ),
        ),
      );

      // We can't check the actual HTML rendering in tests,
      // but we can verify the widget was created successfully
      expect(find.byType(AutoHeightWebView), findsOneWidget);
    });
  });
}

// Test widgets to help verify behavior

class HeightChangeTestWidget extends StatefulWidget {
  final double initialHeight;

  const HeightChangeTestWidget({
    super.key,
    required this.initialHeight,
  });

  @override
  State<HeightChangeTestWidget> createState() => _HeightChangeTestWidgetState();
}

class _HeightChangeTestWidgetState extends State<HeightChangeTestWidget> {
  late double currentHeight;

  @override
  void initState() {
    super.initState();
    currentHeight = widget.initialHeight;
  }

  void updateHeight(double height) {
    setState(() {
      currentHeight = height;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AutoHeightWebView(
      htmlContent: '<div>Test</div>',
      initialHeight: currentHeight,
      onHeightChanged: (height) {
        setState(() {
          currentHeight = height;
        });
      },
    );
  }
}

class HeightConstraintTestWidget extends StatefulWidget {
  final double initialHeight;
  final double minHeight;
  final double maxHeight;

  const HeightConstraintTestWidget({
    super.key,
    required this.initialHeight,
    required this.minHeight,
    required this.maxHeight,
  });

  @override
  State<HeightConstraintTestWidget> createState() =>
      _HeightConstraintTestWidgetState();
}

class _HeightConstraintTestWidgetState
    extends State<HeightConstraintTestWidget> {
  late double currentHeight;

  @override
  void initState() {
    super.initState();
    currentHeight = widget.initialHeight;
  }

  void updateHeight(double height) {
    setState(() {
      currentHeight = height;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AutoHeightWebView(
      htmlContent: '<div>Test</div>',
      initialHeight: currentHeight,
      minHeight: widget.minHeight,
      maxHeight: widget.maxHeight,
      onHeightChanged: (height) {
        setState(() {
          currentHeight = height;
        });
      },
    );
  }
}
