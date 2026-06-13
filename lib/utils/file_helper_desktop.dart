import 'dart:io';

class FileHelperImpl {
  Future<String?> loadFile() async {
    final file = File('/Users/gopu/Documents/configedit/timeAnnounce.json');
    if (await file.exists()) {
      return await file.readAsString();
    }
    return null;
  }

  Future<void> saveFile(String content, String fileName) async {
    final file = File('/Users/gopu/Documents/configedit/timeAnnounce.json');
    await file.writeAsString(content);
  }
}
