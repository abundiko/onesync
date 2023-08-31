import 'package:flutter/material.dart';

class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static void printClassName() {
    debugPrint("current class == ${navigatorKey.currentContext} || ${navigatorKey.currentWidget.runtimeType}");
  }
}
