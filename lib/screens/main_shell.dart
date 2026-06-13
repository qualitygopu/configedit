import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/config_controller.dart';
import 'alarms_screen.dart';
import '../widgets/silent_hours_section.dart';
import '../widgets/song_master_section.dart';
import 'raw_json_screen.dart';

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
                          child: SingleChildScrollView(child: SilentHoursSection()),
                        );
                      case 2:
                        return const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: SingleChildScrollView(child: SongMasterSection()),
                        );
                      case 3:
                        return const RawJsonScreen();
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
    return Container(
      width: 260,
      color: const Color(0xFF020617),
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
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                ),
                child: Icon(Icons.settings_suggest, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Announce",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
                  ),
                  Text(
                    "Config Editor",
                    style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Navigation Links
          Expanded(
            child: Obx(() => Column(
              children: [
                _buildSidebarItem(0, Icons.alarm_outlined, "Alarms Configuration"),
                _buildSidebarItem(1, Icons.volume_off_outlined, "Silent Hours"),
                _buildSidebarItem(2, Icons.library_music_outlined, "Sound Library"),
                _buildSidebarItem(3, Icons.code_outlined, "Raw JSON Editor"),
              ],
            )),
          ),

          // Quick Metadata & Status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.terminal, color: Colors.white38, size: 14),
                    SizedBox(width: 6),
                    Text("ENVIRONMENT", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Target:", style: TextStyle(color: Colors.white70, fontSize: 11)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text("timeAnnounce.json", style: TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace')),
                    )
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String title) {
    final isSelected = activeMenuIndex.value == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () => activeMenuIndex.value = index,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1).withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)) : Border.all(color: Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? const Color(0xFF6366F1) : Colors.white60, size: 20),
              const SizedBox(width: 14),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white60,
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
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, color: Colors.white38, size: 18),
              const SizedBox(width: 8),
              const Text(
                "timeAnnounce.json",
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
              ),
              const SizedBox(width: 12),
              Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: controller.isModified.value ? Colors.orange.withOpacity(0.15) : Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: controller.isModified.value ? Colors.orangeAccent : Colors.greenAccent,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  controller.isModified.value ? "UNSAVED EDITS" : "SYNCED",
                  style: TextStyle(
                    color: controller.isModified.value ? Colors.orangeAccent : Colors.greenAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )),
            ],
          ),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => controller.loadFromFile(),
                icon: const Icon(Icons.file_open_outlined, size: 16),
                label: const Text("Load File"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Get.dialog(
                    AlertDialog(
                      backgroundColor: const Color(0xFF1E293B),
                      title: const Text("Reset to Default", style: TextStyle(color: Colors.white)),
                      content: const Text("Are you sure you want to discard your edits and reset to the template config?", style: TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(),
                          child: const Text("Cancel", style: TextStyle(color: Colors.white60)),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            controller.loadDefault();
                            Get.back();
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                          child: const Text("Reset"),
                        )
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.restart_alt_outlined, size: 16),
                label: const Text("Reset"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => controller.saveToFile(),
                icon: const Icon(Icons.save_outlined, size: 16),
                label: const Text("Save & Export Config"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
