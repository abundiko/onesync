import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:onesync/widgets/widgets.dart';
import 'package:provider/provider.dart';

import '../env.dart';
import '../providers/index.dart';
import '../screens/index.dart';
import '../screens/scan.dart';
import '../utils/functions.dart';
import '../utils/global.dart';
import 'connect_two_pcs.dart';

class AddDevice extends StatefulWidget {
  const AddDevice({super.key});

  @override
  State<AddDevice> createState() => _AddDeviceState();
}

class _AddDeviceState extends State<AddDevice> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
            height: 280,
            width: 280,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 245, 245),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromARGB(83, 0, 0, 0),
                    blurRadius: 30,
                  )
                ],
                borderRadius: BorderRadius.circular(10)),
            child: Provider.of<IndexProvider>(context, listen: false).isWifi
                ? QRCodeWidget(
                    data: base64.encode(utf8.encode(
                        "${deviceData.ipAddress}|||${deviceData.deviceName}|||${deviceData.password}")),
                    size: 200,
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Heading1.smaller(
                        'no wifi connection',
                        color: Color.fromARGB(255, 146, 36, 36),
                      ),
                      AppIconButton(
                        icon: Icons.refresh,
                        color: Colors.black,
                        onclick: () async {
                          final ip = await getMyIp();
                          deviceData.ipAddress = ip;
                          setState(() => true);
                        },
                      )
                    ],
                  )),
        if (Platform.isWindows) ...[
          const SizedBox(
            height: 20,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: AppButtonWithIcon(
                title: 'Connect two PCs',
                color: Theme.of(context).primaryColor,
                textColor: Theme.of(context).scaffoldBackgroundColor,
                onClick: () {
                  showAppBottomSheet(context, const ConnectTwoPcs());
                },
                icon: Icons.laptop_mac_rounded),
          ),
        ],
        if (Platform.isAndroid || Platform.isIOS) ...[
          const SizedBox(
            height: 20,
          ),
          AppButtonWithIcon(
              title: 'Scan QR Code',
              color: Theme.of(context).primaryColor,
              onClick: () {
                to(
                    context,
                    const ScanScreen(
                      isFirst: false,
                    ));
              },
              textColor: Theme.of(context).scaffoldBackgroundColor,
              width: 280,
              icon: Icons.qr_code),
        ]
      ],
    );
  }
}

class DisconnectDevice extends StatefulWidget {
  const DisconnectDevice({super.key, required this.device});
  final Map device;

  @override
  State<DisconnectDevice> createState() => _DisconnectDeviceState();
}

class _DisconnectDeviceState extends State<DisconnectDevice> {
  bool _loading = false;
  @override
  Widget build(BuildContext context) {
    final pl = Provider.of<IndexProvider>(context, listen: false);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: vw(context, 100, max: 400),
          child: Column(
            children: [
              Heading1("Disconnect ${widget.device['name']}?"),
              const SizedBox(
                height: 30,
              ),
              AppButtonWithIcon(
                loading: _loading,
                disabled: _loading,
                title: "Yes Disconnect",
                onClick: () async {
                  setState(() {
                    _loading = true;
                  });
                  if (await pl.removeFromShareGroup(
                    widget.device['ipAddress'],
                  )) {
                    Navigator.of(context).pushAndRemoveUntil(
                        CupertinoPageRoute(
                            builder: (context) => const IndexScreen()),
                        (route) => false);
                  } else {
                    back(context);
                  }
                  setState(() {
                    _loading = false;
                  });
                },
                icon: Icons.cancel,
                textColor: Colors.black87,
                color: const Color.fromARGB(255, 255, 112, 102),
              )
            ],
          ),
        ),
      ],
    );
  }
}

class NewFolder extends StatefulWidget {
  const NewFolder(
      {super.key,
      required this.deviceName,
      required this.path,
      required this.ipAddress,
      required this.onDone});
  final String deviceName, path, ipAddress;
  final Function(bool) onDone;

  @override
  State<NewFolder> createState() => _NewFolderState();
}

class _NewFolderState extends State<NewFolder> {
  final TextEditingController _inputController = TextEditingController();
  bool _loading = false;

