// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:onesync/utils/functions.dart';
import 'package:onesync/widgets/widgets.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import '../utils/host.dart';
import './home.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, this.isFirst = true});
  final bool isFirst;
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  late QRViewController _qrController;
  Barcode? result;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  void _onQRViewCreated(QRViewController controller) {
    _qrController = controller;
    controller.scannedDataStream.listen((scanData) async {
      _qrController.pauseCamera();
      result = scanData;
      showAppToast("connecting...", false);
      final List connectionDataList =
          utf8.decode(base64.decode(scanData.code.toString())).split("|||");
      if (connectionDataList.length != 3) {
        return _qrController.resumeCamera();
      }
      final Map<String, dynamic> connectionData = {
        "ipAddress": connectionDataList[0],
        "name": connectionDataList[1],
        "password": connectionDataList[2],
      };
      if (await Host.knock(
          connectionData["ipAddress"], connectionData["password"])) {
        try {
          if (widget.isFirst) {
            back(context);
            backTo(context, const HomeScreen());
          } else {
            back(context);
            back(context);
          }
        } catch (e) {
          true;
        }
      } else {
        await Future.delayed(const Duration(milliseconds: 1200));
        try {
          _qrController.resumeCamera();
        } catch (e) {
          true;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onclick: () => back(context)),
        title: const Heading1.smaller('Scan Qr COde'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: QRView(
              key: qrKey,
              formatsAllowed: const [BarcodeFormat.qrcode],
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _qrController.dispose();
    super.dispose();
  }
}
