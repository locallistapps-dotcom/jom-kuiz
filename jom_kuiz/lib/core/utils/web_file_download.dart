// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// On Flutter Web, triggers a browser file download for [content].
Future<void> triggerFileDownload(
    String content, String filename, String mimeType) async {
  final html.Blob blob = html.Blob(<String>[content], mimeType);
  final String url = html.Url.createObjectUrlFromBlob(blob);
  final html.AnchorElement anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..style.display = 'none';
  html.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
