// ignore_for_file: use_build_context_synchronously, empty_catches

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:onesync/utils/global.dart';
import 'package:oktoast/oktoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:platform_plus/platform_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:access_wallpaper/access_wallpaper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:open_app_file/open_app_file.dart';

import '../env.dart';
import '../providers/index.dart';
import '../providers/settings.dart';
import '../screens/photo_view_screen.dart';
import '../screens/video_player.dart';
import '../widgets/widgets.dart';

Future<String?> getMyIp([String subnet = '192.168']) async {
  try {
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.address.isNotEmpty &&
            !addr.isLinkLocal &&
            (Platform.isWindows
                ? interface.name.toLowerCase() == "wi-fi"
                : true)) {
          if (addr.address.contains(subnet)) {
            return addr.address;
          }
        }
      }
    }
  } catch (e) {
    return null;
  }
  return null;
}

bool isSmall(BuildContext context) => vw(context, 100) <= 600;

Future<bool> isConnectedToWifi() async {
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.wifi) {
    return true;
  } else {
    return false;
  }
}

Future<dynamic> getInternetIpAddress() async {
  var url = 'https://api.ipify.org';
  var response = await Dio().get((url));
  if (response.statusCode == 200) {
    return response.data;
  }
  return null;
}

to(BuildContext context, Widget newPage) {
  Navigator.of(context).push(CupertinoPageRoute(builder: (context) => newPage));
  debugPrint("screen: ${currentScreen(context)}");
}

back(BuildContext context) {
  Navigator.pop(context);
  debugPrint("screen: ${currentScreen(context)}");
}

backTo(BuildContext context, Widget newPage) {
  Navigator.of(context)
      .pushReplacement(CupertinoPageRoute(builder: (context) => newPage));
  debugPrint("screen: ${currentScreen(context)}");
}

String currentScreen(BuildContext context) {
  final route = ModalRoute.of(context);
  return route?.settings.name ?? '/';
}

String formatDateTime(DateTime dateTime) {
  DateTime now = DateTime.now();

  Duration diff = now.difference(dateTime);
  int minutes = diff.inMinutes;
  int hours = diff.inHours;
  int days = diff.inDays;

  if (minutes < 2) {
    return 'just now';
  } else if (minutes < 60) {
    return '$minutes minutes ago';
  } else if (hours < 24) {
    return '$hours hours ago';
  } else if (days <= 3) {
    return '$days days ago';
  } else {
    return '${dateTime.month}-${dateTime.day} ${_formatTime(dateTime)}';
  }
}

String _formatTime(DateTime dateTime) {
  String amPm = dateTime.hour < 12 ? 'am' : 'pm';
  int hour = dateTime.hour % 12;
  if (hour == 0) hour = 12;
  String minute =
      dateTime.minute < 10 ? '0${dateTime.minute}' : '${dateTime.minute}';
  return '$hour:$minute $amPm';
}

/// formats the [fileSizeInBytes] and returns the most appropriate string
String formatFileSize(int fileSizeInBytes) {
  if (fileSizeInBytes < 1024) {
    return '${fileSizeInBytes}B';
  } else if (fileSizeInBytes < 1024 * 1024) {
    double fileSizeInKb = fileSizeInBytes / 1024;
    return '${fileSizeInKb.toStringAsFixed(2)}KB';
  } else if (fileSizeInBytes < 1024 * 1024 * 1024) {
    double fileSizeInMb = fileSizeInBytes / (1024 * 1024);
    return '${fileSizeInMb.toStringAsFixed(2)}MB';
  } else {
    double fileSizeInGb = fileSizeInBytes / (1024 * 1024 * 1024);
    return '${fileSizeInGb.toStringAsFixed(2)}GB';
  }
}

dynamic listFiles(String path) {
  Directory directory = Directory(path);
  List<String> filesAndFolders = [];
  try {
    if (directory.existsSync()) {
      try {
        directory.listSync().forEach((FileSystemEntity entity) {
          filesAndFolders.add(entity.path.toString().replaceAll('\\', '/'));
        });
      } catch (e) {
        return "";
      }
    } else {
      return null;
    }
  } on FileSystemException {
    // Ignore if the directory is not readable
    return "";
  }

  return filesAndFolders;
}

