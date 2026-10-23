import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// Mobile (webview_flutter) by default, iframe implementation on web.
import 'web_view_impl.dart'
    if (dart.library.js_interop) 'web_view_impl_web.dart';

/// A widget that renders HTML and sizes itself to the content height.
///
/// On Android, iOS and macOS it uses `webview_flutter`; on the web it renders
/// the HTML inside an `<iframe>`. Both report the document height through an
/// injected script, so the widget can live inside a `ListView`,
/// `SingleChildScrollView` or `Column` without bounded height.
///
/// Live height tracking requires JavaScript. With `enableJavaScript: false`
/// the height stays at [initialHeight] on mobile; on the web it is measured
/// once from the parent page when the iframe loads.
///
/// ```dart
/// AutoHeightWebView(
///   htmlContent: '<h1>Hello</h1><p>World</p>',
///   maxHeight: 600,
///   onLinkTap: (url) => launchUrl(Uri.parse(url)),
/// )
/// ```
class AutoHeightWebView extends StatefulWidget {
  /// Creates a widget that shows [htmlContent] and fits its height.
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
    this.css,
    this.useDefaultStyles = true,
    this.baseUrl,
    this.onLinkTap,
    this.allowNavigation = false,
    this.loadingBuilder,
    this.onPageFinished,
    this.scrollWhenClamped = false,
    this.gestureRecognizers,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
  });

  /// The HTML to display. May be a fragment or a full document; a full
  /// document (starting with `<html` or `<!doctype`) is not wrapped again.
  final String htmlContent;

  /// Height used before the content is measured. Defaults to 100.
  final double? initialHeight;

  /// Minimum height. Defaults to 50.
  final double? minHeight;

  /// Maximum height. When the content is taller, the widget stops growing
  /// (see [scrollWhenClamped]). Unbounded when null.
  final double? maxHeight;

  /// Called with the new (clamped) height whenever it changes.
  final ValueChanged<double>? onHeightChanged;

  /// Decoration of the container around the WebView.
  final BoxDecoration? decoration;

  /// JavaScript run after the page has loaded.
  final String? customScript;

  /// Whether JavaScript is enabled. Live height measurement needs it. When
  /// false, the height stays at [initialHeight] on mobile; on the web it is
  /// measured once, at load, from the parent page.
  final bool enableJavaScript;

  /// Extra CSS appended to the document `<head>`.
  final String? css;

  /// Whether to reset the body margin/padding and use a sans-serif font.
  /// When false, no styles are forced on the document.
  final bool useDefaultStyles;

  /// Base URL for relative links and resources. Passed to `loadHtmlString`
  /// on mobile and used as `<base href>` on web.
  final String? baseUrl;

  /// Called with the URL when the user taps a link or the page tries to
  /// navigate away.
  final ValueChanged<String>? onLinkTap;

  /// Whether navigation inside the view is allowed after the first load.
  /// When false, navigation is blocked and only reported to [onLinkTap];
  /// when true it proceeds ([onLinkTap] is still called).
  final bool allowNavigation;

  /// Builds the loading indicator shown until the page finishes loading.
  /// Defaults to a centered [CircularProgressIndicator]; return
  /// `SizedBox.shrink()` to show nothing.
  final WidgetBuilder? loadingBuilder;

  /// Called once the page has finished loading.
  final VoidCallback? onPageFinished;

  /// When true and [maxHeight] is reached, the content scrolls inside the
  /// view (mobile: vertical drags go to the WebView; web: iframe scrolls).
  final bool scrollWhenClamped;

  /// Gestures the WebView claims (mobile only). Overrides the default, which
  /// is empty, or a vertical drag when [scrollWhenClamped] applies.
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  /// Duration of the height animation.
  final Duration animationDuration;

  /// Curve of the height animation.
  final Curve animationCurve;

  @override
  // The state class depends on the platform (mobile WebView or web iframe).
  // ignore: no_logic_in_create_state
  State<AutoHeightWebView> createState() => createPlatformState();
}
