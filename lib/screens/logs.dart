import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings.dart';
import '../utils/functions.dart';
import '../widgets/widgets.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          leading: AppIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onclick: () => back(context)),
          title: const Heading1.smaller(
            "Error Logs",
            maxLines: 1,
          ),
          actions: [
            AppIconButton(
                icon: Icons.delete,
                onclick: () =>
                    Provider.of<SettingsProvider>(context, listen: false)
                        .clearErrors())
          ],
        ),
        body: ListView(
          children: [
            ...Provider.of<SettingsProvider>(context, listen: false)
                .errors
                .map((e) => ListTile(
                      isThreeLine: true,
                      title: Heading1.smaller(e['title']),
                      subtitle: SizedBox(
                        width: double.maxFinite,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Heading1.smaller(
                              e['message'],
                              weight: FontWeight.w300,
                              size: 12,
                            ),
                            Heading1.smaller(e['clue'],
                                weight: FontWeight.w300,
                                size: 12,
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.8)),
                          ],
                        ),
                      ),
                    ))
                .toList()
                .reversed
          ],
        ));
  }
}
