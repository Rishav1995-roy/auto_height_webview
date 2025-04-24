import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

// Mock implementation of WebViewPlatform for testing
class MockWebViewPlatform extends WebViewPlatform {
  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    return MockWebViewController(params);
  }

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
    return MockWebViewWidget(params);
  }

  @override
  PlatformWebViewCookieManager createPlatformCookieManager(
    PlatformWebViewCookieManagerCreationParams params,
  ) {
    return MockWebViewCookieManager(params);
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) {
    return MockNavigationDelegate(params);
  }
}

class MockWebViewController extends PlatformWebViewController {
  MockWebViewController(super.params) : super.implementation();

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setBackgroundColor(Color color) async {}

  @override
  Future<void> loadRequest(LoadRequestParams params) async {}

  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) async {}

  @override
  Future<String?> currentUrl() async => 'https://mock.url';

  @override
  Future<void> addJavaScriptChannel(
      JavaScriptChannelParams javaScriptChannelParams) async {}

  @override
  Future<void> removeJavaScriptChannel(String javaScriptChannelName) async {}

  @override
  Future<void> runJavaScript(String javaScript) async {}

  @override
  Future<void> clearCache() async {}

  @override
  Future<String> runJavaScriptReturningResult(String javaScript) async => '';
}

class MockWebViewWidget extends PlatformWebViewWidget {
  MockWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200, // Mock height
      color: const Color(0xFFEEEEEE),
      child: const Center(
        child: Text('Mock WebView'),
      ),
    );
  }
}

class MockWebViewCookieManager extends PlatformWebViewCookieManager {
  MockWebViewCookieManager(super.params) : super.implementation();

  @override
  Future<void> setCookie(WebViewCookie cookie) async {}
}

class MockNavigationDelegate extends PlatformNavigationDelegate {
  MockNavigationDelegate(super.params) : super.implementation();

  @override
  Future<void> setOnNavigationRequest(
      NavigationRequestCallback onNavigationRequest) async {}

  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async {}

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {
    // Immediately call the callback with a mock URL
    onPageFinished('https://mock.url');
  }

  @override
  Future<void> setOnProgress(ProgressCallback onProgress) async {}

  @override
  Future<void> setOnWebResourceError(
      WebResourceErrorCallback onWebResourceError) async {}
}
