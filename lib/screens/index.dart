import 'package:flutter/material.dart';
import 'package:onesync/utils/global.dart';

import '../utils/navigation_service.dart';
import '../widgets/index_center_pane.dart';
import '../widgets/index_top_pane.dart';

class IndexScreen extends StatefulWidget {
  const IndexScreen({super.key});

  @override
  State<IndexScreen> createState() => _IndexScreenState();
}

class _IndexScreenState extends State<IndexScreen> {
  @override
  void initState() {
    super.initState();
    NavigationService.printClassName();
    deviceData.context = context;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: const PreferredSize(
          preferredSize: Size(double.maxFinite, 80),
          child: IndexTopPane(),
        ),
        body: Column(
          children: const [
            Expanded(child: IndexCenterPane()),
          ],
        ),
      ),
    );
  }
}
