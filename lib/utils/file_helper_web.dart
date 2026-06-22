import 'dart:convert';
import 'dart:html' as html;

class FileHelperImpl {
  Future<String?> loadFile({String? qtronDir}) async {
    final uploadInput = html.InputElement(type: 'file');
    uploadInput.accept = '.qtr,.json';
    uploadInput.click();
    await uploadInput.onChange.first;
    if (uploadInput.files?.isEmpty ?? true) return null;
    final file = uploadInput.files![0];
    final reader = html.FileReader();
    reader.readAsText(file);
    await reader.onLoadEnd.first;
    return reader.result as String?;
  }

  Future<void> saveFile(
    String content,
    String fileName, {
    String? qtronDir,
    bool isSaveAs = false,
  }) async {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<String?> selectDirectory() async => null;
  Future<String?> findAndAddQtronDirectory() async => null;
  Future<List<String>> getSubfolders(String parentPath) async => [];
  Future<int> getFileCount(String folderPath) async => 0;
  Future<List<String>> getFiles(String folderPath) async => [];
  Future<List<String>> getClipboardFilePaths() async => [];
}
