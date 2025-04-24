import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'mock_webview_platform.dart';

/// Sets up the test environment for AutoHeightWebView tests
void setUpWebViewTests() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WebViewPlatform.instance = MockWebViewPlatform();
}

/// Helper function to create a test HTML content
String createTestHtml({
  String bodyContent = 'Test content',
  String additionalStyle = '',
  String additionalScript = '',
}) {
  return '''
    <div style="padding: 16px; background-color: #f8f8f8;">
      <h1 style="color: #333;">Test HTML</h1>
      <div>$bodyContent</div>
      <style>
        body {
          margin: 0;
          padding: 0;
          font-family: sans-serif;
        }
        $additionalStyle
      </style>
      <script>
        $additionalScript
      </script>
    </div>
  ''';
}