  TextStyle _buildTextStyle(double opacity) {
    return TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w400,
        color: Theme.of(context).primaryColorDark.withOpacity(opacity));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          children: [
            const Heading1.smaller(
              "Create a new folder in device: ",
              size: 30,
              weight: FontWeight.w600,
            ),
            Heading1.smaller(
              widget.deviceName,
              size: 30,
              weight: FontWeight.w600,
              color: Theme.of(context).primaryColor.withOpacity(0.8),
            ),
            const Heading1.smaller(
              ", path: ",
              size: 30,
              weight: FontWeight.w600,
            ),
            Heading1.smaller(
              widget.path.isEmpty
                  ? '/'
                  : "/${widget.path.replaceAll("\\", "/")}",
              size: 30,
              weight: FontWeight.w600,
              color: Theme.of(context).primaryColor.withOpacity(0.8),
            ),
          ],
        ),
        const Heading1("Enter Folder Name Below"),
        Container(
          constraints: const BoxConstraints(maxWidth: 400),
          margin: const EdgeInsets.symmetric(vertical: 20),
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).primaryColorDark,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            autofocus: true,
            controller: _inputController,
            onChanged: (e) => setState(() => true),
            onSubmitted: (e) {
              _createFolder();
            },
            decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "folder name",
                hintStyle: _buildTextStyle(0.4)),
            style: _buildTextStyle(1),
          ),
        ),
        ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: AppButtonWithIcon(
              disabled: _inputController.text.isEmpty || _loading,
              loading: _loading,
              title: "Create Folder",
              onClick: _createFolder,
              icon: Icons.create_new_folder_outlined,
              color: Theme.of(context).primaryColor,
              textColor: Theme.of(context).scaffoldBackgroundColor,
            ))
      ],
    );
  }

  void _createFolder() async {
    setState(() {
      _loading = true;
    });
    try {
      if (!isSuitableFileName(_inputController.text)) {
        showAppToast("invalid folder name");
        return;
      }
      final res = await Dio()
          .post("http://${widget.ipAddress}:$FS_PORT$NEW_FOLDER_URL", data: {
        "name": deviceData.deviceName,
        "ipAddress": deviceData.ipAddress,
        "folder": _inputController.text,
        "path": widget.path,
      });
      final data = await json.decode(res.data);
      switch (data['message']) {
        case "created":
          showAppToast("Folder Created", false);
          widget.onDone(true);
          back(context);
          break;
        case "exists":
          showAppToast("Folder \" ${_inputController.text} \" already exists");
          break;
        case "error":
          showAppToast("Error creating folder");
          break;
        default:
          break;
      }
    } on SocketException {
      if (mounted) {
        showAppBottomSheet(
          context,
          const LostConnection(),
        );
      }
    } catch (e) {
      if (mounted) {
        showAppBottomSheet(
          context,
          const LostConnection(),
        );
      }
      newError(e.toString(), "lost connection error",
          "modals.dart > NewFolder() > _createFolder()");
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    widget.onDone(false);
    super.dispose();
  }
}

class LostConnection extends StatelessWidget {
  const LostConnection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: vw(context, 100, max: 400),
          child: Column(
            children: [
              Heading1(
                  "Lost Connection to ${Provider.of<IndexProvider>(context, listen: false).currentShare['name']}..."),
              const SizedBox(
                height: 30,
              ),
              AppButtonWithIcon(
                title: "Disconnect",
                onClick: () async {
                  final bool isLast =
                      await Provider.of<IndexProvider>(context, listen: false)
                          .removeFromShareGroup(
                    Provider.of<IndexProvider>(context, listen: false)
                        .currentShare['ipAddress'],
                  );
                  if (isLast) {
                    back(context);
                    backTo(context, const IndexScreen());
                  } else {
                    back(context);
                  }
                },
                icon: Icons.cancel,
                textColor: Colors.black87,
                color: const Color.fromARGB(255, 255, 112, 102),
              )
            ],
          ),
        ),
      ],
    );
  }
}

