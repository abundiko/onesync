import 'package:flutter/material.dart';
import 'package:onesync/utils/functions.dart';
import 'package:onesync/widgets/small_tab_view.dart';
import 'package:onesync/widgets/widgets.dart';
import 'package:provider/provider.dart';

import '../env.dart';
import '../providers/index.dart';
import 'clipboard_pane.dart';
import 'file_system_pane.dart';

class HomeCenterPane extends StatefulWidget {
  const HomeCenterPane({
    super.key,
  });

  @override
  State<HomeCenterPane> createState() => _HomeCenterPaneState();
}

class _HomeCenterPaneState extends State<HomeCenterPane> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<IndexProvider>(context);
    Widget wallpaper = Container();
    try {
      wallpaper = Image.network(
        "http://${p.currentShare['ipAddress']}:$FS_PORT$REQUEST_WALLPAPER_URL",
        fit: BoxFit.cover,
        errorBuilder: (context, _, __) => const SizedBox(),
        width: double.maxFinite,
        height: double.maxFinite,
      );
    } catch (e) {
      wallpaper = const SizedBox();
    }
    return Expanded(
        child: Stack(
      children: [
        Opacity(opacity: 0.1, child: wallpaper),
        isSmall(context)
            ? const SmallTabView()
            : Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                        flex: 6,
                        child: HomeSect(
                            title: "File System",
                            body: FileSystemPane(
                                path: Provider.of<IndexProvider>(
                              context,
                            ).currentShare['ipAddress'].toString()))),
                    const SizedBox(
                      width: 20,
                    ),
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          Expanded(
                              child: HomeSect(
                            title: "Clipboard",
                            body: ClipboardPane(
                                path: Provider.of<IndexProvider>(
                              context,
                            ).currentShare['ipAddress'].toString()),
                          )),
                          // const SizedBox(
                          //   height: 20,
                          // ),
                          // Expanded(
                          //     child: HomeSect(
                          //   title: "Notifications",
                          //   body: Container(),
                          // )),
                        ],
                      ),
                    )
                  ],
                ),
              ),
      ],
    ));
  }
}
