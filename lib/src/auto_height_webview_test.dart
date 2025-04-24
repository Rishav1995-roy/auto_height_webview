// lib/src/auto_height_webview_test.dart (for testing only)
import 'package:flutter/material.dart';

/// A simplified version of AutoHeightWebView for testing
class MockAutoHeightWebView extends StatelessWidget {
  final String htmlContent;
  final double? initialHeight;
  final double? minHeight;
  final double? maxHeight;
  final BoxDecoration? decoration;
  final Function(double)? onHeightChanged;
  final String? customScript;
  final bool enableJavaScript;
  
  // These match the values in the real implementation
  double get _safeInitialHeight => initialHeight ?? 100.0;
  double get _safeMinHeight => minHeight ?? 50.0;
  
  const MockAutoHeightWebView({
    Key? key,
    required this.htmlContent,
    this.initialHeight,
    this.minHeight,
    this.maxHeight,
    this.decoration,
    this.onHeightChanged,
    this.customScript,
    this.enableJavaScript = true,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _safeInitialHeight,
      constraints: BoxConstraints(
        minHeight: _safeMinHeight,
        maxHeight: maxHeight ?? double.infinity,
      ),
      decoration: decoration ?? const BoxDecoration(
        color: Colors.transparent,
      ),
      child: const Center(
        child: Text("Mock WebView")
      ),
    );
  }
}