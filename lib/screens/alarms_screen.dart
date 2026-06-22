import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/config_model.dart';
import '../controllers/config_controller.dart';
import '../widgets/alarm_editor.dart';

class AlarmsScreen extends StatelessWidget {
  final ConfigController controller = Get.find<ConfigController>();

  AlarmsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subtitleColor = isDark
        ? theme.colorScheme.onSurface.withOpacity(0.6)
        : theme.colorScheme.onSurface.withOpacity(0.85);
    final hintColor = isDark
        ? theme.colorScheme.onSurface.withOpacity(0.38)
        : theme.colorScheme.onSurface.withOpacity(0.65);

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Alarms Configuration Dashboard",
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Drag items to reorder priority, click edit to modify timing rules or sequence tracks.",
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => controller.sortAlarmsByEndTime(),
                    icon: const Icon(Icons.sort, size: 18),
                    label: const Text("Sort by End Time"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.brightness == Brightness.dark
                          ? Colors.white70
                          : const Color(0xFF475569),
                      side: BorderSide(
                        color: theme.brightness == Brightness.dark
                            ? Colors.white24
                            : const Color(0xFFCBD5E1),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Get.dialog(const AlarmEditorDialog());
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("Add New Alarm"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          Expanded(
            child: Obx(() {
              if (controller.alarms.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(64),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.01),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.onSurface.withOpacity(0.08),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.alarm_add,
                        color: theme.colorScheme.onSurface.withOpacity(0.24),
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No alarms configured",
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Click the button at top right to build your first alarm schedule",
                        style: TextStyle(
                          color: hintColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ReorderableListView.builder(
                itemCount: controller.alarms.length,
                onReorder: controller.reorderAlarms,
                itemBuilder: (context, idx) {
                  final alarm = controller.alarms[idx];
                  return _buildAlarmCard(context, alarm, idx, theme);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmCard(
    BuildContext context,
    AlarmConfig alarm,
    int index,
    ThemeData theme,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    final subtitleColor = isDark
        ? theme.colorScheme.onSurface.withOpacity(0.6)
        : theme.colorScheme.onSurface.withOpacity(0.85);
    final hintColor = isDark
        ? theme.colorScheme.onSurface.withOpacity(0.38)
        : theme.colorScheme.onSurface.withOpacity(0.65);

    // Generate beautiful readable schedule details
    final activeDays = alarm.weekdays;
    String dayString = "";
    if (activeDays.length == 7) {
      dayString = "Daily";
    } else if (activeDays.isEmpty) {
      dayString = "No days configured";
    } else {
      final daysNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
      dayString = activeDays.map((d) => daysNames[d - 1]).join(', ');
    }

    String formatHour(int hr) {
      final isPm = hr >= 12;
      final displayHour = hr % 12 == 0 ? 12 : hr % 12;
      final suffix = isPm ? 'PM' : 'AM';
      return '$displayHour $suffix';
    }

    final hourRangesList = alarm.hourRanges;
    String hourString = "";
    if (hourRangesList.isEmpty) {
      hourString = "No hours configured";
    } else {
      hourString = hourRangesList
          .map((range) {
            if (range.length == 2) {
              return "${formatHour(range[0])} - ${formatHour(range[1])}";
            } else if (range.length == 1) {
              return formatHour(range[0]);
            }
            return "";
          })
          .join(', ');
    }

    final mins = alarm.minutes;
    String minStr = "00";
    if (mins.length >= 2) {
      minStr =
          "${mins[0].toString().padLeft(2, '0')}-${mins[1].toString().padLeft(2, '0')}";
    }

    return Card(
      key: ValueKey("alarm_card_$index"),
      margin: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.onSurface.withOpacity(0.08),
          ),
          color: theme.cardTheme.color,
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Drag handle
            Icon(
              Icons.drag_handle,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
              size: 24,
            ),
            const SizedBox(width: 16),

            // Icon status circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: alarm.state
                    ? theme.colorScheme.secondary.withOpacity(0.1)
                    : theme.colorScheme.onSurface.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: alarm.state
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.onSurface.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.alarm,
                  color: alarm.state
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.onSurface.withOpacity(0.38),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 20),

            // Text Info
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        alarm.tit,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (alarm.id != null && alarm.id!.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withOpacity(
                              0.05,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            alarm.id!,
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: hintColor,
                        size: 12,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dayString,
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.access_time,
                        color: hintColor,
                        size: 12,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Hours: $hourString (Min: $minStr)",
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Song tags preview
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: alarm.sc.map((smIndex) {
                        final songName =
                            (smIndex >= 0 &&
                                smIndex < controller.songMaster.length)
                            ? controller.songMaster[smIndex].name
                            : "Unknown ($smIndex)";
                        final source =
                            (smIndex >= 0 &&
                                smIndex < controller.songMaster.length)
                            ? controller.songMaster[smIndex].source
                            : "SYS";
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: source == "SYS"
                                ? theme.colorScheme.primary.withOpacity(0.08)
                                : const Color(0xFFF59E0B).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: source == "SYS"
                                  ? theme.colorScheme.primary.withOpacity(0.3)
                                  : const Color(0xFFF59E0B).withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            songName,
                            style: TextStyle(
                              color: source == "SYS"
                                  ? theme.colorScheme.primary
                                  : const Color(0xFFFBBF24),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            Row(
              children: [
                Switch(
                  value: alarm.state,
                  activeColor: theme.colorScheme.secondary,
                  onChanged: (val) {
                    final updated = alarm.copyWith(state: val);
                    controller.updateAlarm(index, updated);
                  },
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: () {
                    Get.dialog(AlarmEditorDialog(alarm: alarm, index: index));
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: () {
                    Get.dialog(
                      AlertDialog(
                        backgroundColor: theme.colorScheme.surface,
                        title: Text(
                          "Delete Alarm",
                          style: TextStyle(color: theme.colorScheme.onSurface),
                        ),
                        content: Text(
                          "Are you sure you want to delete '${alarm.tit}'?",
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
                              controller.deleteAlarm(index);
                              Get.back();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                            ),
                            child: const Text("Delete"),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
