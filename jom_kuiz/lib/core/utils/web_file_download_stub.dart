import 'package:flutter/services.dart';

/// On non-web platforms, fall back to copying the content to the clipboard.
Future<void> triggerFileDownload(
    String content, String filename, String mimeType) async {
  await Clipboard.setData(ClipboardData(text: content));
}
