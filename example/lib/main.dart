import 'package:flutter/material.dart';
import 'package:auto_height_webview/auto_height_webview.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auto Height WebView Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final UniqueKey _webViewKey1 = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Height WebView Demo'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: AutoHeightWebView(
                key: _webViewKey1,
                htmlContent: '''
                  <div style="padding: 16px; background-color: #ffffff;">
                    <h2 style="color: #2e7d32;">Minimal Parameters Example</h2>
                    <p>This example only uses the required htmlContent parameter.</p>
                    <p>All other parameters use their default values.</p>
                    <ul style="list-style-type: circle;">
                      <li>Default initialHeight = 100.0</li>
                      <li>Default minHeight = 50.0</li>
                      <li>Default decoration = transparent</li>
                    </ul>
                  </div>
                ''',
              ),
            ),
            
            
            
            // Example 3: With some parameters
            // const Padding(
            //   padding: EdgeInsets.all(16.0),
            //   child: Text(
            //     'Example 3: With custom decoration only',
            //     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            //   ),
            // ),
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
            //   child: AutoHeightWebView(
            //     htmlContent: '''
            //       <div style="padding: 16px;">
            //         <h2>Custom Decoration Example</h2>
            //         <p>This example only sets a custom decoration and uses default values for height parameters.</p>
            //       </div>
            //     ''',
            //     decoration: BoxDecoration(
            //       gradient: LinearGradient(
            //         colors: [Colors.blue.shade50, Colors.blue.shade100],
            //         begin: Alignment.topCenter,
            //         end: Alignment.bottomCenter,
            //       ),
            //       borderRadius: BorderRadius.circular(12),
            //       boxShadow: [
            //         BoxShadow(
            //           color: Colors.grey.withOpacity(0.3),
            //           spreadRadius: 2,
            //           blurRadius: 5,
            //           offset: const Offset(0, 3),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
            
          ],
        ),
      ),
    );
  }
}