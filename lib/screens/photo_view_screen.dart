import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

import '../utils/functions.dart';
import '../widgets/widgets.dart';

class PhotoViewScreen extends StatelessWidget {
  const PhotoViewScreen({super.key, required this.url});

  final dynamic url;

  @override
  Widget build(BuildContext context) {
    final String fileName = (url is String)
        ? url.replaceAll('\\', '/').split('/').last
        : url.path.replaceAll('\\', '/').split('/').last;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: AppIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onclick: () => back(context)),
        title: Heading1.smaller(
          fileName,
          maxLines: 1,
        ),
        actions: [
          AppIconButton(
              label: 'open with other app',
              icon: Icons.launch,
              color: Theme.of(context).primaryColor,
              onclick: () async {
                if (url is String) {
                  await openNetworkFile(url, fileName);
                } else if (url is File) {
                  openSavedFile(fileName, "image", context, inApp: false);
                }
                back(context);
              }),
        ],
      ),
      body: (url is String)
          ? PhotoView(
              errorBuilder: (_, __, ___) {
                back(context);
                return const SizedBox();
              },
              imageProvider: NetworkImage(url),
            )
          : (url is File)
              ? PhotoView(
                  errorBuilder: (_, __, ___) {
                    back(context);
                    return const SizedBox();
                  },
                  imageProvider: FileImage(url),
                )
              : const Center(child: Heading1.smaller('unable to load image')),
    );
  }
}
