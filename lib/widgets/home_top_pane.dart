import 'package:flutter/material.dart';
import 'package:onesync/utils/functions.dart';
import 'package:onesync/widgets/widgets.dart';
import 'package:provider/provider.dart';

import '../providers/index.dart';
import '../screens/index.dart';
import '../utils/host.dart';
import 'modals.dart';

class HomeTopPane extends StatefulWidget {
  const HomeTopPane({
    super.key,
  });

  @override
  State<HomeTopPane> createState() => _HomeTopPaneState();
}

class _HomeTopPaneState extends State<HomeTopPane> {
  @override
  Widget build(BuildContext context) {
    final p = Provider.of<IndexProvider>(
      context,
    );
    final pl = Provider.of<IndexProvider>(context, listen: false);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
      child: Column(
        children: [
          Row(mainAxisSize: MainAxisSize.max, children: [
            MaterialButton(
                onPressed: () {
                  showAppBottomSheet(context, Builder(builder: (context) {
                    bool isDisconnectingAll = false;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: vw(context, 100, max: 400),
                          child: Column(
                            children: [
                              const Heading1(
                                  "Disconnect from all share groups?"),
                              const SizedBox(
                                height: 30,
                              ),
                              AppButtonWithIcon(
                                loading: isDisconnectingAll,
                                disabled: isDisconnectingAll,
                                title: "Yes, Disconnect",
                                onClick: () {
                                  try {
                                    setState(() {
                                      isDisconnectingAll = true;
                                    });

                                    back(context);
                                    backTo(context, const IndexScreen());
                                    Host.disconnectAll();
                                  } catch (e) {
                                    newError(
                                        e.toString(),
                                        "disconnect from all sharegroups error",
                                        "home_top_pane.dart > HomeTopPane() > build()");
                                  }
                                },
                                icon: Icons.cancel,
                                textColor:
                                    Theme.of(context).scaffoldBackgroundColor,
                                color: Theme.of(context).canvasColor,
                              )
                            ],
                          ),
                        ),
                      ],
                    );
                  }));
                },
                child: const DeviceInfoWidget()),
            Expanded(
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    ReceivedWidget(),
                    UploadWidget(),
                    ProgressWidget()
                  ]),
            )
          ]),
          // if (!isSmall(context))
          SizedBox(
            height: 40,
            width: double.maxFinite,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...p.shareGroup.map((e) => ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: GestureDetector(
                          onSecondaryTapDown: (details) {
                            Offset position = details.globalPosition;
                            showMenu(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              context: context,
                              position: RelativeRect.fromLTRB(
                                  position.dx > vw(context, 80)
                                      ? position.dx - 100
                                      : position.dx,
                                  position.dy,
                                  position.dx,
                                  position.dy),
                              items: const [
                                PopupMenuItem(
                                  value: 'disconnect',
                                  child: Heading1.smaller(
                                    'Disconnect',
                                    size: 15,
                                  ),
                                ),
                              ],
                            ).then((value) async {
                              if (value == 'disconnect') {
                                if (await pl.removeFromShareGroup(
                                  e['ipAddress'],
                                )) {
                                  backTo(context, const IndexScreen());
                                }
                              }
                            });
                          },
                          child: MaterialButton(
                              padding: const EdgeInsets.all(0),
                              onLongPress: () {
                                showAppBottomSheet(
                                    context, DisconnectDevice(device: e));
                              },
                              onPressed: () {
                                if (p.shareGroup.indexOf(p.currentShare) !=
                                    p.shareGroup.indexOf(e)) {
                                  pl.setCurrentShare(e);
                                }
                              },
                              child: Container(
                                width: vw(context, 30, min: 120, max: 150),
                                padding: const EdgeInsets.all(0),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    border:
                                        p.shareGroup.indexOf(p.currentShare) !=
                                                p.shareGroup.indexOf(e)
                                            ? Border.all(
                                                color: Theme.of(context)
                                                    .primaryColorLight
                                                    .withOpacity(0.1))
                                            : Border.all(
                                                color: Theme.of(context)
                                                    .primaryColor)),
                                child: Heading1.smaller(
                                  e['name'],
                                  maxLines: 1,
                                  size: 14,
                                ),
                              )),
                        ),
                      )),
                  const SizedBox(
                    width: 20,
                  ),
                  AppIconButton(
                    icon: Icons.add,
                    onclick: () {
                      showAppBottomSheet(context, const AddDevice());
                    },
                    color: Theme.of(context).primaryColor,
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UploadWidget extends StatelessWidget {
  const UploadWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<IndexProvider>(context);
    final itemsLeft = (p.uploading.length - p.uploaded.length);
    final Color color = itemsLeft == 0
        ? Theme.of(context).cardColor
        : Theme.of(context).primaryColor.withOpacity(0.8);
    return p.uploading.isEmpty
        ? const SizedBox()
        : GestureDetector(
            onTap: () => showAppBottomSheet(context, const AllFilesUploaded()),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              height: 40,
              width: 40,
              child: Stack(
                children: [
                  Positioned.fill(
                      child: Center(
                    child: itemsLeft == 0
                        ? Icon(
                            Icons.check_circle,
                            color: color,
                          )
                        : Heading1.smaller(itemsLeft.toString()),
                  )),
                  Positioned.fill(
                      child: Center(
                    child: CircularProgressIndicator(
                      color: color,
                      strokeWidth: 4,
                      value: p.uploadData['progress'] == null
                          ? 100
                          : (p.uploadData['progress'] / 100 ?? 0).toDouble(),
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
                                Icons.upload,
                                size: 12,
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                              ),
                            ),
                          ))),
                ],
              ),
            ),
          );
  }
}

class ReceivedWidget extends StatelessWidget {
  const ReceivedWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<IndexProvider>(context);
    final allItems = p.receiving.length;
    final Color color = allItems == p.received.length
        ? Theme.of(context).cardColor
        : Theme.of(context).primaryColor.withOpacity(0.8);
    return p.receiving.isEmpty
        ? const SizedBox()
        : GestureDetector(
            onTap: () => showAppBottomSheet(context, const AllFilesReceived()),
            child: Tooltip(
              message: "Received Files: $allItems",
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                height: 40,
                width: 40,
                child: Stack(
                  children: [
                    Positioned.fill(
                        child: Center(
                      child: Heading1.smaller(
                        allItems.toString(),
                        color: color,
                      ),
                    )),
                    Positioned.fill(
                        child: Center(
                      child: CircularProgressIndicator(
                        color: color,
                        strokeWidth: 4,
                        value: p.receiveData['progress'] == null
                            ? 100
                            : (p.receiveData['progress'] / 100 ?? 0).toDouble(),
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
                                  Icons.arrow_circle_down_rounded,
                                  size: 12,
                                  color:
                                      Theme.of(context).scaffoldBackgroundColor,
                                ),
                              ),
                            ))),
                  ],
                ),
              ),
            ),
          );
  }
}