bool isFile(File file) {
  return file.existsSync() && file.statSync().type == FileSystemEntityType.file;
}

initPlatform() async {
  final box = await Hive.openBox('com.abundiko.onesync');
  bool accessRoot = (box.get("allowRootAccess") ?? false) as bool;
  try {
    var status = await Permission.storage.request();

    if (!status.isGranted) {
      initPlatform();
    }
  } catch (e) {}

  final deviceInfo = await getDeviceInfo();
  deviceData.deviceSystemName = deviceInfo['deviceName'] ?? '';

  deviceData.deviceOs = deviceInfo['os'] ?? '';
  final downloadsDir = PlatformPlus.platform.isWindowsNative
      ? await getDownloadsDirectory()
      : Directory('/storage/emulated/0');
  deviceData.downloadDir = "${downloadsDir!.path}/onesync";
  final Directory saveDir = Directory(deviceData.downloadDir);
  if (!saveDir.existsSync()) saveDir.create();
  if (PlatformPlus.platform.isWindowsNative) {
    deviceData.globalPath = accessRoot
        ? "C:"
        : "C:/Users/${Platform.environment['USERNAME'] ?? 'User'}";
  } else if (PlatformPlus.platform.isAndroidNative) {
    deviceData.globalPath =
        accessRoot ? "/storage/emulated" : "/storage/emulated/0";

    try {
      final AccessWallpaper accessWallpaper = AccessWallpaper();

      Uint8List? wallpaperBytes =
          await accessWallpaper.getWallpaper(AccessWallpaper.homeScreenFlag);
      File wallpaperFile = File("${deviceData.downloadDir}/.my_wallpaper.png");
      wallpaperFile.writeAsBytesSync(wallpaperBytes!);
    } catch (e) {
      newError(e.toString(), "error creating wallpaper",
          "functions.dart > initPlatform()");
    }
  }
}

bool isDirectory(String path) {
  var entity = File(path);
  return entity.existsSync() &&
      entity.statSync().type == FileSystemEntityType.directory;
}

Future<void> downloadUrl(String url, Function(int) onData, String filePath,
    {bool absolutePath = false}) async {
  Dio dio = Dio();
  try {
    Directory downloadDir =
        Directory(absolutePath ? '' : deviceData.downloadDir);
    if (!downloadDir.existsSync()) downloadDir.create();
    File file =
        File("${absolutePath ? '' : '${deviceData.downloadDir}/'}$filePath");
    if (file.existsSync()) {
      onData(100);
      return;
    }
    Response response = await dio.get(
      url,
      onReceiveProgress: (int received, int total) {
        if (total != -1) {
          onData((received / total * 100).toInt());
        }
      },
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: false,
        validateStatus: (status) {
          return status != null && status < 500;
        },
      ),
    );

    var raf = file.openSync(mode: FileMode.write);
    raf.writeFromSync(response.data);
    await raf.close();
  } catch (e) {
    newError(
        e.toString(),
        "error downloading \"${absolutePath ? '' : '${deviceData.downloadDir}/'}$filePath\"",
        "functions.dart > downloadUrl()");
  }
}

void newError(String message, String title, String clue) {
  Provider.of<SettingsProvider>(deviceData.context, listen: false)
      .addError(message, title, clue);
}

void openFileInApp(String url, BuildContext context, String fileType) {
  final pl = Provider.of<IndexProvider>(context, listen: false);
  try {
    final String fileUrl =
        "http://${pl.currentShare['ipAddress']}:$FS_PORT/$url";
    switch (fileType) {
      case 'video':
        to(
            context,
            VideoPlayerScreen(
              url: fileUrl,
            ));
        break;
      case 'image':
        to(
            context,
            PhotoViewScreen(
              url: fileUrl,
            ));
        break;
      default:
        pl.showError("Unable to open File in app, try another app", 4);
        break;
    }
  } catch (e) {
    pl.showError("an error occurred, try another app", 4);
  }
}

/// Function to convert an IP address in string format to int
int ipToInt(String ipAddress) {
  List<int> byteList = ipAddress.split('.').map(int.parse).toList();
  ByteData data = ByteData(4);

  for (int i = 0; i < byteList.length; i++) {
    data.setUint8(i, byteList[i]);
  }

  // Apply a mask to ensure the result is positive
  int result = data.getInt32(0) & 0xFFFFFFFF;

  return result;
}

