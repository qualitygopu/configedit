import 'file_helper_stub.dart'
    if (dart.library.html) 'file_helper_web.dart'
    if (dart.library.io) 'file_helper_desktop.dart';

class FileHelper {
  static final _impl = FileHelperImpl();

  static Future<String?> loadFile() => _impl.loadFile();
  static Future<void> saveFile(String content, String fileName) =>
      _impl.saveFile(content, fileName);
}