class FileUpload extends StatelessWidget {
  const FileUpload({
    super.key,
    required this.deviceName,
    required this.path,
    required this.ipAddress,
  });
  final String deviceName, path, ipAddress;

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<IndexProvider>(context);
    final List itemsFromPath = p.uploading
        .where((element) =>
            element["path"] == path &&
            element['ipAddress'] == p.currentShare['ipAddress'])
        .toList();
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (itemsFromPath.length > 5)
            SizedBox(
              height: vh(context, 20),
            ),
          Wrap(
            children: [
              const Heading1.smaller(
                "Upload files to device: ",
                size: 30,
                weight: FontWeight.w600,
              ),
              Heading1.smaller(
                deviceName,
                size: 30,
                weight: FontWeight.w600,
                color: Theme.of(context).primaryColor.withOpacity(0.8),
              ),
              const Heading1.smaller(
                ", path: ",
                size: 30,
                weight: FontWeight.w600,
              ),
              Heading1.smaller(
                path.isEmpty ? '/' : "/${path.replaceAll("\\", "/")}",
                size: 30,
                weight: FontWeight.w600,
                color: Theme.of(context).primaryColor.withOpacity(0.8),
              ),
            ],
          ),
          FileDropWidget(
            onError: (err) {
              showAppToast(err);
            },
            onData: (file) {
              try {
                Provider.of<IndexProvider>(context, listen: false).addUpload({
                  "file": File(file.path.toString()),
                  "ipAddress": ipAddress,
                  "deviceName": deviceName,
                  "path": path,
                });
              } catch (e) {
                showAppToast("error processing file ${file.name}");
                newError(e.toString(), "error processing file ${file.name}",
                    "modals.dart > FileUpload() > build()");
              }
            },
          ),
          ...itemsFromPath
              .map((e) {
                final bool isCompleted = p.uploaded
                    .where((element) => element["file"] == e["file"])
                    .toList()
                    .isNotEmpty;
                final bool isCurrent = p.uploadData["file"] == e['file'];
                final bool isError = e['error'] != null;
                final Color color = isCompleted
                    ? isError
                        ? Theme.of(context).canvasColor
                        : Theme.of(context).cardColor
                    : isCurrent
                        ? Theme.of(context).primaryColor.withOpacity(0.8)
                        : Theme.of(context).primaryColorDark.withOpacity(0.8);
                return SizedBox(
                  width: vw(context, 90),
                  child: Opacity(
                    opacity: !isCurrent && !isCompleted ? 0.8 : 1,
                    child: ListTile(
                      leading: isCompleted
                          ? Icon(
                              isError ? Icons.cancel : Icons.check_circle,
                              color: isError ? Colors.red : color,
                            )
                          : isCurrent
                              ? Heading1.smaller(
                                  "${p.uploadData['progress'].toString()}%",
                                  color: color,
                                )
                              : SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: color,
                                  ),
                                ),
                      title: Heading1.smaller(
                          (e["file"] as File)
                              .path
                              .replaceAll("\\", "/")
                              .split("/")
                              .last,
                          maxLines: 2,
                          color: color),
                      subtitle: isError
                          ? Heading1.smaller(
                              e['error'],
                              size: 16,
                              weight: FontWeight.w300,
                              color: color,
                            )
                          : null,
                    ),
                  ),
                );
              })
              .toList()
              .reversed,
          if (itemsFromPath.length > 5)
            SizedBox(
              height: vh(context, 20),
            ),
        ],
      ),
    );
  }
}

