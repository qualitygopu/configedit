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
  late TextEditingController idController;
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
    idController = TextEditingController(text: alarm?.id ?? '');
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
    idController.dispose();
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
      Get.snackbar("Required", "Title is required", 
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    final newTim = [
      [startMin, endMin],
      hoursToRanges(selectedHours),
      [[startDay, endDay]],
      [[startMonth, endMonth]],
      selectedWeekdays.toList()..sort(),
      [extraVal]
    ];

    final newAlarm = AlarmConfig(
      tit: titleController.text.trim(),
      id: idController.text.trim().isEmpty ? null : idController.text.trim(),
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
    final bgGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF1E293B).withOpacity(0.95),
        const Color(0xFF0F172A).withOpacity(0.95),
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
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 32,
              offset: const Offset(0, 16),
            )
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
                    widget.alarm != null ? "Edit Alarm Configuration" : "New Alarm Configuration",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  )
                ],
              ),
            ),
            const Divider(color: Colors.white10, height: 1),

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
                          flex: 3,
                          child: _buildTextField(
                            label: "Alarm Title (tit)",
                            controller: titleController,
                            hint: "e.g., Subrabatham",
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            label: "Alarm ID (id, optional)",
                            controller: idController,
                            hint: "e.g., time795",
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "State",
                              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            Switch(
                              value: stateValue,
                              activeColor: const Color(0xFF10B981),
                              inactiveThumbColor: Colors.grey,
                              inactiveTrackColor: Colors.white10,
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
                    const Text(
                      "Days of the Week",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildWeekdaySelector(),
                    const SizedBox(height: 24),

                    // Hours visual scheduler
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Hours Visual Scheduler (Click to toggle hours)",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              if (selectedHours.length == 24) {
                                selectedHours.clear();
                              } else {
                                selectedHours = List.generate(24, (i) => i).toSet();
                              }
                            });
                          },
                          child: Text(
                            selectedHours.length == 24 ? "Deselect All" : "Select All",
                            style: const TextStyle(color: Color(0xFF6366F1)),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildHoursGrid(),
                    const SizedBox(height: 24),

                    // Date & Time specific fields
                    Row(
                      children: [
                        Expanded(
                          child: _buildNumField(
                            label: "Start Min",
                            value: startMin,
                            min: 0,
                            max: 59,
                            onChanged: (val) => setState(() => startMin = val),
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
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildNumField(
                            label: "Start Month",
                            value: startMonth,
                            min: 1,
                            max: 12,
                            onChanged: (val) => setState(() => startMonth = val),
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
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Drag items to reorder the announcement playback sequence",
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                        PopupMenuButton<int>(
                          icon: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, color: Colors.white, size: 18),
                                SizedBox(width: 4),
                                Text("Add Sound", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          tooltip: "Add Sound to Playback Sequence",
                          itemBuilder: (context) {
                            return controller.songMaster.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final item = entry.value;
                              return PopupMenuItem<int>(
                                value: idx,
                                child: Text("${item.name} (${item.code})"),
                              );
                            }).toList();
                          },
                          onSelected: (idx) {
                            setState(() {
                              selectedSC.add(idx);
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSequenceList(),
                  ],
                ),
              ),
            ),
            const Divider(color: Colors.white10, height: 1),

            // Footer Actions
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white30),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(widget.alarm != null ? "Save Changes" : "Create Alarm"),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white30),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value.toString(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_drop_up, color: Colors.white70, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      if (value < max) onChanged(value + 1);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      if (value > min) onChanged(value - 1);
                    },
                  ),
                ],
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildWeekdaySelector() {
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
                  color: isSelected ? const Color(0xFF6366F1).withOpacity(0.2) : Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF6366F1) : Colors.white10,
                  ),
                ),
                child: Center(
                  child: Text(
                    days[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
        final hourStr = idx.toString().padLeft(2, '0');
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
              color: isSelected ? const Color(0xFF10B981).withOpacity(0.2) : Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? const Color(0xFF10B981) : Colors.white10,
              ),
            ),
            child: Center(
              child: Text(
                hourStr,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white60,
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
    if (selectedSC.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: const Center(
          child: Text(
            "No announcements configured. Add sounds using the button above.",
            style: TextStyle(color: Colors.white38),
          ),
        ),
      );
    }

    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.01),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: ReorderableListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex -= 1;
            final item = selectedSC.removeAt(oldIndex);
            selectedSC.insert(newIndex, item);
          });
        },
        children: List.generate(selectedSC.length, (idx) {
          final smIndex = selectedSC[idx];
          // Check bounds in case master changed
          final item = (smIndex >= 0 && smIndex < controller.songMaster.length)
              ? controller.songMaster[smIndex]
              : SongMasterItem(id: smIndex, code: 'ERR', category: 'ERR', source: 'ERR', name: 'Unknown');
          
          return Container(
            key: ValueKey("sc_$idx"),
            width: 140,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.06),
                  Colors.white.withOpacity(0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.source == 'SYS' ? const Color(0xFF6366F1) : const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.source,
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white30, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          selectedSC.removeAt(idx);
                        });
                      },
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.category,
                        style: const TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.drag_handle, color: Colors.white30, size: 18),
              ],
            ),
          );
        }),
      ),
    );
  }
}
