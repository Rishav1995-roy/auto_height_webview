import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Name of the JavaScript channel used on mobile platforms.
const String kHeightMeasurementChannel = 'HeightMeasurementChannel';

/// `source` value stamped on every message posted from an iframe on web.
const String kMessageSource = 'auto_height_webview';

/// How the injected script reports measurements back to Dart.
enum MeasurementTransport {
  /// `HeightMeasurementChannel.postMessage(jsonString)` (mobile WebView).
  channel,

  /// `window.parent.postMessage({source, id, type, ...}, '*')` (web iframe).
  parentWindow,
}

/// A message sent from the measurement script to Dart.
@immutable
class MeasurementMessage {
  /// Creates a message.
  const MeasurementMessage({
    required this.type,
    required this.id,
    this.height,
    this.url,
  });

  /// `height` or `link`.
  final String type;

  /// Id of the widget instance that produced the message.
  final String id;

  /// Measured content height in logical pixels (`height` messages).
  final double? height;

  /// Tapped link (`link` messages).
  final String? url;
}

/// Clamps [value] between [min] and [max] (`max` may be null).
///
/// If [max] is smaller than [min], [min] wins.
double clampHeight(double value, double min, double? max) {
  var result = value;
  if (max != null && result > max) result = max;
  if (result < min) result = min;
  return result;
}

/// Parses a raw message from the measurement script.
///
/// [raw] is either a JSON string (mobile) or a decoded map (web). Returns
/// null when the message is malformed, was not produced by this package, or
/// its id differs from [expectedId].
MeasurementMessage? parseMeasurementMessage(
  Object? raw, {
  required String expectedId,
}) {
  try {
    var data = raw;
    if (data is String) data = jsonDecode(data);
    if (data is! Map) return null;
    final source = data['source'];
    if (source != null && source != kMessageSource) return null;
    if (data['id'] != expectedId) return null;
    final type = data['type'];
    if (type == 'height') {
      final height = data['height'];
      if (height is! num || !height.isFinite) return null;
      return MeasurementMessage(
        type: 'height',
        id: expectedId,
        height: height.toDouble(),
      );
    }
    if (type == 'link') {
      final url = data['url'];
      if (url is! String) return null;
      return MeasurementMessage(type: 'link', id: expectedId, url: url);
    }
  } catch (_) {
    // Malformed payload: ignore.
  }
  return null;
}

/// Whether [url] only moves within the page that was loaded from HTML
/// (`#anchor`), which must not be reported as a link tap on mobile.
bool isSamePageAnchor(String url, {String? baseUrl}) {
  final hash = url.indexOf('#');
  if (hash < 0) return false;
  final head = url.substring(0, hash);
  if (head.isEmpty || head == 'about:blank' || head.startsWith('data:')) {
    return true;
  }
  if (baseUrl != null) {
    final base = baseUrl.split('#').first;
    return head == base;
  }
  return false;
}

final RegExp _fullDocument = RegExp(
  r'^\uFEFF?\s*(?:<!--[\s\S]*?-->\s*)*(?:<!doctype|<html(?=[\s>/]))',
  caseSensitive: false,
);

/// Whether [html] is already a complete document.
///
/// True only when the markup starts (after optional whitespace, a BOM and
/// comments) with `<!doctype` or `<html`, so a fragment that merely mentions
/// `<html>` (an `srcdoc` attribute, a comment, a code sample) is not
/// mistaken for one.
bool isFullDocument(String html) => _fullDocument.hasMatch(html);

/// Default styles applied when `useDefaultStyles` is true.
const String kDefaultStyles = 'body{margin:0;padding:0;'
    'font-family:sans-serif;overflow-x:hidden;width:100%;}';

