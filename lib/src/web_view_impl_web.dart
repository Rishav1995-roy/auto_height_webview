// Web implementation: an <iframe> using package:web + dart:js_interop, so it
// compiles to both JS and WebAssembly. Imported only where
// `dart.library.js_interop` is available.
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'auto_height_webview.dart';
import 'html_document.dart';

/// Creates the state used on the web.
State<AutoHeightWebView> createPlatformState() => _WebState();

class _WebState extends State<AutoHeightWebView> {
  late final String _id;
  late final String _viewType;
  late final web.HTMLIFrameElement _iframe;
  late final JSFunction _messageListener;
  late final JSFunction _loadListener;
  late double _rawHeight;
  late double _height;
  bool _loading = true;

  double get _min => widget.minHeight ?? 50.0;

  @override
  void initState() {
    super.initState();
    _id = generateInstanceId();
    _viewType = 'auto-height-webview-$_id';
    _rawHeight = widget.initialHeight ?? 100.0;
    _height = clampHeight(_rawHeight, _min, widget.maxHeight);

    _iframe = web.HTMLIFrameElement()
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%';
    _applyScrolling();
    _applyDocument();

    ui_web.platformViewRegistry
        .registerViewFactory(_viewType, (int _) => _iframe);

    _messageListener = _onMessage.toJS;
    _loadListener = _onLoad.toJS;
    web.window.addEventListener('message', _messageListener);
    _iframe.addEventListener('load', _loadListener);
  }

  @override
  void didUpdateWidget(AutoHeightWebView old) {
    super.didUpdateWidget(old);
    if (old.enableJavaScript != widget.enableJavaScript ||
        old.htmlContent != widget.htmlContent ||
        old.css != widget.css ||
        old.baseUrl != widget.baseUrl ||
        old.customScript != widget.customScript ||
        old.useDefaultStyles != widget.useDefaultStyles ||
        old.allowNavigation != widget.allowNavigation) {
      _loading = true;
      _applyDocument();
    } else if (old.minHeight != widget.minHeight ||
        old.maxHeight != widget.maxHeight) {
      _applyHeight();
    }
    _applyScrolling();
  }

  @override
  void dispose() {
    web.window.removeEventListener('message', _messageListener);
    _iframe.removeEventListener('load', _loadListener);
    super.dispose();
  }

  void _applyDocument() {
    if (widget.enableJavaScript) {
      _iframe.removeAttribute('sandbox');
    } else {
      // Scripts blocked; same-origin kept so styles/links behave normally.
      _iframe.setAttribute('sandbox', 'allow-same-origin');
    }
    _iframe.srcdoc = buildHtmlDocument(
      html: widget.htmlContent,
      instanceId: _id,
      transport: MeasurementTransport.parentWindow,
      css: widget.css,
      useDefaultStyles: widget.useDefaultStyles,
      baseHref: widget.baseUrl,
      customScript: widget.customScript,
      interceptLinks: true,
      allowNavigation: widget.allowNavigation,
    ).toJS;
  }

  bool get _clamped {
    final max = widget.maxHeight;
    return max != null && _rawHeight > max;
  }

  void _applyScrolling() {
    final scroll = widget.scrollWhenClamped && _clamped;
    _iframe.style.overflow = scroll ? 'auto' : 'hidden';
    _iframe.scrolling = scroll ? 'auto' : 'no';
  }

  void _onLoad(web.Event _) {
    if (!mounted) return;
    if (!widget.enableJavaScript) _measureFromParent();
    setState(() => _loading = false);
    widget.onPageFinished?.call();
  }

  /// Scripts are blocked in the sandboxed iframe, so measure it from here.
  /// The iframe keeps `allow-same-origin`, which makes its document readable.
  /// This happens once, at load.
  void _measureFromParent() {
    try {
      final root = _iframe.contentDocument?.documentElement;
      if (root == null) return;
      final height = root.scrollHeight;
      if (height <= 0) return;
      _rawHeight = height.toDouble();
      _applyHeight();
      _applyScrolling();
    } catch (_) {
      // Document not readable: keep the current height.
    }
  }

  void _onMessage(web.Event event) {
    if (!mounted) return;
    final data = (event as web.MessageEvent).data.dartify();
    final parsed = parseMeasurementMessage(data, expectedId: _id);
    if (parsed == null) return;
    if (parsed.type == 'height') {
      _rawHeight = parsed.height!;
      _applyHeight();
      _applyScrolling();
    } else if (parsed.type == 'link') {
      widget.onLinkTap?.call(parsed.url!);
    }
  }

  void _applyHeight() {
    final clamped = clampHeight(_rawHeight, _min, widget.maxHeight);
    if (clamped == _height) return;
    setState(() => _height = clamped);
    widget.onHeightChanged?.call(clamped);
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
          Positioned.fill(child: HtmlElementView(viewType: _viewType)),
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
