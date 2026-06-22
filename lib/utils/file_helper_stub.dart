class FileHelperImpl {
  Future<String?> loadFile({String? qtronDir}) async => null;
  Future<void> saveFile(
    String content,
    String fileName, {
    String? qtronDir,
    bool isSaveAs = false,
  }) async {}
  Future<String?> selectDirectory() async => null;
  Future<String?> findAndAddQtronDirectory() async => null;
  Future<List<String>> getSubfolders(String parentPath) async => [];
  Future<int> getFileCount(String folderPath) async => 0;
  Future<List<String>> getFiles(String folderPath) async => [];
  Future<List<String>> getClipboardFilePaths() async => [];
}
