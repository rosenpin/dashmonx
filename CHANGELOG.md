## [1.0.6]

* Skip wireless device discovery by default for faster startup
* Add `--include-wireless` to scan attached and wireless devices
* Use Flutter's machine-readable device output for reliable device selection

## [1.0.5]

* Read version dynamically from pubspec.yaml instead of hardcoding

## [1.0.4]

* Fix Android devices not showing in device picker (platform string matching)

## [1.0.3]

* ANSI color output for errors, warnings, and success messages
* Configurable debounce delay with `--debounce=<ms>` flag (default: 500ms)
* Improved terminal startup display with version info

## [1.0.2]

* Fix stdin terminal mode error on Windows (#1)

## [1.0.1]

* Fix flutter not being detected on Windows (#1)

## [1.0.0]

* Fork renamed to dashmonx
* Device picker when multiple devices are connected (like `flutter run`)
* Watch additional directories with `--watch=<dir>` flag
* Clear terminal with `c` key
* Improved file watching with watcher package

## [0.0.3]

* Added support for attach command (thanks @charafau)

## [0.0.2]

* Support hot reload

## [0.0.1]

* Initial Release