/// Method to convert an int back to the corresponding IP address string
String intToIP(int ipInt) {
  List<int> ipBytesList = [];
  for (int i = 0; i < 4; i++) {
    ipBytesList.add((ipInt >> ((3 - i) * 8)) & 255);
  }
  return ipBytesList.join('.');
}

/// generate a random 4 digit code (for desktop connection)
String generateRandomCode() {
  List<int> randomInts = [];

  for (int i = 0; i < 4; i++) {
    int randomNum = Random().nextInt(9);
    randomInts.add(randomNum);
  }

  return randomInts.join("");
}

void openSavedFile(String name, String fileType, BuildContext context,
    {bool inApp = true}) {
  final File file = File("${deviceData.downloadDir}/$name");
  if (inApp) {
    switch (fileType) {
      case 'video':
        to(
            context,
            VideoPlayerScreen(
              url: file,
            ));
        break;
      case 'image':
        to(
            context,
            PhotoViewScreen(
              url: file,
            ));
        break;
      default:
        showAppToast(
          "Unable to open File in app, try another app",
        );
        break;
    }
  } else {
    openFile(file.path).then((value) => showAppToast('opening...', false));
  }
}

Future<void> openFileMobile(String file) async {
  try {
    await OpenAppFile.open(file);
  } catch (e) {
    debugPrint('Failed to open file: $e');
  }
}

Future<void> openNetworkFile(
  String url,
  String filePath,
) async {
  final tmpPath = Platform.isAndroid
      ? await getTemporaryDirectory()
      : await getTemporaryDirectory();
  Directory tempDir = Directory("${tmpPath.path}/onesynctmp");
  if (!tempDir.existsSync()) {
    tempDir.createSync(recursive: true);
  }
  final launchPath =
      "${tmpPath.path}/onesynctmp/$filePath".replaceAll('\\', '/');
  await downloadUrl(url, (p0) async {
    if (p0 != 100) {
      Provider.of<IndexProvider>(deviceData.context, listen: false)
          .showWarning("preparing to open file $filePath ($p0)%");
    }
  }, launchPath, absolutePath: true);
  Provider.of<IndexProvider>(deviceData.context, listen: false)
      .showWarning("opening ($filePath)...");
  await openFile(launchPath);
  Provider.of<IndexProvider>(deviceData.context, listen: false).hideWarning();
}

Future<void> openFile(String filePath) async {
  filePath = File(filePath).absolute.path;
  final Uri uri = Uri.file(filePath);
  if (!File(uri.toFilePath()).existsSync()) return;
  await openFileMobile(filePath);
}

double vh(context, v, {double? min, double? max}) {
  final a = MediaQuery.of(context).size.height / 100 * v;
  if (min != null && min > a) return min;
  if (max != null && max < a) return max;

  return a;
}

double vw(context, v, {double? min, double? max}) {
  final a = MediaQuery.of(context).size.width / 100 * v;
  if (min != null && min > a) return min;
  if (max != null && max < a) return max;

  return a;
}

double vs(context, v, {double? min, double? max}) {
  final a = ((MediaQuery.of(context).size.height +
              MediaQuery.of(context).size.width) /
          2) /
      100 *
      v;
  if (min != null && min > a) return min;
  if (max != null && max < a) return max;

  return a;
}

ToastFuture showAppToast(dynamic child, [bool isError = true]) {
  return showToastWidget(
      Container(
        height: 40,
        alignment: Alignment.center,
        width: 300,
        decoration: BoxDecoration(
            color: isError
                ? Colors.red.withOpacity(0.4)
                : Colors.green.withOpacity(0.4),
            borderRadius: BorderRadius.circular(10)),
        child: child is String
            ? Text(child)
            : child is Widget
                ? child
                : const SizedBox(),
      ),
      position: ToastPosition.bottom);
}

