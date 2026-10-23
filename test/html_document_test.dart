import 'package:auto_height_webview/src/html_document.dart';
import 'package:flutter_test/flutter_test.dart';

String build(
  String html, {
  String id = 'test-id',
  MeasurementTransport transport = MeasurementTransport.channel,
  String? css,
  bool useDefaultStyles = true,
  String? baseHref,
  String? customScript,
  bool interceptLinks = false,
  bool allowNavigation = false,
}) =>
    buildHtmlDocument(
      html: html,
      instanceId: id,
      transport: transport,
      css: css,
      useDefaultStyles: useDefaultStyles,
      baseHref: baseHref,
      customScript: customScript,
      interceptLinks: interceptLinks,
      allowNavigation: allowNavigation,
    );

void main() {
  group('clampHeight', () {
    test('returns the value when within range', () {
      expect(clampHeight(120, 50, 300), 120);
    });
    test('raises values below min', () {
      expect(clampHeight(10, 50, 300), 50);
    });
    test('lowers values above max', () {
      expect(clampHeight(1000, 50, 300), 300);
    });
    test('null max means unbounded', () {
      expect(clampHeight(1e6, 50, null), 1e6);
    });
    test('min wins when max < min', () {
      expect(clampHeight(100, 200, 100), 200);
    });
    test('boundaries are inclusive', () {
      expect(clampHeight(50, 50, 300), 50);
      expect(clampHeight(300, 50, 300), 300);
    });
  });

  group('isFullDocument', () {
    test('detects <html and <!doctype case-insensitively', () {
      expect(isFullDocument('<HTML><body></body></HTML>'), isTrue);
      expect(isFullDocument('<!DocType html><p>x</p>'), isTrue);
      expect(isFullDocument('<html lang="en">'), isTrue);
    });
    test('fragments are not full documents', () {
      expect(isFullDocument('<p>Hello</p>'), isFalse);
      expect(isFullDocument(''), isFalse);
    });
    test('leading whitespace, BOM and comments are allowed', () {
      expect(isFullDocument('  \n<!doctype html><p>x</p>'), isTrue);
      expect(isFullDocument('\uFEFF<html><body></body></html>'), isTrue);
      expect(isFullDocument('<!-- a --> <!-- b -->\n<HTML>'), isTrue);
    });
    test('mentions of <html> inside a fragment are not documents', () {
      expect(isFullDocument('<iframe srcdoc="<html><body>x</body></html>">'),
          isFalse);
      expect(isFullDocument('<!-- <html> --><p>x</p>'), isFalse);
      expect(isFullDocument('<p>use &lt;!doctype html&gt;</p><html>'), isFalse);
      expect(isFullDocument('<htmlish>x</htmlish>'), isFalse);
      expect(isFullDocument('<!-- unterminated <html>'), isFalse);
    });
  });

  group('buildHtmlDocument: fragments', () {
    test('wraps a fragment in a complete document', () {
      final out = build('<p>Hello</p>');
      expect(out, startsWith('<!DOCTYPE html><html><head>'));
      expect(out, contains('<body><p>Hello</p></body></html>'));
      expect(out, contains('<meta charset="UTF-8">'));
      expect(out, contains('name="viewport"'));
    });

    test('includes default styles by default', () {
      expect(build('<p>x</p>'), contains(kDefaultStyles));
    });

    test('omits default styles when useDefaultStyles is false', () {
      final out = build('<p>x</p>', useDefaultStyles: false);
      expect(out, isNot(contains(kDefaultStyles)));
    });

    test('adds extra css', () {
      final out = build('<p>x</p>', css: 'p{color:red}');
      expect(out, contains('<style>p{color:red}</style>'));
    });

    test('ignores empty css', () {
      final out = build('<p>x</p>', css: '', useDefaultStyles: false);
      expect(out, isNot(contains('<style>')));
    });

    test('adds <base href> and escapes it', () {
      final out =
          build('<p>x</p>', baseHref: 'https://example.com/a?b=1&c="2"');
      expect(
          out,
          contains(
              '<base href="https://example.com/a?b=1&amp;c=&quot;2&quot;">'));
    });

    test('no <base> without baseHref', () {
      expect(build('<p>x</p>'), isNot(contains('<base')));
      expect(build('<p>x</p>', baseHref: ''), isNot(contains('<base')));
    });

    test('measurement script contains the instance id', () {
      final out = build('<p>x</p>', id: 'ahw-42-abc');
      expect(out, contains('"ahw-42-abc"'));
    });

    test('channel transport posts to HeightMeasurementChannel', () {
      final out = build('<p>x</p>');
      expect(out, contains('$kHeightMeasurementChannel.postMessage'));
      expect(out, isNot(contains('window.parent.postMessage')));
    });

    test('parentWindow transport posts to the parent window', () {
      final out =
          build('<p>x</p>', transport: MeasurementTransport.parentWindow);
      expect(out, contains('window.parent.postMessage'));
      expect(out, contains(kMessageSource));
      expect(out, isNot(contains('$kHeightMeasurementChannel.postMessage')));
    });

    test('includes customScript', () {
      final out = build('<p>x</p>', customScript: 'console.log("hi");');
      expect(out, contains('console.log("hi");'));
    });

    test('omits customScript when null', () {
      expect(build('<p>x</p>'), isNot(contains('console.error(e)')));
    });

    test('link interception is opt-in', () {
      expect(build('<p>x</p>'), isNot(contains("type: 'link'")));
      expect(build('<p>x</p>', interceptLinks: true), contains("type: 'link'"));
    });

    test('links are cancelled unless allowNavigation', () {
      expect(build('<a>x</a>', interceptLinks: true),
          contains('e.preventDefault();'));
      expect(build('<a>x</a>', interceptLinks: true, allowNavigation: true),
          isNot(contains('e.preventDefault();')));
    });

    test('safely encodes a hostile instance id', () {
      final out = build('<p>x</p>', id: 'a";alert(1);"');
      expect(out, contains(r'"a\";alert(1);\""'));
    });
  });

  group('buildHtmlDocument: full documents', () {
    test('does not wrap a full document a second time', () {
      final out = build(
          '<!DOCTYPE html><html><head><title>t</title></head><body>b</body></html>');
      expect('<html'.allMatches(out.toLowerCase()).length, 1);
      expect('<body'.allMatches(out.toLowerCase()).length, 1);
    });

    test('injects early content right after <head> and css before </head>', () {
      final out = build(
        '<html><head><title>t</title></head><body>b</body></html>',
        css: 'p{color:red}',
      );
      final head = out.indexOf('<head>');
      expect(out.indexOf('<meta charset', head), head + '<head>'.length);
      expect(out.indexOf('<style>p{color:red}</style>'),
          lessThan(out.indexOf('</head>')));
      expect(out.indexOf('<title>t</title>'),
          lessThan(out.indexOf('p{color:red}')));
      expect(out, contains('<body>b</body>'));
    });

    test('handles head tag with attributes and mixed case', () {
      final out = build('<HTML><HEAD lang="x"><TITLE>t</TITLE></HEAD>'
          '<BODY>b</BODY></HTML>');
      expect(out, contains('<HEAD lang="x"><meta charset'));
      expect(out, contains('"test-id"'));
    });

    test('creates a head when missing (after <html>)', () {
      final out =
          build('<html lang="en"><body>b</body></html>', customScript: 'x();');
      expect(out, contains('<html lang="en"><head><meta charset'));
      expect(out, contains('</head><body>b</body></html>'));
      expect(out, contains('x();'));
    });

    test('creates a head after a doctype with no <html> tag... if any', () {
      final out = build('<!doctype html><body>b</body>');
      expect(out, startsWith('<!doctype html><head>'));
      expect(out, contains('<body>b</body>'));
    });

    test('respects useDefaultStyles false and baseHref', () {
      final out = build(
        '<html><head></head><body>b</body></html>',
        useDefaultStyles: false,
        baseHref: 'https://example.com/',
      );
      expect(out, isNot(contains(kDefaultStyles)));
      expect(out, contains('<base href="https://example.com/">'));
    });
  });

  group('parseMeasurementMessage', () {
    test('parses a height message from a JSON string', () {
      final m = parseMeasurementMessage(
        '{"type":"height","height":123.5,"id":"a"}',
        expectedId: 'a',
      );
      expect(m!.type, 'height');
      expect(m.height, 123.5);
    });

    test('parses a link message', () {
      final m = parseMeasurementMessage(
        '{"type":"link","url":"https://x.y","id":"a"}',
        expectedId: 'a',
      );
      expect(m!.type, 'link');
      expect(m.url, 'https://x.y');
    });

    test('parses decoded web maps with the right source', () {
      final m = parseMeasurementMessage(
        {'source': kMessageSource, 'id': 'a', 'type': 'height', 'height': 10},
        expectedId: 'a',
      );
      expect(m!.height, 10);
    });

    test('rejects other ids, sources and malformed payloads', () {
      expect(
          parseMeasurementMessage('{"type":"height","height":1,"id":"b"}',
              expectedId: 'a'),
          isNull);
      expect(
          parseMeasurementMessage(
              {'source': 'other', 'id': 'a', 'type': 'height', 'height': 1},
              expectedId: 'a'),
          isNull);
      expect(parseMeasurementMessage('not json', expectedId: 'a'), isNull);
      expect(parseMeasurementMessage('123', expectedId: 'a'), isNull);
      expect(parseMeasurementMessage(null, expectedId: 'a'), isNull);
      expect(
          parseMeasurementMessage('{"type":"height","id":"a"}',
              expectedId: 'a'),
          isNull);
      expect(
          parseMeasurementMessage('{"type":"height","height":"9","id":"a"}',
              expectedId: 'a'),
          isNull);
      expect(
          parseMeasurementMessage('{"type":"link","id":"a"}', expectedId: 'a'),
          isNull);
      expect(
          parseMeasurementMessage('{"type":"zzz","id":"a"}', expectedId: 'a'),
          isNull);
    });
  });

  group('isSamePageAnchor', () {
    test('bare and about:blank anchors are same-page', () {
      expect(isSamePageAnchor('#top'), isTrue);
      expect(isSamePageAnchor('about:blank#top'), isTrue);
    });
    test('other URLs are not', () {
      expect(isSamePageAnchor('https://a.com/'), isFalse);
      expect(isSamePageAnchor('https://a.com/#x'), isFalse);
    });
    test('matches baseUrl when given', () {
      expect(isSamePageAnchor('https://a.com/p#x', baseUrl: 'https://a.com/p'),
          isTrue);
      expect(isSamePageAnchor('https://b.com/p#x', baseUrl: 'https://a.com/p'),
          isFalse);
    });
  });

  test('generateInstanceId returns unique ids', () {
    final ids = {for (var i = 0; i < 50; i++) generateInstanceId()};
    expect(ids.length, 50);
  });
}
