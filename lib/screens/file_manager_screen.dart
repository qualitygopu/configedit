import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:configedit/utils/file_helper.dart';
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
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Obx(
                        () => Text(
                          controller.taskProgressLabel.value.isNotEmpty
                              ? controller.taskProgressLabel.value
                              : 'Loading...',
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                );
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _buildFileListView(theme, fileItems),
                              ),
                              _buildStatusBar(theme, fileItems),
                            ],
                          ),
                        ),
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

            // Add Files button
            if (controller.currentPath.value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ElevatedButton.icon(
                  onPressed: () => controller.pickAndAddFiles(),
                  icon: const Icon(Icons.add_to_photos),
                  label: const Text('Add Files'),
                ),
              ),

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
              Obx(() {
                final hasPending = controller.hasPendingTasksForCurrentFolder;
                if (!hasPending) return const SizedBox.shrink();
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: OutlinedButton.icon(
                        onPressed: () => controller.renamePendingFiles(
                          controller.currentPath.value,
                        ),
                        icon: const Icon(
                          Icons.drive_file_rename_outline,
                          size: 16,
                        ),
                        label: const Text('Rename'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            controller.randomizeAndRenamePendingFiles(
                              controller.currentPath.value,
                            ),
                        icon: const Icon(Icons.shuffle, size: 16),
                        label: const Text('Random'),
                      ),
                    ),
                  ],
                );
              }),

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
              Obx(() {
                final selected = controller.selectedFilePaths;
                final pendingCount = selected
                    .where((p) => controller.isPathPendingCopy(p))
                    .length;
                final normalCount = selected.length - pendingCount;

                String labelText = 'Delete (${selected.length})';
                IconData iconData = Icons.delete;

                if (normalCount == 0) {
                  labelText = 'Remove (${selected.length})';
                  iconData = Icons.remove_circle_outline;
                } else if (pendingCount > 0) {
                  labelText = 'Delete/Remove (${selected.length})';
                  iconData = Icons.delete_sweep;
                }

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: OutlinedButton.icon(
                        onPressed: () => _showMultiplySelectedFilesDialog(),
                        icon: const Icon(Icons.copy_all, size: 16),
                        label: Text('Multiply (${selected.length})'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: OutlinedButton.icon(
                        onPressed: () => _showDeleteSelectedFilesConfirmation(),
                        icon: Icon(iconData, size: 16),
                        label: Text(labelText),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            if (controller.isTaskExecutionInProgress.value)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(
                        value: controller.taskTotalItems.value > 0
                            ? controller.taskProcessedItems.value /
                                  controller.taskTotalItems.value
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        controller.taskProgressLabel.value.isNotEmpty
                            ? controller.taskProgressLabel.value
                            : 'Processing ${controller.taskProcessedItems.value} of ${controller.taskTotalItems.value} items',
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            if (controller.currentPath.value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final selected = await FileHelper.selectDirectory();
                    if (selected != null) {
                      controller.backupFolderPath.value = selected;
                    }
                  },
                  icon: const Icon(Icons.backup, size: 16),
                  label: Obx(() {
                    final folder = controller.backupFolderPath.value;
                    return Text(
                      folder.isEmpty
                          ? 'Backup Path'
                          : 'Backup: ${folder.split(Platform.pathSeparator).last}',
                    );
                  }),
                ),
              ),
            if (controller.currentPath.value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ElevatedButton.icon(
                  onPressed:
                      controller.copyTasks.isEmpty ||
                          controller.isTaskExecutionInProgress.value
                      ? null
                      : () async {
                          await controller.executeCopyTasks();
                          if (controller.currentPath.value.isNotEmpty) {
                            await controller.navigateToFolder(
                              controller.currentPath.value,
                            );
                          }
                          Get.snackbar(
                            'Tasks Executed',
                            'Task queue execution finished',
                            backgroundColor: Colors.green.withValues(
                              alpha: 0.9,
                            ),
                            colorText: Colors.white,
                          );
                        },
                  icon: controller.isTaskExecutionInProgress.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.playlist_play),
                  label: Obx(
                    () => Text(
                      controller.copyTasks.isEmpty
                          ? 'No Tasks'
                          : 'Run Tasks (${controller.copyTasks.length})',
                    ),
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
                            return Obx(() {
                              final isPending = controller.isPathPendingCopy(
                                folder.path,
                              );
                              final isCurrentCopying =
                                  controller.currentCopyingPath.value ==
                                  folder.path;

                              return DragTarget<FileSystemEntity>(
                                onWillAcceptWithDetails: (details) {
                                  if (isPending) return false;
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
                                    child: Opacity(
                                      opacity: isPending ? 0.45 : 1.0,
                                      child: ListTile(
                                        dense: true,
                                        leading: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.folder,
                                              color: theme.colorScheme.primary,
                                              size: 18,
                                            ),
                                            if (isCurrentCopying) ...[
                                              const SizedBox(width: 4),
                                              const SizedBox(
                                                width: 10,
                                                height: 10,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 1.5,
                                                    ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        title: Text(
                                          name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        selected:
                                            controller.currentPath.value ==
                                            folder.path,
                                        trailing:
                                            isPending &&
                                                !controller
                                                    .isTaskExecutionInProgress
                                                    .value
                                            ? IconButton(
                                                icon: const Icon(
                                                  Icons.close,
                                                  size: 16,
                                                  color: Colors.red,
                                                ),
                                                tooltip: 'Remove from Queue',
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                                onPressed: () => controller
                                                    .removeFileFromQueue(
                                                      folder.path,
                                                    ),
                                              )
                                            : null,
                                        onTap: isPending
                                            ? null
                                            : () => controller.navigateToFolder(
                                                folder.path,
                                              ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            });
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

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(() {
          final columns = [
            DataColumn(
              label: const Text('Name'),
              onSort: (columnIndex, ascending) => controller.toggleSort('Name'),
            ),
            DataColumn(
              label: const Text('Source Path'),
              onSort: (columnIndex, ascending) =>
                  controller.toggleSort('SourcePath'),
            ),
            DataColumn(
              label: const Text('Size'),
              onSort: (columnIndex, ascending) => controller.toggleSort('Size'),
            ),
            DataColumn(
              label: const Text('Status'),
              onSort: (columnIndex, ascending) =>
                  controller.toggleSort('Status'),
            ),
            const DataColumn(label: Text('Actions')),
          ];

          final rows = files.map((file) {
            final name = controller.getItemName(file);
            final sourcePath = controller.getItemSourcePath(file);
            final sizeInt = controller.getItemSize(file);
            final status = controller.getItemStatus(file);
            final selected = controller.isFileSelected(file.path);
            final isPending = controller.isPathPendingCopy(file.path);
            final isCurrentCopying =
                controller.currentCopyingPath.value == file.path;

            // Format size
            String sizeStr = '-';
            if (sizeInt >= 0) {
              if (sizeInt < 1024) {
                sizeStr = '$sizeInt B';
              } else if (sizeInt < 1024 * 1024) {
                sizeStr = '${(sizeInt / 1024).toStringAsFixed(1)} KB';
              } else {
                sizeStr = '${(sizeInt / (1024 * 1024)).toStringAsFixed(1)} MB';
              }
            }

            return DataRow(
              selected: selected,
              onSelectChanged: (bool? val) {
                controller.toggleFileSelection(file.path);
              },
              cells: [
                DataCell(
                  LongPressDraggable<FileSystemEntity>(
                    maxSimultaneousDrags: isPending ? 0 : null,
                    data: file,
                    feedback: Material(
                      elevation: 4,
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.colorScheme.primary),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.description,
                              color: theme.colorScheme.secondary,
                            ),
                            const SizedBox(width: 8),
                            Text(name),
                          ],
                        ),
                      ),
                    ),
                    child: Opacity(
                      opacity: isPending ? 0.45 : 1.0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.description,
                            color: theme.colorScheme.secondary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            name,
                            style: TextStyle(
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Opacity(
                    opacity: isPending ? 0.45 : 1.0,
                    child: Text(
                      sourcePath.isNotEmpty ? sourcePath : '-',
                      style: TextStyle(
                        fontStyle: sourcePath.isNotEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                        color: theme.textTheme.bodyMedium?.color?.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Opacity(
                    opacity: isPending ? 0.45 : 1.0,
                    child: Text(sizeStr),
                  ),
                ),
                DataCell(
                  Opacity(
                    opacity: isPending ? 0.45 : 1.0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCurrentCopying) ...[
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          status,
                          style: TextStyle(
                            color: status == 'Completed'
                                ? Colors.green
                                : (status == 'Copying'
                                      ? theme.colorScheme.primary
                                      : Colors.orange),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(
                  _buildFileTrailingActions(
                    theme,
                    file,
                    enableActions: true,
                    isPending: isPending,
                  ),
                ),
              ],
            );
          }).toList();

          int? sortColumnIndex;
          if (controller.sortColumn.value == 'Name') sortColumnIndex = 0;
          if (controller.sortColumn.value == 'SourcePath') sortColumnIndex = 1;
          if (controller.sortColumn.value == 'Size') sortColumnIndex = 2;
          if (controller.sortColumn.value == 'Status') sortColumnIndex = 3;

          return DataTable(
            sortColumnIndex: sortColumnIndex,
            sortAscending: controller.sortAscending.value,
            showCheckboxColumn: true,
            columns: columns,
            rows: rows,
          );
        }),
      ),
    );
  }

  Widget _buildFileTrailingActions(
    ThemeData theme,
    FileSystemEntity item, {
    required bool enableActions,
    bool isPending = false,
  }) {
    final isMp3 = item is File && item.path.toLowerCase().endsWith('.mp3');
    final isPreviewing = _previewingFilePath == item.path;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isMp3 && !isPending)
          IconButton(
            tooltip: isPreviewing ? 'Stop Preview' : 'Play Preview',
            icon: Icon(
              isPreviewing ? Icons.stop_circle_outlined : Icons.play_arrow,
              size: 20,
            ),
            onPressed: enableActions ? () => _togglePreview(item) : null,
          ),
        _buildFileItemActions(
          theme,
          item,
          enabled: enableActions,
          isPending: isPending,
        ),
      ],
    );
  }

  void _showDeleteSelectedFilesConfirmation() {
    final selected = controller.selectedFilePaths;
    final selectedCount = selected.length;
    if (selectedCount == 0) return;

    final pendingCount = selected
        .where((p) => controller.isPathPendingCopy(p))
        .length;
    final normalCount = selectedCount - pendingCount;

    String titleText = 'Delete Selected Files';
    String contentText = 'Delete $selectedCount selected file(s)?';
    String actionLabel = 'Delete';

    if (normalCount == 0) {
      titleText = 'Remove Pending Copy Files';
      contentText =
          'Remove $selectedCount selected pending file(s) from the copy queue?';
      actionLabel = 'Remove';
    } else if (pendingCount > 0) {
      titleText = 'Delete & Remove Selected Files';
      contentText =
          'Delete $normalCount file(s) from disk and remove $pendingCount file(s) from copy queue?';
      actionLabel = 'Delete/Remove';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titleText),
        content: Text(contentText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final count = await controller.deleteSelectedFiles();
              if (count > 0) {
                String successMsg = '';
                if (normalCount == 0) {
                  successMsg = 'Removed $count file(s) from copy queue';
                } else if (pendingCount > 0) {
                  successMsg = 'Processed $count file(s) (delete/remove)';
                } else {
                  successMsg = 'Deleted $count file(s)';
                }
                Get.snackbar(
                  'Success',
                  successMsg,
                  backgroundColor: Colors.green.withValues(alpha: 0.9),
                  colorText: Colors.white,
                );
              } else {
                Get.snackbar(
                  'Operation Failed',
                  'No files were deleted or removed',
                  backgroundColor: Colors.orange.withValues(alpha: 0.9),
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  void _showMultiplySelectedFilesDialog() {
    final textController = TextEditingController(text: '5');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.copy_all, color: Colors.blue),
            SizedBox(width: 8),
            Text('Multiply Selected Files'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Specify how many copies of each selected file to add to the copy queue:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Number of copies',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.filter_1),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final copies = int.tryParse(textController.text) ?? 0;
              if (copies <= 0) {
                Get.snackbar(
                  'Invalid Value',
                  'Please enter a valid positive number',
                  backgroundColor: Colors.red.withValues(alpha: 0.9),
                  colorText: Colors.white,
                );
                return;
              }
              Navigator.pop(context);
              controller.multiplySelectedFiles(copies);
            },
            child: const Text('Multiply'),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItemActions(
    ThemeData theme,
    FileSystemEntity item, {
    required bool enabled,
    bool isPending = false,
  }) {
    if (isPending) {
      return PopupMenuButton<String>(
        enabled: enabled && !controller.isTaskExecutionInProgress.value,
        onSelected: (value) {
          if (value == 'remove') {
            controller.removeFileFromQueue(item.path);
          } else if (value == 'rename') {
            _showRenameDialog(item);
          }
        },
        itemBuilder: (BuildContext context) => [
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
          const PopupMenuItem(
            value: 'remove',
            child: Row(
              children: [
                Icon(Icons.remove_circle_outline, size: 18, color: Colors.red),
                SizedBox(width: 8),
                Text('Remove from Queue', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      );
    }

    return PopupMenuButton<String>(
      enabled: enabled,
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
    final isPending = controller.isPathPendingCopy(item.path);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isPending ? 'Rename Pending File' : 'Rename'),
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
                if (isPending) {
                  controller.renamePendingFile(
                    item.path,
                    _renameController.text,
                  );
                } else {
                  controller.renameItem(item, _renameController.text);
                }
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

  Widget _buildStatusBar(ThemeData theme, List<File> files) {
    final pendingCount = files
        .where((f) => controller.isPathPendingCopy(f.path))
        .length;

    int totalBytes = 0;
    for (final f in files) {
      final size = controller.getItemSize(f);
      if (size > 0) {
        totalBytes += size;
      }
    }

    String sizeStr = '-';
    if (totalBytes > 0) {
      if (totalBytes < 1024) {
        sizeStr = '$totalBytes B';
      } else if (totalBytes < 1024 * 1024) {
        sizeStr = '${(totalBytes / 1024).toStringAsFixed(1)} KB';
      } else {
        sizeStr = '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    }

    return Obx(() {
      final selectedCount = controller.selectedFilePaths.length;
      return Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: theme.dividerColor, width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedCount > 0
                  ? '$selectedCount of ${files.length} selected'
                  : pendingCount > 0
                  ? '${files.length} file(s) total ($pendingCount pending)'
                  : '${files.length} file(s) total',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
            Text(
              'Total Size: $sizeStr',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    });
  }
}
