import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:drag_and_drop_windows/drag_and_drop_windows.dart' as dnd;

import '../providers/index.dart';
import '../providers/settings.dart';
import '../utils/functions.dart';
import '../utils/global.dart';
import 'modals.dart';

class DeviceInfoWidget extends StatelessWidget {
  const DeviceInfoWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(),
      clipBehavior: Clip.hardEdge,
      constraints:
          BoxConstraints(maxWidth: isSmall(context) ? vw(context, 38) : 280),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(
              deviceData.deviceOs.toLowerCase().contains('window')
                  ? Icons.laptop
                  : deviceData.deviceOs.toLowerCase().contains('andr')
                      ? Icons.android_rounded
                      : Icons.apple,
              color: Theme.of(context).primaryColorDark,
              size: isSmall(context) ? 30 : 50,
            ),
            SizedBox(
              width: isSmall(context) ? 10 : 20,
            ),
            SizedBox(
              height: 50,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Heading1.smaller(
                    Provider.of<SettingsProvider>(context).deviceName,
                    maxLines: 1,
                  ),
                  Heading1.smaller(
                    deviceData.deviceOs,
                    size: 15,
                    weight: FontWeight.w300,
                    maxLines: 1,
                  ),
                ],
              ),
            )
          ]),
    );
  }
}

class Heading1 extends StatelessWidget {
  const Heading1(
    this.text, {
    Key? key,
    this.size = 40,
    this.weight = FontWeight.w800,
    this.color,
    this.maxLines,
    this.isBold = true,
    this.shadow = false,
  }) : super(key: key);
  const Heading1.smaller(
    this.text, {
    Key? key,
    this.size = 20,
    this.weight = FontWeight.w500,
    this.color,
    this.maxLines,
    this.isBold = false,
    this.shadow = false,
  }) : super(key: key);
  final String text;
  final double? size;
  final int? maxLines;
  final FontWeight? weight;
  final Color? color;
  final bool isBold, shadow;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines ?? 200000,
      softWrap: true,
      overflow: TextOverflow.fade,
      style: TextStyle(
        shadows: shadow
            ? <Shadow>[
                const Shadow(
                  color: Colors.black,
                  blurRadius: 1.5,
                  offset: Offset(0, 0),
                )
              ]
            : [],
        fontSize: size! * vs(context, 0.08, max: 0.9, min: 0.8),
        fontWeight: weight,
        color: color ?? Theme.of(context).primaryColorDark.withOpacity(0.8),
      ),
    );
  }
}

class AppButtonWithIcon extends StatelessWidget {
  const AppButtonWithIcon({
    Key? key,
    required this.title,
    this.color,
    this.textColor,
    required this.onClick,
    required this.icon,
    this.width,
    this.height,
    this.loading = false,
    this.disabled = false,
  }) : super(key: key);
  final String title;
  final IconData icon;
  final VoidCallback onClick;
  final Color? color, textColor;
  final double? width, height;

  /// display a loading progress bar
  final bool loading, disabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.8 : 1,
      child: Container(
        constraints: const BoxConstraints(minWidth: 50),
        width: width,
        alignment: Alignment.center,
        // margin: EdgeInsets.all(4),
        height: height ?? 50,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 10,
              )
            ],
            color:
                color ?? Theme.of(context).primaryColorDark.withOpacity(0.08)),
        child: MaterialButton(
          minWidth: width,
          height: double.maxFinite,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          onPressed: disabled ? null : onClick,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: !loading
                    ? [
                        Icon(
                          icon,
                          color: textColor,
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Heading1.smaller(
                          title,
                          weight: FontWeight.w600,
                          color: textColor,
                        )
                      ]
                    : [
                        SizedBox(
                          height: 25,
                          width: 25,
                          child: CircularProgressIndicator(
                            color: textColor,
                            strokeWidth: 4,
                          ),
                        ),
                      ]),
          ),
        ),
      ),
    );
  }
}

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    Key? key,
    required this.icon,
    required this.onclick,
    this.shadow = false,
    this.color,
    this.label,
  }) : super(key: key);
  final IconData icon;
  final VoidCallback onclick;
  final bool shadow;
  final Color? color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(50)),
      height: 40,
      width: 40,
      child: IconButton(
        tooltip: label,
        splashRadius: 20,
        padding: const EdgeInsets.all(4),
        alignment: Alignment.center,
        onPressed: onclick,
        icon: Icon(
          icon,
          color: color ?? Theme.of(context).primaryColorDark,
          shadows: shadow
              ? <Shadow>[const Shadow(color: Colors.black, blurRadius: 5)]
              : [],
        ),
      ),
    );
  }
}

class HomeSect extends StatelessWidget {
  const HomeSect({
    super.key,
    required this.title,
    required this.body,
  });
  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Theme.of(context).primaryColorDark.withOpacity(0.08)),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Heading1.smaller(title),
          const SizedBox(
            height: 8,
          ),
          Expanded(child: body)
        ]),
      ),
    );
  }
}

