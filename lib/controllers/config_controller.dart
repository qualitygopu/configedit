import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/config_model.dart';
import '../utils/file_helper.dart';

class ConfigController extends GetxController {
  final Rx<ThemeMode> themeMode = ThemeMode.light.obs;
  final RxString themeStyle = "Classic".obs; // "Modern" or "Classic"
  final RxString fontSize = "Normal".obs; // "Normal" or "Reduced"
  final Rxn<Config> config = Rxn<Config>();
  final RxList<AlarmConfig> alarms = <AlarmConfig>[].obs;
  final RxList<dynamic> silentHours = <dynamic>[].obs;
  final RxList<SongMasterItem> songMaster = <SongMasterItem>[].obs;
  final RxList<Playlist> playlists = <Playlist>[].obs;
  final RxString rawJson = "".obs;
  final RxString errorMessage = "".obs;
  final RxBool isModified = false.obs;
  final RxString qtronFolder = "".obs;

  void toggleTheme() {
    if (themeMode.value == ThemeMode.dark) {
      themeMode.value = ThemeMode.light;
      Get.changeThemeMode(ThemeMode.light);
    } else {
      themeMode.value = ThemeMode.dark;
      Get.changeThemeMode(ThemeMode.dark);
    }
  }

  void toggleThemeStyle() {
    themeStyle.value = themeStyle.value == "Modern" ? "Classic" : "Modern";
  }

  void toggleFontSize() {
    fontSize.value = fontSize.value == "Normal" ? "Reduced" : "Normal";
  }

  static const String defaultJson =
      r'''{"AlarmConfig":[{"tit":"subrabatham","id":null,"state":true,"tim":[[0,0],[[5,5]],[[1,31]],[[1,12]],[1,2,3,4,5,6,7],[0]],"SC":[0,1,2,3,4,5,12],"type":"time"},{"tit":"time with Panchagam","id":null,"state":true,"tim":[[0,0],[[6,6],[8,8],[10,10]],[[1,31]],[[1,12]],[1,2,3,4,5,6,7],[0]],"SC":[0,1,2,3,4,5,6,7,8,9,10],"type":"time"},{"tit":"time with song","id":"time795","state":true,"tim":[[0,0],[[6,8],[17,19]],[[1,31]],[[1,12]],[1,2,3,4,5,6,7],[0]],"SC":[0,1,2,3,4,5,10],"type":"time"},{"tit":"time with quotes","id":null,"state":true,"tim":[[0,0],[[6,22]],[[1,31]],[[1,12]],[1,2,3,4,5,6,7],[0]],"SC":[0,1,2,3,4,5,11],"type":"time"}],"silentHours":[],"SongMaster":[[24,"hr","SS","SYS","மந்திரம்"],[24,"hr","VO","SYS","ஆலயம் பெயர்"],[24,"hr","HR/HWB","SYS","மணி"],[12,"mo","MO","SYS","ஆங்கில தேதி"],[31,"dt","DT","SYS","ஆங்கில தேதி"],[7,"dw","DW","SYS","ஆங்கில தேதி"],[366,"td","PN","SYS","தமிழ் தேதி"],[366,"tn","PN","SYS","திதி நட்சத்திரம்"],[7,"dw","NN","SYS","நல்லநேரம்"],[100,"sd","PN","SYS","விரத தினம்"],[100,"LP","SN1","CUS","பாடல் 1"],[762,"LP","QU","CUS","Quotes"],[12,"Vinayagar Suprabatham","SP","CUS","Subrapatham"]],"Playlists":[]}''';

  @override
  void onInit() {
    super.onInit();
    // loadDefault();
    detectAndSetQtronFolder();
  }

