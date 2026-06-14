import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/config_model.dart';
import '../controllers/config_controller.dart';

class SongMasterSection extends StatefulWidget {
  const SongMasterSection({super.key});

  @override
  State<SongMasterSection> createState() => _SongMasterSectionState();
}

class _SongMasterSectionState extends State<SongMasterSection> {
  final ConfigController controller = Get.find<ConfigController>();
  final RxString searchQuery = "".obs;
  final RxString sourceFilter = "ALL".obs; // ALL, SYS, CUS

  void _showAddEditDialog([SongMasterItem? item, int? index]) {
    final isEdit = item != null;
    final idCtrl = TextEditingController(text: item?.id?.toString() ?? '');
    final codeCtrl = TextEditingController(text: item?.code ?? '');
    final categoryCtrl = TextEditingController(text: item?.category ?? '');
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    String sourceVal = item?.source ?? 'CUS';

    final theme = Theme.of(context);
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? "Edit Sound Library Item" : "Add Sound Library Item",
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(labelText: "Name (e.g. Suprabatham)", labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: idCtrl,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(labelText: "ID/Count (e.g. 12 or Folder Name)", labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeCtrl,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(labelText: "Code (e.g. SP, hr, LP)", labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryCtrl,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(labelText: "Category (e.g. SYS, CUS, SP, VO)", labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: sourceVal,
                dropdownColor: theme.colorScheme.surface,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(labelText: "Source Type", labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                items: const [
                  DropdownMenuItem(value: "SYS", child: Text("System (SYS)")),
                  DropdownMenuItem(value: "CUS", child: Text("Custom (CUS)")),
                ],
                onChanged: (val) {
                  if (val != null) sourceVal = val;
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text("Cancel", style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (nameCtrl.text.trim().isEmpty || idCtrl.text.trim().isEmpty) {
                        Get.snackbar("Error", "Name and ID are required", snackPosition: SnackPosition.BOTTOM);
                        return;
                      }
                      
                      // Handle ID as number or string
                      dynamic finalId = int.tryParse(idCtrl.text.trim()) ?? idCtrl.text.trim();
                      
                      final newItem = SongMasterItem(
                        id: finalId,
                        code: codeCtrl.text.trim(),
                        category: categoryCtrl.text.trim(),
                        source: sourceVal,
                        name: nameCtrl.text.trim(),
                      );

                      if (isEdit && index != null) {
                        controller.updateSongMasterItem(index, newItem);
                      } else {
                        controller.addSongMasterItem(newItem);
                      }
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: theme.colorScheme.onPrimary),
                    child: Text(isEdit ? "Save" : "Add"),
                  )
                ],
              )
            ],
          ),
        ),
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
          title: Text("Cannot Delete Sound", style: TextStyle(color: theme.colorScheme.onSurface)),
          content: Text(
            "This sound is currently used in the playback sequence of the following alarm(s):\n\n"
            "${referencingAlarms.map((e) => '• $e').join('\n')}\n\n"
            "Please remove it from those sequences before deleting.",
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text("OK", style: TextStyle(color: theme.colorScheme.primary)),
            )
          ],
        ),
      );
      return;
    }

    Get.dialog(
      AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text("Delete Sound", style: TextStyle(color: theme.colorScheme.onSurface)),
        content: Text("Are you sure you want to delete '${item.name}' from the sound library?", style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7))),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Cancel", style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteSongMasterItem(index);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Delete"),
          )
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
                  "Sound Library Database (SongMaster)",
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Manage available sounds, announcement formats, and custom playlists",
                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
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
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              // Search Input
              Expanded(
                flex: 2,
                child: TextField(
                  style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Search sounds by name, category, or code...",
                    hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.38)),
                    prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurface.withOpacity(0.38), size: 20),
                    filled: true,
                    fillColor: theme.colorScheme.onSurface.withOpacity(0.02),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (val) => searchQuery.value = val,
                ),
              ),
              const SizedBox(width: 16),
              // Filter segment (All / System / Custom)
              Obx(() => Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildFilterChip(theme, "ALL", "All Sounds"),
                    _buildFilterChip(theme, "SYS", "System"),
                    _buildFilterChip(theme, "CUS", "Custom"),
                  ],
                ),
              )),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Grid/Table of Sounds
        Obx(() {
          var list = controller.songMaster.asMap().entries.toList();

          // Apply filters
          if (searchQuery.value.isNotEmpty) {
            final query = searchQuery.value.toLowerCase();
            list = list.where((entry) {
              final item = entry.value;
              return item.name.toLowerCase().contains(query) ||
                  item.code.toLowerCase().contains(query) ||
                  item.category.toLowerCase().contains(query) ||
                  item.id.toString().toLowerCase().contains(query);
            }).toList();
          }

          if (sourceFilter.value != "ALL") {
            list = list.where((entry) => entry.value.source == sourceFilter.value).toList();
          }

          if (list.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.01),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.08)),
              ),
              child: Center(
                child: Text("No sounds match your filters", style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.38))),
              ),
            );
          }

          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.01),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.08)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(theme.colorScheme.onSurface.withOpacity(0.03)),
                dataRowMinHeight: 52,
                dataRowMaxHeight: 52,
                columns: [
                  DataColumn(label: Text("INDEX", style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("NAME", style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("CODE", style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("CATEGORY", style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("SOURCE", style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("ID/COUNT", style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("ACTIONS", style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontWeight: FontWeight.bold))),
                ],
                rows: list.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(Text(idx.toString(), style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.3), fontSize: 13))),
                      DataCell(Text(item.name, style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold))),
                      DataCell(Text(item.code, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)))),
                      DataCell(Text(item.category, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.38)))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: item.source == 'SYS' ? const Color(0xFF6366F1).withOpacity(0.15) : const Color(0xFFF59E0B).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: item.source == 'SYS' ? const Color(0xFF6366F1) : const Color(0xFFF59E0B),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            item.source == 'SYS' ? 'SYSTEM' : 'CUSTOM',
                            style: TextStyle(
                              color: item.source == 'SYS' ? const Color(0xFF818CF8) : const Color(0xFFFBBF24),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(item.id.toString(), style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)))),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Color(0xFF6366F1), size: 18),
                              onPressed: () => _showAddEditDialog(item, idx),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
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

  Widget _buildFilterChip(ThemeData theme, String val, String label) {
    final isSelected = sourceFilter.value == val;
    return InkWell(
      onTap: () => sourceFilter.value = val,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface.withOpacity(0.6),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
