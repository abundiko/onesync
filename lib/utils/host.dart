// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onesync/env.dart';
import 'package:onesync/providers/index.dart';
import 'package:onesync/screens/index.dart';
import 'package:onesync/utils/functions.dart';
import 'package:mime/mime.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';

import '../providers/settings.dart';
import '../screens/home.dart';
import '../widgets/widgets.dart';
import 'global.dart';

class Host {
  static void hostFileSystem(
    BuildContext context,
  ) async {
    try {
      var server =
          await HttpServer.bind(deviceData.ipAddress, FS_PORT, shared: true);
      deviceData.server = server;
      debugPrint('Listening on ${server.address}:${server.port}');
      try {
        server.forEach((req) async {
          final String requestIp = (req.connectionInfo!.remoteAddress.address);

          debugPrint("Host Stage 0.1");

          final accessPath =
              "${deviceData.globalPath}${Uri.decodeComponent(req.uri.toString().replaceFirst(deviceData.globalPath, ''))}";
          debugPrint("Host Stage 0.2");

          final pl =
              Provider.of<IndexProvider>(deviceData.context, listen: false);

          final spl =
              Provider.of<SettingsProvider>(deviceData.context, listen: false);
          debugPrint("Host Stage 1");

          if (Uri.decodeComponent(req.uri.toString())
              .contains(REQUEST_WALLPAPER_URL)) {
            debugPrint("Host Stage 2.0");
            final File reqFile =
                File("${deviceData.downloadDir}/.my_wallpaper.png");
            if (reqFile.existsSync()) {
              final bytes = await reqFile.readAsBytes();
              req.response
                ..headers.contentType =
                    ContentType.parse(lookupMimeType(reqFile.absolute.path)!)
                ..add(bytes)
                ..close();
            } else {
              final byteData = await rootBundle.load("assets/images/void.png");
              req.response
                ..headers.contentType = ContentType.parse("image/png")
                ..add(byteData.buffer.asUint8List())
                ..close();
            }
          } else if (Uri.decodeComponent(req.uri.toString())
              .contains(REQUEST_FILE_URL)) {
            debugPrint("Host Stage 2.1");

            if (!HostStatic.isPartOfShareGroup(requestIp)) {
              req.response.statusCode = 403;
              req.response.close();
            } else {
              final reqUrl = Uri.decodeComponent(req.uri.toString())
                  .replaceFirst(REQUEST_FILE_URL, deviceData.globalPath);
              final File reqFile = File(reqUrl);
              if (reqFile.existsSync()) {
                final bytes = await reqFile.readAsBytes();
                req.response
                  ..headers.contentType =
                      ContentType.parse(lookupMimeType(reqFile.absolute.path)!)
                  ..add(bytes)
                  ..close();
              } else {
                req.response
                  ..statusCode = HttpStatus.notFound
                  ..write('File not found');
                await req.response.close();
              }
            }
          } else if (req.uri.toString() == CLIPBOARD_URL) {
            debugPrint("Host Stage 3");

            if (!HostStatic.isPartOfShareGroup(requestIp)) {
              req.response.statusCode = 403;
              req.response.close();
            } else {}
            try {
              final requestBody = await utf8.decoder.bind(req).join();
              final jsonData = json.decode(requestBody);
              pl.addClipboardData(jsonData['from'], jsonData['data']);
              req.response
                ..statusCode = HttpStatus.ok
                ..write("success");
              await req.response.close();
            } catch (e) {
              req.response.write(false);
              await req.response.close();
            }
          } else if (req.uri.toString() == DISCONNECT_URL) {
            debugPrint("Host Stage 4");
            if (HostStatic.shareGroupIsEmpty()) {
              req.response.statusCode = 404;
              await req.response.close();
              // continue;
            }
            try {
              final requestBody = await utf8.decoder.bind(req).join();
              final jsonData = json.decode(requestBody);
              final reqIp = jsonData['from'];
              final isLast = await HostStatic.removeFromShareGroup(reqIp);
              if (isLast) {
                backTo(deviceData.context, const IndexScreen());
              }
            } catch (e) {
              debugPrint("unable to remove share1 $e");
            } finally {
              await req.response.close();
            }
          } else if (req.uri.toString() == KNOCK_DESKTOP_URL) {
            debugPrint("Host Stage 5.0");

            //! When a desktop wants to connect
            bool hasSent = false;
            try {
              final requestBody = await utf8.decoder.bind(req).join();
              final jsonData = json.decode(requestBody);

              if (!HostStatic.isPartOfShareGroup(jsonData['ipAddress'])) {
                req.response
                  ..statusCode = HttpStatus.ok
                  ..write(json.encode({
                    "status": "success",
                    "name": deviceData.deviceName.toString(),
                    "ipAddress": deviceData.ipAddress.toString(),
                    "allowDelete": spl.allowDeletion,
                  }))
                  ..close();
                hasSent = true;
                deviceData.desktopMap[jsonData["ipAddress"]] =
                    generateRandomCode();
                showAppBottomSheet(
                    context,
                    SizedBox(
                      width: vw(context, 80, max: 800),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Heading1(
                              "${jsonData['name']} is trying to connect, use the verification code below..."),
                          Heading1(
                              "${deviceData.desktopMap[jsonData["ipAddress"]]}"),
                          const SizedBox(
                            height: 10,
                          ),
                          ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 280),
                              child: AppButtonWithIcon(
                                title: "Done",
                                onClick: () {
                                  back(context);
                                },
                                icon: Icons.check,
                                color: Theme.of(context).primaryColor,
                                textColor:
                                    Theme.of(context).scaffoldBackgroundColor,
                              ))
                        ],
                      ),
                    ));
              } else {
                req.response
                  ..statusCode = HttpStatus.ok
                  ..write(json.encode({
                    "status": "already",
                  }))
                  ..close();
              }
            } catch (e) {
              if (!hasSent) {
                req.response.write(false);
                await req.response.close();
              }
            }
          } else if (req.uri.toString() == CONNECT_DESKTOP_URL) {
            debugPrint("Host Stage 5.1");
            try {
              final requestBody = await utf8.decoder.bind(req).join();
              final jsonData = json.decode(requestBody);
              if (jsonData['code'] ==
                  deviceData.desktopMap[jsonData['ipAddress']]) {
                if (!HostStatic.isPartOfShareGroup(jsonData['ipAddress'])) {
                  final int newLength = pl.addToShareGroup(jsonData['name'],
                      jsonData['ipAddress'], jsonData['allowDelete'], true);
                  if (newLength > 0) {
                    req.response
                      ..statusCode = HttpStatus.ok
                      ..write(json.encode({
                        "status": "success",
                        "name": deviceData.deviceName.toString(),
                        "ipAddress": deviceData.ipAddress.toString(),
                        "allowDelete": spl.allowDeletion,
                      }));
                    if (newLength == 1) {
                      back(deviceData.context);
                      backTo(deviceData.context, const HomeScreen());
                    }
                  }
                } else {
                  req.response
                    ..statusCode = HttpStatus.ok
                    ..write(json.encode({
                      "status": "already",
                    }));
                }
              } else {
                req.response
                  ..statusCode = HttpStatus.ok
                  ..write(json.encode({"error": "wrong code"}));
              }
              await req.response.close();
            } catch (e) {
              req.response.write(false);
              await req.response.close();
            }
          } else if (req.uri.toString() == FILE_UPLOAD_URL) {
            if (!HostStatic.isPartOfShareGroup(requestIp)) {
              req.response.statusCode = 403;
              req.response.close();
            } else {
              try {
                final boundary =
                    req.headers.contentType!.parameters['boundary'];
                final transformer =
                    MimeMultipartTransformer(boundary.toString());
                final parts = await transformer.bind(req).toList();

                if (parts.isEmpty) {
                  req.response.statusCode = HttpStatus.badRequest;
                  await req.response.close();
                }

                final filePart = parts.firstWhere((part) => part
                    .headers['content-disposition']
                    .toString()
                    .startsWith('form-data; name="file"'));

                final namePart = parts.firstWhere((part) => part
                    .headers['content-disposition']
                    .toString()
                    .startsWith('form-data; name="name"'));
                final savePathPart = parts.firstWhere((part) => part
                    .headers['content-disposition']
                    .toString()
                    .startsWith('form-data; name="path"'));
                final sizePart = parts.firstWhere((part) => part
                    .headers['content-disposition']
                    .toString()
                    .startsWith('form-data; name="size"'));

                final saveName = await utf8.decoder.bind(namePart).join();
                final saveSize =
                    int.tryParse(await utf8.decoder.bind(sizePart).join()) ?? 1;
                final savePath = await utf8.decoder.bind(savePathPart).join();
                final String saveLocation = "$savePath/$saveName";

                final filePath = '${deviceData.globalPath}/$saveLocation';
                final file = File(filePath);
                if (file.existsSync()) {
                  req.response
                      .write(json.encode({"error": "file already exists"}));
                  await req.response.close();
                  // continue;
                }
                final sink = file.openWrite();
                int total = 0, oldProgress = 0;

                await filePart.listen(
                  (event) async {
                    sink.add(event);
                    total += event.length;
                    int progress = ((100 * total) / saveSize).floor();
                    if (oldProgress != progress) {
                      oldProgress = progress;
                      debugPrint("progress: $oldProgress");
                      final List from = pl.shareGroup
                          .where((element) => element["ipAddress"] == requestIp)
                          .toList();
                      pl.updateReceiveData({
                        "fileName": saveName,
                        "path": savePath,
                        "ipAddress": requestIp,
                        "deviceName":
                            from.isEmpty ? "unknown" : from.first['name'],
                      }, progress);
                      if (total == saveSize) {
                        try {
                          req.response.statusCode = HttpStatus.ok;
                          req.response
                              .write(json.encode({"success": "file saved!"}));
                          await req.response.close();
                          await sink.done;
                          await sink.close();
                        } catch (e) {
                          newError(
                              e.toString(),
                              "error sending response and saving file",
                              "host.dart > Host.hostFileSystem() > FILE_UPLOAD_URL");
                        }
                      }
                    }
                  },
                  onDone: () async {},
                  cancelOnError: true,
                ).asFuture();
              } catch (e) {
                newError(e.toString(), "File upload or save error",
                    "host.dart > Host.hostFileSystem() > FILE_UPLOAD_URL");
                await req.response.close();
              }
            }
          } else if (req.uri.toString() == KNOCK_URL) {
            debugPrint("Host Stage 5");

            //! When a device wants to connect
            try {
              final requestBody = await utf8.decoder.bind(req).join();
              final jsonData = json.decode(requestBody);
              if (jsonData['password'] == deviceData.password) {
                final int newLength = pl.addToShareGroup(jsonData['name'],
                    jsonData['ipAddress'], jsonData['allowDelete'], true);
                if (newLength > 0) {
                  req.response
                    ..statusCode = HttpStatus.ok
                    ..write(json.encode({
                      "status": "success",
                      "name": deviceData.deviceName.toString(),
                      "ipAddress": deviceData.ipAddress.toString(),
                      "allowDelete": spl.allowDeletion,
                    }))
                    ..close();
                  if (newLength == 1) {
                    backTo(deviceData.context, const HomeScreen());
                  }
                } else {
                  req.response
                    ..statusCode = HttpStatus.ok
                    ..write(json.encode({
                      "status": "already",
                    }))
                    ..close();
                }
              } else {
                req.response
                  ..statusCode = HttpStatus.ok
                  ..write(json.encode({"error": "wrong password"}))
                  ..close();
              }
            } catch (e) {
              req.response.write(false);
              await req.response.close();
            }
          } else if (req.uri.toString() == NEW_FOLDER_URL) {
            try {
              final requestBody = await utf8.decoder.bind(req).join();
              final jsonData = json.decode(requestBody);
              if (!HostStatic.isPartOfShareGroup(jsonData['ipAddress'])) {
                req.response.write(json.encode({"message": "not part"}));
                req.response.close();
              } else {
                final dirPath =
                    "${deviceData.globalPath}/${jsonData["path"]}${jsonData['path'].toString().isEmpty ? jsonData['folder'] : "/${jsonData['folder']}"}";

                final Directory newDir = Directory(dirPath);
                if (newDir.existsSync()) {
                  req.response.write(json.encode({"message": "exists"}));
                  req.response.close();
                } else {
                  await newDir.create();
                  req.response.write(json.encode({"message": "created"}));
                  req.response.close();
                }
              }
            } catch (e) {
              newError(e.toString(), "create new folder error",
                  "host.dart > Host.hostFileSystem() > NEW_FOLDER_URL");
              req.response.write(json.encode({"message": "error"}));
              req.response.close();
            }
          } else if (req.uri.toString() == DELETE_FILES_URL) {
            debugPrint("Host Stage 6");
            if (!HostStatic.isPartOfShareGroup(requestIp)) {
              req.response.statusCode = 403;
              req.response.close();
            } else {
              final requestBody = await utf8.decoder.bind(req).join();
              final jsonData = json.decode(requestBody);
              int deleted = 0;
              try {
                final List fileList = List.from(jsonData['files']);
                await Future.forEach(fileList, (item) async {
                  File fileToDelete =
                      File("${deviceData.globalPath}/${item["data"]}");
                  try {
                    if (await fileToDelete.exists()) {
                      fileToDelete.delete();
                    }
                  } catch (e) {
                    //when an error occurs when deleting file
                  } finally {
                    deleted++;
                  }
                });
                if (deleted == fileList.length) {
                  req.response.write(json.encode({
                    "success":
                        "Deleted ${fileList.length} ${fileList.length > 1 ? 'Files' : 'file'} Successfully"
                  }));
                } else {
                  req.response.write(json.encode({
                    "success":
                        "Deleted $deleted of ${fileList.length} ${fileList.length > 1 ? 'Files' : 'file'} Successfully"
                  }));
                }
                req.response.close();
              } catch (e) {
                req.response
                    .write(json.encode({"error": "error Deleting files"}));
                req.response.close();
              }
            }
          } else {
            debugPrint("Host Stage 7");

            if (!HostStatic.isPartOfShareGroup(requestIp)) {
              req.response.statusCode = 403;
              req.response.close();
            } else {
              final files = listFiles(accessPath);

              if (files is String) {
                req.response
                  ..statusCode = HttpStatus.ok
                  ..write(json.encode({'status': 'accessDenied'}));
                await req.response.close();
              } else if (files == null) {
                File testFile = File(accessPath);
                if (!testFile.existsSync()) {
                  req.response
                    ..statusCode = HttpStatus.ok
                    ..write(json.encode({'status': 'error'}));
                } else {
                  req.response
                    ..contentLength = testFile.lengthSync()
                    ..statusCode = HttpStatus.ok;
                  await req.response.addStream(testFile.openRead());
                  await req.response.flush();
                }
                await req.response.close();
              } else {
                final List publicFiles =
                    files.where((e) => !spl.hiddenFolders.contains(e)).toList();
                final filesToSend = await generateMap(publicFiles);
                (filesToSend['data'] as List).removeWhere(
                    (str) => str['data'].toString().trim().startsWith('.'));

                req.response
                  ..statusCode = HttpStatus.ok
                  ..write(json.encode(filesToSend));
                await req.response.close();
              }
            }
          }
        });
      } on SocketException {
        showAppToast('cannot initialize connection');
      } catch (e, f) {
        showAppToast("Host Error $e\n $f");
        newError(e.toString(), "host error", "host.dart > Host.hostFileSystem");
      }
    } catch (e) {
      showAppToast("unable to initialize connection");
    }
  }

  static Future<Map> generateMap(List files) async {
    Map filesToSend = {'status': 'directory', 'data': []};
    await Future.forEach(files, (e) async {
      final value = {
        "isFile": isFile(File(e)),
        "data": e.replaceFirst('${deviceData.globalPath}/', ''),
        // "type": await getFileType(e),
        // "size": await getFileSize(e),
      };
      (filesToSend['data'] as List).add(value);
    });
    (filesToSend['data'] as List).sort((a, b) {
      if (a["isFile"] == false && b["isFile"] == false) {
        return a["data"].compareTo(b["data"]);
      } else if (a["isFile"] == false) {
        return -1;
      } else if (b["isFile"] == false) {
        return 1;
      } else {
        return a["data"].compareTo(b["data"]);
      }
    });
    return filesToSend;
  }

  static Future<bool> knock(String ipAddress, String password) async {
    try {
      final spl =
          Provider.of<SettingsProvider>(deviceData.context, listen: false);
      final res =
          await Dio().post("http://$ipAddress:$FS_PORT$KNOCK_URL", data: {
        "name": deviceData.deviceName,
        "ipAddress": deviceData.ipAddress,
        "password": password,
        "allowDelete": spl.allowDeletion,
      });
      final data = await json.decode(res.data);
      if (data == false) return false;
      if (data['status'] == 'already') {
        showAppToast("already connected");
        return false;
      }
      Provider.of<IndexProvider>(deviceData.context, listen: false)
          .addToShareGroup(data['name'], data['ipAddress'],
              (data['allowDelete'] ?? false) as bool, true);
      return true;
    } catch (e) {
      showToast("knock error: $e");
      return false;
    }
  }

  static Future<dynamic> knockDesktop(String connectionCode) async {
    try {
      final ipAddress = intToIP(int.parse(connectionCode));
      final res = await Dio()
          .post("http://$ipAddress:$FS_PORT$KNOCK_DESKTOP_URL", data: {
        "name": deviceData.deviceName,
        "ipAddress": deviceData.ipAddress,
      });
      final data = await json.decode(res.data);
      if (data == false) return false;
      if (data['status'] == 'already') {
        return true;
      }

      return data as Map;
    } catch (e) {
      if (e.toString().contains('timeout')) {
        return 1;
      }
      showToast("knock error: $e");
      newError(e.toString(), "knock desktop error for $connectionCode",
          "host.dart > Host.knockDesktop()");
      return null;
    }
  }

  static Future<dynamic> connectDesktop(
      String verificationCode, String ipAddress) async {
    try {
      final spl =
          Provider.of<SettingsProvider>(deviceData.context, listen: false);
      final res = await Dio()
          .post("http://$ipAddress:$FS_PORT$CONNECT_DESKTOP_URL", data: {
        "name": deviceData.deviceName,
        "ipAddress": deviceData.ipAddress,
        "code": verificationCode,
        "allowDelete": spl.allowDeletion,
      });
      final data = await json.decode(res.data);
      if (data == false) return false;
      if (data['status'] == 'already') {
        return true;
      }

      return data as Map;
    } catch (e) {
      if (e.toString().contains('timeout')) {
        return 1;
      }
      showToast("knock error: $e");
      newError(e.toString(), "connect desktop desktop error for $ipAddress",
          "host.dart > Host.connectDesktop()");
      return null;
    }
  }

  static Future<void> sendClipboardData(String data) async {
    if (HostStatic.shareGroupIsEmpty()) return;
    try {
      final List currentShareIps =
          Provider.of<IndexProvider>(deviceData.context, listen: false)
              .shareGroup
              .map((e) => e['ipAddress'])
              .toList();
      await Future.forEach(currentShareIps, (ip) async {
        try {
          await Dio().post("http://$ip:$FS_PORT$CLIPBOARD_URL",
              data: {"from": deviceData.ipAddress, "data": data});
        } catch (e) {
          showAppToast("error sending clipboard");
          newError(e.toString(), "failed to send clipboard to $ip",
              "host.dart > Host.sendClipboardData()");
        }
      });
    } catch (e) {
      showAppToast("error sending clipboard");
      newError(e.toString(), "send clipboard error",
          "host.dart > Host.sendClipboardData()");
    }
  }

  static disconnectAll() async {
    final List currentShareIps =
        Provider.of<IndexProvider>(deviceData.context, listen: false)
            .shareGroup
            .map((e) => e['ipAddress'])
            .toList();

    await Future.forEach(currentShareIps, (ip) async {
      try {
        await Dio().post("http://$ip:$FS_PORT$DISCONNECT_URL",
            data: {"from": deviceData.ipAddress});
      } catch (e) {
        newError(e.toString(), "disconnect error for $ip",
            "host.dart > Host.disconnectAll() > try-1");
      }
    });
    try {
      debugPrint('removing...');
      Provider.of<IndexProvider>(deviceData.context, listen: false).endShare();
    } catch (e) {
      showAppToast('disconnect error $e');
      newError(e.toString(), "error ending share",
          "host.dart > Host.disconnectAll() > try-1");
    }
  }

  static disconnectOne(String ip) async {
    try {
      await Dio().post("http://$ip:$FS_PORT$DISCONNECT_URL",
          data: {"from": deviceData.ipAddress});
    } catch (e) {
      showAppToast("error disconnectng");
      newError(e.toString(), "disconnect error for $ip",
          "host.dart > Host.disconnectOne()");
    }
  }
}

class HostStatic {
  static bool isPartOfShareGroup(ip) {
    final pl = Provider.of<IndexProvider>(deviceData.context, listen: false);
    return (pl.shareGroup.where(
      (element) => element['ipAddress'] == ip,
    )).isNotEmpty;
  }

  static bool shareGroupIsEmpty() {
    final pl = Provider.of<IndexProvider>(deviceData.context, listen: false);
    return pl.shareGroup.isEmpty;
  }

  static Future<bool> removeFromShareGroup(ip) async {
    final pl = Provider.of<IndexProvider>(deviceData.context, listen: false);
    return (await pl.removeFromShareGroup(ip, false));
  }
}
