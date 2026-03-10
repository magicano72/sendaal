import 'package:flutter/services.dart';

/// Clipboard utilities for copying to clipboard
class ClipboardUtils {
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(
      ClipboardData(text: text),
    );
  }

  static Future<String?> pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    return data?.text;
  }
}
