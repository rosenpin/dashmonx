import 'dart:io';
import 'dart:convert';

import 'package:watcher/watcher.dart';

import 'device_selection.dart';

class Dashmon {
  late Process _process;
  final List<String> args;

  Future? _throttler;

  final List<String> _proxiedArgs = [];
  bool _isFvm = false;
  bool _isAttach = false;
  bool _hasDeviceArg = false;

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

      if (arg == 'attach') {
        _isAttach = true;
        continue;
      }

      // Check if device is already specified
      if (arg == '-d' || arg.startsWith('--device-id')) {
        _hasDeviceArg = true;
      }

      _proxiedArgs.add(arg);
    }
  }

  Future<void> _runUpdate() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _process.stdin.write('r');
  }

  void _print(String line) {
    final trim = line.trim();
    if (trim.isNotEmpty) {
      print(trim);
    }
  }

  void _processLine(String line) {
    _print(line);
  }

  void _processError(String line) {
    _print(line);
  }

  Future<void> start() async {
    // Only show device picker if user hasn't specified a device
    if (!_hasDeviceArg) {
      final devices = await getDevices(useFvm: _isFvm);

      if (devices.length > 1) {
        final selectedDevice = await selectDevice(devices);

        if (selectedDevice == null) {
          print('No device selected.');
          exit(1);
        }

        _proxiedArgs.add('-d');
        _proxiedArgs.add(selectedDevice.id);
      } else if (devices.length == 1) {
        print('Using ${devices[0].name} (${devices[0].id})');
      }
    }

    _process = await (_isFvm
        ? Process.start(
            'fvm', ['flutter', _isAttach ? 'attach' : 'run', ..._proxiedArgs])
        : Process.start(
            'flutter', [_isAttach ? 'attach' : 'run', ..._proxiedArgs]));

    _process.stdout.transform(utf8.decoder).forEach(_processLine);

    _process.stderr.transform(utf8.decoder).forEach(_processError);

    final watcher = DirectoryWatcher('./lib');
    watcher.events.listen((event) {
      if (event.path.endsWith('.dart')) {
        if (_throttler == null) {
          _throttler = _runUpdate();
          _throttler?.then((_) {
            print('Sent reload request...');
            _throttler = null;
          });
        }
      }
    });

    stdin.lineMode = false;
    stdin.echoMode = false;
    stdin.transform(utf8.decoder).forEach(_process.stdin.write);
    final exitCode = await _process.exitCode;
    exit(exitCode);
  }
}