Future<Map<String, String>> getDeviceInfo() async {
  Map<String, String> deviceData = <String, String>{};

  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  try {
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceData['deviceName'] = androidInfo.model;
      deviceData['os'] = "Android ${androidInfo.version.release}";
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceData['deviceName'] = iosInfo.name.toString();
      deviceData['os'] = "IOS ${iosInfo.systemVersion.toString()}";
    } else if (Platform.isWindows) {
      WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
      deviceData['deviceName'] = windowsInfo.computerName;
      deviceData['os'] = 'Windows PC';
    }
  } catch (e) {
    deviceData['deviceName'] = 'unknown';
    deviceData['os'] = 'unknown';
  }

  return deviceData;
}

String getFileType(String ext) {
  final List<String> videoExtensions = [
    'mp4',
    'm4v',
    'mkv',
    'avi',
    'mov',
    'wmv',
    'flv',
    'webm',
    'mpeg',
    'mpg',
    'm2v',
    '3gp'
  ];
  final List<String> imageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'bmp',
    'svg',
    'webp',
    'heif',
    'tiff',
    'jfif'
  ];
  final List<String> audioExtensions = [
    'mp3',
    'm4a',
    'wav',
    'wma',
    'aac',
    'ogg',
    'flac',
    'alac',
    'aiff',
    'opus'
  ];
  final List<String> documentExtensions = [
    'doc',
    'docx',
    'pdf',
    'txt',
    'rtf',
    'odt',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'csv',
    'html',
    'xml',
    'json'
  ];

  if (videoExtensions.contains(ext.toLowerCase())) {
    return 'video';
  } else if (imageExtensions.contains(ext.toLowerCase())) {
    return 'image';
  } else if (audioExtensions.contains(ext.toLowerCase())) {
    return 'audio';
  } else if (documentExtensions.contains(ext.toLowerCase())) {
    return 'document';
  } else {
    return 'other';
  }
}

Future<String> getFileSize(String path) async {
  try {
    final file = File(path);
    final isDirectory = await FileSystemEntity.isDirectory(path);
    if (isDirectory) {
      var totalFiles = 0;
      var totalFolders = 1;
      await for (var entity
          in Directory(path).list(recursive: true, followLinks: false)) {
        if (entity is File) {
          totalFiles++;
        } else if (entity is Directory) {
          totalFolders++;
        }
      }
      return 'Files: $totalFiles\nFolders: $totalFolders';
    } else {
      final length = await file.length();
      return length.toString();
    }
  } catch (e) {
    newError(e.toString(), 'Error getting file size of $path',
        "functions.dart > getFileSize()");
    return "0";
  }
}

/// Check for reserved characters or invalid file name characters
bool isSuitableFileName(String fileName) {
  RegExp regExp = RegExp(r'[<>:"/\|?*]');
  return !regExp.hasMatch(fileName);
}

Future<int> getFolderItemCount(String url) async {
  try {
    final dio = Dio();
    final response = await dio.get(
        "http://${Provider.of<IndexProvider>(deviceData.context, listen: false).currentShare['ipAddress']}:$FS_PORT/$url");
    int itemCount = 0;
    List? fileList = response.data['files'];
    List? folderList = response.data['folders'];
    if (fileList != null) {
      itemCount += fileList.length;
    }
    if (folderList != null) {
      itemCount += folderList.length;
    }
    return itemCount;
  } catch (e) {
    newError(e.toString(), "Error retrieving folder item count of $url",
        "functions.dart > getFolderItemCount()");
    return 0;
  }
}

Future<dynamic> showAppBottomSheet(BuildContext context, Widget child) {
  return showModalBottomSheet(
      enableDrag: isSmall(context),
      useSafeArea: isSmall(context),
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.transparent,
      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor.withOpacity(0.4),
      builder: (ctx) {
        deviceData.context = context;
        return Stack(
          children: [
            Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                  color:
                      Theme.of(ctx).scaffoldBackgroundColor.withOpacity(0.4)),
              alignment: Alignment.center,
              height: vh(ctx, 100),
              width: vw(ctx, 100),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: const SizedBox(),
              ),
            ),
            Container(
              color: Colors.transparent,
              alignment: Alignment.center,
              height: vh(ctx, 100),
              width: vw(ctx, 100),
              child: child,
            ),
            Positioned(
                top: 20,
                left: 20,
                child: AppIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onclick: () {
                    deviceData.context = context;
                    back(ctx);
                  },
                ))
          ],
        );
      });
}
