# Dashmonx

[![Pub Version](https://img.shields.io/pub/v/dashmonx)](https://pub.dev/packages/dashmonx)

A CLI tool to run Flutter applications with automatic hot reload on file changes. Fork of [dashmon](https://github.com/erickzanardo/dashmon) with additional features.

## Install

```
$ dart pub global activate dashmonx
```

## Usage

Just replace `flutter run` with `dashmonx`:

```
$ dashmonx
```

All arguments are proxied to `flutter run`:

```
$ dashmonx -d emulator-5555
$ dashmonx --release
```

### Attach mode

Attach to an existing Flutter instance:

```
$ dashmonx attach
```

### FVM support

Use [FVM](https://github.com/leoafarias/fvm) with the `--fvm` flag:

```
$ dashmonx --fvm
```

## Features over dashmon

### Device picker

When multiple devices are connected, dashmonx shows an interactive picker (just like `flutter run`):

```
Connected devices:
[1]: iPhone 15 Pro (XXXXX-XXXXX)
[2]: Android Emulator (emulator-5554)
Please choose one (or "q" to quit):
```

Single keystroke selection - no need to press Enter.

### Watch additional directories

By default, only `./lib` is watched. Add more directories with `--watch`:

```
$ dashmonx --watch=./packages/shared/lib --watch=./test
```

### Keyboard shortcuts

- `r` - Hot reload (Flutter)
- `R` - Hot restart (Flutter)
- `c` - Clear terminal screen
- `q` - Quit
