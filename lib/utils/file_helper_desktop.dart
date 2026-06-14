import 'dart:io';

class FileHelperImpl {
  Future<String?> loadFile() async {
    final qtrFile = File('/Users/gopu/Documents/configedit/timeAnnounce.qtr');
    if (await qtrFile.exists()) {
      return await qtrFile.readAsString();
    }
    final jsonFile = File('/Users/gopu/Documents/configedit/timeAnnounce.json');
    if (await jsonFile.exists()) {
      return await jsonFile.readAsString();
    }
    return null;
  }

  Future<void> saveFile(String content, String fileName) async {
    final file = File('/Users/gopu/Documents/configedit/$fileName');
    await file.writeAsString(content);
  }
}
