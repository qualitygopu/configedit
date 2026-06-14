import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/config_controller.dart';
import 'alarms_screen.dart';
import '../widgets/silent_hours_section.dart';
import '../widgets/song_master_section.dart';
import 'raw_json_screen.dart';
import 'playlist_creator_screen.dart';

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
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: 260,
      color: isDark
          ? const Color(0xFF020617)
          : const Color(0xFFF1F5F9), // Slate 100 in light mode
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
            child: Obx(
              () => Column(
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
                ],
              ),
            ),
          ),

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
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "ENVIRONMENT",
                      style: TextStyle(
                        color: isDark
                            ? Colors.white38
                            : const Color(0xFF94A3B8),
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
                            : const Color(0xFF475569),
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
                    : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                size: 20,
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? (isDark ? Colors.white : theme.colorScheme.primary)
                      : (isDark ? Colors.white60 : const Color(0xFF64748B)),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                "timeAnnounce.json",
                style: TextStyle(
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
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
                tooltip: "Toggle Theme Mode",
              ),
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
                label: const Text("Save & Export Config"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
