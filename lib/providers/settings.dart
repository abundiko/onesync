import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../utils/global.dart';

class SettingsProvider with ChangeNotifier {
  bool allowDeletion = false,
      allowRootAccess = false,
      useDefaultDeviceName = true;
  String deviceName = '';
  List hiddenFolders = [], errors = [];

  void init() async {
    final box = await Hive.openBox('com.abundiko.onesync');
    allowDeletion = (box.get("allowDeletion") ?? false) as bool;
    allowRootAccess = (box.get("allowRootAccess") ?? false) as bool;
    useDefaultDeviceName = (box.get("useDefaultDeviceName") ?? true) as bool;
    hiddenFolders = (box.get("hiddenFolders") ?? []) as List;
    errors = (box.get("errors") ?? []);
    String hiveDeviceName = (box.get("deviceName") ?? '') as String;
    deviceData.deviceName = (useDefaultDeviceName || hiveDeviceName.isEmpty)
        ? deviceData.deviceSystemName
        : hiveDeviceName;
    deviceName = deviceData.deviceName;
    notifyListeners();
  }

  void addError(String message, String title, String clue) async {
    errors.add({
      "message": message,
      "title": title,
      "clue": clue,
    });
    final box = await Hive.openBox('com.abundiko.onesync');
    box.put("errors", errors);
  }

  void clearErrors() async {
    final box = await Hive.openBox('com.abundiko.onesync');
    errors.clear();
    box.put("errors", errors);
    notifyListeners();
  }

  void addHiddenFolder(String path) async {
    if (!hiddenFolders.contains(path)) {
      final box = await Hive.openBox('com.abundiko.onesync');
      hiddenFolders.add(path);
      box.put("hiddenFolders", hiddenFolders);
    }
    notifyListeners();
  }

  void removeHiddenFolder(String path) async {
    if (hiddenFolders.contains(path)) {
      final box = await Hive.openBox('com.abundiko.onesync');
      hiddenFolders.remove(path);
      box.put("hiddenFolders", hiddenFolders);
    }
    notifyListeners();
  }

  void setAllowDeletion(bool b) async {
    final box = await Hive.openBox('com.abundiko.onesync');
    box.put("allowDeletion", b);

    allowDeletion = b;
    notifyListeners();
  }

  void setAllowRootAccess(bool b) async {
    final box = await Hive.openBox('com.abundiko.onesync');
    box.put("allowRootAccess", b);
    allowRootAccess = b;
    if (Platform.isWindows) {
      deviceData.globalPath =
          b ? "C:" : "C:/Users/${Platform.environment['USERNAME'] ?? 'User'}";
    }
    if (Platform.isAndroid) {
      deviceData.globalPath = b ? "/storage/emulated" : "/storage/emulated/0";
    }
    notifyListeners();
  }

  void setUseDefaultDeviceName(bool b) async {
    final box = await Hive.openBox('com.abundiko.onesync');
    box.put("useDefaultDeviceName", b);
    useDefaultDeviceName = b;
    notifyListeners();
  }

  void setDeviceName(String s) async {
    final box = await Hive.openBox('com.abundiko.onesync');
    box.put("deviceName", s);
    deviceName = s;
    deviceData.deviceName = s;
    notifyListeners();
  }
}
