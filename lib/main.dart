import 'dart:io';

import 'package:flutter/material.dart';
import 'package:onesync/providers/index.dart';
import 'package:onesync/providers/settings.dart';
import 'package:onesync/screens/index.dart';
import 'package:onesync/utils/clipboard.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:url_launcher/link.dart';
import 'package:onesync/utils/functions.dart';
import 'package:onesync/utils/global.dart';
import 'package:onesync/utils/navigation_service.dart';
import 'package:onesync/utils/theme.dart';
import 'package:onesync/widgets/widgets.dart';
import 'package:oktoast/oktoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:video_player_media_kit/init_video_player_media_kit/init_video_player_media_kit_ffi.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1000, 600),
      minimumSize: Size(900, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  initVideoPlayerMediaKitIfNeeded();
  await Hive.initFlutter();
  await Hive.openBox('com.abundiko.onesync');
  await requestPermssions();
  await initPlatform();
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => IndexProvider()),
    ChangeNotifierProvider(create: (_) => SettingsProvider()),
  ], child: const MyApp()));
}

// ignore: use_key_in_widget_constructors
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WindowListener {
  bool _isLoading = Platform.isWindows ? true : false;
  @override
  void initState() {
    if (Platform.isWindows) {
      Future.delayed(const Duration(seconds: 5), () {
        _isLoading = false;
        if (mounted) {
          setState(() {});
        }
      });
    }
    Provider.of<SettingsProvider>(context, listen: false).init();
    Provider.of<IndexProvider>(context, listen: false).handleStreams();
    ClipboardManager.init();
    super.initState();
    deviceData.context = context;
    windowManager.addListener(this);
    FlutterNativeSplash.remove();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OKToast(
      child: MaterialApp(
        navigatorKey: NavigationService.navigatorKey,
        title: 'OneSync',
        themeMode: ThemeMode.system,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: _isLoading
            ? Container(
                height: double.maxFinite,
                width: double.maxFinite,
                alignment: Alignment.center,
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/images/logo_with_text.png',
                          height: 200, fit: BoxFit.contain),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Heading1.smaller("developed by ",
                              color: Theme.of(context)
                                  .primaryColorDark
                                  .withOpacity(0.4)),
                          Link(
                              target: LinkTarget.blank,
                              uri: Uri.parse('https://github.com/abundiko'),
                              builder: (context, _) => GestureDetector(
                                    onTap: _,
                                    child: Heading1.smaller('Abundance',
                                        color: Theme.of(context).primaryColor),
                                  ))
                        ],
                      ),
                    ],
                  ),
                ))
            : const IndexScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  @override
  void onWindowClose() {
    if (deviceData.server != null) {
      deviceData.server!.close();
    }
  }
}

Future<void> requestPermssions() async {
  if (!await Permission.storage.isGranted) await Permission.storage.request();
  if (!await Permission.manageExternalStorage.isGranted) {
    await Permission.manageExternalStorage.request();
  }
  if (!await Permission.requestInstallPackages.isGranted) {
    await Permission.requestInstallPackages.request();
  }
}
