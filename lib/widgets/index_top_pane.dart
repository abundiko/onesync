import 'package:flutter/material.dart';
import 'package:onesync/widgets/widgets.dart';

import '../screens/index.dart';
import '../screens/settings.dart';
import '../utils/functions.dart';

class IndexTopPane extends StatelessWidget {
  const IndexTopPane({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const DeviceInfoWidget(),
        Row(
          children: [
            AppIconButton(
                icon: Icons.refresh,
                onclick: () {
                  backTo(context, const IndexScreen());
                },
                label: "Refresh"),
            AppIconButton(
                icon: Icons.settings,
                onclick: () {
                  to(context, const SettingsScreen());
                },
                label: "Settings"),
            const SizedBox(
              width: 20,
            )
          ],
        )
      ]),
    );
  }
}
