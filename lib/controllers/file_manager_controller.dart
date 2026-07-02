import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'config_controller.dart';
import '../utils/file_helper.dart';

class FileCopyTask {
  final String destinationFolder;
  final List<List<String>> files;

  FileCopyTask({required this.destinationFolder, List<List<String>>? files})
    : files = files ?? [];

  Map<String, dynamic> toJson() {
    return {'destinationFolder': destinationFolder, 'Files': files};
  }

  factory FileCopyTask.fromJson(Map<String, dynamic> json) {
    final rawFiles = json['Files'];
    final files = <List<String>>[];
    if (rawFiles is List<dynamic>) {
      for (final entry in rawFiles) {
        if (entry is List<dynamic> && entry.length >= 2) {
          final fileName = entry[0]?.toString() ?? '';
          final sourcePath = entry[1]?.toString() ?? '';
          files.add([fileName, sourcePath]);
        }
      }
    }
    return FileCopyTask(
      destinationFolder: json['destinationFolder']?.toString() ?? '',
      files: files,
    );
  }
}

class FileManagerController extends GetxController {
  static const Set<String> _hiddenFolderNames = {
    '@CONF',
    'DT',
    'DW',
    'HR',
    'MO',
    'NN',
    'PN',
  };

  final ConfigController _configController = Get.find<ConfigController>();
  final RxString currentPath = ''.obs;
  final RxString rootPath = ''.obs;
  final RxList<FileSystemEntity> items = <FileSystemEntity>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isTaskExecutionInProgress = false.obs;
  final RxInt taskTotalItems = 0.obs;
  final RxInt taskProcessedItems = 0.obs;
  final RxString taskProgressLabel = ''.obs;
  final RxString currentCopyingPath = ''.obs;
  final RxList<String> completedCopyingPaths = <String>[].obs;
  final RxString errorMessage = ''.obs;
  final Rxn<FileSystemEntity> clipboardItem = Rxn<FileSystemEntity>();
  final RxString clipboardOperation = ''.obs; // 'copy' or 'cut'
  final RxList<String> breadcrumbs = <String>[].obs;
  final RxList<String> selectedFilePaths = <String>[].obs;
  final RxList<FileCopyTask> copyTasks = <FileCopyTask>[].obs;
  final RxString sortColumn =
      'None'.obs; // 'None', 'Name', 'SourcePath', 'Size', 'Status'
  final RxBool sortAscending = true.obs;
  final RxString backupFolderPath = ''.obs;
  Worker? _qtronFolderWorker;

  @override
  void onInit() {
    super.onInit();
    _initializeFromMasterFolder();
    _qtronFolderWorker = ever<String>(_configController.qtronFolder, (path) {
      _initializeFromMasterFolder(path: path, showErrorIfEmpty: false);
    });
  }

  @override
  void onClose() {
    _qtronFolderWorker?.dispose();
    super.onClose();
  }

  Future<void> _initializeFromMasterFolder({
    String? path,
    bool showErrorIfEmpty = true,
  }) async {
    final masterPath = (path ?? _configController.qtronFolder.value).trim();

    if (masterPath.isEmpty) {
      rootPath.value = '';
      currentPath.value = '';
      items.clear();
      breadcrumbs.clear();
      copyTasks.clear();
      if (showErrorIfEmpty) {
        errorMessage.value = 'Master qtronFolder is not set';
      }
      return;
    }

    rootPath.value = masterPath;
    await _loadCopyTasks();
    if (currentPath.value.isEmpty ||
        !_isWithinRoot(currentPath.value, masterPath)) {
      await navigateToFolder(masterPath);
    }
  }

  bool _isWithinRoot(String path, String root) {
    final normalizedPath = _normalizePath(path);
    final normalizedRoot = _normalizePath(root);
    if (normalizedRoot.isEmpty) {
      return true;
    }
    return normalizedPath == normalizedRoot ||
        normalizedPath.startsWith('$normalizedRoot${Platform.pathSeparator}');
  }

  bool isPathPendingCopy(String path) {
    final normalizedPath = _normalizePath(path);
    bool isQueueItem = false;
    for (final task in copyTasks) {
      final destFolder = _resolveTaskDestinationPath(task.destinationFolder);
      for (final entry in task.files) {
        if (entry.isEmpty) continue;
        final fileName = entry[0];
        final targetPath = '$destFolder${Platform.pathSeparator}$fileName';
        if (_normalizePath(targetPath) == normalizedPath) {
          isQueueItem = true;
          break;
        }
      }
      if (isQueueItem) break;
    }

    if (!isQueueItem) return false;

    if (isTaskExecutionInProgress.value) {
      final isCompleted = completedCopyingPaths.any(
        (p) => _normalizePath(p) == normalizedPath,
      );
      return !isCompleted;
    }

    final fileExists = File(path).existsSync() || Directory(path).existsSync();
    return !fileExists;
  }

  String getItemName(FileSystemEntity item) {
    return item.path.split(Platform.pathSeparator).last;
  }

  String getItemSourcePath(FileSystemEntity item) {
    final normalizedPath = _normalizePath(item.path);
    for (final task in copyTasks) {
      final destFolder = _resolveTaskDestinationPath(task.destinationFolder);
      for (final entry in task.files) {
        if (entry.length < 2) continue;
        final fileName = entry[0];
        final fileTargetPath = '$destFolder${Platform.pathSeparator}$fileName';
        if (_normalizePath(fileTargetPath) == normalizedPath) {
          return entry[1];
        }
      }
    }
    return '';
  }

  int getItemSize(FileSystemEntity item) {
    if (item is Directory) return -1;
    try {
      if (item.existsSync()) {
        return (item as File).lengthSync();
      }
      final sourcePath = getItemSourcePath(item);
      if (sourcePath.isNotEmpty) {
        final sourceFile = File(sourcePath);
        if (sourceFile.existsSync()) {
          return sourceFile.lengthSync();
        }
      }
    } catch (_) {}
    return 0;
  }

  String getItemStatus(FileSystemEntity item) {
    final path = item.path;
    final isPending = isPathPendingCopy(path);
    if (!isPending) return 'Completed';
    final isCurrentCopying = currentCopyingPath.value == path;
    return isCurrentCopying ? 'Copying' : 'Pending';
  }

