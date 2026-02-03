import 'package:dashmonx/dashmonx.dart';

const version = '1.0.0';

const helpText = '''
Dashmonx - Auto hot reload for Flutter applications

Usage: dashmonx [options] [flutter-run-args]
       dashmonx attach [options] [flutter-attach-args]

Options:
  -h, --help       Show this help message
  -v, --version    Show version number
  --fvm            Use FVM (Flutter Version Manager)
  --watch=<dir>    Watch additional directory (can be used multiple times)

Examples:
  dashmonx                       Run with auto hot reload
  dashmonx -d emulator-5555      Run on specific device
  dashmonx --fvm                 Run using FVM
  dashmonx attach                Attach to running app
  dashmonx --watch=./test        Also watch test directory

Keyboard shortcuts:
  r    Hot reload (handled by Flutter)
  R    Hot restart (handled by Flutter)
  c    Clear terminal screen
  q    Quit

All other arguments are passed directly to flutter run/attach.
''';

void main(List<String> args) {
  if (args.contains('-h') || args.contains('--help')) {
    print(helpText);
    return;
  }

  if (args.contains('-v') || args.contains('--version')) {
    print('dashmonx $version');
    return;
  }

  print('Starting Dashmonx...');
  final dashmon = Dashmon(args);
  dashmon.start();
}
