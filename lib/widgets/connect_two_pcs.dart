import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:onesync/providers/index.dart';
import 'package:onesync/utils/functions.dart';
import 'package:onesync/utils/global.dart';
import 'package:onesync/widgets/widgets.dart';
import 'package:provider/provider.dart';

import '../screens/home.dart';
import '../utils/host.dart';

class ConnectTwoPcs extends StatefulWidget {
  const ConnectTwoPcs({super.key});

  @override
  State<ConnectTwoPcs> createState() => _ConnectTwoPcsState();
}

class _ConnectTwoPcsState extends State<ConnectTwoPcs> {
  @override
  Widget build(BuildContext context) {
    String originalString = ipToInt(deviceData.ipAddress!).toString();
    String modifiedString =
        "${originalString.substring(0, originalString.length ~/ 2)} ${originalString.substring(originalString.length ~/ 2)}";
    return SizedBox(
      width: vw(context, 80, max: 800),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Heading1.smaller(
            "Enter the code below on the other Desktop...",
            size: 30,
            weight: FontWeight.w600,
          ),
          Heading1(modifiedString),
          const Heading1.smaller(
            "or...",
            size: 30,
            weight: FontWeight.w600,
          ),
          const SizedBox(
            height: 10,
          ),
          ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: AppButtonWithIcon(
                title: "Enter Code",
                onClick: () {
                  showAppBottomSheet(context, const CTPEnterCode());
                },
                icon: Icons.pin,
                color: Theme.of(context).primaryColor,
                textColor: Theme.of(context).scaffoldBackgroundColor,
              ))
        ],
      ),
    );
  }
}

class CTPEnterCode extends StatefulWidget {
  const CTPEnterCode({super.key});

  @override
  State<CTPEnterCode> createState() => _CTPEnterCodeState();
}

class _CTPEnterCodeState extends State<CTPEnterCode> {
  bool _knockIsLoading = false;
  bool _connectIsLoading = false;
  bool _isConnecting = false;
  String _deviceName = '';
  String _deviceIp = '';
  final TextEditingController _inputController = TextEditingController();

  TextStyle _buildTextStyle(double opacity) {
    return TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w500,
        letterSpacing: 15,
        color: Theme.of(context).primaryColorDark.withOpacity(opacity));
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: vw(context, 80, max: 800),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedOpacity(
            opacity: _knockIsLoading || _connectIsLoading ? 0.5 : 1,
            duration: const Duration(milliseconds: 400),
            child: !_isConnecting
                ? const Heading1("Enter Other Desktop Connection Code Below")
                : Wrap(
                    children: [
                      const Heading1("Enter Verification code for "),
                      Heading1(
                        _deviceName,
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
          ),
          Container(
            constraints: const BoxConstraints(maxWidth: 400),
            margin: const EdgeInsets.symmetric(vertical: 20),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).primaryColorDark,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              autofocus: true,
              controller: _inputController,
              onChanged: (e) => setState(() => true),
              onSubmitted: (e) {
                _isConnecting ? _tryConnect() : _tryCode();
              },
              decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "00000000",
                  hintStyle: _buildTextStyle(0.4)),
              style: _buildTextStyle(1),
            ),
          ),
          ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: _isConnecting
                  ? AppButtonWithIcon(
                      loading: _connectIsLoading,
                      disabled:
                          _connectIsLoading || _inputController.text.isEmpty,
                      title: "Connect",
                      onClick: _tryConnect,
                      icon: Icons.check_box_rounded,
                      color: Theme.of(context).primaryColor,
                      textColor: Theme.of(context).scaffoldBackgroundColor,
                    )
                  : AppButtonWithIcon(
                      loading: _knockIsLoading,
                      disabled:
                          _knockIsLoading || _inputController.text.isEmpty,
                      title: "Next",
                      onClick: _tryCode,
                      icon: Icons.send,
                      color: Theme.of(context).primaryColor,
                      textColor: Theme.of(context).scaffoldBackgroundColor,
                    ))
        ],
      ),
    );
  }

  void _tryConnect() async {
    if (int.tryParse(_inputController.text) == null) {
      showAppToast("Invalid code, remove all spaces and retry");
      return;
    }
    setState(() {
      _connectIsLoading = true;
    });
    final input = _inputController.text;
    final result = await Host.connectDesktop(input, _deviceIp);
    if (result == null || result == false) {
      showAppToast("An Error Occurred");
    } else if (result == true) {
      showAppToast("You are Already Connected");
    } else if (result == 1) {
      showAppToast("Connection Timed out");
    } else if (result is Map) {
      if (result['error'] != null) {
        showAppToast("incorrect code");
      } else {
        _deviceName = result["name"];
        _deviceIp = result["ipAddress"];
        showAppToast("connecting..", false);
        if (mounted) {
          final int newLength =
              Provider.of<IndexProvider>(context, listen: false)
                  .addToShareGroup(result['name'], result['ipAddress'],
                      result['allowDelete'], true);
          if (newLength == 1) {
            Navigator.pushAndRemoveUntil(
              context,
              CupertinoPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          } else {
            back(context);
            back(context);
            back(context);
          }
        }

        _inputController.clear();
      }
    }
    _connectIsLoading = false;
    setState(() => true);
  }

  void _tryCode() async {
    if (int.tryParse(_inputController.text) == null) {
      showAppToast("Invalid code, remove all spaces and retry");
      return;
    }
    setState(() {
      _knockIsLoading = true;
    });
    final input = _inputController.text;
    final result = await Host.knockDesktop(input);
    if (result == null || result == false) {
      showAppToast("An Error Occurred");
    } else if (result == true) {
      showAppToast("You are Already Connected");
    } else if (result == 1) {
      showAppToast("No Device Found, check code and retry");
    } else if (result is Map) {
      _isConnecting = true;
      _deviceName = result["name"];
      _deviceIp = result["ipAddress"];
      _inputController.clear();
    }
    _knockIsLoading = false;
    if (mounted) setState(() => true);
  }
}

class CTPController {}
