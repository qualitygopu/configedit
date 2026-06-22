import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/file_manager_controller.dart';

class FileManagerScreen extends StatefulWidget {
  const FileManagerScreen({super.key});

  @override
  State<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends State<FileManagerScreen> {
  late FileManagerController controller;
  late TextEditingController _folderNameController;
  late TextEditingController _renameController;
  late AudioPlayer _audioPlayer;
  StreamSubscription<void>? _playerCompleteSub;
  String? _previewingFilePath;
  bool _isDropOver = false;

  @override
  void initState() {
    super.initState();
    controller = Get.put(FileManagerController());
    _folderNameController = TextEditingController();
    _renameController = TextEditingController();
    _audioPlayer = AudioPlayer();
    _playerCompleteSub = _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _previewingFilePath = null;
      });
    });
  }

  @override
  void dispose() {
    _playerCompleteSub?.cancel();
    _audioPlayer.dispose();
    _folderNameController.dispose();
    _renameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Column(
        children: [
          // Toolbar
          _buildToolbar(theme),

          // Breadcrumbs
          Obx(
            () => controller.currentPath.value.isNotEmpty
                ? _buildBreadcrumbs(theme)
                : const SizedBox.shrink(),
          ),

          // Error message
          Obx(
            () => controller.errorMessage.value.isNotEmpty
                ? _buildErrorBanner(theme)
                : const SizedBox.shrink(),
          ),

          // Split view: folders (left) + files (right)
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.currentPath.value.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 64,
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Select _QTRON folder to get started',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                );
              }

              final folderItems = controller.items
                  .whereType<Directory>()
                  .toList(growable: false);
              final fileItems = controller.items.whereType<File>().toList(
                growable: false,
              );

              return DropTarget(
                onDragEntered: (_) => setState(() => _isDropOver = true),
                onDragExited: (_) => setState(() => _isDropOver = false),
                onDragDone: (detail) async {
                  setState(() => _isDropOver = false);
                  final paths = detail.files
                      .map((xFile) => xFile.path)
                      .where((path) => path.isNotEmpty)
                      .toList();
                  if (paths.isNotEmpty) {
                    await controller.importDroppedPaths(paths);
                  }
                },
                child: Stack(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 280,
                          child: _buildFolderSideView(theme, folderItems),
                        ),
                        VerticalDivider(width: 1, color: theme.dividerColor),
                        Expanded(child: _buildFileListView(theme, fileItems)),
                      ],
                    ),
                    if (_isDropOver)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.12,
                            ),
                            alignment: Alignment.center,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: theme.scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              child: Text(
                                'Drop files/folders to import here',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: Obx(
        () => Row(
          children: [
            // Back button
            if (controller.currentPath.value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Go Back',
                  onPressed: () => controller.goBack(),
                ),
              ),

            // Create Folder button
            if (controller.currentPath.value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ElevatedButton.icon(
                  onPressed: () => _showCreateFolderDialog(theme),
                  icon: const Icon(Icons.create_new_folder),
                  label: const Text('New Folder'),
                ),
              ),

            // Paste button
            if (controller.currentPath.value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ElevatedButton.icon(
                  onPressed: () => controller.pasteItem(),
                  icon: const Icon(Icons.paste),
                  label: Text(
                    controller.clipboardItem.value != null &&
                            controller.clipboardOperation.value == 'cut'
                        ? 'Paste (Move)'
                        : 'Paste',
                  ),
                ),
              ),

            if (controller.currentPath.value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: OutlinedButton.icon(
                  onPressed: controller.items.whereType<File>().isEmpty
                      ? null
                      : () => controller.selectAllFilesInCurrentFolder(),
                  icon: const Icon(Icons.select_all, size: 16),
                  label: const Text('Select All Files'),
                ),
              ),

            if (controller.selectedFilePaths.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton.icon(
                  onPressed: () => controller.clearFileSelection(),
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: Text('Clear (${controller.selectedFilePaths.length})'),
                ),
              ),

            const Spacer(),

            // Refresh button
            if (controller.selectedFilePaths.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: OutlinedButton.icon(
                  onPressed: () => _showDeleteSelectedFilesConfirmation(),
                  icon: const Icon(Icons.delete, size: 16),
                  label: Text(
                    'Delete (${controller.selectedFilePaths.length})',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            if (controller.currentPath.value.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: () =>
                    controller.navigateToFolder(controller.currentPath.value),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumbs(ThemeData theme) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Obx(
        () => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                for (int i = 0; i < controller.breadcrumbs.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Row(
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 36),
                          ),
                          onPressed: () => controller.navigateToBreadcrumb(
                            controller.breadcrumbs[i],
                          ),
                          child: Text(
                            controller.breadcrumbs[i],
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: i == controller.breadcrumbs.length - 1
                                  ? theme.colorScheme.primary
                                  : theme.textTheme.bodyMedium?.color,
                              fontWeight: i == controller.breadcrumbs.length - 1
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (i < controller.breadcrumbs.length - 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: theme.dividerColor,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.red.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              controller.errorMessage.value,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => controller.errorMessage.value = '',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderSideView(ThemeData theme, List<Directory> folders) {
    final rootName = controller.rootPath.value.isEmpty
        ? 'Root'
        : controller.rootPath.value.split(Platform.pathSeparator).last;

    return Container(
      color: theme.cardColor.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Folders',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.home_filled, size: 18),
            title: Text(rootName),
            selected: controller.currentPath.value == controller.rootPath.value,
            onTap: controller.rootPath.value.isEmpty
                ? null
                : () => controller.navigateToFolder(controller.rootPath.value),
          ),
          const Divider(height: 1),
          Expanded(
            child: controller.rootPath.value.isEmpty
                ? Center(
                    child: Text(
                      'No root folder',
                      style: theme.textTheme.bodySmall,
                    ),
                  )
                : (folders.isEmpty
                      ? Center(
                          child: Text(
                            'No subfolders',
                            style: theme.textTheme.bodySmall,
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: folders.length,
                          itemBuilder: (context, index) {
                            final folder = folders[index];
                            final name = folder.path
                                .split(Platform.pathSeparator)
                                .last;
                            return DragTarget<FileSystemEntity>(
                              onWillAcceptWithDetails: (details) {
                                final data = details.data;
                                final sourceParent = Directory(
                                  data.path,
                                ).parent.path;
                                return sourceParent != folder.path;
                              },
                              onAcceptWithDetails: (details) async {
                                await controller.moveItemToFolder(
                                  details.data,
                                  folder.path,
                                );
                              },
                              builder: (context, candidateData, rejectedData) {
                                final isHovering = candidateData.isNotEmpty;
                                return Container(
                                  color: isHovering
                                      ? theme.colorScheme.primary.withValues(
                                          alpha: 0.12,
                                        )
                                      : Colors.transparent,
                                  child: ListTile(
                                    dense: true,
                                    leading: Icon(
                                      Icons.folder,
                                      color: theme.colorScheme.primary,
                                      size: 18,
                                    ),
                                    title: Text(
                                      name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    selected:
                                        controller.currentPath.value ==
                                        folder.path,
                                    onTap: () => controller.navigateToFolder(
                                      folder.path,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        )),
          ),
        ],
      ),
    );
  }

  Widget _buildFileListView(ThemeData theme, List<File> files) {
    if (files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insert_drive_file_outlined,
              size: 52,
              color: theme.colorScheme.primary.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 10),
            Text('No files in this folder', style: theme.textTheme.bodyMedium),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) {
        final item = files[index];
        return _buildFileItem(theme, item);
      },
    );
  }

  Widget _buildFileItem(ThemeData theme, FileSystemEntity item) {
    final name = item.path.split(Platform.pathSeparator).last;
    final size = _getItemSize(item);

    return Obx(() {
      final selected = controller.isFileSelected(item.path);
      return LongPressDraggable<FileSystemEntity>(
        data: item,
        feedback: Material(
          elevation: 4,
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.primary),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.description, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                Text(name),
              ],
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.45,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: Icon(
                Icons.description,
                color: theme.colorScheme.secondary,
              ),
              title: Text(name),
              subtitle: size != null ? Text(size) : null,
              trailing: _buildFileTrailingActions(theme, item),
            ),
          ),
        ),
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : null,
          child: ListTile(
            leading: Checkbox(
              value: selected,
              onChanged: (_) => controller.toggleFileSelection(item.path),
            ),
            title: Row(
              children: [
                Icon(Icons.description, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                Expanded(child: Text(name, overflow: TextOverflow.ellipsis)),
              ],
            ),
            subtitle: size != null ? Text(size) : null,
            trailing: _buildFileTrailingActions(theme, item),
            onTap: null,
          ),
        ),
      );
    });
  }

  Widget _buildFileTrailingActions(ThemeData theme, FileSystemEntity item) {
    final isMp3 = item is File && item.path.toLowerCase().endsWith('.mp3');
    final isPreviewing = _previewingFilePath == item.path;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isMp3)
          IconButton(
            tooltip: isPreviewing ? 'Stop Preview' : 'Play Preview',
            icon: Icon(
              isPreviewing ? Icons.stop_circle_outlined : Icons.play_arrow,
              size: 20,
            ),
            onPressed: () => _togglePreview(item),
          ),
        _buildFileItemActions(theme, item),
      ],
    );
  }

  void _showDeleteSelectedFilesConfirmation() {
    final selectedCount = controller.selectedFilePaths.length;
    if (selectedCount == 0) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Files'),
        content: Text('Delete $selectedCount selected file(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final deletedCount = await controller.deleteSelectedFiles();
              if (deletedCount > 0) {
                Get.snackbar(
                  'Deleted',
                  'Deleted $deletedCount file(s)',
                  backgroundColor: Colors.green.withValues(alpha: 0.9),
                  colorText: Colors.white,
                );
              } else {
                Get.snackbar(
                  'Delete Selected',
                  'No files were deleted',
                  backgroundColor: Colors.orange.withValues(alpha: 0.9),
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItemActions(ThemeData theme, FileSystemEntity item) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleFileAction(value, item),
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem(
          value: 'copy',
          child: Row(
            children: [
              Icon(Icons.content_copy, size: 18),
              SizedBox(width: 8),
              Text('Copy'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'cut',
          child: Row(
            children: [
              Icon(Icons.cut, size: 18),
              SizedBox(width: 8),
              Text('Cut'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'rename',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text('Rename'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  void _handleFileAction(String action, FileSystemEntity item) {
    switch (action) {
      case 'copy':
        controller.copyItem(item);
        break;
      case 'cut':
        controller.cutItem(item);
        break;
      case 'rename':
        _showRenameDialog(item);
        break;
      case 'delete':
        _showDeleteConfirmation(item);
        break;
    }
  }

  Future<void> _togglePreview(FileSystemEntity item) async {
    if (item is! File || !item.path.toLowerCase().endsWith('.mp3')) {
      return;
    }

    try {
      if (_previewingFilePath == item.path) {
        await _audioPlayer.stop();
        if (!mounted) return;
        setState(() {
          _previewingFilePath = null;
        });
        return;
      }

      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(item.path));
      if (!mounted) return;
      setState(() {
        _previewingFilePath = item.path;
      });
    } catch (e) {
      if (!mounted) return;
      Get.snackbar(
        'Preview Error',
        'Unable to play preview: $e',
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    }
  }

  void _showCreateFolderDialog(ThemeData theme) {
    _folderNameController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Folder'),
        content: TextField(
          controller: _folderNameController,
          decoration: const InputDecoration(
            hintText: 'Folder name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_folderNameController.text.isNotEmpty) {
                controller.createFolder(_folderNameController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(FileSystemEntity item) {
    final oldName = item.path.split(Platform.pathSeparator).last;
    _renameController.text = oldName;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: _renameController,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_renameController.text.isNotEmpty &&
                  _renameController.text != oldName) {
                controller.renameItem(item, _renameController.text);
                Navigator.pop(context);
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(FileSystemEntity item) {
    final name = item.path.split(Platform.pathSeparator).last;
    final isDir = item is Directory;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete'),
        content: Text(
          'Are you sure you want to delete ${isDir ? 'folder' : 'file'} "$name"?'
          '${isDir ? '\nThis will delete all contents inside.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteItem(item);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String? _getItemSize(FileSystemEntity item) {
    try {
      if (item is File) {
        final bytes = item.lengthSync();
        if (bytes < 1024) return '$bytes B';
        if (bytes < 1024 * 1024)
          return '${(bytes / 1024).toStringAsFixed(2)} KB';
        return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
      } else if (item is Directory) {
        return 'Folder';
      }
    } catch (e) {
      debugPrint('Error getting item size: $e');
    }
    return null;
  }
}