/// Builds the JavaScript that measures the document height and reports it.
///
/// The script is idempotent (`window.__ahwInstalled`). Height is observed with
/// `ResizeObserver` (falling back to `MutationObserver`), plus capture-phase
/// `load` events, `document.fonts.ready` and window resize. Updates are
/// throttled with `requestAnimationFrame` and only posted when the value
/// changes. When [interceptLinks] is true, anchor clicks are reported as
/// `link` messages (and cancelled unless [allowNavigation]).
String buildMeasurementScript({
  required String instanceId,
  required MeasurementTransport transport,
  bool interceptLinks = false,
  bool allowNavigation = false,
}) {
  final viaChannel = transport == MeasurementTransport.channel;
  return '''
(function () {
  if (window.__ahwInstalled) return;
  window.__ahwInstalled = true;
  var ID = ${jsonEncode(instanceId)};
  function post(msg) {
    msg.id = ID;
    try {
      ${viaChannel ? '$kHeightMeasurementChannel.postMessage(JSON.stringify(msg));' : "msg.source = '$kMessageSource'; window.parent.postMessage(msg, '*');"}
    } catch (e) {}
  }
  var last = -1, queued = false;
  function measure() {
    var de = document.documentElement, b = document.body;
    var h = de ? de.getBoundingClientRect().height : 0;
    if (b) h = Math.max(h, b.getBoundingClientRect().bottom + (window.scrollY || 0));
    return Math.ceil(h);
  }
  function report() {
    queued = false;
    var h = measure();
    if (h !== last) { last = h; post({ type: 'height', height: h }); }
  }
  function schedule() {
    if (queued) return;
    queued = true;
    if (window.requestAnimationFrame) window.requestAnimationFrame(report);
    else setTimeout(report, 16);
  }
  var observed = false;
  function observe() {
    if (observed || !document.body) return;
    observed = true;
    if (window.ResizeObserver) {
      var ro = new ResizeObserver(schedule);
      ro.observe(document.documentElement);
      ro.observe(document.body);
    } else if (window.MutationObserver) {
      new MutationObserver(schedule).observe(document.documentElement,
        { attributes: true, childList: true, subtree: true, characterData: true });
    }
    schedule();
  }
  document.addEventListener('load', schedule, true);
  window.addEventListener('load', schedule);
  window.addEventListener('resize', schedule);
  if (document.fonts && document.fonts.ready) document.fonts.ready.then(schedule);
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', observe);
  else observe();
${interceptLinks ? '''
  document.addEventListener('click', function (e) {
    var el = e.target;
    while (el && el.nodeType === 1 && !(el.tagName === 'A' && el.getAttribute('href') !== null)) el = el.parentNode;
    if (!el || el.nodeType !== 1) return;
    var href = el.getAttribute('href');
    if (!href || href.charAt(0) === '#' || /^javascript:/i.test(href)) return;
    post({ type: 'link', url: el.href });
    ${allowNavigation ? '' : 'e.preventDefault();'}
  }, true);
''' : ''}
})();
''';
}

/// Builds the final HTML document shown by the WebView / iframe.
///
/// Plain fragments are wrapped in a new document. If [html] is already a full
/// document (starting with `<html` or `<!doctype`), the meta tag, styles and scripts are
/// injected into its `<head>` instead (a head is created when missing).
String buildHtmlDocument({
  required String html,
  required String instanceId,
  required MeasurementTransport transport,
  String? css,
  bool useDefaultStyles = true,
  String? baseHref,
  String? customScript,
  bool interceptLinks = false,
  bool allowNavigation = false,
}) {
  final early = StringBuffer()
    ..write('<meta charset="UTF-8">')
    ..write('<meta name="viewport" content="width=device-width, '
        'initial-scale=1.0, maximum-scale=1.0, user-scalable=no">');
  if (baseHref != null && baseHref.isNotEmpty) {
    early.write(
        '<base href="${const HtmlEscape(HtmlEscapeMode.attribute).convert(baseHref)}">');
  }
  if (useDefaultStyles) early.write('<style>$kDefaultStyles</style>');
  early.write('<script>${buildMeasurementScript(
    instanceId: instanceId,
    transport: transport,
    interceptLinks: interceptLinks,
    allowNavigation: allowNavigation,
  )}</script>');

  final late = StringBuffer();
  if (css != null && css.isNotEmpty) late.write('<style>$css</style>');
  if (customScript != null && customScript.isNotEmpty) {
    late.write('<script>window.addEventListener("load",function(){'
        'try{$customScript\n}catch(e){console.error(e);}});</script>');
  }

  if (!isFullDocument(html)) {
    return '<!DOCTYPE html><html><head>$early$late</head>'
        '<body>$html</body></html>';
  }

  final headOpen = RegExp(r'<head(\s[^>]*)?>', caseSensitive: false);
  final headClose = RegExp(r'</head\s*>', caseSensitive: false);
  final open = headOpen.firstMatch(html);
  if (open != null) {
    var result = html.replaceRange(open.end, open.end, early.toString());
    final close = headClose.firstMatch(result);
    if (close != null) {
      return result.replaceRange(close.start, close.start, late.toString());
    }
    result = result.replaceRange(
        open.end + early.length, open.end + early.length, late.toString());
    return result;
  }
  final head = '<head>$early$late</head>';
  final htmlOpen =
      RegExp(r'<html(\s[^>]*)?>', caseSensitive: false).firstMatch(html);
  if (htmlOpen != null) {
    return html.replaceRange(htmlOpen.end, htmlOpen.end, head);
  }
  final doctype =
      RegExp(r'<!doctype[^>]*>', caseSensitive: false).firstMatch(html);
  if (doctype != null) {
    return html.replaceRange(doctype.end, doctype.end, head);
  }
  return '$head$html';
}

/// Creates a unique id for one widget instance.
String generateInstanceId() {
  _instanceCounter++;
  final salt = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  return 'ahw-$_instanceCounter-$salt';
}

int _instanceCounter = 0;
