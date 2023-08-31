import 'package:flutter/services.dart';
import 'package:onesync/utils/host.dart';

class ClipboardManager {
  static List<String> clipboardValues = [];

  static void init() async {
    dynamic formerValue;
    while (true) {
      await Future.delayed(const Duration(seconds: 2));
      try {
        final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
        String clipboardText = clipboardData!.text!;
        if (clipboardText == formerValue) continue;
        formerValue = clipboardText;
        Host.sendClipboardData(formerValue.toString());
        clipboardValues.add(formerValue);
      } catch (e) {
        await Future.delayed(const Duration(seconds: 2));
        continue;
      }
    }
  }
}
