/// HTML snippets used by the demo cards in `main.dart`.
library;

const String minimalHtml = '''
<h2>Hello, AutoHeightWebView</h2>
<p>This widget grows and shrinks to fit its HTML content, so it can live
inside a <code>ListView</code> or <code>Column</code> without a fixed height.</p>
''';

String dynamicHtml(int version) => '''
<h3>Version $version</h3>
${List.generate(version, (i) => '<p>Paragraph ${i + 1}: content added by the button.</p>').join()}
<div id="late"></div>
''';

/// Appended to the page after a delay, to show that late DOM changes resize
/// the widget too.
const String dynamicScript = '''
setTimeout(function () {
  var p = document.createElement('p');
  p.innerHTML = '<b>Added by JavaScript after 2 seconds.</b>';
  document.getElementById('late').appendChild(p);
}, 2000);
''';

const String imagesHtml = '''
<p>The height updates once each image has loaded.</p>
<img src="https://picsum.photos/id/1015/600/300" style="width:100%;border-radius:8px" alt="River valley">
<p>And another one below it.</p>
<img src="https://picsum.photos/id/1025/600/400" style="width:100%;border-radius:8px" alt="Pug">
''';

final String longHtml = '''
<h3>Long content</h3>
${List.generate(14, (i) => '<p>Line ${i + 1}. Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>').join()}
''';

const String linksHtml = '''
<p>Tap a link to see <code>onLinkTap</code> fire. Navigation is blocked
because <code>allowNavigation</code> is false.</p>
<ul>
  <li><a href="https://flutter.dev">flutter.dev</a></li>
  <li><a href="https://pub.dev/packages/auto_height_webview">pub.dev package</a></li>
</ul>
''';

const String themedHtml = '''
<h3>Themed content</h3>
<p>The text and link colours come from the app's <code>ColorScheme</code>,
so they follow light and dark mode.</p>
<blockquote>Switch your device theme to see this card update.</blockquote>
<p><a href="#">A styled link</a></p>
''';

const String fullDocumentHtml = '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <style>
      body { font-family: sans-serif; background: #fff3e0; color: #3e2723; padding: 12px; }
      table { border-collapse: collapse; width: 100%; }
      td, th { border: 1px solid #bcaaa4; padding: 6px; }
    </style>
  </head>
  <body>
    <h3>A complete HTML document</h3>
    <table>
      <tr><th>Platform</th><th>Supported</th></tr>
      <tr><td>Android</td><td>Yes</td></tr>
      <tr><td>iOS</td><td>Yes</td></tr>
      <tr><td>Web</td><td>Yes</td></tr>
    </table>
  </body>
</html>
''';

const String shortHtml = '<p>Short: a single line.</p>';

const String tallHtml = '''
<h3>Tall</h3>
<p>One.</p><p>Two.</p><p>Three.</p><p>Four.</p><p>Five.</p><p>Six.</p>
''';
