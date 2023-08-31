import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onesync/providers/index.dart';
import 'package:onesync/widgets/widgets.dart';
import 'package:provider/provider.dart';

import '../utils/functions.dart';

class ClipboardPane extends StatefulWidget {
  const ClipboardPane({super.key, required this.path});
  final String path;
  @override
  State<ClipboardPane> createState() => _ClipboardPaneState();
}

class _ClipboardPaneState extends State<ClipboardPane> {
  late Timer _timer;
  @override
  void initState() {
    if (mounted) {
      _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
        setState(() {});
      });
    }
    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<IndexProvider>(context);
    final pl = Provider.of<IndexProvider>(context, listen: false);
    return ListView(
      children: [
        if (p.currentShare['clipboard'] != null)
          ...(p.currentShare['clipboard'] as List)
              .map((e) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Theme.of(context)
                              .primaryColorDark
                              .withOpacity(0.1))),
                  child: ListTile(
                    onTap: () async {
                      try {
                        await Clipboard.setData(ClipboardData(text: e['data']));
                        pl.showSuccess("Copied!", 3);
                      } catch (e) {
                        pl.showError("Unable to copy!", 4);
                      }
                    },
                    contentPadding: EdgeInsets.zero,
                    subtitle: Heading1.smaller(
                      e['data'].toString(),
                      weight: FontWeight.w300,
                    ),
                    title: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Heading1.smaller(
                            "${e['data'].toString().length} chars",
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.8),
                            size: 13,
                          ),
                          Heading1.smaller(
                            formatDateTime(e['date']),
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.8),
                            size: 13,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              })
              .toList()
              .reversed
      ],
    );
  }
}
