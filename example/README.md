# auto_height_webview example

A Material 3 demo of the [`auto_height_webview`](../) package. Each card shows
one feature: minimal usage, dynamic content, images, min/max height, link
handling, custom CSS with dark mode, full HTML documents, and independent
heights for several widgets.

## Run

```sh
cd example
flutter pub get
flutter run                 # pick a connected device
```

| Platform | Command |
|---|---|
| Android | `flutter run -d <android-device-id>` |
| iOS | `flutter run -d <ios-device-id>` (needs Xcode and CocoaPods) |
| macOS | `flutter run -d macos` |
| Web | `flutter run -d chrome` (or `flutter build web --wasm`) |

Run `flutter devices` to list device ids. Images in the demo load from
`picsum.photos`, so the device needs network access.

## Test

```sh
flutter test
```