class AllFilesUploaded extends StatelessWidget {
  const AllFilesUploaded({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<IndexProvider>(context);
    final List itemsFromPath = p.uploading
        .where((element) => element['ipAddress'] == p.currentShare['ipAddress'])
        .toList();
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (itemsFromPath.length > 5)
            SizedBox(
              height: vh(context, 20),
            ),
          const Heading1("All Uploaded Files"),
          ...itemsFromPath
              .map((e) {
                final bool isCompleted = p.uploaded
                    .where((element) => element["file"] == e["file"])
                    .toList()
                    .isNotEmpty;
                final bool isCurrent = p.uploadData["file"] == e['file'];
                final bool isError = e['error'] != null;
                final Color color = isCompleted
                    ? isError
                        ? Theme.of(context).canvasColor
                        : Theme.of(context).cardColor
                    : isCurrent
                        ? Theme.of(context).primaryColor.withOpacity(0.8)
                        : Theme.of(context).primaryColorDark.withOpacity(0.8);
                return SizedBox(
                  width: vw(context, 90),
                  child: Opacity(
                    opacity: !isCurrent && !isCompleted ? 0.8 : 1,
                    child: ListTile(
                      leading: isCompleted
                          ? Icon(
                              isError ? Icons.cancel : Icons.check_circle,
                              color: isError ? Colors.red : color,
                            )
                          : isCurrent
                              ? Heading1.smaller(
                                  "${p.uploadData['progress'].toString()}%",
                                  color: color,
                                )
                              : SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: color,
                                  ),
                                ),
                      title: Heading1.smaller(
                          (e["file"] as File)
                              .path
                              .replaceAll("\\", "/")
                              .split("/")
                              .last,
                          maxLines: 2,
                          color: color),
                      subtitle: Wrap(
                        children: [
                          Heading1.smaller(
                            e['path'],
                            size: 16,
                            weight: FontWeight.w300,
                            color: color,
                          ),
                          if (isError)
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Icon(Icons.fiber_manual_record,
                                  color: color, size: 5),
                            ),
                          if (isError)
                            Heading1.smaller(
                              e['error'],
                              size: 16,
                              weight: FontWeight.w300,
                              color: color,
                            )
                        ],
                      ),
                    ),
                  ),
                );
              })
              .toList()
              .reversed,
          if (itemsFromPath.length > 5)
            SizedBox(
              height: vh(context, 20),
            ),
        ],
      ),
    );
  }
}

class AllFilesReceived extends StatelessWidget {
  const AllFilesReceived({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<IndexProvider>(context);
    final List itemsFromPath = p.received;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (itemsFromPath.length > 5)
            SizedBox(
              height: vh(context, 20),
            ),
          const Heading1("All Received Files"),
          ...itemsFromPath
              .map((e) {
                final Color color =
                    Theme.of(context).cardColor.withOpacity(0.8);
                return SizedBox(
                  width: vw(context, 90),
                  child: ListTile(
                    leading: Icon(
                      Icons.check_circle,
                      color: color,
                    ),
                    title: Heading1.smaller((e["fileName"]),
                        maxLines: 2, color: color),
                    subtitle: Wrap(
                      children: [
                        Heading1.smaller(
                          e['path'],
                          size: 16,
                          weight: FontWeight.w300,
                          color: color,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Icon(Icons.fiber_manual_record,
                              color: color, size: 5),
                        ),
                        Heading1.smaller(
                          "from ${e['deviceName']}",
                          size: 16,
                          weight: FontWeight.w300,
                          color: color,
                        )
                      ],
                    ),
                  ),
                );
              })
              .toList()
              .reversed,
          if (itemsFromPath.length > 5)
            SizedBox(
              height: vh(context, 20),
            ),
        ],
      ),
    );
  }
}

