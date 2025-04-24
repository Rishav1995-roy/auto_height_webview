# Auto Height WebView

A Flutter package for rendering HTML content with inline CSS across platforms (iOS, Android, Web) with automatic height adjustment similar to React/React Native's AutoWebView functionality.

## Features

- Automatically adjusts height based on content
- Works across all platforms (iOS, Android, Web)
- Detects content changes and resizes accordingly
- Handles dynamic content (JavaScript-generated content)
- Customizable appearance with decoration options
- Supports custom JavaScript injection
- Provides height change notifications

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  auto_height_webview: ^0.1.0
```

## Usage

### Basic Usage

```dart
AutoHeightWebView(
  htmlContent: '<div style="padding: 20px;">Hello, world!</div>',
  initialHeight: 100,
)
```

### Advanced Usage

```dart
AutoHeightWebView(
  htmlContent: htmlString,
  initialHeight: 200,
  minHeight: 100,
  maxHeight: 500,
  onHeightChanged: (height) {
    print('WebView height changed to: $height');
  },
  decoration: BoxDecoration(
    border: Border.all(color: Colors.grey),
    borderRadius: BorderRadius.circular(8),
  ),
  customScript: 'console.log("Custom script executed!");',
  enableJavaScript: true,
)
```

## How It Works

The package uses different approaches based on the platform:

- **Mobile (iOS/Android)**: Uses `webview_flutter` with JavaScript height measurement
- **Web**: Uses an `iframe` with message passing for height updates

In both cases, the widget automatically adjusts its height based on the content height.

## Platform-Specific Notes

### Android

Make sure to set minimum SDK version in `android/app/build.gradle`:

```gradle
minSdkVersion 19
```

### iOS

No special configuration required.

### Web

No special configuration required. The package uses web-specific implementation for web platform.

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.