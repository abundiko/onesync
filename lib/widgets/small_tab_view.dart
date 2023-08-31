import 'package:flutter/material.dart';
import 'package:onesync/widgets/widgets.dart';
import 'package:provider/provider.dart';

import '../providers/index.dart';
import 'clipboard_pane.dart';
import 'file_system_pane.dart';

class SmallTabView extends StatefulWidget {
  const SmallTabView({Key? key}) : super(key: key);

  @override
  State<SmallTabView> createState() => _SmallTabViewState();
}

class _SmallTabViewState extends State<SmallTabView> {
  final controller = PageController(initialPage: 0);
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            color: Theme.of(context).primaryColorDark.withOpacity(0.04),
            child: PageView(
              controller: controller,
              onPageChanged: (index) {
                setState(() {
                  currentIndex = index;
                });
              },
              children: [
                FileSystemPane(
                    path: Provider.of<IndexProvider>(
                  context,
                ).currentShare['ipAddress'].toString()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipboardPane(
                      path: Provider.of<IndexProvider>(
                    context,
                  ).currentShare['ipAddress'].toString()),
                ),
                // _buildPage("Notification"),
              ],
            ),
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        SizedBox(
          height: 55,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTabButton("Files", 0),
              _buildTabButton("Clipboard", 1),
              // _buildTabButton("Notification", 2),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(String title, int index) {
    title = title.toLowerCase();
    final Color? color =
        currentIndex == index ? Theme.of(context).primaryColor : null;
    return Column(
      children: [
        AppIconButton(
            icon: (title == 'files'
                ? Icons.folder
                : title == 'clipboard'
                    ? Icons.copy
                    : Icons.notifications_active),
            color: color,
            onclick: () {
              setState(() {
                currentIndex = index;
                controller.animateToPage(index,
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.easeInOut);
              });
            }),
        Heading1.smaller(
          title,
          size: 12,
          color: color,
        )
      ],
    );
  }
}
