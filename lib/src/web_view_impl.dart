// Mobile / desktop implementation (webview_flutter). No web-only imports.
import 'dart:async';

import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'auto_height_webview.dart';
import 'html_document.dart';

/// Creates the state used on non-web platforms.
State<AutoHeightWebView> createPlatformState() => _MobileState();

class _MobileState extends State<AutoHeightWebView> {
  late final String _id;
  late final WebViewController _controller;
  late double _rawHeight;
  late double _height;
  bool _loading = true;
  bool _pageLoaded = false;
  bool _wasClamped = false;

  double get _min => widget.minHeight ?? 50.0;

  @override
  void initState() {
    super.initState();
    _id = generateInstanceId();
    _rawHeight = widget.initialHeight ?? 100.0;
    _height = clampHeight(_rawHeight, _min, widget.maxHeight);
    _controller = WebViewController()
      ..setJavaScriptMode(widget.enableJavaScript
          ? JavaScriptMode.unrestricted
          : JavaScriptMode.disabled)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: _onNavigationRequest,
        onPageFinished: _onPageFinished,
      ))
      ..addJavaScriptChannel(
        kHeightMeasurementChannel,
        onMessageReceived: _onMessage,
      );
    _load();
  }

  @override
  void didUpdateWidget(AutoHeightWebView old) {
    super.didUpdateWidget(old);
    final jsChanged = old.enableJavaScript != widget.enableJavaScript;
    if (jsChanged) {
      _controller.setJavaScriptMode(widget.enableJavaScript
          ? JavaScriptMode.unrestricted
          : JavaScriptMode.disabled);
    }
    if (jsChanged ||
        old.htmlContent != widget.htmlContent ||
        old.css != widget.css ||
        old.baseUrl != widget.baseUrl ||
        old.customScript != widget.customScript ||
        old.useDefaultStyles != widget.useDefaultStyles) {
      _loading = true;
      _load();
    } else if (old.minHeight != widget.minHeight ||
        old.maxHeight != widget.maxHeight) {
      _applyHeight();
    }
  }

  void _load() {
    _pageLoaded = false;
    final html = buildHtmlDocument(
      html: widget.htmlContent,
      instanceId: _id,
      transport: MeasurementTransport.channel,
      css: widget.css,
      useDefaultStyles: widget.useDefaultStyles,
      customScript: widget.customScript,
    );
    unawaited(_controller.loadHtmlString(html, baseUrl: widget.baseUrl));
  }

  FutureOr<NavigationDecision> _onNavigationRequest(NavigationRequest r) {
    if (!_pageLoaded || !r.isMainFrame) return NavigationDecision.navigate;
    if (isSamePageAnchor(r.url, baseUrl: widget.baseUrl)) {
      return NavigationDecision.navigate;
    }
    widget.onLinkTap?.call(r.url);
    return widget.allowNavigation
        ? NavigationDecision.navigate
        : NavigationDecision.prevent;
  }

  void _onPageFinished(String url) {
    if (!mounted) return;
    if (_pageLoaded && widget.enableJavaScript) {
      // A page we did not load (allowed in-view navigation) has no measuring
      // script. The script is idempotent, so injecting it again is harmless.
      unawaited(_controller
          .runJavaScript(buildMeasurementScript(
            instanceId: _id,
            transport: MeasurementTransport.channel,
          ))
          .catchError((Object _) {}));
    }
    _pageLoaded = true;
    setState(() => _loading = false);
    widget.onPageFinished?.call();
  }

  void _onMessage(JavaScriptMessage message) {
    if (!mounted) return;
    final parsed = parseMeasurementMessage(message.message, expectedId: _id);
    if (parsed == null) return;
    if (parsed.type == 'height') {
      _rawHeight = parsed.height!;
      _applyHeight();
    } else if (parsed.type == 'link') {
      widget.onLinkTap?.call(parsed.url!);
    }
  }

  void _applyHeight() {
    final clamped = clampHeight(_rawHeight, _min, widget.maxHeight);
    final isClamped = _isClamped;
    final clampFlipped = widget.scrollWhenClamped && isClamped != _wasClamped;
    _wasClamped = isClamped;
    if (clamped == _height) {
      // Only the clamping state (scrolling) may have changed.
      if (clampFlipped) setState(() {});
      return;
    }
    setState(() => _height = clamped);
    widget.onHeightChanged?.call(clamped);
  }

  bool get _isClamped {
    final max = widget.maxHeight;
    return max != null && _rawHeight > max;
  }

  Set<Factory<OneSequenceGestureRecognizer>> get _gestures {
    final custom = widget.gestureRecognizers;
    if (custom != null) return custom;
    if (widget.scrollWhenClamped && _isClamped) {
      return {
        Factory<VerticalDragGestureRecognizer>(
            () => VerticalDragGestureRecognizer())
      };
    }
    return const <Factory<OneSequenceGestureRecognizer>>{};
  }

  @override
  Widget build(BuildContext context) {
    final loader = widget.loadingBuilder?.call(context) ??
        const Center(child: CircularProgressIndicator());
    return AnimatedContainer(
      duration: widget.animationDuration,
      curve: widget.animationCurve,
      height: _height,
      decoration:
          widget.decoration ?? const BoxDecoration(color: Colors.transparent),
      child: Stack(
        children: [
          Positioned.fill(
            child: WebViewWidget(
              controller: _controller,
              gestureRecognizers: _gestures,
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _loading
                    ? KeyedSubtree(key: const ValueKey('loader'), child: loader)
                    : const SizedBox.shrink(key: ValueKey('done')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