  void sortItems(String column, bool ascending) {
    sortColumn.value = column;
    sortAscending.value = ascending;

    if (column == 'None') {
      final dirs = items.whereType<Directory>().toList();
      dirs.sort(
        (a, b) => getItemName(
          a,
        ).toLowerCase().compareTo(getItemName(b).toLowerCase()),
      );
      final files = items.whereType<File>().toList();
      items.assignAll([...dirs, ...files]);
      return;
    }

    items.sort((a, b) {
      final aIsDir = a is Directory;
      final bIsDir = b is Directory;
      if (aIsDir != bIsDir) {
        return aIsDir ? -1 : 1;
      }

      int cmp = 0;
      switch (column) {
        case 'Name':
          final aName = getItemName(a);
          final bName = getItemName(b);
          cmp = aName.toLowerCase().compareTo(bName.toLowerCase());
          break;
        case 'SourcePath':
          final aSrc = getItemSourcePath(a);
          final bSrc = getItemSourcePath(b);
          cmp = aSrc.toLowerCase().compareTo(bSrc.toLowerCase());
          break;
        case 'Size':
          final aSize = getItemSize(a);
          final bSize = getItemSize(b);
          cmp = aSize.compareTo(bSize);
          break;
        case 'Status':
          final aStatus = getItemStatus(a);
          final bStatus = getItemStatus(b);
          cmp = aStatus.compareTo(bStatus);
          break;
      }
      return ascending ? cmp : -cmp;
    });
    items.refresh();
  }

  Future<void> renamePendingFile(String targetPath, String newName) async {
    final normalizedTarget = _normalizePath(targetPath);
    final destFolder = _taskDestinationFolder(currentPath.value);
    final task = _findCopyTask(destFolder);
    if (task == null || task.files.isEmpty) return;

    bool updated = false;
    for (int i = 0; i < task.files.length; i++) {
      final entry = task.files[i];
      if (entry.length < 2) continue;
      final fileName = entry[0];
      final fileTargetPath =
          '${currentPath.value}${Platform.pathSeparator}$fileName';
      if (_normalizePath(fileTargetPath) == normalizedTarget) {
        final dotIndex = fileName.lastIndexOf('.');
        final extension = dotIndex != -1 ? fileName.substring(dotIndex) : '';

        String finalNewName = newName.trim();
        if (extension.isNotEmpty &&
            !finalNewName.toLowerCase().endsWith(extension.toLowerCase())) {
          finalNewName += extension;
        }

        task.files[i] = [finalNewName, entry[1]];
        updated = true;
        break;
      }
    }

    if (updated) {
      await _saveCopyTasks();
      if (currentPath.value.isNotEmpty) {
        await navigateToFolder(currentPath.value);
      }
      Get.snackbar(
        'Success',
        'Pending file renamed to $newName',
        backgroundColor: Colors.green.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    }
  }

  void toggleSort(String column) {
    if (sortColumn.value == column) {
      sortAscending.value = !sortAscending.value;
    } else {
      sortColumn.value = column;
      sortAscending.value = true;
    }
    sortItems(sortColumn.value, sortAscending.value);
  }

  String _normalizePath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return '';
    final withoutTrailing = trimmed.replaceAll(RegExp(r'[\\/]+$'), '');
    return Platform.isWindows ? withoutTrailing.toLowerCase() : withoutTrailing;
  }

  String _relativePathToRoot(String path) {
    if (rootPath.value.isEmpty) return path;
    final normalizedRoot = _normalizePath(rootPath.value);
    final normalizedPath = _normalizePath(path);
    if (normalizedPath == normalizedRoot) {
      return '';
    }
    final prefix = '$normalizedRoot${Platform.pathSeparator}';
    if (normalizedPath.startsWith(prefix)) {
      final relative = path.substring(rootPath.value.length);
      return relative.replaceFirst(RegExp(r'^[\\/]+'), '');
    }
    return path;
  }

  String _resolveTaskDestinationPath(String destinationFolder) {
    if (rootPath.value.isEmpty) {
      return destinationFolder.isEmpty ? currentPath.value : destinationFolder;
    }
    if (destinationFolder.isEmpty) {
      return rootPath.value;
    }
    return '${rootPath.value}${Platform.pathSeparator}$destinationFolder';
  }

  String _taskDestinationFolder(String destinationPath) {
    return _relativePathToRoot(destinationPath);
  }

  Future<String?> _copyTasksFilePath() async {
    if (rootPath.value.isEmpty) return null;
    return '${rootPath.value}${Platform.pathSeparator}filecopy.json';
  }

