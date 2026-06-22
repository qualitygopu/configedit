import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/config_controller.dart';
import 'alarms_screen.dart';
import '../widgets/silent_hours_section.dart';
import '../widgets/song_master_section.dart';
import 'raw_json_screen.dart';
import 'playlist_creator_screen.dart';
import 'file_manager_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final ConfigController controller = Get.find<ConfigController>();
  final RxInt activeMenuIndex = 0.obs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Row(
        children: [
          // Sidebar Menu
          _buildSidebar(theme),

          // Main View Pane
          Expanded(
            child: Column(
              children: [
                // Top Header Bar
                _buildHeader(theme),

                // Content Switcher
                Expanded(
                  child: Obx(() {
                    switch (activeMenuIndex.value) {
                      case 0:
                        return AlarmsScreen();
                      case 1:
                        return const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: SingleChildScrollView(
                            child: SilentHoursSection(),
                          ),
                        );
                      case 2:
                        return const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: SingleChildScrollView(
                            child: SongMasterSection(),
                          ),
                        );
                      case 3:
                        return const RawJsonScreen();
                      case 4:
                        return const PlaylistCreatorScreen();
                      case 5:
                        return const FileManagerScreen();
                      default:
                        return const SizedBox.shrink();
                    }
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(ThemeData theme) {
    return Obx(() {
      final isDark = theme.brightness == Brightness.dark;
      final isClassic = controller.themeStyle.value == "Classic";
      final sidebarColor = isDark
          ? (isClassic ? const Color(0xFF1E1E1E) : const Color(0xFF020617))
          : (isClassic ? const Color(0xFFE0E0E0) : const Color(0xFFF1F5F9));
      return Container(
        width: 260,
        color: sidebarColor,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Branding/Logo
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.settings_suggest,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Announce",
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      "Config Editor",
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Navigation Links
            Expanded(
              child: Column(
                children: [
                  _buildSidebarItem(
                    0,
                    Icons.alarm_outlined,
                    "Alarms Configuration",
                  ),
                  _buildSidebarItem(
                    1,
                    Icons.volume_off_outlined,
                    "Silent Hours",
                  ),
                  _buildSidebarItem(
                    2,
                    Icons.library_music_outlined,
                    "Sound Library",
                  ),
                  _buildSidebarItem(
                    4,
                    Icons.queue_music_outlined,
                    "Playlist Manager",
                  ),
                  _buildSidebarItem(3, Icons.code_outlined, "Raw JSON Editor"),
                  _buildSidebarItem(5, Icons.folder_outlined, "File Manager"),
                ],
              ),
            ),

            // Removable Drive / QTRON Selection
            Obx(() {
              final folder = controller.qtronFolder.value;
              final isDetected = folder.isNotEmpty;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.02)
                      : Colors.black.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isDetected
                              ? Icons.usb_rounded
                              : Icons.usb_off_rounded,
                          color: isDetected
                              ? theme.colorScheme.primary
                              : (isDark
                                    ? Colors.white38
                                    : const Color(0xFF475569)),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "QTRON LOCATION",
                          style: TextStyle(
                            color: isDark
                                ? Colors.white38
                                : const Color(0xFF475569),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isDetected ? folder : "Not Connected / Configured",
                      style: TextStyle(
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF1E293B),
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Manual select
                        TextButton.icon(
                          onPressed: () => controller.manualSelectQtronFolder(),
                          icon: const Icon(
                            Icons.folder_open_outlined,
                            size: 14,
                          ),
                          label: const Text(
                            "Select",
                            style: TextStyle(fontSize: 11),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        // Refresh/Auto-detect
                        TextButton.icon(
                          onPressed: () => controller.detectAndSetQtronFolder(),
                          icon: const Icon(Icons.refresh_rounded, size: 14),
                          label: const Text(
                            "Detect",
                            style: TextStyle(fontSize: 11),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            // Quick Metadata & Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.02)
                    : Colors.black.withOpacity(0.02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.terminal,
                        color: isDark
                            ? Colors.white38
                            : const Color(0xFF475569),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "ENVIRONMENT",
                        style: TextStyle(
                          color: isDark
                              ? Colors.white38
                              : const Color(0xFF475569),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Target:",
                        style: TextStyle(
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF1E293B),
                          fontSize: 11,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "timeAnnounce.json",
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSidebarItem(int index, IconData icon, String title) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = activeMenuIndex.value == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () => activeMenuIndex.value = index,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: theme.colorScheme.primary.withOpacity(0.3))
                : Border.all(color: Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? theme.colorScheme.primary
                    : (isDark ? Colors.white60 : const Color(0xFF334155)),
                size: 20,
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? (isDark ? Colors.white : theme.colorScheme.primary)
                      : (isDark ? Colors.white60 : const Color(0xFF334155)),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,

        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  color: isDark ? Colors.white38 : const Color(0xFF475569),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  "timeAnnounce.json",
                  style: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 12),
                Obx(
                  () => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: controller.isModified.value
                          ? Colors.orange.withOpacity(0.15)
                          : Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: controller.isModified.value
                            ? Colors.orangeAccent
                            : Colors.greenAccent,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      controller.isModified.value ? "UNSAVED EDITS" : "SYNCED",
                      style: TextStyle(
                        color: controller.isModified.value
                            ? Colors.orangeAccent
                            : Colors.greenAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () => controller.loadFromFile(),
                  icon: const Icon(Icons.file_open_outlined, size: 16),
                  label: const Text("Load File"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark
                        ? Colors.white70
                        : const Color(0xFF475569),
                    side: BorderSide(
                      color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Get.dialog(
                      AlertDialog(
                        backgroundColor: theme.colorScheme.surface,
                        title: Text(
                          "Reset to Default",
                          style: TextStyle(color: theme.colorScheme.onSurface),
                        ),
                        content: Text(
                          "Are you sure you want to discard your edits and reset to the template config?",
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(),
                            child: Text(
                              "Cancel",
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              controller.loadDefault();
                              Get.back();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                            ),
                            child: const Text("Reset"),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.restart_alt_outlined, size: 16),
                  label: const Text("Reset"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark
                        ? Colors.white70
                        : const Color(0xFF475569),
                    side: BorderSide(
                      color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => controller.saveToFile(),
                  icon: const Icon(Icons.save_outlined, size: 16),
                  label: const Text("Save Config"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => controller.saveAsToFile(),
                  icon: const Icon(Icons.save_as_outlined, size: 16),
                  label: const Text("Save As..."),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark
                        ? Colors.white70
                        : const Color(0xFF475569),
                    side: BorderSide(
                      color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () => controller.toggleTheme(),
                  icon: Obx(
                    () => Icon(
                      controller.themeMode.value == ThemeMode.dark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                  tooltip: "Toggle Light/Dark Theme",
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.palette_outlined,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                  tooltip: "Theme Style",
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: "Modern",
                      child: Row(
                        children: [
                          Icon(Icons.brush, size: 18, color: Color(0xFF4F46E5)),
                          SizedBox(width: 8),
                          Text("Modern Indigo Style"),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: "Classic",
                      child: Row(
                        children: [
                          Icon(
                            Icons.palette,
                            size: 18,
                            color: Color(0xFF1565C0),
                          ),
                          SizedBox(width: 8),
                          Text("Classic Blue Style"),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (style) {
                    controller.themeStyle.value = style;
                  },
                ),
                Obx(
                  () => Text(
                    controller.themeStyle.value,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.format_size_outlined,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                  tooltip: "Text Sizing Mode",
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: "Normal",
                      child: Row(
                        children: [
                          Icon(Icons.text_fields, size: 18),
                          SizedBox(width: 8),
                          Text("Normal Size (100%)"),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: "Reduced",
                      child: Row(
                        children: [
                          Icon(Icons.text_decrease, size: 18),
                          SizedBox(width: 8),
                          Text("Reduced Size (85%)"),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (size) {
                    controller.fontSize.value = size;
                  },
                ),
                Obx(
                  () => Text(
                    controller.fontSize.value == "Reduced"
                        ? "Reduced"
                        : "Normal",
                    style: TextStyle(
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
