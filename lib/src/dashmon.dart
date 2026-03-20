import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:watcher/watcher.dart';

import 'colors.dart';
import 'device_selection.dart';
import 'terminal.dart';

class Dashmon {
  late Process _process;
  final List<String> args;

  Timer? _debounceTimer;

  final List<String> _proxiedArgs = [];
  final List<String> _watchDirs = ['./lib'];
  bool _isFvm = false;
  bool _isAttach = false;
  bool _hasDeviceArg = false;
  int _debounceMs = 500;
  String? _selectedDeviceName;

  Dashmon(this.args) {
    _parseArgs();
  }

  void _parseArgs() {
    for (int i = 0; i < args.length; i++) {
      final arg = args[i];

      if (arg == '--fvm') {
        _isFvm = true;
        continue;
      }

      if (arg.startsWith('--debounce=')) {
        final val = int.tryParse(arg.substring('--debounce='.length));
        if (val != null && val > 0) {
          _debounceMs = val;
        }
        continue;
      }

      if (arg == 'attach') {
        _isAttach = true;
        continue;
      }

      // Parse --watch=<dir> for additional directories to watch
      if (arg.startsWith('--watch=')) {
        final dir = arg.substring('--watch='.length);
        if (dir.isNotEmpty) {
          _watchDirs.add(dir);
        }
        continue;
      }

      // Check if device is already specified
      if (arg == '-d' || arg.startsWith('--device-id')) {
        _hasDeviceArg = true;
      }

      _proxiedArgs.add(arg);
    }
  }

  void _processLine(String line) {
    print(colorize(line));
  }

  void _processError(String line) {
    print(red(line));
  }

  Future<void> start() async {
    // Check if flutter/fvm is available
    final command = _isFvm ? 'fvm' : 'flutter';
    final whichCmd = Platform.isWindows ? 'where' : 'which';
    try {
      final result = await Process.run(whichCmd, [command]);
      if (result.exitCode != 0) throw ProcessException(command, []);
    } on ProcessException {
      print(red('Error: $command is not installed or not in PATH.'));
      if (_isFvm) {
        print(yellow(
            'Install FVM: https://fvm.app/docs/getting_started/installation'));
      } else {
        print(yellow(
            'Install Flutter: https://docs.flutter.dev/get-started/install'));
      }
      exit(1);
    }

    // Only show device picker if user hasn't specified a device
    if (!_hasDeviceArg) {
      stdout.write(dim('Detecting devices...'));
      final devices = await getDevices(useFvm: _isFvm);
      clearLine();

      if (devices.length > 1) {
        final selectedDevice = await selectDevice(devices);

        if (selectedDevice == null) {
          print(yellow('No device selected.'));
          exit(1);
        }

        _proxiedArgs.add('-d');
        _proxiedArgs.add(selectedDevice.id);
        _selectedDeviceName = selectedDevice.name;
      } else if (devices.length == 1) {
        _selectedDeviceName = devices[0].name;
        print('Using ${devices[0].name} ${dim('(${devices[0].id})')}');
      }
    }

    // Set terminal title
    final titleDevice = _selectedDeviceName ?? 'Flutter';
    setTitle('dashmonx: $titleDevice');

    _printStartupSummary();

    final subcommand = _isAttach ? 'attach' : 'run';

    _process = await (_isFvm
        ? Process.start('fvm', ['flutter', subcommand, ..._proxiedArgs],
            runInShell: true)
        : Process.start('flutter', [subcommand, ..._proxiedArgs],
            runInShell: true));

    _process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach(_processLine);

    _process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach(_processError);

    for (final dir in _watchDirs) {
      final watcher = DirectoryWatcher(dir);
      watcher.events.listen((event) {
        if (event.path.endsWith('.dart')) {
          _debounceTimer?.cancel();
          _debounceTimer = Timer(Duration(milliseconds: _debounceMs), () {
            _process.stdin.write('r');
          });
        }
      });
    }

    // Handle graceful shutdown
    ProcessSignal.sigint.watch().listen((_) => _shutdown());
    if (!Platform.isWindows) {
      ProcessSignal.sigterm.watch().listen((_) => _shutdown());
    }

    stdin.echoMode = false;
    stdin.lineMode = false;
    stdin.transform(utf8.decoder).listen((input) {
      if (input == 'q') {
        _shutdown();
      } else if (input == 'c') {
        clearScreen();
      } else {
        _process.stdin.write(input);
      }
    });
    final exitCode = await _process.exitCode;
    resetTitle();
    exit(exitCode);
  }

  void _printStartupSummary() {
    if (_selectedDeviceName != null) {
      print('${dim('Device:')}    $_selectedDeviceName');
    }
    print('${dim('Mode:')}      ${_isAttach ? 'attach' : 'run'}');
    print('${dim('Watching:')}   ${_watchDirs.join(', ')}');
    if (_debounceMs != 500) {
      print('${dim('Debounce:')}  ${_debounceMs}ms');
    }
    print(
        '${dim('Shortcuts:')} r ${dim("reload")}  R ${dim("restart")}  c ${dim("clear")}  q ${dim("quit")}');
    print('');
  }

  void _shutdown() {
    resetTitle();
    _process.kill();
    exit(0);
  }
}
