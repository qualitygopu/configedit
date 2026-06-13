import 'dart:convert';
import 'dart:html' as html;

class FileHelperImpl {
  Future<String?> loadFile() async {
    final uploadInput = html.InputElement(type: 'file');
    uploadInput.accept = '.json';
    uploadInput.click();
    await uploadInput.onChange.first;
    if (uploadInput.files?.isEmpty ?? true) return null;
    final file = uploadInput.files![0];
    final reader = html.FileReader();
    reader.readAsText(file);
    await reader.onLoadEnd.first;
    return reader.result as String?;
  }

  Future<void> saveFile(String content, String fileName) async {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
