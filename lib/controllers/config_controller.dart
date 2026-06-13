import 'dart:convert';
import 'package:get/get.dart';
import '../models/config_model.dart';
import '../utils/file_helper.dart';

class ConfigController extends GetxController {
  final Rxn<Config> config = Rxn<Config>();
  final RxList<AlarmConfig> alarms = <AlarmConfig>[].obs;
  final RxList<dynamic> silentHours = <dynamic>[].obs;
  final RxList<SongMasterItem> songMaster = <SongMasterItem>[].obs;
  final RxString rawJson = "".obs;
  final RxString errorMessage = "".obs;
  final RxBool isModified = false.obs;

  static const String defaultJson = r'''{"AlarmConfig":[{"tit":"subrabatham","id":null,"state":true,"tim":[[0,0],[[5,5]],[[1,31]],[[1,12]],[1,2,3,4,5,6,7],[0]],"SC":[0,1,2,3,4,5,12],"type":"time"},{"tit":"time with Panchagam","id":null,"state":true,"tim":[[0,0],[[6,6],[8,8],[10,10]],[[1,31]],[[1,12]],[1,2,3,4,5,6,7],[0]],"SC":[0,1,2,3,4,5,6,7,8,9,10],"type":"time"},{"tit":"time with song","id":"time795","state":true,"tim":[[0,0],[[6,8],[17,19]],[[1,31]],[[1,12]],[1,2,3,4,5,6,7],[0]],"SC":[0,1,2,3,4,5,10],"type":"time"},{"tit":"time with quotes","id":null,"state":true,"tim":[[0,0],[[6,22]],[[1,31]],[[1,12]],[1,2,3,4,5,6,7],[0]],"SC":[0,1,2,3,4,5,11],"type":"time"}],"silentHours":[],"SongMaster":[[24,"hr","SS","SYS","மந்திரம்"],[24,"hr","VO","SYS","ஆலயம் பெயர்"],[24,"hr","HR/HWB","SYS","மணி"],[12,"mo","MO","SYS","ஆங்கில தேதி"],[31,"dt","DT","SYS","ஆங்கில தேதி"],[7,"dw","DW","SYS","ஆங்கில தேதி"],[366,"td","PN","SYS","தமிழ் தேதி"],[366,"tn","PN","SYS","திதி நட்சத்திரம்"],[7,"dw","NN","SYS","நல்லநேரம்"],[100,"sd","PN","SYS","விரத தினம்"],[100,"LP","SN1","CUS","பாடல் 1"],[762,"LP","QU","CUS","Quotes"],[12,"Vinayagar Suprabatham","SP","CUS","Subrapatham"]]}''';

  @override
  void onInit() {
    super.onInit();
    loadDefault();
  }

  // Load from a raw JSON string
  bool loadConfig(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException("Root JSON must be an object");
      }
      final parsedConfig = Config.fromJson(decoded);
      
      config.value = parsedConfig;
      alarms.assignAll(parsedConfig.alarmConfig);
      silentHours.assignAll(parsedConfig.silentHours);
      songMaster.assignAll(parsedConfig.songMaster);
      
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

  // Pick and load file
  Future<void> loadFromFile() async {
    final fileContent = await FileHelper.loadFile();
    if (fileContent != null && fileContent.trim().isNotEmpty) {
      loadConfig(fileContent);
    }
  }

  // Export/Save file
  Future<void> saveToFile() async {
    if (config.value == null) return;
    refreshRawJson();
    // Use minified or formatted depending on preference. 
    // We will save with formatting to make it clean for version control
    final jsonString = const JsonEncoder.withIndent('  ').convert(config.value!.toJson());
    await FileHelper.saveFile(jsonString, "timeAnnounce.json");
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
    );
    config.value = updatedConfig;
    rawJson.value = const JsonEncoder.withIndent('  ').convert(updatedConfig.toJson());
  }

  void markModified() {
    isModified.value = true;
    refreshRawJson();
  }

  // Alarm management
  void addAlarm(AlarmConfig alarm) {
    alarms.add(alarm);
    markModified();
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
}
