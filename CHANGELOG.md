## 0.0.2

### Added

* macOS support (via `webview_flutter`).
* Web implementation built on `package:web` (iframe), compatible with WASM.
* New parameters: `css`, `useDefaultStyles`, `baseUrl`, `onLinkTap`, `allowNavigation`, `loadingBuilder`, `onPageFinished`, `scrollWhenClamped`, `gestureRecognizers`, `animationDuration` and `animationCurve`.
* Full HTML documents are detected and no longer wrapped a second time.
* Height tracking with `ResizeObserver` (with a `MutationObserver` fallback), image and font load events, throttled with `requestAnimationFrame`.
* Widget tests.
* Web: with `enableJavaScript: false` the height is measured once, at load, from the parent page.

### Fixed

* Multiple web instances on one page picking up each other's heights.
* Changes to `htmlContent` being ignored (added `didUpdateWidget`).
* Repeated `setState` and `onHeightChanged` calls when content is taller than `maxHeight`.
* `setState` called after the widget was disposed.
* The app-wide WebView cache being cleared on dispose.
* Links navigating inside the small view; they are now blocked by default and reported to `onLinkTap`.
* Missed resizes caused by late-loading images and fonts.
* The loading indicator blocking the WebView.
* Height freezing after an allowed in-view navigation on mobile (the measuring script is injected into the new page).
* Fragments that merely mention `<html>` (for example in an `srcdoc` attribute or a comment) being treated as full documents.
* `dart:io` usage that blocked compilation to WASM.

### Changed

* `onHeightChanged` is now `ValueChanged<double>` (source-compatible with `Function(double)`).
* Requires Dart `^3.6.0` and Flutter `>=3.27.0`. Android `minSdk` is 21.
* Height changes are animated (`animationDuration`, `animationCurve`).

### Removed

* Unused dependencies `flutter_inappwebview`, `universal_html` and `js`, which considerably reduces the native footprint of apps that use the package.

## 0.0.1

* Initial release of auto_height_webview
* Support for iOS, Android, and Web platforms
* Automatic height adjustment based on content
* Customizable appearance and behavior
