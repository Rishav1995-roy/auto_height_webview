import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Conditionally import based on platform
import 'web_view_impl.dart' if (dart.library.html) 'web_view_impl_web.dart';

/// A WebView widget that automatically adjusts its height based on content.
class AutoHeightWebView extends StatefulWidget {
  /// The HTML content to display.
  final String htmlContent;

  /// Initial height before content is measured.
  /// Defaults to 100.0 if not provided.
  final double? initialHeight;

  /// Minimum height constraint for the WebView.
  /// Defaults to 50.0 if not provided.
  final double? minHeight;

  /// Maximum height constraint for the WebView.
  final double? maxHeight;

  /// Callback fired when height changes.
  final Function(double height)? onHeightChanged;

  /// Additional styling for the WebView container.
  final BoxDecoration? decoration;

  /// JavaScript to execute after page load.
  final String? customScript;

  /// Whether to allow JavaScript execution.
  final bool enableJavaScript;

  /// Creating an AutoHeightWebView with HTML content
  const AutoHeightWebView({
    super.key,
    required this.htmlContent,
    this.initialHeight,
    this.minHeight,
    this.maxHeight,
    this.onHeightChanged,
    this.decoration,
    this.customScript,
    this.enableJavaScript = true,
  });

  @override
  State<AutoHeightWebView> createState() => _AutoHeightWebViewState();
}

class _AutoHeightWebViewState extends State<AutoHeightWebView> {
  late double _height;
  bool _isLoading = true;
  WebViewController? _controller;
  final String _heightMeasurementChannel = 'HeightMeasurementChannel';
  final bool _isIOS = !kIsWeb && Platform.isIOS;
  final UniqueKey _viewKey = UniqueKey();

  // Safe defaults
  double get _safeInitialHeight => widget.initialHeight ?? 100.0;
  double get _safeMinHeight => widget.minHeight ?? 50.0;
  BoxDecoration get _safeDecoration =>
      widget.decoration ?? const BoxDecoration(color: Colors.transparent);

  @override
  void dispose() {
    if (!kIsWeb) {
      // Special handling for iOS WebViews
      if (_isIOS) {
        // Ensure we give the platform enough time to clean up
        _controller = null;
        Future.delayed(const Duration(milliseconds: 250), () {
          // This is intentionally empty - just ensuring time for cleanup
        });
      } else {
        _controller?.clearCache();
      }
    }
    super.dispose();
  }

// Also, update the initState method to ensure we're not recreating an existing WebView
  @override
  void initState() {
    super.initState();
    _height = _safeInitialHeight;

    if (!kIsWeb) {
      // iOS-specific delay - needs to be longer than for Android
      final delay = _isIOS ? 200 : 50;
      Future.delayed(Duration(milliseconds: delay), () {
        if (mounted) {
          _setupMobileController();
        }
      });
    }
  }

  void _setupMobileController() {
    final controller = WebViewController();
    controller
      ..setJavaScriptMode(widget.enableJavaScript
          ? JavaScriptMode.unrestricted
          : JavaScriptMode.disabled)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => _injectHeightMeasurementScript(),
        ),
      )
      ..addJavaScriptChannel(
        _heightMeasurementChannel,
        onMessageReceived: (JavaScriptMessage message) {
          _updateHeight(double.tryParse(message.message) ?? _safeInitialHeight);
        },
      );

    _controller = controller;

    // Load HTML content
    _loadHtmlContent();
  }

  void _loadHtmlContent() {
    if (_controller == null) return;

    // Inject meta viewport tag for proper mobile rendering
    final htmlWithViewport = '''
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
          <style>
            body {
              margin: 0;
              padding: 0;
              font-family: sans-serif;
              overflow-x: hidden;
              width: 100%;
            }
          </style>
        </head>
        <body>
          ${widget.htmlContent}
        </body>
      </html>
    ''';

    _controller!.loadHtmlString(htmlWithViewport);
  }

  void _injectHeightMeasurementScript() {
    if (_controller == null) return;

    final script = '''
      function updateHeight() {
        const height = Math.max(
          document.body.scrollHeight,
          document.body.offsetHeight,
          document.documentElement.clientHeight,
          document.documentElement.scrollHeight,
          document.documentElement.offsetHeight
        );
        $_heightMeasurementChannel.postMessage(height);
      }
      
      // Initial measurement
      updateHeight();
      
      // Set up mutation observer to detect content changes
      const observer = new MutationObserver(updateHeight);
      observer.observe(document.body, { 
        attributes: true, 
        childList: true, 
        subtree: true 
      });
      
      // Handle window resize events
      window.addEventListener('resize', updateHeight);
      
      // Handle image and media loading
      window.addEventListener('load', updateHeight);
      
      // Custom script if provided
      ${widget.customScript ?? ''}
    ''';

    _controller!.runJavaScript(script);
    setState(() => _isLoading = false);
  }

  void _updateHeight(double newHeight) {
    if (newHeight != _height && mounted) {
      setState(() => _height = _constrainHeight(newHeight));
      widget.onHeightChanged?.call(_height);
    }
  }

  double _constrainHeight(double height) {
    double constrainedHeight = height;

    if (height < _safeMinHeight) {
      constrainedHeight = _safeMinHeight;
    } else if (widget.maxHeight != null && height > widget.maxHeight!) {
      constrainedHeight = widget.maxHeight!;
    }

    return constrainedHeight;
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return WebViewImplementation(
        htmlContent: widget.htmlContent,
        initialHeight: _safeInitialHeight,
        minHeight: _safeMinHeight,
        maxHeight: widget.maxHeight,
        onHeightChanged: widget.onHeightChanged,
        decoration: widget.decoration,
        customScript: widget.customScript,
        enableJavaScript: widget.enableJavaScript,
      );
    }

    // For iOS, wrap the WebViewWidget in a key-specific container
    Widget webViewContent = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _controller != null
            ? _isIOS
                ? KeyedSubtree(
                    key: _viewKey,
                    child: WebViewWidget(controller: _controller!),
                  )
                : WebViewWidget(controller: _controller!)
            : const SizedBox();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _height,
      constraints: BoxConstraints(
        minHeight: _safeMinHeight,
        maxHeight: widget.maxHeight ?? double.infinity,
      ),
      decoration: _safeDecoration,
      child: webViewContent,
    );
  }
}
