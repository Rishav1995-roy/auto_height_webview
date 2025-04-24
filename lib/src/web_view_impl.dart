// Implementation for mobile platforms (no dart:html imports)
import 'package:flutter/material.dart';

class WebViewImplementation extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // This is just a stub that should never be called on mobile platforms.
    // The actual implementation is in the main AutoHeightWebView class.
    throw UnimplementedError(
        'This file should not be used on mobile platforms.');
  }
}
