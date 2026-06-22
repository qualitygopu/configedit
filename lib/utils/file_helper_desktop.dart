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
      bool hasDirectAccess = false;
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
          hasDirectAccess = true;
        } catch (_) {}
      }

      if (!hasDirectAccess) {
        try {
          final result = await Process.run('osascript', [
            '-e',
            'tell application "Finder"\ntry\nset volumesList to every item of (POSIX file "/Volumes" as alias)\nrepeat with aVolume in volumesList\ntry\nset volPath to POSIX path of (aVolume as alias)\nset qtronPath to volPath & "_QTRON"\nif exists (POSIX file qtronPath as alias) then\nreturn qtronPath\nend if\nend try\nend repeat\nend try\nend tell\nreturn ""',
          ]);
          if (result.exitCode == 0) {
            final path = result.stdout.toString().trim();
            if (path.isNotEmpty) {
              return path;
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

    if (Platform.isMacOS) {
      try {
        final result = await Process.run('osascript', [
          '-e',
          'POSIX path of (choose file with prompt "Select Config File" of type {"qtr", "json"})',
        ]);
        if (result.exitCode == 0) {
          final path = result.stdout.toString().trim();
          if (path.isNotEmpty) {
            final file = File(path);
            return await file.readAsString();
          }
        }
      } catch (_) {}
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

    if (Platform.isMacOS) {
      try {
        final result = await Process.run('osascript', [
          '-e',
          'POSIX path of (choose file name default name "$fileName" with prompt "Save Config File As")',
        ]);
        if (result.exitCode == 0) {
          final outputPath = result.stdout.toString().trim();
          if (outputPath.isNotEmpty) {
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
            return;
          }
        }
      } catch (_) {}
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

  Future<String?> selectDirectory() async {
    if (Platform.isMacOS) {
      try {
        final result = await Process.run('osascript', [
          '-e',
          'POSIX path of (choose folder with prompt "Select QTRON Directory")',
        ]);
        if (result.exitCode == 0) {
          return result.stdout.toString().trim();
        }
      } catch (_) {}
    }
    return FilePicker.getDirectoryPath(dialogTitle: 'Select QTRON Directory');
  }

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
      bool hasDirectAccess = false;
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
          hasDirectAccess = true;
        } catch (_) {}
      }

      if (!hasDirectAccess) {
        try {
          final result = await Process.run('osascript', [
            '-e',
            'tell application "Finder"\ntry\nset volumesList to every item of (POSIX file "/Volumes" as alias)\nset res to ""\nrepeat with aVolume in volumesList\ntry\nset volPath to POSIX path of (aVolume as alias)\nif volPath is not "/" and volPath is not "/Volumes/Macintosh HD" and volPath does not start with "/Volumes/Macintosh" then\nset res to volPath\nexit repeat\nend if\nend try\nend repeat\nreturn res\nend try\nend tell\nreturn ""',
          ]);
          if (result.exitCode == 0) {
            final volPath = result.stdout.toString().trim();
            if (volPath.isNotEmpty) {
              final qtronPath = '$volPath/_QTRON';
              final qtronDir = Directory(qtronPath);
              if (!await qtronDir.exists()) {
                try {
                  await Process.run('osascript', [
                    '-e',
                    'tell application "Finder" to make new folder at (POSIX file "$volPath" as alias) with properties {name:"_QTRON"}',
                  ]);
                } catch (_) {}
              }
              return qtronPath;
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

    final List<String> list = [];
    try {
      final dir = Directory(parentPath);
      await for (final entity in dir.list()) {
        if (entity is Directory) {
          final name = entity.path.split(Platform.pathSeparator).last;
          if (name.isNotEmpty && !name.startsWith('.')) {
            list.add(name);
          }
        }
      }
    } catch (_) {
      if (Platform.isMacOS) {
        try {
          final result = await Process.run('osascript', [
            '-e',
            'tell application "Finder"\ntry\nset folderList to every folder of (POSIX file "$parentPath" as alias)\nset resultText to ""\nrepeat with aFolder in folderList\nset resultText to resultText & (name of aFolder) & "\\n"\nend repeat\nreturn resultText\non error\nreturn ""\nend try\nend tell\nreturn ""',
          ]);
          if (result.exitCode == 0) {
            final output = result.stdout.toString().trim();
            if (output.isNotEmpty) {
              final names = output
                  .split('\n')
                  .map((line) => line.trim())
                  .where((line) => line.isNotEmpty && !line.startsWith('.'))
                  .toList();
              names.sort();
              return names;
            }
          }
        } catch (_) {}
      }
    }
    list.sort();
    return list;
  }

  Future<int> getFileCount(String folderPath) async {
    final files = await getFiles(folderPath);
    return files.length;
  }

  Future<List<String>> getFiles(String folderPath) async {
    if (folderPath.isEmpty) return [];

    final List<String> list = [];
    try {
      final dir = Directory(folderPath);
      await for (final entity in dir.list()) {
        if (entity is File) {
          final name = entity.path.split(Platform.pathSeparator).last;
          if (name.isNotEmpty && !name.startsWith('.')) {
            list.add(name);
          }
        }
      }
    } catch (_) {
      if (Platform.isMacOS) {
        try {
          final result = await Process.run('osascript', [
            '-e',
            'tell application "Finder"\ntry\nset fileList to every file of (POSIX file "$folderPath" as alias)\nset resultText to ""\nrepeat with aFile in fileList\nset resultText to resultText & (name of aFile) & "\\n"\nend repeat\nreturn resultText\non error\nreturn ""\nend try\nend tell\nreturn ""',
          ]);
          if (result.exitCode == 0) {
            final output = result.stdout.toString().trim();
            if (output.isNotEmpty) {
              final names = output
                  .split('\n')
                  .map((line) => line.trim())
                  .where((line) => line.isNotEmpty && !line.startsWith('.'))
                  .toList();
              names.sort();
              return names;
            }
          }
        } catch (_) {}
      }
    }
    list.sort();
    return list;
  }

  Future<List<String>> getClipboardFilePaths() async {
    if (Platform.isWindows) {
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
    } else if (Platform.isMacOS) {
      try {
        final result = await Process.run('swift', [
          '-e',
          r'import AppKit; var paths: [String] = []; if let filenames = NSPasteboard.general.propertyList(forType: NSPasteboard.PasteboardType("NSFilenamesPboardType")) as? [String] { paths = filenames }; if paths.isEmpty { if let urls = NSPasteboard.general.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] { paths = urls.filter { $0.isFileURL }.map { $0.path } } }; for path in paths { print(path) }',
        ]);
        if (result.exitCode == 0) {
          final output = result.stdout.toString().trim();
          if (output.isEmpty) {
            return [];
          }
          return output
              .split(RegExp(r'\n'))
              .map((line) => line.trim())
              .where((line) => line.isNotEmpty)
              .toList();
        }
      } catch (_) {}
    }
    return [];
  }
}