  Future<void> _loadCopyTasks() async {
    copyTasks.clear();
    final path = await _copyTasksFilePath();
    if (path == null) return;
    try {
      final file = File(path);
      if (!await file.exists()) return;
      final content = await file.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is List<dynamic>) {
        for (final entry in decoded) {
          if (entry is Map<String, dynamic>) {
            copyTasks.add(FileCopyTask.fromJson(entry));
          }
        }
      }
    } catch (_) {
      copyTasks.clear();
    }
  }

  Future<void> _saveCopyTasks() async {
    final path = await _copyTasksFilePath();
    if (path == null) return;
    try {
      final file = File(path);
      final encoder = const JsonEncoder.withIndent('  ');
      await file.writeAsString(
        encoder.convert(copyTasks.map((task) => task.toJson()).toList()),
      );
    } catch (_) {}
  }

  FileCopyTask? _findCopyTask(String destinationFolder) {
    for (final task in copyTasks) {
      if (task.destinationFolder == destinationFolder) {
        return task;
      }
    }
    return null;
  }

  String _getUniqueFileName(
    String destinationFolderPath,
    String originalName,
    String sourcePath,
    FileCopyTask? existingTask, {
    List<List<String>>? localBuffer,
    bool allowDuplicateSource = false,
  }) {
    bool nameExists(String name) {
      final destPath = '$destinationFolderPath${Platform.pathSeparator}$name';
      if (File(destPath).existsSync() || Directory(destPath).existsSync()) {
        return true;
      }
      if (existingTask != null) {
        if (existingTask.files.any((e) => e[0] == name)) {
          return true;
        }
      }
      if (localBuffer != null) {
        if (localBuffer.any((e) => e[0] == name)) {
          return true;
        }
      }
      return false;
    }

    // Check if the exact same source path is already queued
    if (!allowDuplicateSource && existingTask != null) {
      final isAlreadyQueued = existingTask.files.any(
        (e) => _normalizePath(e[1]) == _normalizePath(sourcePath),
      );
      if (isAlreadyQueued) {
        return ''; // Skip
      }
    }
    if (!allowDuplicateSource && localBuffer != null) {
      final isAlreadyInBuffer = localBuffer.any(
        (e) => _normalizePath(e[1]) == _normalizePath(sourcePath),
      );
      if (isAlreadyInBuffer) {
        return ''; // Skip
      }
    }

    // Check if destination path is identical to source path (copying onto itself)
    final directDestPath =
        '$destinationFolderPath${Platform.pathSeparator}$originalName';
    if (_normalizePath(directDestPath) == _normalizePath(sourcePath)) {
      return ''; // Skip
    }

    if (!nameExists(originalName)) {
      return originalName;
    }

    int counter = 1;
    final dotIndex = originalName.lastIndexOf('.');
    final base = dotIndex != -1
        ? originalName.substring(0, dotIndex)
        : originalName;
    final ext = dotIndex != -1 ? originalName.substring(dotIndex) : '';

    String newName = originalName;
    while (nameExists(newName)) {
      newName = '${base}_$counter$ext';
      counter++;
    }
    return newName;
  }

  Future<void> _addCopyTask(
    String destinationPath,
    String fileName,
    String sourcePath,
  ) async {
    sortColumn.value = 'None';
    final destinationFolder = _taskDestinationFolder(destinationPath);
    final existing = _findCopyTask(destinationFolder);

    final uniqueName = _getUniqueFileName(
      destinationPath,
      fileName,
      sourcePath,
      existing,
    );
    if (uniqueName.isEmpty) return; // skipped

    if (existing != null) {
      existing.files.add([uniqueName, sourcePath]);
    } else {
      copyTasks.add(
        FileCopyTask(
          destinationFolder: destinationFolder,
          files: [
            [uniqueName, sourcePath],
          ],
        ),
      );
    }
    copyTasks.refresh();
    await _saveCopyTasks();
  }

  Future<void> _addCopyTasksBulk(
    String destinationPath,
    List<List<String>> entries,
  ) async {
    if (entries.isEmpty) return;
    sortColumn.value = 'None';
    final destinationFolder = _taskDestinationFolder(destinationPath);
    final existing = _findCopyTask(destinationFolder);
    if (existing != null) {
      for (final entry in entries) {
        final originalName = entry[0];
        final sourcePath = entry[1];
        final alreadyExists = existing.files.any(
          (e) => e[1] == sourcePath || e[0] == originalName,
        );
        if (!alreadyExists) {
          existing.files.add(entry);
        }
      }
    } else {
      copyTasks.add(
        FileCopyTask(
          destinationFolder: destinationFolder,
          files: List<List<String>>.from(entries),
        ),
      );
    }
    copyTasks.refresh();
    await _saveCopyTasks();
  }

  Future<void> _backupCopyTasksToPath(String directory) async {
    if (directory.isEmpty) return;
    try {
      final backupPath =
          '$directory${Platform.pathSeparator}filecopy_copy.json';
      final file = File(backupPath);
      final encoder = const JsonEncoder.withIndent('  ');
      await file.writeAsString(
        encoder.convert(copyTasks.map((task) => task.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<void> executeCopyTasks() async {
    if (copyTasks.isEmpty) return;

    if (backupFolderPath.value.isEmpty) {
      final selected = await FileHelper.selectDirectory();
      if (selected == null) {
        Get.snackbar(
          'Backup Cancelled',
          'Copy tasks execution aborted because backup folder was not selected',
          backgroundColor: Colors.red.withValues(alpha: 0.9),
          colorText: Colors.white,
        );
        return;
      }
      backupFolderPath.value = selected;
    }

    await _backupCopyTasksToPath(backupFolderPath.value);
    final taskList = List<FileCopyTask>.from(copyTasks);
    taskTotalItems.value = taskList.fold<int>(
      0,
      (sum, task) => sum + task.files.length,
    );
    taskProcessedItems.value = 0;
    taskProgressLabel.value = 'Starting task queue';
    currentCopyingPath.value = '';
    completedCopyingPaths.clear();
    isTaskExecutionInProgress.value = true;
    try {
      for (final task in taskList) {
        final destinationFolder = _resolveTaskDestinationPath(
          task.destinationFolder,
        );
        final destinationDir = Directory(destinationFolder);
        if (!await destinationDir.exists()) {
          await destinationDir.create(recursive: true);
        }

        for (final entry in task.files) {
          if (entry.length < 2) continue;
          final fileName = entry[0];
          final sourcePath = entry[1];
          final targetPath =
              '$destinationFolder${Platform.pathSeparator}$fileName';
          currentCopyingPath.value = targetPath;

          taskProgressLabel.value = 'Copying $fileName';

          try {
            final sourceFile = File(sourcePath);
            if (await sourceFile.exists()) {
              if (await File(targetPath).exists()) {
                if (!completedCopyingPaths.contains(targetPath)) {
                  completedCopyingPaths.add(targetPath);
                }
                continue;
              }
              await sourceFile.copy(targetPath);
              if (!completedCopyingPaths.contains(targetPath)) {
                completedCopyingPaths.add(targetPath);
              }
              _appendCopiedItemIfVisible(targetPath);
              continue;
            }

            final sourceDir = Directory(sourcePath);
            if (await sourceDir.exists()) {
              await _copyDirectory(sourceDir, Directory(targetPath));
              if (!completedCopyingPaths.contains(targetPath)) {
                completedCopyingPaths.add(targetPath);
              }
              _appendCopiedItemIfVisible(targetPath);
            }
          } catch (_) {
            // ignore individual copy failures and continue with other tasks
          } finally {
            taskProcessedItems.value += 1;
          }
        }
      }
      copyTasks.clear();
    } finally {
      currentCopyingPath.value = '';
      completedCopyingPaths.clear();
      taskProgressLabel.value = '';
      taskTotalItems.value = 0;
      taskProcessedItems.value = 0;
      isTaskExecutionInProgress.value = false;
      await _saveCopyTasks();
    }
  }

  void _appendCopiedItemIfVisible(String targetPath) {
    if (currentPath.value.isEmpty) return;
    final parentPath = Directory(targetPath).parent.path;
    if (_normalizePath(parentPath) != _normalizePath(currentPath.value)) {
      return;
    }

    final normalizedTarget = _normalizePath(targetPath);
    final alreadyListed = items.any(
      (entity) => _normalizePath(entity.path) == normalizedTarget,
    );
    if (alreadyListed) return;

    final file = File(targetPath);
    if (file.existsSync()) {
      items.add(file);
    } else {
      final dir = Directory(targetPath);
      if (dir.existsSync()) {
        items.add(dir);
      }
    }

    items.sort((a, b) {
      final aIsDir = a is Directory;
      final bIsDir = b is Directory;
      if (aIsDir != bIsDir) {
        return aIsDir ? -1 : 1;
      }
      final aName = a.path.split(Platform.pathSeparator).last;
      final bName = b.path.split(Platform.pathSeparator).last;
      return aName.compareTo(bName);
    });
    items.refresh();
  }

  Future<void> clearCopyTasks() async {
    copyTasks.clear();
    await _saveCopyTasks();
    if (currentPath.value.isNotEmpty) {
      await navigateToFolder(currentPath.value);
    }
  }

  Future<void> removeFileFromQueue(String targetPath) async {
    final normalizedTarget = _normalizePath(targetPath);
    bool removed = false;

    final tasksToRemove = <FileCopyTask>[];

    for (final task in copyTasks) {
      final destFolder = _resolveTaskDestinationPath(task.destinationFolder);
      final entriesToRemove = <List<String>>[];

      for (final entry in task.files) {
        if (entry.length < 2) continue;
        final fileName = entry[0];
        final fileTargetPath = '$destFolder${Platform.pathSeparator}$fileName';
        if (_normalizePath(fileTargetPath) == normalizedTarget) {
          entriesToRemove.add(entry);
        }
      }

      if (entriesToRemove.isNotEmpty) {
        task.files.removeWhere((entry) => entriesToRemove.contains(entry));
        removed = true;
        if (task.files.isEmpty) {
          tasksToRemove.add(task);
        }
      }
    }

    if (removed) {
      if (tasksToRemove.isNotEmpty) {
        copyTasks.removeWhere((task) => tasksToRemove.contains(task));
      }
      copyTasks.refresh();
      await _saveCopyTasks();

      if (currentPath.value.isNotEmpty) {
        await navigateToFolder(currentPath.value);
      }

      final fileName = targetPath.split(Platform.pathSeparator).last;
      Get.snackbar(
        'Queue Updated',
        'Removed $fileName from queue',
        backgroundColor: Colors.blue.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    }
  }

  bool get hasPendingTasksForCurrentFolder {
    if (currentPath.value.isEmpty) return false;
    final destFolder = _taskDestinationFolder(currentPath.value);
    final task = _findCopyTask(destFolder);
    return task != null && task.files.isNotEmpty;
  }

  Future<void> renamePendingFiles(String destinationPath) async {
    final destFolder = _taskDestinationFolder(destinationPath);
    final task = _findCopyTask(destFolder);
    if (task == null || task.files.isEmpty) return;

    // 1. Get the pending files from the currently sorted items list
    final sortedPendingFiles = items
        .whereType<File>()
        .where((file) => isPathPendingCopy(file.path))
        .toList();

    if (sortedPendingFiles.isEmpty) return;

    // 2. Map target path to entry in task.files
    final entryMap = <String, List<String>>{};
    for (final entry in task.files) {
      if (entry.length < 2) continue;
      final fileName = entry[0];
      final targetPath = '$destinationPath${Platform.pathSeparator}$fileName';
      entryMap[_normalizePath(targetPath)] = entry;
    }

    // 3. Rebuild the list of pending entries in the sorted order
    final sortedPendingEntries = <List<String>>[];
    for (final file in sortedPendingFiles) {
      final normPath = _normalizePath(file.path);
      final entry = entryMap[normPath];
      if (entry != null) {
        sortedPendingEntries.add(entry);
      }
    }

    // If for some reason we missed any entries (e.g. they weren't in sortedPendingFiles),
    // let's collect the remaining entries to not lose them
    final remainingEntries = <List<String>>[];
    for (final entry in task.files) {
      if (!sortedPendingEntries.contains(entry)) {
        remainingEntries.add(entry);
      }
    }

    // 4. Rename the sorted pending entries sequentially
    final fileCount = sortedPendingEntries.length;
    final padLength = fileCount < 1000 ? 3 : 4;

    final renamedPendingEntries = <List<String>>[];
    for (int i = 0; i < fileCount; i++) {
      final entry = sortedPendingEntries[i];
      final originalName = entry[0];
      final sourcePath = entry[1];

      final dotIndex = originalName.lastIndexOf('.');
      final extension = dotIndex != -1 ? originalName.substring(dotIndex) : '';

      final indexStr = (i + 1).toString().padLeft(padLength, '0');
      final newFileName = '$indexStr$extension';

      renamedPendingEntries.add([newFileName, sourcePath]);
    }

    // 5. Replace task.files: put renamed pending entries first, then any remaining ones
    task.files.clear();
    task.files.addAll(renamedPendingEntries);
    task.files.addAll(remainingEntries);

    copyTasks.refresh();
    await _saveCopyTasks();

    if (currentPath.value.isNotEmpty) {
      await navigateToFolder(currentPath.value);
    }

    Get.snackbar(
      'Queue Updated',
      'Renamed $fileCount pending files in current sorted order',
      backgroundColor: Colors.green.withValues(alpha: 0.9),
      colorText: Colors.white,
    );
  }

  Future<void> randomizeAndRenamePendingFiles(String destinationPath) async {
    final destFolder = _taskDestinationFolder(destinationPath);
    final task = _findCopyTask(destFolder);
    if (task == null || task.files.isEmpty) return;

    // 1. Get the pending files from the current folder (to match task entries)
    final pendingFiles = items
        .whereType<File>()
        .where((file) => isPathPendingCopy(file.path))
        .toList();

    if (pendingFiles.isEmpty) return;

    // 2. Map target path to entry in task.files
    final entryMap = <String, List<String>>{};
    for (final entry in task.files) {
      if (entry.length < 2) continue;
      final fileName = entry[0];
      final targetPath = '$destinationPath${Platform.pathSeparator}$fileName';
      entryMap[_normalizePath(targetPath)] = entry;
    }

    // 3. Collect the entries of the pending files
    final pendingEntries = <List<String>>[];
    for (final file in pendingFiles) {
      final normPath = _normalizePath(file.path);
      final entry = entryMap[normPath];
      if (entry != null) {
        pendingEntries.add(entry);
      }
    }

    // 4. Shuffle the pending entries randomly
    pendingEntries.shuffle();

    // Collect any remaining entries in task.files that were not pending
    final remainingEntries = <List<String>>[];
    for (final entry in task.files) {
      if (!pendingEntries.contains(entry)) {
        remainingEntries.add(entry);
      }
    }

    // 5. Replace task.files: put randomized pending entries first, then remaining ones
    task.files.clear();
    task.files.addAll(pendingEntries);
    task.files.addAll(remainingEntries);

    copyTasks.refresh();
    await _saveCopyTasks();

    if (currentPath.value.isNotEmpty) {
      await navigateToFolder(currentPath.value);
    }

    Get.snackbar(
      'Queue Updated',
      'Randomized pending files in queue',
      backgroundColor: Colors.green.withValues(alpha: 0.9),
      colorText: Colors.white,
    );
  }

  Future<void> multiplySelectedFiles(int copies) async {
    if (currentPath.value.isEmpty || selectedFilePaths.isEmpty || copies <= 0) {
      return;
    }

    final destFolder = _taskDestinationFolder(currentPath.value);
    var task = _findCopyTask(destFolder);

    if (task == null) {
      task = FileCopyTask(destinationFolder: destFolder);
      copyTasks.add(task);
    }

    int addedCount = 0;
    sortColumn.value = 'None';

    for (int i = 0; i < copies; i++) {
      for (final path in selectedFilePaths) {
        String sourcePath = '';
        String originalName = path.split(Platform.pathSeparator).last;

        if (isPathPendingCopy(path)) {
          final entry = task.files.firstWhereOrNull(
            (e) =>
                e.length >= 2 &&
                _normalizePath(
                      '${currentPath.value}${Platform.pathSeparator}${e[0]}',
                    ) ==
                    _normalizePath(path),
          );
          if (entry != null) {
            sourcePath = entry[1];
          }
        } else {
          sourcePath = path;
        }

        if (sourcePath.isEmpty) continue;

        final dotIndex = originalName.lastIndexOf('.');
        final base = dotIndex != -1
            ? originalName.substring(0, dotIndex)
            : originalName;
        final ext = dotIndex != -1 ? originalName.substring(dotIndex) : '';

        final targetName = '${base}_${i + 1}$ext';
        final uniqueName = _getUniqueFileName(
          currentPath.value,
          targetName,
          sourcePath,
          task,
          allowDuplicateSource: true,
        );
        if (uniqueName.isNotEmpty) {
          task.files.add([uniqueName, sourcePath]);
          addedCount++;
        }
      }
    }

    if (addedCount > 0) {
      copyTasks.refresh();
      await _saveCopyTasks();

      selectedFilePaths.clear();
      await navigateToFolder(currentPath.value);

      Get.snackbar(
        'Queue Updated',
        'Multiplied selected file(s) by $copies copies',
        backgroundColor: Colors.green.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    }
  }

  String _baseName(String path) {
    final normalized = path.replaceAll(RegExp(r'[\\/]+$'), '');
    if (normalized.isEmpty) return '';
    return normalized.split(RegExp(r'[\\/]')).last;
  }

  bool _isHiddenFolderName(String folderName) {
    return _hiddenFolderNames.contains(folderName.toUpperCase());
  }

  bool _isHiddenFolderPath(String path) {
    return _isHiddenFolderName(_baseName(path));
  }

  Future<void> navigateToFolder(String path) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      if (_isHiddenFolderPath(path)) {
        errorMessage.value = 'This folder is non-editable and hidden';
        isLoading.value = false;
        return;
      }

      final activeRoot = rootPath.value;
      if (activeRoot.isNotEmpty && !_isWithinRoot(path, activeRoot)) {
        errorMessage.value = 'Navigation outside master qtronFolder is blocked';
        isLoading.value = false;
        return;
      }

      final dir = Directory(path);
      bool exists = false;
      try {
        exists = await dir.exists();
      } catch (_) {}

      if (!exists && Platform.isMacOS) {
        try {
          final result = await Process.run('osascript', [
            '-e',
            'tell application "Finder"\ntry\nexists (POSIX file "$path" as alias)\non error\nreturn "false"\nend try\nend tell',
          ]);
          if (result.exitCode == 0) {
            exists = result.stdout.toString().trim() == 'true';
          }
        } catch (_) {}
      }

      if (!exists) {
        errorMessage.value = 'Folder does not exist';
        isLoading.value = false;
        return;
      }

      currentPath.value = path;
      selectedFilePaths.clear();

      // Load items
      final List<FileSystemEntity> loadedItems = [];
      try {
        try {
          await for (final entity in dir.list()) {
            final name = entity.path.split(Platform.pathSeparator).last;
            if (name.isNotEmpty &&
                !name.startsWith('.') &&
                !(entity is Directory && _isHiddenFolderName(name))) {
              loadedItems.add(entity);
            }
          }
        } catch (e) {
          final folders = await FileHelper.getSubfolders(path);
          final files = await FileHelper.getFiles(path);
          if (folders.isEmpty && files.isEmpty) {
            rethrow;
          }
          final separator = Platform.pathSeparator;
          for (final f in folders) {
            if (!_isHiddenFolderName(f)) {
              loadedItems.add(Directory('$path$separator$f'));
            }
          }
          for (final f in files) {
            loadedItems.add(File('$path$separator$f'));
          }
        }
      } catch (e) {
        errorMessage.value = 'Error reading folder: $e';
      }

      // Inject pending copy task placeholders
      final normalizedCurrent = _normalizePath(path);
      for (final task in copyTasks) {
        final destFolder = _resolveTaskDestinationPath(task.destinationFolder);
        if (_normalizePath(destFolder) == normalizedCurrent) {
          for (final entry in task.files) {
            if (entry.length < 2) continue;
            final fileName = entry[0];
            final sourcePath = entry[1];
            final targetPath = '$destFolder${Platform.pathSeparator}$fileName';

            final normalizedTarget = _normalizePath(targetPath);
            final alreadyLoaded = loadedItems.any(
              (entity) => _normalizePath(entity.path) == normalizedTarget,
            );

            if (!alreadyLoaded) {
              final isDir = Directory(sourcePath).existsSync();
              if (isDir) {
                loadedItems.add(Directory(targetPath));
              } else {
                loadedItems.add(File(targetPath));
              }
            }
          }
        }
      }

      items.assignAll(loadedItems);
      sortItems(sortColumn.value, sortAscending.value);
      _updateBreadcrumbs(path);
    } catch (e) {
      errorMessage.value = 'Error: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void _updateBreadcrumbs(String path) {
    final base = rootPath.value;
    if (base.isEmpty || !_isWithinRoot(path, base)) {
      breadcrumbs.assignAll([path]);
      return;
    }

    final normalizedBase = _normalizePath(base);
    final normalizedPath = _normalizePath(path);

    final List<String> crumbs = [base];
    if (normalizedPath == normalizedBase) {
      breadcrumbs.assignAll(crumbs);
      return;
    }

    final relative = normalizedPath
        .substring(normalizedBase.length)
        .replaceFirst(RegExp(r'^[\\/]'), '');
    final parts = relative
        .split(RegExp(r'[\\/]'))
        .where((part) => part.isNotEmpty)
        .toList();

    var buildPath = base;
    for (final part in parts) {
      buildPath = '$buildPath${Platform.pathSeparator}$part';
      crumbs.add(buildPath);
    }

    breadcrumbs.assignAll(crumbs);
  }

  Future<void> goBack() async {
    if (currentPath.value.isEmpty) return;
    if (rootPath.value.isNotEmpty &&
        _normalizePath(currentPath.value) == _normalizePath(rootPath.value)) {
      return;
    }
    final parent = Directory(currentPath.value).parent;
    await navigateToFolder(parent.path);
  }

  Future<void> navigateToBreadcrumb(String path) async {
    if (rootPath.value.isNotEmpty && !_isWithinRoot(path, rootPath.value)) {
      errorMessage.value = 'Invalid location';
      return;
    }
    await navigateToFolder(path);
  }

  Future<void> createFolder(String folderName) async {
    try {
      if (currentPath.value.isEmpty) {
        errorMessage.value = 'No folder selected';
        return;
      }

      final newPath =
          '${currentPath.value}${Platform.pathSeparator}$folderName';
      final newFolder = Directory(newPath);

      if (await newFolder.exists()) {
        errorMessage.value = 'Folder already exists';
        Get.snackbar(
          'Error',
          'Folder already exists',
          backgroundColor: Colors.red.withValues(alpha: 0.9),
          colorText: Colors.white,
        );
        return;
      }

      try {
        await newFolder.create();
      } catch (e) {
        if (Platform.isMacOS) {
          final parent = currentPath.value;
          final result = await Process.run('osascript', [
            '-e',
            'tell application "Finder" to make new folder at (POSIX file "$parent" as alias) with properties {name:"$folderName"}',
          ]);
          if (result.exitCode != 0) {
            rethrow;
          }
        } else {
          rethrow;
        }
      }
      Get.snackbar(
        'Success',
        'Folder created: $folderName',
        backgroundColor: Colors.green.withValues(alpha: 0.9),
        colorText: Colors.white,
      );

      // Refresh folder
      await navigateToFolder(currentPath.value);
    } catch (e) {
      errorMessage.value = 'Error creating folder: $e';
      Get.snackbar(
        'Error',
        'Failed to create folder',
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    }
  }

  void copyItem(FileSystemEntity item) {
    clipboardItem.value = item;
    clipboardOperation.value = 'copy';
    final name = item.path.split(Platform.pathSeparator).last;
    Get.snackbar(
      'Copied',
      'Copied: $name',
      backgroundColor: Colors.blue.withValues(alpha: 0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void cutItem(FileSystemEntity item) {
    clipboardItem.value = item;
    clipboardOperation.value = 'cut';
    final name = item.path.split(Platform.pathSeparator).last;
    Get.snackbar(
      'Cut',
      'Cut: $name',
      backgroundColor: Colors.orange.withValues(alpha: 0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> pasteItem() async {
    try {
      if (currentPath.value.isEmpty) {
        errorMessage.value = 'No destination folder selected';
        return;
      }
      sortColumn.value = 'None';

      if (clipboardItem.value == null || clipboardOperation.value.isEmpty) {
        final externalPaths = await FileHelper.getClipboardFilePaths();
        if (externalPaths.isEmpty) {
          errorMessage.value = 'Nothing to paste';
          return;
        }

        isLoading.value = true;
        taskProgressLabel.value = 'Preparing clipboard items...';
        final pastedCount = await _pasteFromExternalPathsToDestination(
          externalPaths,
          currentPath.value,
        );

        await navigateToFolder(currentPath.value);
        Get.snackbar(
          'Queued',
          pastedCount > 0
              ? 'Queued $pastedCount item(s) for copy from OS clipboard'
              : 'No valid clipboard files/folders to queue',
          backgroundColor: (pastedCount > 0 ? Colors.green : Colors.orange)
              .withValues(alpha: 0.9),
          colorText: Colors.white,
        );
        return;
      }

      final source = clipboardItem.value!;
      final sourceName = source.path.split(Platform.pathSeparator).last;
      final destPath =
          '${currentPath.value}${Platform.pathSeparator}$sourceName';

      isLoading.value = true;

      if (source is File) {
        if (clipboardOperation.value == 'copy') {
          await _addCopyTask(currentPath.value, sourceName, source.path);
          Get.snackbar(
            'Queued',
            'File copy queued: $sourceName',
            backgroundColor: Colors.blue.withValues(alpha: 0.9),
            colorText: Colors.white,
          );
        } else if (clipboardOperation.value == 'cut') {
          await source.rename(destPath);
          clipboardItem.value = null;
          clipboardOperation.value = '';
          Get.snackbar(
            'Success',
            'File moved: $sourceName',
            backgroundColor: Colors.green.withValues(alpha: 0.9),
            colorText: Colors.white,
          );
        }
      } else if (source is Directory) {
        if (clipboardOperation.value == 'copy') {
          await _addCopyTask(currentPath.value, sourceName, source.path);
          Get.snackbar(
            'Queued',
            'Folder copy queued: $sourceName',
            backgroundColor: Colors.blue.withValues(alpha: 0.9),
            colorText: Colors.white,
          );
        } else if (clipboardOperation.value == 'cut') {
          await source.rename(destPath);
          clipboardItem.value = null;
          clipboardOperation.value = '';
          Get.snackbar(
            'Success',
            'Folder moved: $sourceName',
            backgroundColor: Colors.green.withValues(alpha: 0.9),
            colorText: Colors.white,
          );
        }
      }

      await navigateToFolder(currentPath.value);
    } catch (e) {
      errorMessage.value = 'Error pasting: $e';
      Get.snackbar(
        'Error',
        'Failed to paste',
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> _pasteFromExternalPathToDestination(
    String sourcePath,
    String destinationFolderPath,
  ) async {
    try {
      if (rootPath.value.isNotEmpty &&
          !_isWithinRoot(destinationFolderPath, rootPath.value)) {
        return false;
      }

      final file = File(sourcePath);
      if (await file.exists()) {
        final sourceName = sourcePath.split(Platform.pathSeparator).last;
        final destPath =
            '$destinationFolderPath${Platform.pathSeparator}$sourceName';
        if (_normalizePath(destPath) == _normalizePath(sourcePath) ||
            await File(destPath).exists()) {
          return false;
        }
        await _addCopyTask(destinationFolderPath, sourceName, sourcePath);
        return true;
      }

      final dir = Directory(sourcePath);
      if (await dir.exists()) {
        final sourceName = sourcePath.split(Platform.pathSeparator).last;
        final destPath =
            '$destinationFolderPath${Platform.pathSeparator}$sourceName';
        if (_normalizePath(destPath) == _normalizePath(sourcePath) ||
            await Directory(destPath).exists()) {
          return false;
        }
        await _addCopyTask(destinationFolderPath, sourceName, sourcePath);
        return true;
      }
    } catch (_) {}

    return false;
  }

  Future<int> _pasteFromExternalPathsToDestination(
    List<String> sourcePaths,
    String destinationFolderPath,
  ) async {
    if (rootPath.value.isNotEmpty &&
        !_isWithinRoot(destinationFolderPath, rootPath.value)) {
      return 0;
    }

    final destinationFolder = _taskDestinationFolder(destinationFolderPath);
    final existing = _findCopyTask(destinationFolder);

    final entriesToAdd = <List<String>>[];
    int processed = 0;

    for (final sourcePath in sourcePaths) {
      processed++;
      taskProgressLabel.value =
          'Adding item $processed of ${sourcePaths.length} to queue...';

      try {
        final file = File(sourcePath);
        if (await file.exists()) {
          final sourceName = sourcePath.split(Platform.pathSeparator).last;
          final uniqueName = _getUniqueFileName(
            destinationFolderPath,
            sourceName,
            sourcePath,
            existing,
            localBuffer: entriesToAdd,
          );
          if (uniqueName.isNotEmpty) {
            entriesToAdd.add([uniqueName, sourcePath]);
          }
          continue;
        }

        final dir = Directory(sourcePath);
        if (await dir.exists()) {
          final sourceName = sourcePath.split(Platform.pathSeparator).last;
          final uniqueName = _getUniqueFileName(
            destinationFolderPath,
            sourceName,
            sourcePath,
            existing,
            localBuffer: entriesToAdd,
          );
          if (uniqueName.isNotEmpty) {
            entriesToAdd.add([uniqueName, sourcePath]);
          }
        }
      } catch (_) {}
    }

    if (entriesToAdd.isNotEmpty) {
      await _addCopyTasksBulk(destinationFolderPath, entriesToAdd);
    }

    return entriesToAdd.length;
  }

  Future<void> importDroppedPaths(
    List<String> sourcePaths, {
    String? destinationFolderPath,
  }) async {
    final destination = destinationFolderPath ?? currentPath.value;
    if (destination.isEmpty) {
      errorMessage.value = 'No destination folder selected';
      return;
    }

    isLoading.value = true;
    taskProgressLabel.value = 'Preparing dropped items...';
    try {
      final importedCount = await _pasteFromExternalPathsToDestination(
        sourcePaths,
        destination,
      );

      await navigateToFolder(currentPath.value);
      Get.snackbar(
        'Drop Import',
        importedCount > 0
            ? 'Imported $importedCount item(s)'
            : 'No valid items imported',
        backgroundColor: (importedCount > 0 ? Colors.green : Colors.orange)
            .withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickAndAddFiles() async {
    try {
      final result = await FilePicker.pickFiles(allowMultiple: true);
      if (result != null) {
        final paths = result.paths.whereType<String>().toList();
        if (paths.isNotEmpty) {
          await importDroppedPaths(paths);
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error picking files',
        e.toString(),
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    }
  }

  Future<void> moveItemToFolder(
    FileSystemEntity source,
    String destinationFolderPath,
  ) async {
    try {
      if (destinationFolderPath.isEmpty) return;
      if (_isHiddenFolderPath(destinationFolderPath)) {
        errorMessage.value = 'Cannot move items into non-editable folder';
        return;
      }
      if (rootPath.value.isNotEmpty &&
          !_isWithinRoot(destinationFolderPath, rootPath.value)) {
        errorMessage.value = 'Invalid destination folder';
        return;
      }

      final sourceName = source.path.split(Platform.pathSeparator).last;
      final destPath =
          '$destinationFolderPath${Platform.pathSeparator}$sourceName';

      if (_normalizePath(source.path) == _normalizePath(destPath)) {
        return;
      }

      isLoading.value = true;

      if (source is File) {
        if (await File(destPath).exists()) {
          Get.snackbar(
            'Skipped',
            'File already exists: $sourceName',
            backgroundColor: Colors.orange.withValues(alpha: 0.9),
            colorText: Colors.white,
          );
          return;
        }
        await source.rename(destPath);
      } else if (source is Directory) {
        if (await Directory(destPath).exists()) {
          Get.snackbar(
            'Skipped',
            'Folder already exists: $sourceName',
            backgroundColor: Colors.orange.withValues(alpha: 0.9),
            colorText: Colors.white,
          );
          return;
        }
        await source.rename(destPath);
      }

      await navigateToFolder(currentPath.value);
      Get.snackbar(
        'Moved',
        'Moved $sourceName',
        backgroundColor: Colors.green.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    } catch (e) {
      errorMessage.value = 'Drag move failed: $e';
      Get.snackbar(
        'Error',
        'Failed to move dropped item',
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    try {
      if (!await destination.exists()) {
        if (Platform.isMacOS && destination.path.contains('/Volumes/')) {
          try {
            final parent = destination.parent.path;
            final name = destination.path.split(Platform.pathSeparator).last;
            await Process.run('osascript', [
              '-e',
              'tell application "Finder" to make new folder at (POSIX file "$parent" as alias) with properties {name:"$name"}',
            ]);
          } catch (_) {
            await destination.create(recursive: true);
          }
        } else {
          await destination.create(recursive: true);
        }
      }

      final List<FileSystemEntity> entities = [];
      try {
        await for (var entity in source.list(recursive: false)) {
          entities.add(entity);
        }
      } catch (_) {
        final folders = await FileHelper.getSubfolders(source.path);
        final files = await FileHelper.getFiles(source.path);
        final separator = Platform.pathSeparator;
        for (final f in folders) {
          entities.add(Directory('${source.path}$separator$f'));
        }
        for (final f in files) {
          entities.add(File('${source.path}$separator$f'));
        }
      }

      for (var entity in entities) {
        final basename = entity.path.split(Platform.pathSeparator).last;
        final targetPath =
            '${destination.path}${Platform.pathSeparator}$basename';

        if (entity is Directory) {
          await _copyDirectory(entity, Directory(targetPath));
        } else if (entity is File) {
          try {
            await entity.copy(targetPath);
          } catch (_) {
            if (Platform.isMacOS) {
              await Process.run('osascript', [
                '-e',
                'tell application "Finder" to duplicate file (POSIX file "${entity.path}" as alias) to folder (POSIX file "${destination.path}" as alias) with replacing',
              ]);
            } else {
              rethrow;
            }
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to copy directory: $e');
    }
  }

  Future<void> deleteItem(FileSystemEntity item) async {
    try {
      final name = item.path.split(Platform.pathSeparator).last;

      try {
        if (item is File) {
          await item.delete();
        } else if (item is Directory) {
          await item.delete(recursive: true);
        }
      } catch (e) {
        if (Platform.isMacOS) {
          final result = await Process.run('osascript', [
            '-e',
            'tell application "Finder" to delete (POSIX file "${item.path}" as alias)',
          ]);
          if (result.exitCode != 0) {
            rethrow;
          }
        } else {
          rethrow;
        }
      }

      Get.snackbar(
        'Success',
        'Deleted: $name',
        backgroundColor: Colors.green.withValues(alpha: 0.9),
        colorText: Colors.white,
      );

      await navigateToFolder(currentPath.value);
    } catch (e) {
      errorMessage.value = 'Error deleting: $e';
      Get.snackbar(
        'Error',
        'Failed to delete',
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    }
  }

  Future<void> renameItem(FileSystemEntity item, String newName) async {
    try {
      final newPath =
          '${Directory(item.path).parent.path}${Platform.pathSeparator}$newName';

      try {
        if (item is File) {
          await item.rename(newPath);
        } else if (item is Directory) {
          await item.rename(newPath);
        }
      } catch (e) {
        if (Platform.isMacOS) {
          final result = await Process.run('osascript', [
            '-e',
            'tell application "Finder" to set name of (POSIX file "${item.path}" as alias) to "$newName"',
          ]);
          if (result.exitCode != 0) {
            rethrow;
          }
        } else {
          rethrow;
        }
      }

      Get.snackbar(
        'Success',
        'Renamed to: $newName',
        backgroundColor: Colors.green.withValues(alpha: 0.9),
        colorText: Colors.white,
      );

      await navigateToFolder(currentPath.value);
    } catch (e) {
      errorMessage.value = 'Error renaming: $e';
      Get.snackbar(
        'Error',
        'Failed to rename',
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    }
  }

  void selectAllFilesInCurrentFolder() {
    final filePaths = items
        .whereType<File>()
        .map((file) => file.path)
        .toList(growable: false);
    selectedFilePaths.assignAll(filePaths);
  }

  void clearFileSelection() {
    selectedFilePaths.clear();
  }

  bool isFileSelected(String filePath) {
    return selectedFilePaths.contains(filePath);
  }

  void toggleFileSelection(String filePath) {
    if (selectedFilePaths.contains(filePath)) {
      selectedFilePaths.remove(filePath);
    } else {
      selectedFilePaths.add(filePath);
    }
  }

  Future<int> deleteSelectedFiles() async {
    if (currentPath.value.isEmpty || selectedFilePaths.isEmpty) {
      return 0;
    }

    isLoading.value = true;
    int deletedCount = 0;
    int removedQueueCount = 0;
    try {
      for (final path in List<String>.from(selectedFilePaths)) {
        if (isPathPendingCopy(path)) {
          final normalizedTarget = _normalizePath(path);
          final tasksToRemove = <FileCopyTask>[];
          for (final task in copyTasks) {
            final entryIndex = task.files.indexWhere(
              (entry) =>
                  entry.length >= 2 &&
                  _normalizePath(
                        '${currentPath.value}${Platform.pathSeparator}${entry[0]}',
                      ) ==
                      normalizedTarget,
            );
            if (entryIndex != -1) {
              task.files.removeAt(entryIndex);
              removedQueueCount++;
              if (task.files.isEmpty) {
                tasksToRemove.add(task);
              }
            }
          }
          if (tasksToRemove.isNotEmpty) {
            copyTasks.removeWhere((t) => tasksToRemove.contains(t));
          }
        } else {
          try {
            final file = File(path);
            if (await file.exists()) {
              await file.delete();
              deletedCount++;
            }
          } catch (_) {}
        }
      }

      if (removedQueueCount > 0) {
        copyTasks.refresh();
        await _saveCopyTasks();
      }

      selectedFilePaths.clear();
      await navigateToFolder(currentPath.value);
      return deletedCount + removedQueueCount;
    } finally {
      isLoading.value = false;
    }
  }

  Future<int> deleteAllFilesInCurrentFolder() async {
    if (currentPath.value.isEmpty) {
      return 0;
    }

    isLoading.value = true;
    int deletedCount = 0;
    try {
      final files = items.whereType<File>().toList(growable: false);
      for (final file in files) {
        try {
          if (await file.exists()) {
            await file.delete();
            deletedCount++;
          }
        } catch (_) {}
      }
      selectedFilePaths.clear();
      await navigateToFolder(currentPath.value);
      return deletedCount;
    } finally {
      isLoading.value = false;
    }
  }
}
