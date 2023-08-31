import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';
import '../utils/functions.dart';
import '../widgets/widgets.dart';
import 'logs.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({
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
            "About",
            maxLines: 1,
          ),
        ),
        body: SizedBox(
          width: double.maxFinite,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            const SizedBox(height: 20),
            Image.asset('assets/images/logo_with_text.png',
                width: 350, fit: BoxFit.cover),
            GestureDetector(
              onLongPressMoveUpdate: (e) {
                to(context,const LogsScreen());
              },
              child: Heading1.smaller("version 0.4.1",
                  color: Theme.of(context).primaryColorDark.withOpacity(0.4)),
            ),
            const Spacer(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Heading1.smaller("developed by ",
                    color: Theme.of(context).primaryColorDark.withOpacity(0.4)),
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
            const SizedBox(height: 20),
          ]),
        ));
  }
}
