import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../env.dart';
import '../utils/functions.dart';
import '../utils/host.dart';

class IndexProvider with ChangeNotifier {
  bool isWifi = false, changedCurrentShare = false;
  List<Map> shareGroup = [],
      receiving = [],
      received = [],
      uploading = [],
      uploaded = [],
      downloading = [],
      downloaded = [];

  Map receiveData = {}, uploadData = {}, downloadData = {};
  Map currentShare = {};
  String? error, success, warning, updatedPath;

  final StreamController<Map> _downloadController =
      StreamController<Map>.broadcast();
  final StreamController<Map> _uploadController =
      StreamController<Map>.broadcast();
  final StreamController<Map> _receiveController =
      StreamController<Map>.broadcast();
  int _nextUpload = 0, _nextDownload = 0;

  void changeCurrentShare(bool b) {
    changedCurrentShare = b;
  }

  int addToShareGroup(String name, String ipAddress, bool allowDelete,
      [bool isCurrent = false]) {
    Map data = {
      "name": name,
      "ipAddress": ipAddress,
      "allowDelete": allowDelete
    };
    final Map contains = shareGroup.firstWhere(
      (element) => element['ipAddress'] == data['ipAddress'],
      orElse: () {
        return {};
      },
    );
    if (contains.isEmpty) {
      shareGroup.add(data);
    }
    if (isCurrent && shareGroup.isNotEmpty) setCurrentShare(shareGroup.last);
    notifyListeners();
    return shareGroup.length;
  }

  Future<bool> removeFromShareGroup(String ip, [bool twice = true]) async {
    if (twice) await Host.disconnectOne(ip);
    shareGroup.removeWhere((element) => element['ipAddress'] == ip);
    if (currentShare['ipAddress'] == ip && shareGroup.isNotEmpty) {
      setCurrentShare(shareGroup.last);
    }
    notifyListeners();
    return (shareGroup.isEmpty);
  }

  void setCurrentShare(Map value) {
    currentShare = value;
    changeCurrentShare(true);
    notifyListeners();
  }

  void endShare() {
    shareGroup.clear();
    currentShare = {};
    notifyListeners();
  }

  void unsetUpdatedPath() {
    updatedPath = null;
  }

  void setIsWifi(bool b) {
    isWifi = b;
    notifyListeners();
  }

  void showError(String err, [int? delay]) async {
    error = err;
    notifyListeners();
    if (delay != null) {
      await Future.delayed(Duration(seconds: delay));
      error = null;
      notifyListeners();
    }
  }

  void hideError() {
    error = null;
    notifyListeners();
  }

  void showSuccess(String suc, [int? delay]) async {
    success = suc;
    notifyListeners();
    if (delay != null) {
      await Future.delayed(Duration(seconds: delay));
      success = null;
      notifyListeners();
    }
  }

  void hideSuccess() {
    success = null;
    notifyListeners();
  }

  void showWarning(String warn, [int? delay]) async {
    warning = warn;
    notifyListeners();
    if (delay != null) {
      await Future.delayed(Duration(seconds: delay));
      warning = null;
      notifyListeners();
    }
  }

  void hideWarning() {
    warning = null;
    notifyListeners();
  }

  void addDownload(Map map) {
    map['ipAddress'] = currentShare['ipAddress'];
    map['from'] = currentShare['name'];
    if (!downloading.contains(map)) {
      downloading.add(map);
      _downloadController.add(map);
      showSuccess(
          "Added ${map['data'].toString().replaceAll("\\", '/').split('/').last} to download cue",
          3);
    } else {
      showWarning(
          "Already downloaded ${map['data'].toString().replaceAll("\\", '/').split('/').last}",
          3);
    }
    notifyListeners();
  }

  void addUpload(Map map) {
    _uploadController.add(map);
    uploading.add(map);
    notifyListeners();
  }

