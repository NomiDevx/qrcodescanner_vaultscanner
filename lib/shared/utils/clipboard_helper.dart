import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Helper for copying text to clipboard with toast feedback.
class ClipboardHelper {
  ClipboardHelper._();

  /// Copy [text] to clipboard and show a toast notification.
  static Future<void> copy(String text, {String? label}) async {
    await Clipboard.setData(ClipboardData(text: text));
    Fluttertoast.showToast(
      msg: label ?? 'Copied to clipboard',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }
}
