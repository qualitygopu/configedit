import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'config_controller.dart';
import '../utils/file_helper.dart';

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
  final RxString errorMessage = ''.obs;
  final Rxn<FileSystemEntity> clipboardItem = Rxn<FileSystemEntity>();
  final RxString clipboardOperation = ''.obs; // 'copy' or 'cut'
  final RxList<String> breadcrumbs = <String>[].obs;
  final RxList<String> selectedFilePaths = <String>[].obs;
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
      if (showErrorIfEmpty) {
        errorMessage.value = 'Master qtronFolder is not set';
      }
      return;
    }

    rootPath.value = masterPath;
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

  String _normalizePath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return '';
    final withoutTrailing = trimmed.replaceAll(RegExp(r'[\\/]+$'), '');
    return Platform.isWindows ? withoutTrailing.toLowerCase() : withoutTrailing;
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
      if (!await dir.exists()) {
        errorMessage.value = 'Folder does not exist';
        isLoading.value = false;
        return;
      }

      currentPath.value = path;
      selectedFilePaths.clear();

      // Load items
      final List<FileSystemEntity> loadedItems = [];
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
        errorMessage.value = 'Error reading folder: $e';
      }

      // Sort: folders first, then files
      loadedItems.sort((a, b) {
        bool aIsDir = a is Directory;
        bool bIsDir = b is Directory;
        if (aIsDir != bIsDir) {
          return aIsDir ? -1 : 1;
        }
        String aName = a.path.split(Platform.pathSeparator).last;
        String bName = b.path.split(Platform.pathSeparator).last;
        return aName.compareTo(bName);
      });

      items.assignAll(loadedItems);
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

      await newFolder.create();
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

      if (clipboardItem.value == null || clipboardOperation.value.isEmpty) {
        final externalPaths = await FileHelper.getClipboardFilePaths();
        if (externalPaths.isEmpty) {
          errorMessage.value = 'Nothing to paste';
          return;
        }

        isLoading.value = true;
        int pastedCount = 0;
        for (final sourcePath in externalPaths) {
          final didPaste = await _pasteFromExternalPath(sourcePath);
          if (didPaste) {
            pastedCount++;
          }
        }

        await navigateToFolder(currentPath.value);
        Get.snackbar(
          'Pasted',
          pastedCount > 0
              ? 'Pasted $pastedCount item(s) from OS clipboard'
              : 'No valid clipboard files/folders to paste',
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
        final destFile = File(destPath);
        if (clipboardOperation.value == 'copy') {
          await source.copy(destPath);
          Get.snackbar(
            'Success',
            'File copied: $sourceName',
            backgroundColor: Colors.green.withValues(alpha: 0.9),
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
        await _copyDirectory(source, Directory(destPath));
        if (clipboardOperation.value == 'copy') {
          Get.snackbar(
            'Success',
            'Folder copied: $sourceName',
            backgroundColor: Colors.green.withValues(alpha: 0.9),
            colorText: Colors.white,
          );
        } else if (clipboardOperation.value == 'cut') {
          await source.delete(recursive: true);
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

  Future<bool> _pasteFromExternalPath(String sourcePath) async {
    try {
      final file = File(sourcePath);
      if (await file.exists()) {
        final sourceName = sourcePath.split(Platform.pathSeparator).last;
        final destPath =
            '${currentPath.value}${Platform.pathSeparator}$sourceName';
        if (_normalizePath(destPath) == _normalizePath(sourcePath)) {
          return false;
        }
        await file.copy(destPath);
        return true;
      }

      final dir = Directory(sourcePath);
      if (await dir.exists()) {
        final sourceName = sourcePath.split(Platform.pathSeparator).last;
        final destPath =
            '${currentPath.value}${Platform.pathSeparator}$sourceName';
        if (_normalizePath(destPath) == _normalizePath(sourcePath)) {
          return false;
        }
        await _copyDirectory(dir, Directory(destPath));
        return true;
      }
    } catch (_) {}

    return false;
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
        await file.copy(destPath);
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
        await _copyDirectory(dir, Directory(destPath));
        return true;
      }
    } catch (_) {}

    return false;
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
    try {
      int importedCount = 0;
      for (final sourcePath in sourcePaths) {
        final ok = await _pasteFromExternalPathToDestination(
          sourcePath,
          destination,
        );
        if (ok) {
          importedCount++;
        }
      }

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
        await destination.create(recursive: true);
      }

      await for (var entity in source.list(recursive: false)) {
        final basename = entity.path.split(Platform.pathSeparator).last;
        final targetPath =
            '${destination.path}${Platform.pathSeparator}$basename';

        if (entity is Directory) {
          await _copyDirectory(entity, Directory(targetPath));
        } else if (entity is File) {
          await (entity as File).copy(targetPath);
        }
      }
    } catch (e) {
      throw Exception('Failed to copy directory: $e');
    }
  }

  Future<void> deleteItem(FileSystemEntity item) async {
    try {
      final name = item.path.split(Platform.pathSeparator).last;

      if (item is File) {
        await item.delete();
      } else if (item is Directory) {
        await item.delete(recursive: true);
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

      if (item is File) {
        await item.rename(newPath);
      } else if (item is Directory) {
        await item.rename(newPath);
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
    try {
      for (final path in List<String>.from(selectedFilePaths)) {
        try {
          final file = File(path);
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
