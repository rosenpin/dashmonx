import 'dart:convert';
import 'dart:io';

import 'colors.dart';

class Device {
  Device({
    required this.id,
    required this.name,
    required this.platform,
  });

  final String id;
  final String name;
  final String platform;
}

Set<String> _getSupportedPlatforms() {
  final supported = <String>{};

  if (Directory('ios').existsSync()) supported.add('ios');
  if (Directory('android').existsSync()) supported.add('android');
  if (Directory('macos').existsSync()) supported.add('macos');
  if (Directory('web').existsSync()) supported.add('web');
  if (Directory('linux').existsSync()) supported.add('linux');
  if (Directory('windows').existsSync()) supported.add('windows');

  return supported;
}

String? _projectPlatformFor(String targetPlatform) {
  if (targetPlatform == 'ios') return 'ios';
  if (targetPlatform == 'darwin') return 'macos';
  if (targetPlatform.startsWith('android')) return 'android';
  if (targetPlatform.startsWith('web')) return 'web';
  if (targetPlatform.startsWith('linux')) return 'linux';
  if (targetPlatform.startsWith('windows')) return 'windows';
  return null;
}

Future<List<Device>> getDevices({
  bool useFvm = false,
  bool includeWireless = false,
}) async {
  final connection = includeWireless ? 'both' : 'attached';
  final args = [
    if (useFvm) 'flutter',
    'devices',
    '--machine',
    '--device-connection=$connection',
  ];
  final result = useFvm
      ? await Process.run('fvm', args, runInShell: true)
      : await Process.run('flutter', args, runInShell: true);

  if (result.exitCode != 0) {
    throw ProcessException(
      useFvm ? 'fvm' : 'flutter',
      args,
      result.stderr.toString().trim(),
      result.exitCode,
    );
  }

  final supportedPlatforms = _getSupportedPlatforms();
  final output = jsonDecode(result.stdout.toString());
  if (output is! List) {
    throw const FormatException('Unexpected output from flutter devices');
  }

  final devices = <Device>[];
  for (final value in output) {
    if (value is! Map<String, dynamic> || value['isSupported'] == false) {
      continue;
    }

    final name = value['name'];
    final id = value['id'];
    final targetPlatform = value['targetPlatform'];
    if (name is! String || id is! String || targetPlatform is! String) {
      continue;
    }

    final projectPlatform = _projectPlatformFor(targetPlatform.toLowerCase());
    if (projectPlatform != null &&
        supportedPlatforms.contains(projectPlatform)) {
      devices.add(Device(
        name: name,
        id: id,
        platform: targetPlatform,
      ));
    }
  }

  return devices;
}

Future<Device?> selectDevice(List<Device> devices) async {
  if (devices.isEmpty) {
    print(yellow('No devices found.'));
    return null;
  }

  print(cyan(bold('Connected devices:')));
  for (int i = 0; i < devices.length; i++) {
    print(
        '  ${cyan('[${i + 1}]')} ${devices[i].name} ${dim('(${devices[i].id})')}');
  }

  stdout.write(dim('Please choose one (or "q" to quit): '));

  String input;

  if (devices.length <= 9) {
    // Single keystroke for 9 or fewer devices
    stdin.echoMode = false;
    stdin.lineMode = false;

    input = String.fromCharCode(stdin.readByteSync());

    // Restore terminal settings
    stdin.lineMode = true;
    stdin.echoMode = true;

    print(input); // Echo the character
  } else {
    // Require Enter for more than 9 devices
    input = stdin.readLineSync() ?? '';
  }

  if (input.toLowerCase() == 'q') {
    return null;
  }

  final index = int.tryParse(input);
  if (index == null || index < 1 || index > devices.length) {
    print(red('Invalid selection.'));
    return null;
  }

  return devices[index - 1];
}
