import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/index.dart';
import '../utils/functions.dart';
import '../widgets/widgets.dart';

class ReceivedScreen extends StatelessWidget {
  const ReceivedScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<IndexProvider>(context);
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          leading: AppIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onclick: () => back(context)),
          title: const Heading1.smaller(
            "Received Files",
            maxLines: 1,
          ),
        ),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          children: [...buildTiles(context, p)],
        ));
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

  Iterable<Widget> buildTiles(BuildContext context, IndexProvider pl) {
  
    return pl.receiving.map((e) {
      String fileType = getFileType(e['name'].split('.').last);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
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
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                AppIconButton(
                    label: 'open with other app',
                    icon: Icons.launch,
                    color: Theme.of(context).primaryColor,
                    onclick: () {}),
              ])),
          title: Heading1.smaller(
            e['name'],
            maxLines: 2,
          ),
          subtitle: Heading1.smaller(
            "from: ${e['from']}",
            maxLines: 1,
            weight: FontWeight.w300,
            size: 14,
          ),
          onTap: () {
            openSavedFile(
              e['name'],
              fileType,
              context,
            );
          },
        ),
      );
    });
  }
}
