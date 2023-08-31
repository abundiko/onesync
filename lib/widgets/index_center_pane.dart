import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:onesync/utils/functions.dart';
import 'package:onesync/widgets/widgets.dart';
import 'package:provider/provider.dart';

import '../providers/index.dart';
import '../screens/scan.dart';
import '../utils/global.dart';
import '../utils/host.dart';
import 'connect_two_pcs.dart';

class IndexCenterPane extends StatefulWidget {
  const IndexCenterPane({
    super.key,
  });

  @override
  State<IndexCenterPane> createState() => _IndexCenterPaneState();
}

class _IndexCenterPaneState extends State<IndexCenterPane> {
  String _connectionString = '';
  late Timer _timer;

  void _prepare() async {
    try {
      final ip = await getMyIp();
      if (ip == null) throw Error();
      deviceData.ipAddress = ip;
      Host.hostFileSystem(context);
      Provider.of<IndexProvider>(context, listen: false).setIsWifi(true);
      _connectionString =
          "${deviceData.ipAddress}|||${deviceData.deviceName}|||${deviceData.password}";
      setState(() {});
    } on Error {
      if (mounted) {
        setState(() {});
      } else {
        return;
      }
      await Future.delayed(const Duration(seconds: 4));
      _prepare();
    }
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
        const Duration(
          seconds: 3,
        ), (t) async {
      final ip = await getMyIp();
      if (ip != null && mounted) {
        deviceData.ipAddress = ip;
        _connectionString =
            "${deviceData.ipAddress}|||${deviceData.deviceName}|||${deviceData.password}";
      }
      if (mounted) setState(() {});
    });
    _prepare();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      color: Theme.of(context).primaryColorDark.withOpacity(0.04),
      child: SizedBox(
        width: vw(context, 90, max: 1200),
        child: Flex(
            direction: !isSmall(context) ? Axis.horizontal : Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: isSmall(context) ? 5 : 4,
                child: Container(
                  padding:
                      isSmall(context) ? const EdgeInsets.only(top: 20) : null,
                  alignment: isSmall(context)
                      ? Alignment.center
                      : Alignment.centerRight,
                  child: Container(
                      height: 280,
                      width: 280,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 221, 221, 221),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromARGB(108, 0, 0, 0),
                              blurRadius: 30,
                            )
                          ],
                          borderRadius: BorderRadius.circular(10)),
                      child: Provider.of<IndexProvider>(context, listen: false)
                              .isWifi
                          ? QRCodeWidget(
                              data:
                                  base64.encode(utf8.encode(_connectionString)),
                              size: 200,
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Heading1.smaller(
                                  'no wifi connection...',
                                  color: Color.fromARGB(255, 146, 36, 36),
                                ),
                                AppIconButton(
                                  icon: Icons.refresh,
                                  color: Colors.black,
                                  onclick: () async {
                                    _prepare();
                                  },
                                )
                              ],
                            )),
                ),
              ),
              SizedBox(
                width: vw(context, 100) < 700 ? 20 : 50,
                height: vw(context, 100) < 700 ? 20 : 50,
              ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: isSmall(context) ? 20 : 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: isSmall(context)
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.start,
                    children: [
                      Image.asset("assets/images/logo_text.png",
                          width: isSmall(context) ? 250 : 350,
                          fit: BoxFit.cover),
                      const SizedBox(
                        height: 10,
                      ),
                      const Heading1.smaller(
                          'Connect your two devices to the same wifi network. Scan the QR code with an android device to connect'),
                      const SizedBox(
                        height: 20,
                      ),
                      if (Platform.isWindows)
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 280),
                          child: AppButtonWithIcon(
                              title: 'Connect two PCs',
                              color: Theme.of(context).primaryColor,
                              textColor:
                                  Theme.of(context).scaffoldBackgroundColor,
                              onClick: () {
                                showAppBottomSheet(
                                    context, const ConnectTwoPcs());
                              },
                              icon: Icons.laptop_mac_rounded),
                        ),
                      if (Platform.isAndroid || Platform.isIOS)
                        AppButtonWithIcon(
                            title: 'Scan QR Code',
                            color: Theme.of(context).primaryColor,
                            onClick: () {
                              to(context, const ScanScreen());
                            },
                            textColor:
                                Theme.of(context).scaffoldBackgroundColor,
                            icon: Icons.qr_code),
                    ],
                  ),
                ),
              )
            ]),
      ),
    );
  }
}
