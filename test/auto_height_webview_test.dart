import 'dart:convert';

import 'package:auto_height_webview/auto_height_webview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'support/fake_webview_platform.dart';

late FakeWebViewPlatform platform;

FakePlatformWebViewController get ctrl => platform.controller;

/// Extracts the instance id the widget put into the loaded document.
String idOf(FakePlatformWebViewController c) {
  final m = RegExp(r'var ID = ("[^"]*");').firstMatch(c.loadedHtml.last)!;
  return jsonDecode(m.group(1)!) as String;
}

void sendHeight(WidgetTester tester, num height, {String? id}) {
  ctrl.postMessage(
    kChannel,
    jsonEncode({'type': 'height', 'height': height, 'id': id ?? idOf(ctrl)}),
  );
}

const kChannel = 'HeightMeasurementChannel';

Future<void> pumpWidget(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ));
}

double heightOf(WidgetTester tester) =>
    tester.getSize(find.byType(AnimatedContainer)).height;

/// Builds the frame that starts the animations, then runs them to the end.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUp(() {
    platform = FakeWebViewPlatform();
    WebViewPlatform.instance = platform;
  });

  group('rendering', () {
    testWidgets('uses the default initial height of 100', (tester) async {
      await pumpWidget(
          tester, const AutoHeightWebView(htmlContent: '<p>a</p>'));
      expect(heightOf(tester), 100);
    });

    testWidgets('uses a custom initialHeight', (tester) async {
      await pumpWidget(
        tester,
        const AutoHeightWebView(htmlContent: '<p>a</p>', initialHeight: 220),
      );
      expect(heightOf(tester), 220);
    });

    testWidgets('loads the document once, with fragment wrapped',
        (tester) async {
      await pumpWidget(
          tester, const AutoHeightWebView(htmlContent: '<p>a</p>'));
      expect(ctrl.loadedHtml, hasLength(1));
      expect(ctrl.loadedHtml.single, contains('<body><p>a</p></body>'));
      expect(ctrl.channels.keys, contains(kChannel));
      expect(ctrl.javaScriptMode, JavaScriptMode.unrestricted);
    });

    testWidgets('disabled JavaScript is forwarded', (tester) async {
      await pumpWidget(
        tester,
        const AutoHeightWebView(htmlContent: 'a', enableJavaScript: false),
      );
      expect(ctrl.javaScriptMode, JavaScriptMode.disabled);
    });

    testWidgets('css, customScript and baseUrl reach the platform',
        (tester) async {
      await pumpWidget(
        tester,
        const AutoHeightWebView(
          htmlContent: '<p>a</p>',
          css: 'p{color:red}',
          customScript: 'window.hello = 1;',
          baseUrl: 'https://example.com/',
          useDefaultStyles: false,
        ),
      );
      final html = ctrl.loadedHtml.single;
      expect(html, contains('p{color:red}'));
      expect(html, contains('window.hello = 1;'));
      expect(ctrl.loadedBaseUrls.single, 'https://example.com/');
    });

    testWidgets('applies the decoration', (tester) async {
      await pumpWidget(
        tester,
        const AutoHeightWebView(
          htmlContent: 'a',
          decoration: BoxDecoration(color: Colors.red),
        ),
      );
      final box = tester
          .widget<AnimatedContainer>(find.byType(AnimatedContainer))
          .decoration as BoxDecoration;
      expect(box.color, Colors.red);
    });
  });

  group('height', () {
    testWidgets('a height message resizes the widget', (tester) async {
      await pumpWidget(
          tester, const AutoHeightWebView(htmlContent: '<p>a</p>'));
      sendHeight(tester, 300);
      await settle(tester);
      expect(heightOf(tester), 300);
    });

    testWidgets('animates rather than jumping', (tester) async {
      await pumpWidget(
        tester,
        const AutoHeightWebView(
          htmlContent: 'a',
          animationDuration: Duration(milliseconds: 400),
        ),
      );
      sendHeight(tester, 300);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final mid = heightOf(tester);
      expect(mid, greaterThan(100));
      expect(mid, lessThan(300));
      await tester.pump(const Duration(milliseconds: 400));
      expect(heightOf(tester), 300);
    });

    testWidgets('clamps to minHeight', (tester) async {
      final seen = <double>[];
      await pumpWidget(
        tester,
        AutoHeightWebView(
          htmlContent: 'a',
          minHeight: 80,
          onHeightChanged: seen.add,
        ),
      );
      sendHeight(tester, 10);
      await settle(tester);
      expect(heightOf(tester), 80);
      expect(seen, [80]);
    });

    testWidgets('clamps to maxHeight', (tester) async {
      await pumpWidget(
        tester,
        const AutoHeightWebView(htmlContent: 'a', maxHeight: 400),
      );
      sendHeight(tester, 5000);
      await settle(tester);
      expect(heightOf(tester), 400);
    });

    testWidgets('onHeightChanged reports the clamped value', (tester) async {
      final seen = <double>[];
      await pumpWidget(
        tester,
        AutoHeightWebView(
          htmlContent: 'a',
          maxHeight: 400,
          onHeightChanged: seen.add,
        ),
      );
      sendHeight(tester, 250);
      sendHeight(tester, 900);
      await settle(tester);
      expect(seen, [250, 400]);
    });

    testWidgets('does not repeat the callback for the same clamped value',
        (tester) async {
      final seen = <double>[];
      await pumpWidget(
        tester,
        AutoHeightWebView(
          htmlContent: 'a',
          maxHeight: 400,
          onHeightChanged: seen.add,
        ),
      );
      sendHeight(tester, 1000);
      sendHeight(tester, 1000);
      sendHeight(tester, 2000);
      await settle(tester);
      expect(seen, [400]);
    });

    testWidgets('does not call back when height equals the initial height',
        (tester) async {
      final seen = <double>[];
      await pumpWidget(
        tester,
        AutoHeightWebView(htmlContent: 'a', onHeightChanged: seen.add),
      );
      sendHeight(tester, 100);
      await settle(tester);
      expect(seen, isEmpty);
    });

    testWidgets('raising maxHeight re-applies the stored content height',
        (tester) async {
      final seen = <double>[];
      Widget app(double max) => MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: AutoHeightWebView(
                  htmlContent: 'a',
                  maxHeight: max,
                  onHeightChanged: seen.add,
                ),
              ),
            ),
          );
      await tester.pumpWidget(app(300));
      sendHeight(tester, 800);
      await settle(tester);
      expect(heightOf(tester), 300);
      await tester.pumpWidget(app(1000));
      await settle(tester);
      expect(heightOf(tester), 800);
      expect(seen, [300, 800]);
      expect(ctrl.loadedHtml, hasLength(1));
    });

    testWidgets('ignores malformed messages and other instances',
        (tester) async {
      final seen = <double>[];
      await pumpWidget(
        tester,
        AutoHeightWebView(htmlContent: 'a', onHeightChanged: seen.add),
      );
      ctrl.postMessage(kChannel, 'not json');
      ctrl.postMessage(kChannel, '{"type":"height","height":500}');
      sendHeight(tester, 500, id: 'someone-else');
      ctrl.postMessage(
          kChannel, '{"type":"height","height":"x","id":"${idOf(ctrl)}"}');
      await settle(tester);
      expect(seen, isEmpty);
      expect(heightOf(tester), 100);
    });

    testWidgets('each instance has its own id', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Column(children: [
          AutoHeightWebView(htmlContent: 'a'),
          AutoHeightWebView(htmlContent: 'b'),
        ]),
      ));
      expect(platform.controllers, hasLength(2));
      expect(
          idOf(platform.controllers[0]), isNot(idOf(platform.controllers[1])));
    });
  });

  group('scrollWhenClamped', () {
    testWidgets('rebuilds only when the clamped state flips', (tester) async {
      var builds = 0;
      await pumpWidget(
        tester,
        AutoHeightWebView(
          htmlContent: 'a',
          maxHeight: 200,
          scrollWhenClamped: true,
          loadingBuilder: (_) {
            builds++;
            return const SizedBox.shrink();
          },
        ),
      );
      sendHeight(tester, 150);
      await settle(tester);
      var before = builds;
      sendHeight(tester, 160);
      await settle(tester);
      expect(builds, greaterThan(before)); // height changed

      sendHeight(tester, 300); // flips to clamped
      await settle(tester);
      expect(heightOf(tester), 200);
      before = builds;
      sendHeight(tester, 400); // still clamped, same height: no rebuild
      sendHeight(tester, 500);
      await settle(tester);
      expect(builds, before);

      sendHeight(tester, 200); // not clamped any more (== max)
      await settle(tester);
      expect(builds, greaterThan(before));
    });
  });

  group('reloading', () {
    Widget app({
      String html = '<p>a</p>',
      String? css,
      String? base,
      String? script,
      VoidCallback? onFinished,
    }) =>
        MaterialApp(
          home: AutoHeightWebView(
            htmlContent: html,
            css: css,
            baseUrl: base,
            customScript: script,
            onPageFinished: onFinished,
          ),
        );

    testWidgets('htmlContent change loads again', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpWidget(app(html: '<p>b</p>'));
      expect(ctrl.loadedHtml, hasLength(2));
      expect(ctrl.loadedHtml.last, contains('<p>b</p>'));
      expect(platform.controllers, hasLength(1));
    });

    testWidgets('css, baseUrl and customScript changes load again',
        (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpWidget(app(css: 'p{color:red}'));
      await tester.pumpWidget(app(css: 'p{color:red}', base: 'https://a.com/'));
      await tester.pumpWidget(
          app(css: 'p{color:red}', base: 'https://a.com/', script: 'x();'));
      expect(ctrl.loadedHtml, hasLength(4));
      expect(ctrl.loadedBaseUrls.last, 'https://a.com/');
      expect(ctrl.loadedHtml.last, contains('x();'));
    });

    testWidgets('rebuilding with the same inputs does not reload',
        (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpWidget(app());
      expect(ctrl.loadedHtml, hasLength(1));
    });

    testWidgets('the loader comes back while reloading', (tester) async {
      await tester.pumpWidget(app());
      ctrl.navigationDelegate!.finishPage();
      await settle(tester);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.pumpWidget(app(html: '<p>b</p>'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('navigation is open again until the reloaded page finishes',
        (tester) async {
      final taps = <String>[];
      Widget a(String html) => MaterialApp(
            home: AutoHeightWebView(htmlContent: html, onLinkTap: taps.add),
          );
      await tester.pumpWidget(a('a'));
      final nav = ctrl.navigationDelegate!;
      nav.finishPage();
      await tester.pumpWidget(a('b'));
      expect(await nav.request('about:blank'), NavigationDecision.navigate);
      expect(taps, isEmpty);
    });
  });

  group('loading indicator', () {
    testWidgets('is visible, then hidden after the page finished',
        (tester) async {
      await pumpWidget(tester, const AutoHeightWebView(htmlContent: 'a'));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(const Key('fake_webview')), findsOneWidget);

      ctrl.navigationDelegate!.finishPage();
      await settle(tester);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byKey(const Key('fake_webview')), findsOneWidget);
    });

    testWidgets('uses a custom loadingBuilder', (tester) async {
      await pumpWidget(
        tester,
        AutoHeightWebView(
          htmlContent: 'a',
          loadingBuilder: (_) => const Text('please wait'),
        ),
      );
      expect(find.text('please wait'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      ctrl.navigationDelegate!.finishPage();
      await settle(tester);
      expect(find.text('please wait'), findsNothing);
    });

    testWidgets('calls onPageFinished', (tester) async {
      var calls = 0;
      await pumpWidget(
        tester,
        AutoHeightWebView(htmlContent: 'a', onPageFinished: () => calls++),
      );
      expect(calls, 0);
      ctrl.navigationDelegate!.finishPage();
      expect(calls, 1);
    });
  });

  group('navigation', () {
    testWidgets('everything is allowed before the first page finished',
        (tester) async {
      final taps = <String>[];
      await pumpWidget(
        tester,
        AutoHeightWebView(htmlContent: 'a', onLinkTap: taps.add),
      );
      expect(await ctrl.navigationDelegate!.request('about:blank'),
          NavigationDecision.navigate);
      expect(taps, isEmpty);
    });

    testWidgets('after load: link is reported and prevented', (tester) async {
      final taps = <String>[];
      await pumpWidget(
        tester,
        AutoHeightWebView(htmlContent: 'a', onLinkTap: taps.add),
      );
      final nav = ctrl.navigationDelegate!..finishPage();
      expect(await nav.request('https://example.com/x'),
          NavigationDecision.prevent);
      expect(taps, ['https://example.com/x']);
    });

    testWidgets('allowNavigation lets it through but still reports',
        (tester) async {
      final taps = <String>[];
      await pumpWidget(
        tester,
        AutoHeightWebView(
          htmlContent: 'a',
          allowNavigation: true,
          onLinkTap: taps.add,
        ),
      );
      final nav = ctrl.navigationDelegate!..finishPage();
      expect(await nav.request('https://example.com/x'),
          NavigationDecision.navigate);
      expect(taps, ['https://example.com/x']);
    });

    testWidgets('injects the measuring script into a navigated page',
        (tester) async {
      await pumpWidget(
        tester,
        const AutoHeightWebView(htmlContent: 'a', allowNavigation: true),
      );
      final nav = ctrl.navigationDelegate!..finishPage();
      expect(ctrl.executedScripts, isEmpty); // our own document
      nav.finishPage('https://example.com/next');
      await tester.pump();
      expect(ctrl.executedScripts, hasLength(1));
      expect(ctrl.executedScripts.single, contains(idOf(ctrl)));
      expect(ctrl.executedScripts.single, contains('__ahwInstalled'));
    });

    testWidgets('does not inject with JavaScript disabled', (tester) async {
      await pumpWidget(
        tester,
        const AutoHeightWebView(
          htmlContent: 'a',
          allowNavigation: true,
          enableJavaScript: false,
        ),
      );
      ctrl.navigationDelegate!
        ..finishPage()
        ..finishPage('https://example.com/next');
      await tester.pump();
      expect(ctrl.executedScripts, isEmpty);
    });

    testWidgets('prevents navigation without an onLinkTap', (tester) async {
      await pumpWidget(tester, const AutoHeightWebView(htmlContent: 'a'));
      final nav = ctrl.navigationDelegate!..finishPage();
      expect(await nav.request('https://example.com/x'),
          NavigationDecision.prevent);
    });

    testWidgets('sub-frame requests are never blocked', (tester) async {
      final taps = <String>[];
      await pumpWidget(
        tester,
        AutoHeightWebView(htmlContent: 'a', onLinkTap: taps.add),
      );
      final nav = ctrl.navigationDelegate!..finishPage();
      expect(
          await nav.request('https://youtube.com/embed/1', isMainFrame: false),
          NavigationDecision.navigate);
      expect(taps, isEmpty);
    });

    testWidgets('same-page anchors are not reported', (tester) async {
      final taps = <String>[];
      await pumpWidget(
        tester,
        AutoHeightWebView(htmlContent: 'a', onLinkTap: taps.add),
      );
      final nav = ctrl.navigationDelegate!..finishPage();
      expect(await nav.request('about:blank#section'),
          NavigationDecision.navigate);
      expect(taps, isEmpty);
    });

    testWidgets('link messages from the script call onLinkTap', (tester) async {
      final taps = <String>[];
      await pumpWidget(
        tester,
        AutoHeightWebView(htmlContent: 'a', onLinkTap: taps.add),
      );
      ctrl.postMessage(
        kChannel,
        jsonEncode({'type': 'link', 'url': 'https://a.com', 'id': idOf(ctrl)}),
      );
      expect(taps, ['https://a.com']);
    });
  });

  group('lifecycle', () {
    testWidgets('messages and page events after dispose are ignored',
        (tester) async {
      final seen = <double>[];
      var finished = 0;
      await pumpWidget(
        tester,
        AutoHeightWebView(
          htmlContent: 'a',
          onHeightChanged: seen.add,
          onPageFinished: () => finished++,
        ),
      );
      final c = ctrl;
      final id = idOf(c);
      final nav = c.navigationDelegate!;

      await tester.pumpWidget(const SizedBox());
      c.postMessage(
          kChannel, jsonEncode({'type': 'height', 'height': 400, 'id': id}));
      nav.finishPage();
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(seen, isEmpty);
      expect(finished, 0);
    });

    testWidgets('a running height animation can be disposed', (tester) async {
      await pumpWidget(tester, const AutoHeightWebView(htmlContent: 'a'));
      sendHeight(tester, 500);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    });
  });
}
