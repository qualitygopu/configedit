import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:get/get.dart';
import '../controllers/config_controller.dart';

class RawJsonScreen extends StatefulWidget {
  const RawJsonScreen({super.key});

  @override
  State<RawJsonScreen> createState() => _RawJsonScreenState();
}

class _RawJsonScreenState extends State<RawJsonScreen> {
  final ConfigController controller = Get.find<ConfigController>();
  late TextEditingController jsonEditorController;
  late Worker jsonWorker;

  @override
  void initState() {
    super.initState();
    jsonEditorController = TextEditingController(text: controller.rawJson.value);
    
    // Sync text editor with state changes from controller
    jsonWorker = ever(controller.rawJson, (val) {
      if (jsonEditorController.text != val) {
        jsonEditorController.text = val;
      }
    });
  }

  @override
  void dispose() {
    jsonWorker.dispose();
    jsonEditorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    "Raw JSON Configuration Editor",
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Directly modify the config JSON. Invalid JSON syntax will display errors.",
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final val = controller.updateFromRawText(jsonEditorController.text);
                  if (val) {
                    Get.snackbar(
                      "Success",
                      "Visual editor updated successfully from raw JSON data!",
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: const Color(0xFF10B981),
                      colorText: Colors.white,
                    );
                  } else {
                    Get.snackbar(
                      "Syntax Error",
                      "Failed to apply JSON due to structure errors. Please check the error message below.",
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.redAccent,
                      colorText: Colors.white,
                    );
                  }
                },
                icon: const Icon(Icons.check, size: 18),
                label: const Text("Apply JSON Edits"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          
          // Error alert
          Obx(() {
            if (controller.errorMessage.value.isNotEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        controller.errorMessage.value,
                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // JSON Editor Text Field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withOpacity(0.3)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08)),
              ),
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: jsonEditorController,
                maxLines: null,
                minLines: 100, // Make it fill constraints
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.5,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (text) {
                  // Validate dynamically in background without triggering full reactive rebuilds immediately
                  try {
                    jsonDecode(text);
                    controller.errorMessage.value = "";
                  } catch (e) {
                    controller.errorMessage.value = "JSON validation error: $e";
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
