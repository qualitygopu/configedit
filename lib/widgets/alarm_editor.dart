import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/config_model.dart';
import '../controllers/config_controller.dart';

class AlarmEditorDialog extends StatefulWidget {
  final AlarmConfig? alarm;
  final int? index;

  const AlarmEditorDialog({super.key, this.alarm, this.index});

  @override
  State<AlarmEditorDialog> createState() => _AlarmEditorDialogState();
}

class _AlarmEditorDialogState extends State<AlarmEditorDialog> {
  final ConfigController controller = Get.find<ConfigController>();

  late TextEditingController titleController;
  late bool stateValue;
  late Set<int> selectedHours;
  late Set<int> selectedWeekdays;
  late List<int> selectedSC;

  int startMin = 0;
  int endMin = 0;
  int startDay = 1;
  int endDay = 31;
  int startMonth = 1;
  int endMonth = 12;
  int extraVal = 0;

  @override
  void initState() {
    super.initState();
    final alarm = widget.alarm;
    titleController = TextEditingController(text: alarm?.tit ?? '');
    stateValue = alarm?.state ?? true;

    // Parse times
    if (alarm != null) {
      selectedHours = rangesToHours(alarm.hourRanges);
      selectedWeekdays = alarm.weekdays.toSet();
      selectedSC = List<int>.from(alarm.sc);

      final mins = alarm.minutes;
      if (mins.length >= 2) {
        startMin = mins[0];
        endMin = mins[1];
      }

      final dom = alarm.dayOfMonthRanges;
      if (dom.isNotEmpty && dom[0].length >= 2) {
        startDay = dom[0][0];
        endDay = dom[0][1];
      }

      final mos = alarm.monthRanges;
      if (mos.isNotEmpty && mos[0].length >= 2) {
        startMonth = mos[0][0];
        endMonth = mos[0][1];
      }

      final ext = alarm.extra;
      if (ext.isNotEmpty) {
        extraVal = ext[0];
      }
    } else {
      selectedHours = {6, 7, 8, 17, 18, 19}; // Default hours
      selectedWeekdays = {1, 2, 3, 4, 5, 6, 7}; // Default all days
      selectedSC = [];
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  Set<int> rangesToHours(List<List<int>> ranges) {
    Set<int> hours = {};
    for (final range in ranges) {
      if (range.length == 2) {
        for (int h = range[0]; h <= range[1]; h++) {
          hours.add(h);
        }
      } else if (range.length == 1) {
        hours.add(range[0]);
      }
    }
    return hours;
  }

  List<List<int>> hoursToRanges(Set<int> hours) {
    if (hours.isEmpty) return [];
    final sorted = hours.toList()..sort();
    List<List<int>> ranges = [];
    int start = sorted[0];
    int prev = sorted[0];

    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i] == prev + 1) {
        prev = sorted[i];
      } else {
        ranges.add([start, prev]);
        start = sorted[i];
        prev = sorted[i];
      }
    }
    ranges.add([start, prev]);
    return ranges;
  }

  void save() {
    if (titleController.text.trim().isEmpty) {
      Get.snackbar(
        "Required",
        "Title is required",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    final newTim = [
      [startMin, endMin],
      hoursToRanges(selectedHours),
      [
        [startDay, endDay],
      ],
      [
        [startMonth, endMonth],
      ],
      selectedWeekdays.toList()..sort(),
      [extraVal],
    ];

    final newAlarm = AlarmConfig(
      tit: titleController.text.trim(),
      id: widget.alarm?.id,
      state: stateValue,
      tim: newTim,
      sc: selectedSC,
      type: widget.alarm?.type ?? 'time',
    );

    if (widget.index != null) {
      controller.updateAlarm(widget.index!, newAlarm);
    } else {
      controller.addAlarm(newAlarm);
    }
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        theme.colorScheme.surface.withOpacity(0.98),
        theme.scaffoldBackgroundColor.withOpacity(0.98),
      ],
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        width: 800,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          gradient: bgGradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.onSurface.withOpacity(0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.alarm != null
                        ? "Edit Alarm Configuration"
                        : "New Alarm Configuration",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(
                      Icons.close,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              color: theme.colorScheme.onSurface.withOpacity(0.08),
              height: 1,
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row for Title & ID & State
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: "Alarm Title / Name",
                            controller: titleController,
                            hint: "e.g., Subrabatham",
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "State",
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.7,
                                ),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Switch(
                              value: stateValue,
                              activeColor: theme.colorScheme.secondary,
                              inactiveThumbColor: Colors.grey,
                              inactiveTrackColor: theme.colorScheme.onSurface
                                  .withOpacity(0.15),
                              onChanged: (val) {
                                setState(() {
                                  stateValue = val;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Weekdays selection
                    Text(
                      "Days of the Week",
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildWeekdaySelector(),
                    const SizedBox(height: 24),

                    // Hours visual scheduler
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Hours Visual Scheduler (Click to toggle hours)",
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              if (selectedHours.length == 24) {
                                selectedHours.clear();
                              } else {
                                selectedHours = List.generate(
                                  24,
                                  (i) => i,
                                ).toSet();
                              }
                            });
                          },
                          child: Text(
                            selectedHours.length == 24
                                ? "Deselect All"
                                : "Select All",
                            style: TextStyle(color: theme.colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildHoursGrid(),
                    const SizedBox(height: 24),

                    // Date & Time specific fields (Disabled)
                    Row(
                      children: [
                        Expanded(
                          child: _buildNumField(
                            label: "Start Min",
                            value: startMin,
                            min: 0,
                            max: 59,
                            onChanged: (val) => setState(() => startMin = val),
                            enabled: false,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildNumField(
                            label: "End Min",
                            value: endMin,
                            min: 0,
                            max: 59,
                            onChanged: (val) => setState(() => endMin = val),
                            enabled: false,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildNumField(
                            label: "Start Day",
                            value: startDay,
                            min: 1,
                            max: 31,
                            onChanged: (val) => setState(() => startDay = val),
                            enabled: false,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildNumField(
                            label: "End Day",
                            value: endDay,
                            min: 1,
                            max: 31,
                            onChanged: (val) => setState(() => endDay = val),
                            enabled: false,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildNumField(
                            label: "Start Month",
                            value: startMonth,
                            min: 1,
                            max: 12,
                            onChanged: (val) =>
                                setState(() => startMonth = val),
                            enabled: false,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildNumField(
                            label: "End Month",
                            value: endMonth,
                            min: 1,
                            max: 12,
                            onChanged: (val) => setState(() => endMonth = val),
                            enabled: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Song Announcement Sequence Composer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Announcement Sequence (SC)",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Drag items to reorder the announcement playback sequence",
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Obx(() {
                              if (controller.playlists.isEmpty)
                                return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: PopupMenuButton<Playlist>(
                                  icon: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.secondary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.playlist_play,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          "Load Playlist",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  tooltip:
                                      "Load Track Sequence from Saved Playlist",
                                  itemBuilder: (context) {
                                    return controller.playlists.map((playlist) {
                                      return PopupMenuItem<Playlist>(
                                        value: playlist,
                                        child: Text(playlist.name),
                                      );
                                    }).toList();
                                  },
                                  onSelected: (playlist) {
                                    setState(() {
                                      selectedSC = List<int>.from(playlist.sc);
                                    });
                                  },
                                ),
                              );
                            }),
                            PopupMenuButton<int>(
                              icon: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      "Add Sound",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              tooltip: "Add Sound to Playback Sequence",
                              itemBuilder: (context) {
                                return controller.songMaster
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                      final idx = entry.key;
                                      final item = entry.value;
                                      return PopupMenuItem<int>(
                                        value: idx,
                                        child: Text(
                                          "${item.name} (${item.code})",
                                        ),
                                      );
                                    })
                                    .toList();
                              },
                              onSelected: (idx) {
                                setState(() {
                                  selectedSC.add(idx);
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSequenceList(),
                  ],
                ),
              ),
            ),
            Divider(
              color: theme.colorScheme.onSurface.withOpacity(0.08),
              height: 1,
            ),

            // Footer Actions
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.brightness == Brightness.dark
                          ? Colors.white70
                          : const Color(0xFF475569),
                      side: BorderSide(
                        color: theme.brightness == Brightness.dark
                            ? Colors.white30
                            : const Color(0xFFCBD5E1),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      widget.alarm != null ? "Save Changes" : "Create Alarm",
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: TextStyle(color: theme.colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            filled: true,
            fillColor: theme.colorScheme.onSurface.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumField({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: enabled
                ? theme.colorScheme.onSurface.withOpacity(0.7)
                : theme.colorScheme.onSurface.withOpacity(0.38),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: enabled
                ? theme.colorScheme.onSurface.withOpacity(0.05)
                : theme.colorScheme.onSurface.withOpacity(0.01),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value.toString(),
                style: TextStyle(
                  color: enabled
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withOpacity(0.38),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_drop_up,
                      color: enabled
                          ? theme.colorScheme.onSurface.withOpacity(0.7)
                          : theme.colorScheme.onSurface.withOpacity(0.2),
                      size: 16,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: enabled
                        ? () {
                            if (value < max) onChanged(value + 1);
                          }
                        : null,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: enabled
                          ? theme.colorScheme.onSurface.withOpacity(0.7)
                          : theme.colorScheme.onSurface.withOpacity(0.2),
                      size: 16,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: enabled
                        ? () {
                            if (value > min) onChanged(value - 1);
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdaySelector() {
    final theme = Theme.of(context);
    final days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final dayNum = index + 1;
        final isSelected = selectedWeekdays.contains(dayNum);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    selectedWeekdays.remove(dayNum);
                  } else {
                    selectedWeekdays.add(dayNum);
                  }
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withOpacity(0.2)
                      : theme.colorScheme.onSurface.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.08),
                  ),
                ),
                child: Center(
                  child: Text(
                    days[index],
                    style: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHoursGrid() {
    final theme = Theme.of(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 12,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1.2,
      ),
      itemCount: 24,
      itemBuilder: (context, idx) {
        final isSelected = selectedHours.contains(idx);
        final isPm = idx >= 12;
        final displayHour = idx % 12 == 0 ? 12 : idx % 12;
        final suffix = isPm ? 'PM' : 'AM';
        final hourStr = '$displayHour $suffix';
        return InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedHours.remove(idx);
              } else {
                selectedHours.add(idx);
              }
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.secondary.withOpacity(0.2)
                  : theme.colorScheme.onSurface.withOpacity(0.03),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.onSurface.withOpacity(0.08),
              ),
            ),
            child: Center(
              child: Text(
                hourStr,
                style: TextStyle(
                  color: isSelected
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withOpacity(0.9),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSequenceList() {
    final theme = Theme.of(context);
    if (selectedSC.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withOpacity(0.01),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.onSurface.withOpacity(0.08),
          ),
        ),
        child: Center(
          child: Text(
            "No announcements configured. Add sounds using the button above.",
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.08),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: ReorderableListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex -= 1;
            final item = selectedSC.removeAt(oldIndex);
            selectedSC.insert(newIndex, item);
          });
        },
        children: List.generate(selectedSC.length, (idx) {
          final smIndex = selectedSC[idx];
          final item = (smIndex >= 0 && smIndex < controller.songMaster.length)
              ? controller.songMaster[smIndex]
              : SongMasterItem(
                  count: smIndex,
                  code: 'ERR',
                  folder: 'ERR',
                  mode: 'ERR',
                  name: 'Unknown',
                );

          return Card(
            key: ValueKey("sc_$idx"),
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: theme.colorScheme.onSurface.withOpacity(0.08),
              ),
            ),
            child: ListTile(
              dense: true,
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.drag_handle,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: item.mode == 'SYS'
                          ? theme.colorScheme.primary
                          : const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.mode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(
                item.name,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 12,
                ),
              ),
              subtitle: Text(
                "Code: ${item.code} | Category: ${item.folder}",
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 10,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.redAccent,
                  size: 18,
                ),
                onPressed: () {
                  setState(() {
                    selectedSC.removeAt(idx);
                  });
                },
              ),
            ),
          );
        }),
      ),
    );
  }
}
