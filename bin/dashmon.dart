import 'package:dashmon/dashmon.dart';

const version = '0.0.3';

const helpText = '''
Dashmon - Auto hot reload for Flutter applications

Usage: dashmon [options] [flutter-run-args]
       dashmon attach [options] [flutter-attach-args]

Options:
  -h, --help       Show this help message
  -v, --version    Show version number
  --fvm            Use FVM (Flutter Version Manager)
  --watch=<dir>    Watch additional directory (can be used multiple times)

Examples:
  dashmon                       Run with auto hot reload
  dashmon -d emulator-5555      Run on specific device
  dashmon --fvm                 Run using FVM
  dashmon attach                Attach to running app
  dashmon --watch=./test        Also watch test directory

All other arguments are passed directly to flutter run/attach.
''';

void main(List<String> args) {
  if (args.contains('-h') || args.contains('--help')) {
    print(helpText);
    return;
  }

  if (args.contains('-v') || args.contains('--version')) {
    print('dashmon $version');
    return;
  }

  print('Starting Dashmon...');
  final dashmon = Dashmon(args);
  dashmon.start();
}