  // Load from a raw JSON string (supporting both raw JSON and base64 encoded JSON)
  bool loadConfig(String content) {
    try {
      String jsonString = content.trim();
      // Auto-detect base64 encoding by checking if it does not start with '{'
      if (jsonString.isNotEmpty && !jsonString.startsWith('{')) {
        try {
          final decodedBytes = base64.decode(jsonString);
          jsonString = utf8.decode(decodedBytes);
        } catch (_) {
          // Fall back to original content if decoding fails
        }
      }

      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException("Root JSON must be an object");
      }
      final parsedConfig = Config.fromJson(decoded);

      config.value = parsedConfig;
      alarms.assignAll(parsedConfig.alarmConfig);
      silentHours.assignAll(parsedConfig.silentHours);
      songMaster.assignAll(parsedConfig.songMaster);
      playlists.assignAll(parsedConfig.playlists);

      // Pretty print JSON in editor
      rawJson.value = const JsonEncoder.withIndent('  ').convert(decoded);
      errorMessage.value = "";
      isModified.value = false;
      return true;
    } catch (e) {
      errorMessage.value = "Error parsing JSON: $e";
      return false;
    }
  }

  void loadDefault() {
    loadConfig(defaultJson);
  }

  Future<void> detectAndSetQtronFolder() async {
    final path = await FileHelper.findAndAddQtronDirectory();
    if (path != null) {
      qtronFolder.value = path;
    } else {
      qtronFolder.value = "";
    }
  }

  Future<void> manualSelectQtronFolder() async {
    final selectedDirectory = await FileHelper.selectDirectory();
    if (selectedDirectory != null) {
      var path = selectedDirectory;
      final parts = path.split(path.contains('\\') ? '\\' : '/');
      final dirName = parts.last;
      if (dirName != '_QTRON') {
        final separator = path.contains('\\') ? '\\' : '/';
        final subDirPath = '$path${separator}_QTRON';
        if (await FileHelper.getSubfolders(
          path,
        ).then((folders) => folders.contains('_QTRON'))) {
          path = subDirPath;
        } else {
          qtronFolder.value = path;
          Get.snackbar(
            "Master Location Saved",
            "Set master location to: $path",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.blueAccent,
            colorText: Colors.white,
          );
          return;
        }
      }
      qtronFolder.value = path;
      Get.snackbar(
        "Master Location Saved",
        "Set master location to: $path",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blueAccent,
        colorText: Colors.white,
      );
    }
  }

  // Pick and load file
  Future<void> loadFromFile() async {
    final fileContent = await FileHelper.loadFile(
      qtronDir: qtronFolder.value.isNotEmpty ? qtronFolder.value : null,
    );
    if (fileContent != null && fileContent.trim().isNotEmpty) {
      loadConfig(fileContent);
    }
  }

  // Export/Save file as Base64 encoded
  Future<void> saveToFile() async {
    if (config.value == null) return;
    refreshRawJson();

    final jsonString = jsonEncode(config.value!.toJson());
    // Convert JSON to Base64
    final base64String = base64.encode(utf8.encode(jsonString));

    await FileHelper.saveFile(
      base64String,
      "timeAnnounce.qtr",
      qtronDir: qtronFolder.value.isNotEmpty ? qtronFolder.value : null,
    );
    isModified.value = false;
  }

  // Export/Save file as Base64 encoded with prompt
  Future<void> saveAsToFile() async {
    if (config.value == null) return;
    refreshRawJson();

    final jsonString = jsonEncode(config.value!.toJson());
    // Convert JSON to Base64
    final base64String = base64.encode(utf8.encode(jsonString));

    await FileHelper.saveFile(
      base64String,
      "timeAnnounce.qtr",
      qtronDir: qtronFolder.value.isNotEmpty ? qtronFolder.value : null,
      isSaveAs: true,
    );
    isModified.value = false;
  }

  // Try updating state from raw JSON editing
  bool updateFromRawText(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) return false;
      final parsedConfig = Config.fromJson(decoded);

      config.value = parsedConfig;
      alarms.assignAll(parsedConfig.alarmConfig);
      silentHours.assignAll(parsedConfig.silentHours);
      songMaster.assignAll(parsedConfig.songMaster);
      playlists.assignAll(parsedConfig.playlists);

      rawJson.value = text;
      errorMessage.value = "";
      isModified.value = true;
      return true;
    } catch (e) {
      errorMessage.value = "Invalid JSON structure: $e";
      return false;
    }
  }

  // Synchronize state changes back to rawJson
  void refreshRawJson() {
    if (config.value == null) return;
    final updatedConfig = config.value!.copyWith(
      alarmConfig: alarms.toList(),
      silentHours: silentHours.toList(),
      songMaster: songMaster.toList(),
      playlists: playlists.toList(),
    );
    config.value = updatedConfig;
    rawJson.value = const JsonEncoder.withIndent(
      '  ',
    ).convert(updatedConfig.toJson());
  }

  void markModified() {
    isModified.value = true;
    refreshRawJson();
  }

  // Alarm management
  void addAlarm(AlarmConfig alarm) {
    alarms.add(alarm);
    sortAlarmsByEndTime();
  }

  void updateAlarm(int index, AlarmConfig alarm) {
    if (index >= 0 && index < alarms.length) {
      alarms[index] = alarm;
      markModified();
    }
  }

  void deleteAlarm(int index) {
    if (index >= 0 && index < alarms.length) {
      alarms.removeAt(index);
      markModified();
    }
  }

  void reorderAlarms(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = alarms.removeAt(oldIndex);
    alarms.insert(newIndex, item);
    markModified();
  }

  void sortAlarmsByEndTime() {
    alarms.sort((a, b) => a.endTimeInMinutes.compareTo(b.endTimeInMinutes));
    markModified();
  }

  // Song Master management
  void addSongMasterItem(SongMasterItem item) {
    songMaster.add(item);
    markModified();
  }

  void updateSongMasterItem(int index, SongMasterItem item) {
    if (index >= 0 && index < songMaster.length) {
      songMaster[index] = item;
      markModified();
    }
  }

  void deleteSongMasterItem(int index) {
    if (index >= 0 && index < songMaster.length) {
      songMaster.removeAt(index);
      markModified();
    }
  }

  // Playlist management
  void addPlaylist(Playlist playlist) {
    playlists.add(playlist);
    markModified();
  }

  void updatePlaylist(int index, Playlist playlist) {
    if (index >= 0 && index < playlists.length) {
      playlists[index] = playlist;
      markModified();
    }
  }

  void deletePlaylist(int index) {
    if (index >= 0 && index < playlists.length) {
      playlists.removeAt(index);
      markModified();
    }
  }

  // Silent Hours management
  void addSilentHour(dynamic range) {
    silentHours.add(range);
    markModified();
  }

  void updateSilentHour(int index, dynamic range) {
    if (index >= 0 && index < silentHours.length) {
      silentHours[index] = range;
      markModified();
    }
  }

  void deleteSilentHour(int index) {
    if (index >= 0 && index < silentHours.length) {
      silentHours.removeAt(index);
      markModified();
    }
  }

  Future<void> analyzeAndUpdateSongMasterCounts() async {
    final folderPath = qtronFolder.value.trim();
    if (folderPath.isEmpty) {
      Get.snackbar(
        "Analyze Failed",
        "Master folder is not set",
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
      return;
    }

    final dir = Directory(folderPath);
    if (!await dir.exists()) {
      Get.snackbar(
        "Analyze Failed",
        "Master folder does not exist",
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
      return;
    }

    int updatedCount = 0;
    final List<SongMasterItem> updatedItems = [];
    final Set<String> missingFolders = {};

    for (final item in songMaster) {
      final subFolderName = item.folder;
      if (subFolderName.isEmpty) {
        updatedItems.add(item);
        continue;
      }

      Directory? matchedSubDir;
      try {
        final subDir = Directory(
          '$folderPath${Platform.pathSeparator}$subFolderName',
        );
        if (await subDir.exists()) {
          matchedSubDir = subDir;
        } else {
          await for (final entity in dir.list()) {
            if (entity is Directory) {
              final name = entity.path.split(Platform.pathSeparator).last;
              if (name.toLowerCase() == subFolderName.toLowerCase()) {
                matchedSubDir = entity;
                break;
              }
            }
          }
        }
      } catch (_) {}

      if (matchedSubDir != null) {
        int filesCount = 0;
        try {
          await for (final entity in matchedSubDir.list()) {
            if (entity is File) {
              final extension = entity.path.split('.').last.toLowerCase();
              if (extension == 'mp3') {
                filesCount++;
              }
            }
          }
        } catch (_) {}

        if (item.count != filesCount) {
          updatedItems.add(item.copyWith(id: filesCount));
          updatedCount++;
        } else {
          updatedItems.add(item);
        }
      } else {
        missingFolders.add(subFolderName);
        if (item.count != 0) {
          updatedItems.add(item.copyWith(id: 0));
          updatedCount++;
        } else {
          updatedItems.add(item);
        }
      }
    }

    if (updatedCount > 0) {
      songMaster.assignAll(updatedItems);
      markModified();
    }

    if (missingFolders.isNotEmpty) {
      Get.dialog(
        AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text("Missing Folders Detected"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "The following folders configured in Song Master are missing from the master directory on your PC:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...missingFolders.map(
                (f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.folder_off,
                        size: 16,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        f,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Their song counts have been reset to 0.",
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text("OK")),
          ],
        ),
      );
    } else if (updatedCount > 0) {
      Get.snackbar(
        "Analysis Complete",
        "Updated file counts for $updatedCount folder(s)",
        backgroundColor: Colors.green.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        "Analysis Complete",
        "All folder file counts are already up-to-date",
        backgroundColor: Colors.blue.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    }
  }
}
