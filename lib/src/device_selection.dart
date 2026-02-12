import 'dart:io';

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

Future<List<Device>> getDevices({bool useFvm = false}) async {
  final result = useFvm
      ? await Process.run('fvm', ['flutter', 'devices'], runInShell: true)
      : await Process.run('flutter', ['devices'], runInShell: true);

  final lines = result.stdout.toString().split('\n');
  final supportedPlatforms = _getSupportedPlatforms();

  return lines.where((line) => line.contains('•')).map((line) {
    final parts = line.split('•');
    return Device(
      name: parts[0].trim(),
      id: parts[1].trim(),
      platform: parts.length > 2 ? parts[2].trim().toLowerCase() : '',
    );
  }).where((device) {
    // Filter devices to only those supported by the project
    return supportedPlatforms.contains(device.platform);
  }).toList();
}

Future<Device?> selectDevice(List<Device> devices) async {
  if (devices.isEmpty) {
    print('No devices found.');
    return null;
  }

  print('Connected devices:');
  for (int i = 0; i < devices.length; i++) {
    print('[${i + 1}]: ${devices[i].name} (${devices[i].id})');
  }

  stdout.write('Please choose one (or "q" to quit): ');

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
    print('Invalid selection.');
    return null;
  }

  return devices[index - 1];
}
