import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

/// A [WebViewPlatform] that creates recording fakes, so the real
/// `AutoHeightWebView` can be tested without a native WebView.
class FakeWebViewPlatform extends WebViewPlatform {
  /// Every controller created, in creation order.
  final List<FakePlatformWebViewController> controllers = [];

  /// The most recently created controller.
  FakePlatformWebViewController get controller => controllers.last;

  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    final c = FakePlatformWebViewController(params);
    controllers.add(c);
    return c;
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) =>
      FakePlatformNavigationDelegate(params);

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) =>
      FakePlatformWebViewWidget(params);
}

/// Records calls and exposes the callbacks registered by the widget.
class FakePlatformWebViewController extends PlatformWebViewController {
  FakePlatformWebViewController(super.params) : super.implementation();

  /// HTML strings passed to `loadHtmlString`, in order.
  final List<String> loadedHtml = [];

  /// `baseUrl` arguments passed to `loadHtmlString`, in order.
  final List<String?> loadedBaseUrls = [];

  /// Scripts passed to `runJavaScript`.
  final List<String> executedScripts = [];

  /// Registered JavaScript channels by name.
  final Map<String, JavaScriptChannelParams> channels = {};

  JavaScriptMode? javaScriptMode;
  Color? backgroundColor;
  FakePlatformNavigationDelegate? navigationDelegate;
  int clearCacheCount = 0;

  /// Simulates JavaScript posting [message] on channel [name].
  void postMessage(String name, String message) {
    channels[name]!.onMessageReceived(JavaScriptMessage(message: message));
  }

  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) async {
    loadedHtml.add(html);
    loadedBaseUrls.add(baseUrl);
  }

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {
    this.javaScriptMode = javaScriptMode;
  }

  @override
  Future<void> setBackgroundColor(Color color) async {
    backgroundColor = color;
  }

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {
    navigationDelegate = handler as FakePlatformNavigationDelegate;
  }

  @override
  Future<void> addJavaScriptChannel(
    JavaScriptChannelParams javaScriptChannelParams,
  ) async {
    channels[javaScriptChannelParams.name] = javaScriptChannelParams;
  }

  @override
  Future<void> removeJavaScriptChannel(String javaScriptChannelName) async {
    channels.remove(javaScriptChannelName);
  }

  @override
  Future<void> runJavaScript(String javaScript) async {
    executedScripts.add(javaScript);
  }

  @override
  Future<void> clearCache() async {
    clearCacheCount++;
  }

  @override
  Future<void> enableZoom(bool enabled) async {}

  @override
  Future<void> setVerticalScrollBarEnabled(bool enabled) async {}

  @override
  Future<void> setHorizontalScrollBarEnabled(bool enabled) async {}

  @override
  Future<void> setOverScrollMode(WebViewOverScrollMode mode) async {}
}

/// Captures navigation callbacks so tests can drive them.
class FakePlatformNavigationDelegate extends PlatformNavigationDelegate {
  FakePlatformNavigationDelegate(super.params) : super.implementation();

  NavigationRequestCallback? onNavigationRequest;
  PageEventCallback? onPageStarted;
  PageEventCallback? onPageFinished;

  @override
  Future<void> setOnNavigationRequest(
    NavigationRequestCallback onNavigationRequest,
  ) async {
    this.onNavigationRequest = onNavigationRequest;
  }

  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async {
    this.onPageStarted = onPageStarted;
  }

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {
    this.onPageFinished = onPageFinished;
  }

  @override
  Future<void> setOnProgress(ProgressCallback onProgress) async {}

  @override
  Future<void> setOnWebResourceError(
    WebResourceErrorCallback onWebResourceError,
  ) async {}

  @override
  Future<void> setOnUrlChange(UrlChangeCallback onUrlChange) async {}

  /// Simulates the page finishing to load.
  void finishPage([String url = 'about:blank']) => onPageFinished?.call(url);

  /// Asks the widget whether a navigation should proceed.
  Future<NavigationDecision> request(
    String url, {
    bool isMainFrame = true,
  }) async {
    final cb = onNavigationRequest;
    if (cb == null) return NavigationDecision.navigate;
    return cb(NavigationRequest(url: url, isMainFrame: isMainFrame));
  }
}

/// Renders a placeholder box where the native view would be.
class FakePlatformWebViewWidget extends PlatformWebViewWidget {
  FakePlatformWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) =>
      const SizedBox.expand(key: Key('fake_webview'));
}
