import 'package:flutter_test/flutter_test.dart';

// Import all test files
import 'auto_height_webview_test.dart' as base_tests;
import 'widget_behavior_test.dart' as behavior_tests;
import 'platform_specific_test.dart' as platform_tests;
import 'edge_case_test.dart' as edge_case_tests;
import 'test_helper.dart';

void main() {
  group('AutoHeightWebView Tests', () {
    setUpWebViewTests();

    group('Basic Tests', () {
      base_tests.main();
    });

    group('Behavior Tests', () {
      behavior_tests.main();
    });

    group('Platform-Specific Tests', () {
      platform_tests.main();
    });

    group('Edge Case Tests', () {
      edge_case_tests.main();
    });
  });
}
