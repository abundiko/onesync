import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static ThemeData light = ThemeData.light().copyWith(
      primaryColor: const Color.fromARGB(255, 0, 30, 182),
      scaffoldBackgroundColor: const Color.fromARGB(255, 236, 236, 236),
      primaryColorDark: Colors.black,
      canvasColor: const Color.fromARGB(255, 255, 46, 31), //used for danger
      cardColor: const Color.fromARGB(255, 37, 149, 41), //used for success
      appBarTheme: AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: const Color.fromARGB(255, 236, 236, 236),
        systemNavigationBarIconBrightness: Brightness.dark,
        statusBarColor: const Color.fromARGB(255, 236, 236, 236),
      )));
  static ThemeData dark = ThemeData.dark().copyWith(
      primaryColor: const Color.fromARGB(255, 66, 183, 255),
      scaffoldBackgroundColor: Colors.black,
      primaryColorDark: const Color.fromARGB(255, 236, 236, 236),
      canvasColor: const Color.fromARGB(255, 255, 104, 94), //used for danger
      cardColor: const Color.fromARGB(255, 122, 254, 127), //used for success
      appBarTheme: AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
        statusBarColor: Colors.black,
      )));
}
