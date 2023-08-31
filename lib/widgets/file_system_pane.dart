import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:onesync/widgets/modals.dart';
import 'package:onesync/widgets/widgets.dart';
import 'package:provider/provider.dart';

import '../env.dart';
import '../providers/index.dart';
import '../utils/functions.dart';

class FileSystemPane extends StatefulWidget {
  const FileSystemPane({
    super.key,
    required this.path,
  });
  final String path;

  @override
  State<FileSystemPane> createState() => _FileSystemPaneState();
}

class _FileSystemPaneState extends State<FileSystemPane> {
  List _paths = [];
  final List _allPaths = [], _selected = [];
  final ScrollController _scrollController = ScrollController(),
      _titleController = ScrollController();

  void getPaths([String path = '', bool push = true]) async {
    try {
      var response = await Dio().get('http://${widget.path}:5051/$path');
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.data) as Map;
        if (jsonData['status'] == 'error') return;
        if (jsonData['status'] == 'failed') {
          return setState(() {
            Provider.of<IndexProvider>(context, listen: false)
                .showError("An error occurred", 3);
          });
        } else if (jsonData['status'] == 'accessDenied') {
          return setState(() {
            Provider.of<IndexProvider>(context, listen: false)
                .showError("Access denied for folder ($path)", 3);
          });
        } else if (jsonData['status'] == 'directory') {
          setState(() {
            _paths = jsonData['data'] as List;
            if (push) _allPaths.add(path);
            _scrollController.jumpTo(0);
            _titleController.jumpTo(1000);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        showAppBottomSheet(
          context,
          const LostConnection(),
        );
      }
    }
  }

  @override
  void initState() {
    if (mounted) getPaths('');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<IndexProvider>(
      context,
    );
    final pl = Provider.of<IndexProvider>(context, listen: false);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (p.changedCurrentShare) {
        _allPaths.clear();
        getPaths('');
        p.changeCurrentShare(false);
      }
      if (p.updatedPath != null) {
        if (p.updatedPath == _allPaths.last) {
          getPaths(p.updatedPath!, false);
        }
        pl.unsetUpdatedPath();
      }
    });
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      color: Theme.of(context)
                          .primaryColorLight
                          .withOpacity(0.4)))),
          child: Row(
            children: [
              if (_selected.isEmpty && _allPaths.isNotEmpty) ...[
                AppIconButton(
                    label: "previous",
                    icon: Icons.arrow_back_ios_rounded,
                    onclick: () {
                      _allPaths.removeLast();
                      setState(() {});
                      getPaths(_allPaths.isEmpty ? "" : _allPaths.last, false);
                    }),
                AppIconButton(
                    label: "home | root",
                    icon: Icons.home_rounded,
                    onclick: () {
                      _allPaths.clear();
                      setState(() {});
                      getPaths("", false);
                    })
              ],
              if (_selected.isNotEmpty) ...[
                AppIconButton(
                    label: "Cancel selection",
                    icon: Icons.close,
                    onclick: () {
                      _selected.clear();
                      setState(() {});
                    }),
                Builder(builder: (context) {
                  final bool allAreSelected = _paths
                          .where((item) => item["isFile"] as bool)
                          .toList()
                          .length ==
                      _selected.length;
                  return AppIconButton(
                      label: "${!allAreSelected ? 'Select' : 'Un-select'} all",
                      icon: Icons.check_box,
                      color: allAreSelected
                          ? Theme.of(context).primaryColor
                          : null,
                      onclick: () {
                        if (allAreSelected) {
                          _selected.clear();
                        } else {
                          _selected.clear();
                          _selected.addAll(_paths
                              .where((item) => item["isFile"] as bool)
                              .toList());
                        }
                        setState(() {});
                      });
                }),
              ],
              Expanded(
                child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColorDark,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      controller: _titleController,
                      child: Heading1.smaller(
                        _selected.isNotEmpty
                            ? "${_selected.length} ${_selected.length > 1 ? 'files' : 'file'} selected"
                            : "/${_allPaths.isEmpty ? '' : _allPaths.last.replaceAll("\\", "/")}",
                        maxLines: 1,
                        color: Theme.of(context).scaffoldBackgroundColor,
                      ),
                    )),
              ),
              if (_selected.isNotEmpty) ...[
                AppIconButton(
                    label: "Download Files",
                    icon: Icons.download,
                    onclick: () {
                      for (var item in _selected) {
                        if (item["isFile"]) {
                          Provider.of<IndexProvider>(context, listen: false)
                              .addDownload(item);
                        }
                      }
                      _selected.clear();
                      setState(() {});
                    }),
                if (pl.currentShare['allowDelete'] != null &&
                    pl.currentShare['allowDelete'])
                  AppIconButton(
                      label: "Delete Files",
                      icon: Icons.delete,
                      color: Theme.of(context).canvasColor,
                      onclick: () async {
                        await showAppBottomSheet(
                            context,
                            DeleteFiles(
                                files: List<Map>.from(_selected),
                                deviceName: pl.currentShare['name'],
                                ipAddress: pl.currentShare['ipAddress'],
                                onDone: (e) {
                                  _selected.clear();
                                  getPaths(_allPaths.last, false);
                                }));
                      }),
              ],
              if (_selected.isEmpty) ...[
                AppIconButton(
                    label: "upload file",
                    icon: Icons.file_upload_rounded,
                    onclick: () {
                      showAppBottomSheet(
                          context,
                          FileUpload(
                            deviceName: pl.currentShare["name"],
                            ipAddress: pl.currentShare["ipAddress"],
                            path: _allPaths.isEmpty ? '' : _allPaths.last,
                          ));
                    }),
                AppIconButton(
                    label: "new folder",
                    icon: Icons.create_new_folder,
                    onclick: () {
                      showAppBottomSheet(
                          context,
                          NewFolder(
                              deviceName: pl.currentShare["name"],
                              ipAddress: pl.currentShare["ipAddress"],
                              path: _allPaths.isEmpty ? '' : _allPaths.last,
                              onDone: (e) {
                                if (e) {
                                  if (_allPaths.isNotEmpty) {
                                    getPaths(_allPaths.last, false);
                                  } else {
                                    getPaths("", false);
                                  }
                                }
                              }));
                    }),
              ]
            ],
          ),
        ),
        Expanded(
          child: ListView(
            controller: _scrollController,
            children: [...buildTiles(context, pl)],
          ),
        ),
      ],
    );
  }

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

  void _trySelect(Map e, bool isFile) {
    if (isFile) {
      if (_selected.contains(e)) {
        _selected.remove(e);
      } else {
        _selected.add(e);
      }
    }
    setState(() {});
  }

  Iterable<Widget> buildTiles(BuildContext context, IndexProvider pl) {
    return _paths.map((e) {
      String realPath = e['data'].replaceAll('\\', '/');
      bool isFile = e['isFile'];
      realPath = realPath.split('/').last;
      String fileType =
          isFile ? getFileType(realPath.split('.').last) : 'folder';
      return _selected.isNotEmpty && !isFile
          ? const SizedBox()
          : Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              color: _selected.contains(e)
                  ? Theme.of(context).primaryColor.withOpacity(0.08)
                  : null,
              child: GestureDetector(
                onSecondaryTapUp: (_) {
                  _trySelect(e, isFile);
                },
                child: ListTile(
                  onLongPress: () {
                    _trySelect(e, isFile);
                  },
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(suitableIcon(fileType)),
                  ),
                  trailing: SizedBox(
                      width: 100,
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!isFile)
                              const Icon(Icons.arrow_forward_ios_rounded),
                            if (isFile)
                              AppIconButton(
                                  label: 'Download',
                                  icon: Icons.download,
                                  color: Theme.of(context).primaryColor,
                                  onclick: () {
                                    Provider.of<IndexProvider>(context,
                                            listen: false)
                                        .addDownload(e);
                                  }),
                            if (isFile &&
                                !(pl.currentShare['allowDelete'] != null &&
                                    pl.currentShare['allowDelete'] as bool))
                              AppIconButton(
                                  label: 'open with other app',
                                  icon: Icons.launch,
                                  color: Theme.of(context).primaryColor,
                                  onclick: () {
                                    openNetworkFile(
                                        "http://${pl.currentShare['ipAddress']}:$FS_PORT/${e['data']}",
                                        realPath);
                                  }),
                            if (pl.currentShare['allowDelete'] != null &&
                                pl.currentShare['allowDelete'] as bool &&
                                isFile)
                              GestureDetector(
                                onTapDown: (details) {
                                  Offset position = details.globalPosition;
                                  showMenu(
                                    color: Theme.of(context)
                                        .scaffoldBackgroundColor,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    context: context,
                                    position: RelativeRect.fromLTRB(
                                        position.dx - 130,
                                        position.dy,
                                        position.dx,
                                        position.dy),
                                    items: [
                                      PopupMenuItem(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        value: 1,
                                        child: SizedBox(
                                          width: 130,
                                          child: Row(
                                            children: [
                                              Icon(Icons.launch,
                                                  color: Theme.of(context)
                                                      .primaryColor),
                                              const SizedBox(width: 5),
                                              const Heading1.smaller(
                                                'Open with device',
                                                size: 15,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      PopupMenuItem(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        value: 2,
                                        child: SizedBox(
                                          width: 130,
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete,
                                                  color: Theme.of(context)
                                                      .canvasColor),
                                              const SizedBox(width: 5),
                                              const Heading1.smaller(
                                                'Delete',
                                                size: 15,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ).then((value) async {
                                    ///when "open with device" is selected
                                    if (value == 1) {
                                      openNetworkFile(
                                          "http://${pl.currentShare['ipAddress']}:$FS_PORT/${e['data']}",
                                          realPath);
                                    }

                                    ///when "delete" is selected
                                    else if (value == 2) {
                                      await showAppBottomSheet(
                                          context,
                                          DeleteFiles(
                                              files: [e],
                                              ipAddress:
                                                  pl.currentShare['ipAddress'],
                                              deviceName:
                                                  pl.currentShare['name'],
                                              onDone: (e) {
                                                if (e) {
                                                  if (_allPaths.isNotEmpty) {
                                                    getPaths(
                                                        _allPaths.last, false);
                                                  } else {
                                                    getPaths("", false);
                                                  }
                                                }
                                              }));
                                    }
                                  });
                                },
                                child: Icon(Icons.more_horiz,
                                    color: Theme.of(context).primaryColor),
                              ),
                          ])),
                  title: Heading1.smaller(
                    realPath,
                    maxLines: 2,
                  ),
                  onTap: () {
                    _selected.isNotEmpty
                        ? _trySelect(e, isFile)
                        : isFile
                            ? () {
                                openFileInApp(e['data'], context, fileType);
                              }()
                            : getPaths(e['data']);
                  },
                ),
              ),
            );
    });
  }
}
