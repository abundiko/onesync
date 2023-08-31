import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:onesync/providers/settings.dart';
import 'package:provider/provider.dart';

import '../utils/functions.dart';
import '../utils/global.dart';
import '../widgets/widgets.dart';
import 'about.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _inputController = TextEditingController();
  TextStyle _buildTextStyle(double opacity) {
    return TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      color: Theme.of(context).primaryColorDark.withOpacity(opacity),
    );
  }

  @override
  void initState() {
    _inputController.text = deviceData.deviceName;
    if (mounted) setState(() => true);
    super.initState;
  }

  @override
  Widget build(BuildContext context) {
    final spl = Provider.of<SettingsProvider>(context, listen: false);
    final sp = Provider.of<SettingsProvider>(context);
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          leading: AppIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onclick: () => back(context)),
          title: const Heading1.smaller(
            "Settings",
            maxLines: 1,
          ),
        ),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColorDark.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Heading1.smaller("Device Name"),
                      SizedBox(
                        child: Row(
                          children: [
                            const Heading1.smaller("Use default",
                                weight: FontWeight.w300),
                            Checkbox(
                              value: sp.useDefaultDeviceName,
                              onChanged: (e) {
                                spl.setUseDefaultDeviceName(e ?? false);
                                if (e ?? false) {
                                  deviceData.deviceName =
                                      deviceData.deviceSystemName;
                                  _inputController.text =
                                      deviceData.deviceSystemName;
                                  spl.setDeviceName(
                                      deviceData.deviceSystemName);
                                }
                              },
                              activeColor: Theme.of(context).primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: double.maxFinite,
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: EdgeInsets.symmetric(
                        horizontal: isSmall(context) ? 10 : 20),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context)
                            .primaryColorDark
                            .withOpacity(0.08),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      enabled: !sp.useDefaultDeviceName,
                      controller: _inputController,
                      onChanged: (e) => setState(() => true),
                      onSubmitted: (e) {
                        if (e.isEmpty) {
                          showAppToast("Invalid Username");
                        } else if (e.length < 3 || e.length > 12) {
                          showAppToast(
                              "Username must be within 3 to 12 characters");
                        } else {
                          spl.setDeviceName(e);
                          _inputController.text = e;
                          setState(() => true);
                          showAppToast("Username changed!", false);
                        }
                      },
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "enter username here",
                          hintStyle: _buildTextStyle(0.4)),
                      style: _buildTextStyle(1),
                    ),
                  )
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColorDark.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Heading1.smaller("Permissions"),
                  AppListTile(
                    value: sp.allowDeletion,
                    title: 'Allow Deletion of files',
                    icon: Icons.admin_panel_settings,
                    subTitle:
                        "if enabled, devices connected to this device can delete files",
                    onChange: (b) {
                      spl.setAllowDeletion(b);
                    },
                  ),
                  if (Platform.isWindows)
                    AppListTile(
                      value: sp.allowRootAccess,
                      title: 'Allow Root Storage Access',
                      icon: Icons.folder_off_rounded,
                      subTitle:
                          "if enabled, devices will access this device's file system from the root: ${Platform.isAndroid ? 'storage/emulated/' : Platform.isWindows ? 'drive C:/' : '/'} ",
                      onChange: (b) {
                        spl.setAllowRootAccess(b);
                      },
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColorDark.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Heading1.smaller("Hidden Folders"),
                      AppIconButton(
                        icon: Icons.add,
                        label: "add new",
                        onclick: () async {
                          final folder = await _selectFolderFile();
                          if (folder != null) {
                            spl.addHiddenFolder(folder);
                          }
                        },
                        color: Theme.of(context).primaryColor,
                      )
                    ],
                  ),
                  ...spl.hiddenFolders.map((e) {
                    return ListTile(
                        title: Heading1.smaller(e),
                        trailing: AppIconButton(
                          icon: Icons.remove,
                          label: "remove",
                          color: Theme.of(context).canvasColor,
                          onclick: () => spl.removeHiddenFolder(e),
                        ));
                  }).toList(),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColorDark.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(0),
                title: const Heading1.smaller('About'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => to(
                  context,
                  const AboutScreen(),
                ),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ));
  }

  Future<String?> _selectFolderFile() async {
    final res = await FilePicker.platform.pickFiles(
        dialogTitle: "Select a file from the folder you want to hide");
    if (res != null) {
      final totalString = res.files[0].path.toString().replaceAll('\\', '/');
      final String last = totalString.split('/').last;
      final String folder =
          totalString.substring(0, totalString.indexOf("/$last"));
      if (folder != deviceData.globalPath) {
        return folder;
      } else {
        showAppToast('stop playing 🙄');
      }
    }
    return null;
  }
}

class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.title,
    required this.subTitle,
    required this.icon,
    required this.value,
    required this.onChange,
  });
  final String title, subTitle;
  final IconData icon;
  final Function(bool) onChange;
  final bool value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.all(0),
      horizontalTitleGap: 0,
      leading: Icon(icon),
      title: Heading1.smaller(title),
      subtitle: Heading1.smaller(
        subTitle,
        size: 15,
        weight: FontWeight.w300,
      ),
      trailing: CupertinoSwitch(
        value: value,
        onChanged: (e) {
          onChange(e);
        },
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }
}