  void addClipboardData(String from, String data) {
    final map =
        shareGroup.firstWhere((element) => element['ipAddress'] == from);
    final int mapIndex = shareGroup.indexOf(map);
    final clipboardMap = {
      "data": data,
      "date": DateTime.now(),
    };
    shareGroup[mapIndex]['clipboard'] == null
        ? shareGroup[mapIndex]['clipboard'] = [clipboardMap]
        : (shareGroup[mapIndex]['clipboard'] as List).add(clipboardMap);
    notifyListeners();
  }

  void updateReceiveData(Map data, int progress) {
    receiveData = {...data, "progress": progress};
    bool contains = receiving
        .where((element) =>
            element['fileName'] == data['fileName'] &&
            element['path'] == data['path'])
        .isNotEmpty;
    if (!contains) {
      receiving.add(data);
    }
    notifyListeners();
    if (progress == 100) {
      _receiveController.add(data);
      notifyListeners();
    }
  }

  void handleStreams() {
    _downloadController.stream.listen((e) async {
      final int index = downloading.indexOf(e);
      while (true) {
        if (index != _nextDownload) {
          await Future.delayed(const Duration(seconds: 1));
          continue;
        } else {
          final String fileName =
              e['data'].toString().replaceAll("\\", '/').split('/').last;
          downloadData['name'] = fileName;
          downloadData['from'] = e['from'];
          final contains = downloading.firstWhere((element) {
            return element['name'] == fileName;
          }, orElse: () => {});
          await downloadUrl("http://${e['ipAddress']}:$FS_PORT/${e['data']}",
              (p0) {
            downloadData['progress'] = p0;
            notifyListeners();
            if (p0 >= 100) {}
          }, fileName);
          if (contains.isEmpty) downloaded.add(e);
          _nextDownload++;
          notifyListeners();
          break;
        }
      }
    });
    _uploadController.stream.listen((data) async {
      final int index = uploading.indexOf(data);
      while (true) {
        if (index != _nextUpload) {
          await Future.delayed(const Duration(seconds: 1));
          continue;
        } else {
          try {
            final url = "http://${data['ipAddress']}:$FS_PORT$FILE_UPLOAD_URL";
            FormData formData = FormData.fromMap({
              "path": data['path'],
              "size": await data['file'].length(),
              "name": data['file'].path.replaceAll("\\", "/").split('/').last,
              "file": await MultipartFile.fromFile(data['file'].path,
                  filename: data['file'].path.split('/').last),
            });
            int oldProgress = 0;
            uploadData["progress"] = oldProgress;
            uploadData["file"] = data['file'];
            uploadData["to"] = data['deviceName'];
            notifyListeners();
            final res = await Dio().post(url, data: formData,
                onSendProgress: (sent, total) {
              int progress = ((100 * sent) / total).floor();
              if (oldProgress != progress) {
                oldProgress = progress;
                uploadData["progress"] = oldProgress;
                notifyListeners();
              }
            });

            final Map jsonData = json.decode(res.data);
            if (jsonData['error'] != null) {
              showAppToast(jsonData['error']);
              uploading[index]["error"] = jsonData['error'];
            } else if (jsonData['success'] != null) {
              showSuccess(
                  "uploaded ${data['file'].path.replaceAll("\\", "/").split("/").last} to ${data['deviceName']}",
                  3);
              notifyListeners();
            } else {
              showAppToast("file upload error!");
              uploading[index]["error"] = "file upload error!";
            }
            uploaded.add(data);
            _nextUpload++;
            updatedPath = data["path"].toString();
            notifyListeners();
            break;
          } catch (e) {
            debugPrint("file upload client error: ${e.toString()}");

            showAppToast(
                "Error uploading file: ${data['file'].path.replaceAll("\\", "/").split("/").last}");
            _nextUpload++;
            notifyListeners();
            break;
          }
        }
      }
    });
    _receiveController.stream.listen((data) async {
      received.add(data);
      notifyListeners();
    });
  }
}
