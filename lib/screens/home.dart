import 'package:flutter/material.dart';
import 'package:onesync/providers/index.dart';
import 'package:provider/provider.dart';

import '../utils/global.dart';
import '../widgets/home_center_pane.dart';
import '../widgets/home_top_pane.dart';
import '../widgets/widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    deviceData.context = context;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: SafeArea(
        child: Scaffold(
          body: Column(
            children: [
              const HomeTopPane(),
              const HomeCenterPane(),
              if (Provider.of<IndexProvider>(context).success != null)
                MessageView(
                  text: Provider.of<IndexProvider>(context).success!,
                  color: const Color.fromARGB(255, 154, 255, 155),
                ),
              if (Provider.of<IndexProvider>(context).error != null)
                MessageView(
                  text: Provider.of<IndexProvider>(context).error!,
                  color: const Color.fromARGB(255, 255, 184, 179),
                ),
              if (Provider.of<IndexProvider>(context).warning != null)
                MessageView(
                  text: Provider.of<IndexProvider>(context).warning!,
                  color: const Color.fromARGB(255, 255, 213, 179),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.color,
    required this.text,
  });

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color,
      ),
      child: Heading1.smaller(
        text,
        color: Colors.black87,
      ),
    );
  }
}
