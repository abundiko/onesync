import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';

class DeviceData {
  String? ipAddress;
  HttpServer? server;
  String globalPath = '';
  String downloadDir = '';
  String deviceName = '';
  String deviceSystemName = '';
  String deviceOs = '';
  String password = const Uuid().v4();
  Map desktopMap = {};
  late BuildContext context;
}

final deviceData = DeviceData();
