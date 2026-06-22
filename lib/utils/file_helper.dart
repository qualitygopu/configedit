import 'file_helper_stub.dart'
    if (dart.library.html) 'file_helper_web.dart'
    if (dart.library.io) 'file_helper_desktop.dart';

class FileHelper {
  static final _impl = FileHelperImpl();

  static Future<String?> loadFile({String? qtronDir}) =>
      _impl.loadFile(qtronDir: qtronDir);
  static Future<void> saveFile(
    String content,
    String fileName, {
    String? qtronDir,
    bool isSaveAs = false,
  }) =>
      _impl.saveFile(content, fileName, qtronDir: qtronDir, isSaveAs: isSaveAs);

  static Future<String?> selectDirectory() => _impl.selectDirectory();
  static Future<String?> findAndAddQtronDirectory() =>
      _impl.findAndAddQtronDirectory();
  static Future<List<String>> getSubfolders(String parentPath) =>
      _impl.getSubfolders(parentPath);
  static Future<int> getFileCount(String folderPath) =>
      _impl.getFileCount(folderPath);
  static Future<List<String>> getFiles(String folderPath) =>
      _impl.getFiles(folderPath);
  static Future<List<String>> getClipboardFilePaths() =>
      _impl.getClipboardFilePaths();
}
