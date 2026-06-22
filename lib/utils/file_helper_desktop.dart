import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class FileHelperImpl {
  Future<String?> _findQtronDirectory() async {
    if (Platform.isWindows) {
      final driveLetters = [
        'D',
        'E',
        'F',
        'G',
        'H',
        'I',
        'J',
        'K',
        'L',
        'M',
        'N',
        'O',
        'P',
        'Q',
        'R',
        'S',
        'T',
        'U',
        'V',
        'W',
        'X',
        'Y',
        'Z',
      ];
      for (final drive in driveLetters) {
        final path = '$drive:\\_QTRON';
        try {
          if (await Directory(path).exists()) {
            return path;
          }
        } catch (_) {}
      }
    } else if (Platform.isMacOS) {
      final dir = Directory('/Volumes');
      if (await dir.exists()) {
        try {
          await for (final entity in dir.list()) {
            if (entity is Directory) {
              final path = '${entity.path}/_QTRON';
              if (await Directory(path).exists()) {
                return path;
              }
            }
          }
        } catch (_) {}
      }
    } else if (Platform.isLinux) {
      final mediaDir = Directory('/media');
      if (await mediaDir.exists()) {
        try {
          await for (final userEntity in mediaDir.list()) {
            if (userEntity is Directory) {
              await for (final driveEntity in userEntity.list()) {
                if (driveEntity is Directory) {
                  final path = '${driveEntity.path}/_QTRON';
                  if (await Directory(path).exists()) {
                    return path;
                  }
                }
              }
            }
          }
        } catch (_) {}
      }
    }
    return null;
  }

  Future<String?> loadFile({String? qtronDir}) async {
    final activeDir = qtronDir ?? await _findQtronDirectory();
    String? initialDir = activeDir;
    if (activeDir != null) {
      final separator = Platform.pathSeparator;
      final confDir = '$activeDir${separator}@CONF';
      initialDir = confDir;

      try {
        final d = Directory(confDir);
        if (!await d.exists()) {
          await d.create();
        }
      } catch (_) {}

      final qtrFile = File('$confDir${separator}timeAnnounce.qtr');
      if (await qtrFile.exists()) {
        Get.snackbar(
          "Auto-Loaded",
          "Loaded config directly from Removable Drive: $confDir",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        return await qtrFile.readAsString();
      }

      final jsonFile = File('$confDir${separator}timeAnnounce.json');
      if (await jsonFile.exists()) {
        Get.snackbar(
          "Auto-Loaded",
          "Loaded config directly from Removable Drive: $confDir",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        return await jsonFile.readAsString();
      }
    }

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['qtr', 'json'],
      initialDirectory: initialDir,
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      return await file.readAsString();
    }
    return null;
  }

  Future<void> saveFile(
    String content,
    String fileName, {
    String? qtronDir,
    bool isSaveAs = false,
  }) async {
    final activeDir = qtronDir ?? await _findQtronDirectory();
    String? initialDir = activeDir;
    if (activeDir != null) {
      final separator = Platform.pathSeparator;
      final confDir = '$activeDir${separator}@CONF';
      initialDir = confDir;

      try {
        final d = Directory(confDir);
        if (!await d.exists()) {
          await d.create();
        }
      } catch (_) {}

      if (!isSaveAs) {
        final file = File('$confDir$separator$fileName');
        await file.writeAsString(content);
        Get.snackbar(
          "Auto-Saved",
          "Saved config directly to Removable Drive: ${file.path}",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        return;
      }
    }

    final outputPath = await FilePicker.saveFile(
      dialogTitle: 'Save Config File As',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['qtr', 'json'],
      initialDirectory: initialDir,
    );
    if (outputPath != null) {
      final file = File(outputPath);
      await file.writeAsString(content);
      Get.snackbar(
        "Saved As",
        "Saved config to: ${file.path}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  Future<String?> selectDirectory() =>
      FilePicker.getDirectoryPath(dialogTitle: 'Select QTRON Directory');

  Future<String?> findAndAddQtronDirectory() async {
    final existing = await _findQtronDirectory();
    if (existing != null) {
      return existing;
    }

    if (Platform.isWindows) {
      final driveLetters = [
        'D',
        'E',
        'F',
        'G',
        'H',
        'I',
        'J',
        'K',
        'L',
        'M',
        'N',
        'O',
        'P',
        'Q',
        'R',
        'S',
        'T',
        'U',
        'V',
        'W',
        'X',
        'Y',
        'Z',
      ];
      for (final drive in driveLetters) {
        final path = '$drive:\\';
        try {
          if (await Directory(path).exists()) {
            final qtronPath = '$drive:\\_QTRON';
            await Directory(qtronPath).create();
            return qtronPath;
          }
        } catch (_) {}
      }
    } else if (Platform.isMacOS) {
      final dir = Directory('/Volumes');
      if (await dir.exists()) {
        try {
          await for (final entity in dir.list()) {
            if (entity is Directory) {
              final path = entity.path;
              if (!path.startsWith('/Volumes/Macintosh')) {
                final qtronPath = '$path/_QTRON';
                await Directory(qtronPath).create();
                return qtronPath;
              }
            }
          }
        } catch (_) {}
      }
    } else if (Platform.isLinux) {
      final mediaDir = Directory('/media');
      if (await mediaDir.exists()) {
        try {
          await for (final userEntity in mediaDir.list()) {
            if (userEntity is Directory) {
              await for (final driveEntity in userEntity.list()) {
                if (driveEntity is Directory) {
                  final qtronPath = '${driveEntity.path}/_QTRON';
                  await Directory(qtronPath).create();
                  return qtronPath;
                }
              }
            }
          }
        } catch (_) {}
      }
    }
    return null;
  }

  Future<List<String>> getSubfolders(String parentPath) async {
    if (parentPath.isEmpty) return [];
    final dir = Directory(parentPath);
    if (!await dir.exists()) return [];

    final List<String> list = [];
    try {
      await for (final entity in dir.list()) {
        if (entity is Directory) {
          final name = entity.path.split(Platform.pathSeparator).last;
          if (name.isNotEmpty && !name.startsWith('.')) {
            list.add(name);
          }
        }
      }
    } catch (_) {}
    list.sort();
    return list;
  }

  Future<int> getFileCount(String folderPath) async {
    if (folderPath.isEmpty) return 0;
    final dir = Directory(folderPath);
    if (!await dir.exists()) return 0;

    int count = 0;
    try {
      await for (final entity in dir.list()) {
        if (entity is File) {
          count++;
        }
      }
    } catch (_) {}
    return count;
  }

  Future<List<String>> getFiles(String folderPath) async {
    if (folderPath.isEmpty) return [];
    final dir = Directory(folderPath);
    if (!await dir.exists()) return [];

    final List<String> list = [];
    try {
      await for (final entity in dir.list()) {
        if (entity is File) {
          final name = entity.path.split(Platform.pathSeparator).last;
          if (name.isNotEmpty && !name.startsWith('.')) {
            list.add(name);
          }
        }
      }
    } catch (_) {}
    list.sort();
    return list;
  }

  Future<List<String>> getClipboardFilePaths() async {
    if (!Platform.isWindows) return [];

    try {
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-Command',
        r'Get-Clipboard -Format FileDropList | ForEach-Object { $_.FullName }',
      ]);

      if (result.exitCode != 0) {
        return [];
      }

      final output = (result.stdout ?? '').toString().trim();
      if (output.isEmpty) {
        return [];
      }

      return output
          .split(RegExp(r'\r?\n'))
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
