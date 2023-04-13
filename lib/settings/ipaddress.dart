import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../control.dart';
import 'smartconfig.dart';

class StackchanIpAddressSettingsPage extends StatefulWidget {
  const StackchanIpAddressSettingsPage({super.key});

  @override
  State<StackchanIpAddressSettingsPage> createState() => _StackchanIpAddressSettingsPageState();
}

class _StackchanIpAddressSettingsPageState extends State<StackchanIpAddressSettingsPage> {
  final stackchanIpAddressTextArea = TextEditingController();

  String errorMessage = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    stackchanIpAddressTextArea.addListener(onUpdate);
    restoreSettings();
  }

  @override
  void dispose() {
    stackchanIpAddressTextArea.dispose();
    super.dispose();
  }

  void restoreSettings() async {
    final prefs = await SharedPreferences.getInstance();
    stackchanIpAddressTextArea.text = prefs.getString('stackchanIpAddress') ?? '';
  }

  void onUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('stackchanIpAddress', stackchanIpAddressTextArea.text);
  }

  void test() async {
    final stackchanIpAddress = stackchanIpAddressTextArea.text;
    if (stackchanIpAddress.isNotEmpty) {
      try {
        setState(() {
          errorMessage = 'Connecting...';
          isLoading = true;
        });
        Stackchan(stackchanIpAddress).speech("接続できました");
        setState(() {
          errorMessage = '接続できました';
        });
      } catch (e) {
        setState(() {
          errorMessage = 'Error: ${e.toString()}';
        });
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  bool canSmartConfig() {
    return Platform.isAndroid;
  }

  void startSmartConfig() async {
    final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SmartConfigPage()));
    debugPrint("SmartConfig result: $result");
    if (result != null) {
      stackchanIpAddressTextArea.text = result;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ｽﾀｯｸﾁｬﾝ ｺﾝﾈｸﾄ'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "ｽﾀｯｸﾁｬﾝの IP アドレスを入力してください",
                      style: TextStyle(fontSize: 20),
                    ),
                    TextField(
                      controller: stackchanIpAddressTextArea,
                      style: const TextStyle(fontSize: 20),
                    ),
                    Visibility(
                      visible: canSmartConfig(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "SmartConfig に対応している場合は、以下から自動設定できます。",
                            style: TextStyle(fontSize: 20),
                          ),
                          ElevatedButton(
                            onPressed: startSmartConfig,
                            child: const Text(
                              'SmartConfig で設定する',
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  errorMessage,
                  style: const TextStyle(fontSize: 20),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ValueListenableBuilder(
                    valueListenable: stackchanIpAddressTextArea,
                    builder: (context, value, child) {
                      return ElevatedButton(
                        onPressed: stackchanIpAddressTextArea.text.isEmpty || isLoading ? null : test,
                        child: const Text(
                          '確認',
                          style: TextStyle(fontSize: 20),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
