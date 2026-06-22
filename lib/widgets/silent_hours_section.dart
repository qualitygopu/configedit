import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/config_controller.dart';

class SilentHoursSection extends StatefulWidget {
  const SilentHoursSection({super.key});

  @override
  State<SilentHoursSection> createState() => _SilentHoursSectionState();
}

class _SilentHoursSectionState extends State<SilentHoursSection> {
  final ConfigController controller = Get.find<ConfigController>();
  int startHour = 22;
  int endHour = 6;

  void _addRange() {
    controller.addSilentHour([startHour, endHour]);
  }

  String _formatHour(int hr) {
    final isPm = hr >= 12;
    final displayHour = hr % 12 == 0 ? 12 : hr % 12;
    final suffix = isPm ? 'PM' : 'AM';
    return '$displayHour $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final hours = controller.silentHours;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Silent Hours Configuration",
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Configure time ranges or specific hours during which announcements are muted",
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Form to add a new silent hour range
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.01),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.onSurface.withOpacity(0.08),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Start Hour (0-23)",
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: startHour,
                        dropdownColor: theme.colorScheme.surface,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: theme.colorScheme.onSurface.withOpacity(
                            0.03,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: List.generate(
                          24,
                          (i) =>
                              DropdownMenuItem(value: i, child: Text(_formatHour(i))),
                        ),
                        onChanged: (val) =>
                            setState(() => startHour = val ?? 22),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "End Hour (0-23)",
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: endHour,
                        dropdownColor: theme.colorScheme.surface,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: theme.colorScheme.onSurface.withOpacity(
                            0.03,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: List.generate(
                          24,
                          (i) =>
                              DropdownMenuItem(value: i, child: Text(_formatHour(i))),
                        ),
                        onChanged: (val) => setState(() => endHour = val ?? 6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _addRange,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Add Silent Period"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // List of current items
          if (hours.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.01),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withOpacity(0.08),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.volume_up,
                    color: theme.colorScheme.onSurface.withOpacity(0.24),
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "No silent hours defined",
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Announcements will run 24/7 based on alarm rules",
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.38),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.8,
              ),
              itemCount: hours.length,
              itemBuilder: (context, index) {
                final item = hours[index];
                final isRange = item is List;
                String title = "";
                if (isRange) {
                  title = "Muted from ${_formatHour(item[0])} to ${_formatHour(item[1])}";
                } else {
                  title = "Muted at ${_formatHour(item)}";
                }

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.onSurface.withOpacity(0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.volume_off,
                                  color: Colors.redAccent,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isRange ? "Hour Range" : "Specific Hour",
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.38),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              title,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                        onPressed: () => controller.deleteSilentHour(index),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      );
    });
  }
}