class ProgressWidget extends StatelessWidget {
  const ProgressWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<IndexProvider>(
      context,
    );
    final allItems = p.downloaded.length - p.downloading.length;
    final String name;
    final Color color = p.downloading.length == p.downloaded.length
        ? Theme.of(context).cardColor
        : Theme.of(context).primaryColor;
    if (p.downloadData['name'].toString().length < 25) {
      name = p.downloadData['name'].toString();
    } else {
      name =
          "${p.downloadData['name'].toString().substring(0, 18)}...${p.downloadData['name'].toString().split('.').last}";
    }
    return p.downloadData.isNotEmpty && p.downloadData['progress'] != null
        ? GestureDetector(
            onTap: () async {
              await showAppBottomSheet(context, const AllFilesDownloaded());
              deviceData.context = context;
            },
            child: isSmall(context) &&
                    (p.received.isNotEmpty || p.uploading.isNotEmpty)
                ? Tooltip(
                    message: "Downloaded Files: ${p.downloaded.length}",
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      height: 40,
                      width: 40,
                      child: Stack(
                        children: [
                          Positioned.fill(
                              child: Center(
                            child: allItems == 0
                                ? Icon(Icons.check_circle, color: color)
                                : Heading1.smaller(
                                    allItems.toString(),
                                    color: color,
                                  ),
                          )),
                          Positioned.fill(
                              child: Center(
                            child: CircularProgressIndicator(
                              color: color,
                              strokeWidth: 4,
                              value: p.downloadData['progress'] == null
                                  ? 100
                                  : (p.downloadData['progress'] / 100 ?? 0)
                                      .toDouble(),
                            ),
                          )),
                          Positioned.fill(
                              child: Container(
                                  alignment: Alignment.topCenter,
                                  child: Transform.translate(
                                    offset: const Offset(0, -5),
                                    child: CircleAvatar(
                                      maxRadius: 7,
                                      backgroundColor: color,
                                      child: Icon(
                                        Icons.download,
                                        size: 12,
                                        color: Theme.of(context)
                                            .scaffoldBackgroundColor,
                                      ),
                                    ),
                                  ))),
                        ],
                      ),
                    ),
                  )
                : Container(
                    clipBehavior: Clip.hardEdge,
                    height: 40,
                    width: double.maxFinite,
                    constraints:
                        BoxConstraints(maxWidth: isSmall(context) ? 160 : 300),
                    decoration: BoxDecoration(
                        color: Theme.of(context).primaryColorDark,
                        borderRadius: BorderRadius.circular(10)),
                    child: Stack(
                      children: [
                        SizedBox(
                          height: double.maxFinite,
                          width: double.maxFinite,
                          child: ClipRRect(
                            child: LinearProgressIndicator(
                              color: Theme.of(context).cardColor,
                              value: (p.downloadData['progress'] as int) / 100,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 6,
                                    child: Heading1.smaller(
                                      "$name ${p.downloadData['progress'].toString()}%",
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                      maxLines: 1,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 5,
                                    child: Heading1.smaller(
                                      "from: ${p.downloadData['from']}",
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                      size: 15,
                                      maxLines: 1,
                                    ),
                                  ),
                                ]),
                          ),
                        ),
                      ],
                    ),
                  ),
          )
        : const SizedBox();
  }
}

class QRCodeWidget extends StatelessWidget {
  final String data;
  final double size;

  const QRCodeWidget({
    Key? key,
    required this.data,
    this.size = 180.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
    ));
  }
}

class FileDropWidget extends StatefulWidget {
  const FileDropWidget({
    super.key,
    required this.onData,
    required this.onError,
  });
  final Function(PlatformFile) onData;
  final Function(String) onError;

  @override
  State<FileDropWidget> createState() => _FileDropWidgetState();
}

class _FileDropWidgetState extends State<FileDropWidget> {
  void _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
          dialogTitle: "Select files",
          allowMultiple: true,
          withReadStream: true);
      if (result != null) {
        final List pickedFiles = result.files;
        for (final PlatformFile file in pickedFiles) {
          widget.onData(file);
        }
      }
    } catch (e) {
      widget.onError("unable to load file picker");
    }
  }

  Future<PlatformFile> convertFileToPlatformFile(File file) async {
    final rawPath = file.absolute.path;
    final byteData = await file.readAsBytes();
    final platformFile = PlatformFile(
      name: file.path.split('/').last,
      bytes: byteData.buffer.asUint8List(),
      path: rawPath,
      size: byteData.lengthInBytes,
    );
    return platformFile;
  }

  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription ??= dnd.dropEventStream.listen((event) async {
      await Future.forEach(event, (element) async {
        widget.onData(await convertFileToPlatformFile(File(element)));
      });
    });
  }

  @override
  void dispose() {
    _subscription!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _pickFiles();
      },
      child: Container(
        height: vh(context, 30),
        alignment: Alignment.center,
        width: double.maxFinite,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_rounded,
              size: vs(context, 10),
            ),
            const Heading1.smaller("drag files here or tap to select files")
          ],
        ),
      ),
    );
  }
}
