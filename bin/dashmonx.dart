import 'dart:io';
import 'dart:isolate';

import 'package:dashmonx/dashmonx.dart';

Future<String> getVersion() async {
  try {
    final packageUri = Uri.parse('package:dashmonx/dashmonx.dart');
    final resolved = await Isolate.resolvePackageUri(packageUri);
    if (resolved == null) return 'unknown';
    // resolved points to lib/dashmonx.dart, go up to pubspec.yaml
    final pubspecFile = File.fromUri(resolved.resolve('../pubspec.yaml'));
    if (!pubspecFile.existsSync()) return 'unknown';
    final content = pubspecFile.readAsStringSync();
    final match =
        RegExp(r'^version:\s*(.+)$', multiLine: true).firstMatch(content);
    return match?.group(1)?.trim() ?? 'unknown';
  } catch (_) {
    return 'unknown';
  }
}

const helpText = '''
Dashmonx - Auto hot reload for Flutter applications

Usage: dashmonx [options] [flutter-run-args]
       dashmonx attach [options] [flutter-attach-args]

Options:
  -h, --help       Show this help message
  -v, --version    Show version number
  --fvm               Use FVM (Flutter Version Manager)
  --include-wireless  Include wireless devices during device discovery
  --watch=<dir>       Watch additional directory (can be used multiple times)
  --debounce=<ms>     Set debounce delay in ms (default: 500)

Examples:
  dashmonx                       Run with auto hot reload
  dashmonx -d emulator-5555      Run on specific device
  dashmonx --fvm                 Run using FVM
  dashmonx --include-wireless    Include attached and wireless devices
  dashmonx attach                Attach to running app
  dashmonx --watch=./test        Also watch test directory
  dashmonx --debounce=200        Faster reload debounce

Keyboard shortcuts:
  r    Hot reload (handled by Flutter)
  R    Hot restart (handled by Flutter)
  c    Clear terminal screen
  q    Quit

All other arguments are passed directly to flutter run/attach.
''';

void main(List<String> args) async {
  if (args.contains('-h') || args.contains('--help')) {
    print(helpText);
    return;
  }

  final version = await getVersion();

  if (args.contains('-v') || args.contains('--version')) {
    print('dashmonx $version');
    return;
  }

  print('${bold(cyan('dashmonx'))} ${dim('v$version')}');
  final dashmon = Dashmon(args);
  dashmon.start();
}
