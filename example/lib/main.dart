import 'package:auto_height_webview/auto_height_webview.dart';
import 'package:flutter/material.dart';

import 'samples.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  static const String title = 'AutoHeightWebView';

  @override
  Widget build(BuildContext context) {
    const seed = Colors.indigo;
    return MaterialApp(
      title: title,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
      ),
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatelessWidget {
  const DemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(ExampleApp.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          DemoCard(
            title: '1. Minimal usage',
            description: 'Only htmlContent is required.',
            child: AutoHeightWebView(htmlContent: minimalHtml),
          ),
          DynamicContentDemo(),
          DemoCard(
            title: '3. Images',
            description: 'The widget resizes after the images finish loading.',
            child: AutoHeightWebView(htmlContent: imagesHtml),
          ),
          ClampedHeightDemo(),
          LinksDemo(),
          ThemedDemo(),
          DemoCard(
            title: '7. Full HTML document',
            description: 'Documents with their own head and styles work too. '
                'useDefaultStyles is off so the page keeps its own look.',
            child: AutoHeightWebView(
              htmlContent: fullDocumentHtml,
              useDefaultStyles: false,
            ),
          ),
          IndependentHeightsDemo(),
        ],
      ),
    );
  }
}

/// A titled card wrapping one demo.
class DemoCard extends StatelessWidget {
  const DemoCard({
    super.key,
    required this.title,
    required this.description,
    required this.child,
    this.trailing,
  });

  final String title;
  final String description;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(description, style: theme.textTheme.bodyMedium),
            if (trailing != null) ...[const SizedBox(height: 8), trailing!],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// Bordered container so each webview's bounds are visible.
BoxDecoration _outline(BuildContext context) => BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(8),
    );

// 2. Dynamic content ---------------------------------------------------------

class DynamicContentDemo extends StatefulWidget {
  const DynamicContentDemo({super.key});

  @override
  State<DynamicContentDemo> createState() => _DynamicContentDemoState();
}

class _DynamicContentDemoState extends State<DynamicContentDemo> {
  int _version = 1;

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: '2. Dynamic content',
      description: 'Changing htmlContent re-renders and re-measures. '
          'A script also appends a paragraph after 2 seconds.',
      trailing: FilledButton.tonal(
        onPressed: () => setState(() => _version++),
        child: Text('Add paragraph (v$_version)'),
      ),
      child: AutoHeightWebView(
        htmlContent: dynamicHtml(_version),
        customScript: dynamicScript,
        decoration: _outline(context),
      ),
    );
  }
}

// 4. Min / max height --------------------------------------------------------

class ClampedHeightDemo extends StatefulWidget {
  const ClampedHeightDemo({super.key});

  @override
  State<ClampedHeightDemo> createState() => _ClampedHeightDemoState();
}

class _ClampedHeightDemoState extends State<ClampedHeightDemo> {
  double _height = 0;

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: '4. Min / max height',
      description: 'maxHeight is 150. With scrollWhenClamped the content '
          'scrolls inside the widget once it is clamped.',
      trailing: Text('Reported height: ${_height.toStringAsFixed(1)} px'),
      child: AutoHeightWebView(
        htmlContent: longHtml,
        minHeight: 80,
        maxHeight: 150,
        scrollWhenClamped: true,
        decoration: _outline(context),
        onHeightChanged: (height) => setState(() => _height = height),
      ),
    );
  }
}

// 5. Links -------------------------------------------------------------------

class LinksDemo extends StatelessWidget {
  const LinksDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: '5. Links',
      description: 'onLinkTap reports the URL. To open it, pass it to '
          'url_launcher (not included in this example).',
      child: AutoHeightWebView(
        htmlContent: linksHtml,
        onLinkTap: (url) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text('Tapped: $url')));
        },
      ),
    );
  }
}

// 6. Custom CSS + dark mode --------------------------------------------------

class ThemedDemo extends StatelessWidget {
  const ThemedDemo({super.key});

  String _hex(Color c) => '#${[c.r, c.g, c.b].map(
        (v) => (v * 255).round().toRadixString(16).padLeft(2, '0'),
      ).join()}';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final css = '''
      body { color: ${_hex(scheme.onSurface)}; background: ${_hex(scheme.surfaceContainerHighest)}; }
      a { color: ${_hex(scheme.primary)}; }
      blockquote { border-left: 4px solid ${_hex(scheme.primary)}; margin-left: 0; padding-left: 12px; }
    ''';
    return DemoCard(
      title: '6. Custom CSS and dark mode',
      description: 'The css parameter is built from the current ColorScheme.',
      child: AutoHeightWebView(
        // Changing the key is not needed: css changes are applied on rebuild.
        htmlContent: themedHtml,
        css: css,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

// 8. Independent heights -----------------------------------------------------

class IndependentHeightsDemo extends StatelessWidget {
  const IndependentHeightsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: '8. Independent heights',
      description: 'Two widgets side by side each size to their own content.',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AutoHeightWebView(
              htmlContent: shortHtml,
              decoration: _outline(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AutoHeightWebView(
              htmlContent: tallHtml,
              decoration: _outline(context),
            ),
          ),
        ],
      ),
    );
  }
}
