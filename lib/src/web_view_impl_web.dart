// Implementation for web platform only
// This file is only imported in web environments
import 'dart:async';
import 'dart:math' as math;
// These imports will only be resolved on web platforms
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class WebViewImplementation extends StatefulWidget {
  final String htmlContent;
  final double initialHeight;
  final double minHeight;
  final double? maxHeight;
  final Function(double height)? onHeightChanged;
  final BoxDecoration? decoration;
  final String? customScript;
  final bool enableJavaScript;

  const WebViewImplementation({
    super.key,
    required this.htmlContent,
    required this.initialHeight,
    required this.minHeight,
    this.maxHeight,
    this.onHeightChanged,
    this.decoration,
    this.customScript,
    required this.enableJavaScript,
  });

  @override
  State<WebViewImplementation> createState() => _WebViewImplementationState();
}

class _WebViewImplementationState extends State<WebViewImplementation> {
  late String _viewId;
  late html.IFrameElement _iframeElement;
  late double _height;
  StreamSubscription? _subscription;
  final _heightStreamController = StreamController<double>();

  // Safe defaults
  BoxDecoration get _safeDecoration =>
      widget.decoration ?? const BoxDecoration(color: Colors.transparent);

  @override
  void initState() {
    super.initState();
    _height = widget.initialHeight;
    _setupWebView();
  }

  void _setupWebView() {
    // Create a unique ID for this instance using both timestamp and a random value
    // This helps prevent ID collisions during hot reload
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = 10000 + (100000 * math.Random().nextDouble()).toInt();
    _viewId = 'auto-height-webview-$timestamp-$random';

    // Create an iframe element
    _iframeElement = html.IFrameElement()
      ..style.border = 'none'
      ..style.height = '${widget.initialHeight}px'
      ..style.width = '100%'
      ..style.overflow = 'hidden'
      ..srcdoc = _getHtmlContent()
      ..id = _viewId;

    // Register the view with Flutter web
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) => _iframeElement,
    );

    // Setup message listener for height updates
    html.window.addEventListener('message', _handleMessage);

    // Listen for height changes
    _subscription = _heightStreamController.stream.listen(_updateHeight);
  }

  String _getHtmlContent() {
    // Inject the script to measure content height
    return '''
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
          <script type="text/javascript">
            // Script to measure and report content height
            function updateHeight() {
              const height = Math.max(
                document.body.scrollHeight,
                document.body.offsetHeight,
                document.documentElement.clientHeight,
                document.documentElement.scrollHeight,
                document.documentElement.offsetHeight
              );
              window.parent.postMessage({ type: 'resize', height: height }, '*');
            }
            
            document.addEventListener('DOMContentLoaded', function() {
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
              
              // Add event listeners to all images
              document.querySelectorAll('img').forEach(img => {
                img.addEventListener('load', updateHeight);
              });
              
              ${widget.customScript ?? ''}
            });
          </script>
        </head>
        <body>
          ${widget.htmlContent}
        </body>
      </html>
    ''';
  }

  void _handleMessage(html.Event event) {
    if (event is html.MessageEvent) {
      try {
        final data = event.data;
        if (data is Map && data['type'] == 'resize') {
          final height = data['height'];
          if (height is num) {
            _heightStreamController.add(height.toDouble());
          }
        }
      } catch (e) {
        debugPrint('Error handling message: $e');
      }
    }
  }

  void _updateHeight(double newHeight) {
    if (newHeight != _height && mounted) {
      setState(() {
        _height = _constrainHeight(newHeight);
        _iframeElement.style.height = '${_height}px';
      });
      widget.onHeightChanged?.call(_height);
    }
  }

  double _constrainHeight(double height) {
    double constrainedHeight = height;

    if (height < widget.minHeight) {
      constrainedHeight = widget.minHeight;
    } else if (widget.maxHeight != null && height > widget.maxHeight!) {
      constrainedHeight = widget.maxHeight!;
    }

    return constrainedHeight;
  }

  @override
  void dispose() {
    html.window.removeEventListener('message', _handleMessage);
    _subscription?.cancel();
    _heightStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _height,
      constraints: BoxConstraints(
        minHeight: widget.minHeight,
        maxHeight: widget.maxHeight ?? double.infinity,
      ),
      decoration: _safeDecoration,
      child: HtmlElementView(viewType: _viewId),
    );
  }
}
