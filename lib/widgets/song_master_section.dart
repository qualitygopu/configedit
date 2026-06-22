import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/config_model.dart';
import '../controllers/config_controller.dart';
import '../utils/file_helper.dart';

class SongMasterSection extends StatefulWidget {
  const SongMasterSection({super.key});

  @override
  State<SongMasterSection> createState() => _SongMasterSectionState();
}

class _SongMasterSectionState extends State<SongMasterSection> {
  final ConfigController controller = Get.find<ConfigController>();
  final RxBool showSystemSounds = false.obs; // Toggle to show system sounds

  void _showAddEditDialog([SongMasterItem? item, int? index]) {
    Get.dialog(
      _SongMasterAddEditDialog(
        item: item,
        index: index,
        onSave: (newItem) {
          if (item != null && index != null) {
            controller.updateSongMasterItem(index, newItem);
          } else {
            controller.addSongMasterItem(newItem);
          }
        },
      ),
    );
  }

  void _confirmDelete(int index, SongMasterItem item) {
    // Check if this item index is used in any alarm SC list
    List<String> referencingAlarms = [];
    for (final alarm in controller.alarms) {
      if (alarm.sc.contains(index)) {
        referencingAlarms.add(alarm.tit);
      }
    }

    final theme = Theme.of(context);
    if (referencingAlarms.isNotEmpty) {
      Get.dialog(
        AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text(
            "Cannot Delete Sound",
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          content: Text(
            "This sound is currently used in the playback sequence of the following alarm(s):\n\n"
            "${referencingAlarms.map((e) => '• $e').join('\n')}\n\n"
            "Please remove it from those sequences before deleting.",
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                "OK",
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
          ],
        ),
      );
      return;
    }

    Get.dialog(
      AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          "Delete Sound",
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: Text(
          "Are you sure you want to delete '${item.name}' from the sound library?",
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteSongMasterItem(index);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Song Master",
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Manage available sounds, announcement formats, and custom playlists",
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => _showAddEditDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Add New Sound"),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Filters bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withOpacity(0.01),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.onSurface.withOpacity(0.08),
            ),
          ),
          child: Row(
            children: [
              // Show System Sounds toggle
              Obx(
                () => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Show System Sounds",
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: showSystemSounds.value,
                      onChanged: (val) => showSystemSounds.value = val,
                      activeColor: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Grid/Table of Sounds
        Obx(() {
          var list = controller.songMaster.asMap().entries.toList();

          // Apply filters

          if (!showSystemSounds.value) {
            list = list.where((entry) => entry.value.source != "SYS").toList();
          }

          if (list.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.01),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withOpacity(0.08),
                ),
              ),
              child: Center(
                child: Text(
                  "No sounds match your filters",
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.38),
                  ),
                ),
              ),
            );
          }

          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.01),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.onSurface.withOpacity(0.08),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  theme.colorScheme.onSurface.withOpacity(0.03),
                ),
                dataRowMinHeight: 52,
                dataRowMaxHeight: 52,
                columns: [
                  DataColumn(
                    label: Text(
                      "INDEX",
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "NAME",
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "CODE",
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "CATEGORY",
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "SOURCE",
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "ID/COUNT",
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "ACTIONS",
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                rows: list.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          idx.toString(),
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          item.name,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            // fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          item.code,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          item.category,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(
                              0.38,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: item.source == 'SYS'
                                ? theme.colorScheme.primary.withOpacity(0.15)
                                : const Color(0xFFF59E0B).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: item.source == 'SYS'
                                  ? theme.colorScheme.primary
                                  : const Color(0xFFF59E0B),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            item.source == 'SYS' ? 'SYSTEM' : 'CUSTOM',
                            style: TextStyle(
                              color: item.source == 'SYS'
                                  ? theme.colorScheme.primary
                                  : const Color(0xFFFBBF24),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          item.id.toString(),
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.edit_outlined,
                                color: theme.colorScheme.primary,
                                size: 18,
                              ),
                              onPressed: () => _showAddEditDialog(item, idx),
                            ),
                            if (item.source != 'SYS')
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                  size: 18,
                                ),
                                onPressed: () => _confirmDelete(idx, item),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _SongMasterAddEditDialog extends StatefulWidget {
  final SongMasterItem? item;
  final int? index;
  final Function(SongMasterItem) onSave;

  const _SongMasterAddEditDialog({this.item, this.index, required this.onSave});

  @override
  State<_SongMasterAddEditDialog> createState() =>
      _SongMasterAddEditDialogState();
}

class _SongMasterAddEditDialogState extends State<_SongMasterAddEditDialog> {
  late TextEditingController nameCtrl;
  late TextEditingController categoryCtrl;
  late TextEditingController idCtrl;
  late TextEditingController fileNameCtrl;

  String selectedPlaybackMode = 'Single';
  String sourceVal = 'CUS';

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    nameCtrl = TextEditingController(text: item?.name ?? '');
    categoryCtrl = TextEditingController(text: item?.category ?? '');
    idCtrl = TextEditingController(text: item?.id?.toString() ?? '1');
    sourceVal = item?.source ?? 'CUS';

    final initialCode = item?.code ?? '';
    final isSystemMode =
        initialCode == 'LP' ||
        initialCode == 'hr' ||
        initialCode == 'dw' ||
        initialCode == 'LPW';

    selectedPlaybackMode = isSystemMode ? initialCode : 'Single';
    fileNameCtrl = TextEditingController(text: isSystemMode ? '' : initialCode);
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    categoryCtrl.dispose();
    idCtrl.dispose();
    fileNameCtrl.dispose();
    super.dispose();
  }

  final ConfigController controller = Get.find<ConfigController>();

  Future<void> _selectFolder() async {
    final masterLoc = controller.qtronFolder.value;
    if (masterLoc.isEmpty) {
      Get.snackbar(
        'QTRON Folder',
        'No QTRON master location detected or set. Enter storage folder manually.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }

    try {
      final subfolders = await FileHelper.getSubfolders(masterLoc);
      subfolders.removeWhere((f) => f.startsWith('@'));

      if (subfolders.isEmpty) {
        Get.snackbar(
          'QTRON Folder',
          'No subfolders found in $masterLoc. Please create folders in it first.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orangeAccent,
          colorText: Colors.white,
        );
        return;
      }

      final theme = Get.theme;
      final String? selected = await Get.dialog<String>(
        AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text(
            'Select Storage Folder',
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          content: SizedBox(
            width: 300,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: subfolders.length,
              itemBuilder: (context, index) {
                final folder = subfolders[index];
                return ListTile(
                  title: Text(
                    folder,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                  onTap: () => Get.back(result: folder),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
      );

      if (selected != null) {
        setState(() {
          categoryCtrl.text = selected;
          fileNameCtrl.clear();
        });

        final separator = masterLoc.contains('\\') ? '\\' : '/';
        final folderPath = '$masterLoc$separator$selected';
        final fileCount = await FileHelper.getFileCount(folderPath);
        setState(() {
          idCtrl.text = fileCount.toString();
        });
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to retrieve subfolders or file count: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _selectSingleFile() async {
    final masterLoc = controller.qtronFolder.value;
    final folder = categoryCtrl.text.trim();
    if (masterLoc.isEmpty || folder.isEmpty) {
      Get.snackbar(
        'Storage Folder',
        'Please set the QTRON folder and select a storage folder first.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }

    try {
      final separator = masterLoc.contains('\\') ? '\\' : '/';
      final folderPath = '$masterLoc$separator$folder';
      final files = await FileHelper.getFiles(folderPath);

      if (files.isEmpty) {
        Get.snackbar(
          'Files',
          'No files found in $folderPath',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orangeAccent,
          colorText: Colors.white,
        );
        return;
      }

      final theme = Get.theme;
      final String? selectedFile = await Get.dialog<String>(
        AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text(
            'Select File',
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          content: SizedBox(
            width: 300,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: files.length,
              itemBuilder: (context, index) {
                final file = files[index];
                return ListTile(
                  title: Text(
                    file,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                  onTap: () => Get.back(result: file),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
      );

      if (selectedFile != null) {
        setState(() {
          fileNameCtrl.text = selectedFile;
        });
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to retrieve files: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.item != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.onSurface.withOpacity(0.08),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? "Edit Sound Library Item" : "Add Sound Library Item",
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Song Title / Description
              Text(
                'Song Title / Description',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameCtrl,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. Morning Prayer',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  prefixIcon: Icon(
                    Icons.music_note_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Storage Folder and File Count side-by-side
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Storage Folder',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Obx(() {
                          final hasMaster =
                              controller.qtronFolder.value.isNotEmpty;
                          return TextField(
                            controller: categoryCtrl,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Folder Name',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              prefixIcon: Icon(
                                Icons.folder_open_rounded,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                              suffixIcon: hasMaster
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.arrow_drop_down_circle_outlined,
                                        size: 18,
                                      ),
                                      onPressed: _selectFolder,
                                      tooltip:
                                          'Select folder from Removable Drive',
                                    )
                                  : null,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'File Count',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: idCtrl,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            prefixIcon: Icon(
                              Icons.numbers_rounded,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Playback Mode Dropdown
              Text(
                'Playback Mode',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedPlaybackMode,
                dropdownColor: theme.colorScheme.surface,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  prefixIcon: Icon(
                    Icons.play_circle_outline_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Single',
                    child: Text('Play Single File'),
                  ),
                  DropdownMenuItem(value: 'LP', child: Text('Loop All Files')),
                  DropdownMenuItem(
                    value: 'hr',
                    child: Text('Hour Wise (1-24)'),
                  ),
                  DropdownMenuItem(value: 'dw', child: Text('Day Wise (1-7)')),
                  DropdownMenuItem(
                    value: 'LPW',
                    child: Text('Day Specific Folders'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      selectedPlaybackMode = val;
                    });
                  }
                },
              ),

              // Single File Name Input (shown if playback mode is 'Single')
              if (selectedPlaybackMode == 'Single') ...[
                const SizedBox(height: 16),
                Text(
                  'Single File Name',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() {
                  final hasMaster = controller.qtronFolder.value.isNotEmpty;
                  return TextField(
                    controller: fileNameCtrl,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. morning.mp3',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      prefixIcon: Icon(
                        Icons.audio_file_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      suffixIcon: hasMaster
                          ? IconButton(
                              icon: const Icon(
                                Icons.music_video_outlined,
                                size: 18,
                              ),
                              onPressed: _selectSingleFile,
                              tooltip: 'Select file from Removable Drive',
                            )
                          : null,
                    ),
                  );
                }),
              ],
              const SizedBox(height: 16),

              // Source Type Dropdown
              Text(
                'Source Type',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: sourceVal,
                dropdownColor: theme.colorScheme.surface,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  prefixIcon: Icon(
                    Icons.settings_input_component_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: "SYS", child: Text("System (SYS)")),
                  DropdownMenuItem(value: "CUS", child: Text("Custom (CUS)")),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      sourceVal = val;
                    });
                  }
                },
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      final folder = categoryCtrl.text.trim();
                      final fileCountStr = idCtrl.text.trim();

                      if (name.isEmpty ||
                          folder.isEmpty ||
                          fileCountStr.isEmpty) {
                        Get.snackbar(
                          "Error",
                          "All fields are required",
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.redAccent,
                          colorText: Colors.white,
                        );
                        return;
                      }

                      final fileCount = int.tryParse(fileCountStr) ?? 1;

                      final code = selectedPlaybackMode == 'Single'
                          ? fileNameCtrl.text.trim()
                          : selectedPlaybackMode;

                      if (selectedPlaybackMode == 'Single' && code.isEmpty) {
                        Get.snackbar(
                          "Error",
                          "Single file name is required for Single mode",
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.redAccent,
                          colorText: Colors.white,
                        );
                        return;
                      }

                      final newItem = SongMasterItem(
                        id: fileCount,
                        code: code,
                        category: folder,
                        source: sourceVal,
                        name: name,
                      );

                      widget.onSave(newItem);
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(isEdit ? "Save" : "Add"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
