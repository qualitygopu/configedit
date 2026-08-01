import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/config_controller.dart';

class DeviceInfoSection extends StatefulWidget {
  const DeviceInfoSection({super.key});

  @override
  State<DeviceInfoSection> createState() => _DeviceInfoSectionState();
}

class _DeviceInfoSectionState extends State<DeviceInfoSection> {
  final ConfigController controller = Get.find<ConfigController>();
  late final TextEditingController _nameController;
  late final TextEditingController _serialController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: controller.deviceName.value);
    _serialController = TextEditingController(
      text: controller.deviceSerialNo.value,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serialController.dispose();
    super.dispose();
  }

  void _save() {
    controller.updateDeviceInfo(
      name: _nameController.text.trim(),
      serialNo: _serialController.text.trim(),
    );
    Get.snackbar(
      "Device Info Saved",
      "Device details have been updated",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blueAccent,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Device Info",
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Identify this QTRON device. Stored as a separate DeviceInfo object in the config",
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withOpacity(0.01),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.onSurface.withOpacity(0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Device Name",
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(
                              0.7,
                            ),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          decoration: InputDecoration(
                            hintText: "e.g. Temple Hall Speaker",
                            filled: true,
                            fillColor: theme.colorScheme.onSurface.withOpacity(
                              0.03,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
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
                          "Device Serial No",
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(
                              0.7,
                            ),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _serialController,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontFamily: 'monospace',
                          ),
                          decoration: InputDecoration(
                            hintText: "e.g. QTR-0001",
                            filled: true,
                            fillColor: theme.colorScheme.onSurface.withOpacity(
                              0.03,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text("Save Device Info"),
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
              ),
            ],
          ),
        ),
      ],
    );
  }
}