class AllFilesDownloaded extends StatelessWidget {
  const AllFilesDownloaded({
    super.key,
  });
  IconData suitableIcon(String s) {
    switch (s) {
      case 'video':
        return Icons.play_circle;
      case 'image':
        return Icons.photo;
      case 'audio':
        return Icons.music_note_rounded;
      case 'document':
        return Icons.book;
      case 'folder':
        return Icons.folder;
      default:
        return Icons.note;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<IndexProvider>(context);
    final List allDownloads = p.downloading;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (allDownloads.length > 5)
            SizedBox(
              height: vh(context, 20),
            ),
          const Heading1("All Downloaded Files"),
          ...allDownloads
              .map((e) {
                final String fileName =
                    e['data'].toString().replaceAll("\\", '/').split('/').last;
                final String fileType = getFileType(fileName.split('.').last);
                final bool isCompleted = p.downloaded
                    .where((element) => element["data"] == e["data"])
                    .toList()
                    .isNotEmpty;
                final bool isCurrent = p.downloadData["name"] == fileName;
                final Color color = isCompleted
                    ? Theme.of(context).cardColor
                    : isCurrent
                        ? Theme.of(context).primaryColor.withOpacity(0.8)
                        : Theme.of(context).primaryColorDark.withOpacity(0.8);
                return SizedBox(
                  width: vw(context, 90),
                  child: Opacity(
                    opacity: !isCurrent && !isCompleted ? 0.8 : 1,
                    child: ListTile(
                      onTap: isCompleted
                          ? () {
                              openSavedFile(
                                fileName,
                                fileType,
                                context,
                              );
                            }
                          : null,
                      leading: isCompleted
                          ? Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Icon(suitableIcon(fileType)),
                            )
                          : isCurrent
                              ? Heading1.smaller(
                                  "${p.downloadData['progress'].toString()}%",
                                  color: color,
                                )
                              : SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: color,
                                  ),
                                ),
                      title:
                          Heading1.smaller(fileName, maxLines: 2, color: color),
                      subtitle: SizedBox(
                        height: 25,
                        child: Row(
                          children: [
                            if (isCompleted)
                              SizedBox(
                                height: 25,
                                child: FutureBuilder(
                                    future: getFileSize(
                                        "${deviceData.downloadDir}/$fileName"),
                                    builder: ((context, snapshot) {
                                      return snapshot.hasData
                                          ? Heading1.smaller(
                                              formatFileSize(int.parse(
                                                  snapshot.data.toString())),
                                              size: 16,
                                              weight: FontWeight.w300,
                                              color: color,
                                            )
                                          : const SizedBox();
                                    })),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Icon(Icons.fiber_manual_record,
                                  color: color, size: 5),
                            ),
                            Heading1.smaller(
                              "from ${e['from']}",
                              size: 16,
                              weight: FontWeight.w300,
                              color: color,
                            )
                          ],
                        ),
                      ),
                      trailing: isCompleted
                          ? AppIconButton(
                              icon: Icons.launch,
                              onclick: () => openSavedFile(
                                  fileName, fileType, context,
                                  inApp: false))
                          : null,
                    ),
                  ),
                );
              })
              .toList()
              .reversed,
          if (allDownloads.length > 5)
            SizedBox(
              height: vh(context, 20),
            ),
        ],
      ),
    );
  }
}

class DeleteFiles extends StatefulWidget {
  const DeleteFiles(
      {super.key,
      required this.files,
      required this.deviceName,
      required this.ipAddress,
      required this.onDone});
  final String deviceName, ipAddress;
  final List<Map> files;
  final Function(bool) onDone;
  @override
  State<DeleteFiles> createState() => _DeleteFilesState();
}

class _DeleteFilesState extends State<DeleteFiles> {
  bool _isLoading = false;
  @override
  void initState() {
    if (widget.files.isEmpty) {
      back(context);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: vw(context, 90, max: 800),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              children: [
                const Heading1('Are you sure you want to delete: '),
                Heading1(
                    widget.files.length == 1
                        ? widget.files.first["data"]
                        : "${widget.files.first["data"]} and ${widget.files.length == 2 ? widget.files[1]['data'] : '${widget.files.length - 1} other files'}",
                    color: Theme.of(context).primaryColor.withOpacity(0.8)),
                const Heading1(" from: "),
                Heading1(widget.deviceName,
                    color: Theme.of(context).primaryColor.withOpacity(0.8)),
              ],
            ),
            Heading1.smaller(
              "This process cant be undone!",
              color: Theme.of(context).canvasColor.withOpacity(0.8),
            ),
            Container(
              margin: const EdgeInsets.only(top: 20),
              width: vw(context, 40, min: 280, max: 300),
              child: AppButtonWithIcon(
                loading: _isLoading,
                disabled: _isLoading,
                title: "Delete Permanently",
                onClick: () async {
                  setState(() => _isLoading = true);
                  try {
                    final res = await Dio().post(
                        "http://${widget.ipAddress}:$FS_PORT$DELETE_FILES_URL",
                        data: {
                          "files": widget.files,
                        });
                    final jsonData = json.decode(res.data);
                    debugPrint("data is $jsonData");
                    if (jsonData["error"] != null) {
                      showAppToast(jsonData['error']);
                    } else if (jsonData['success'] != null) {
                      Provider.of<IndexProvider>(context, listen: false)
                          .showSuccess(jsonData['success'], 3);
                      widget.onDone(true);
                      if (mounted) back(context);
                    }
                  } catch (e) {
                    showAppToast("an error occurred");
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
                icon: Icons.cancel,
                textColor: Theme.of(context).scaffoldBackgroundColor,
                color: Theme.of(context).canvasColor,
              ),
            )
          ]),
    );
  }

  @override
  void dispose() {
    super.dispose();
    widget.onDone(false);
  }
}
