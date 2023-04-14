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
  /// 設定更新中
  bool updating = false;

  /// ステータスメッセージ
  String statusMessage = "";

  /// IP アドレス入力
  final stackchanIpAddressTextArea = TextEditingController();

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
    stackchanIpAddressTextArea.text = prefs.getString("stackchanIpAddress") ?? "";
  }

  void onUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("stackchanIpAddress", stackchanIpAddressTextArea.text);
  }

  void test() async {
    final stackchanIpAddress = stackchanIpAddressTextArea.text;
    if (stackchanIpAddress.isEmpty) {
      return;
    }

    setState(() {
      updating = true;
      statusMessage = "";
    });
    try {
      await Stackchan(stackchanIpAddress).speech("接続できました");
      setState(() {
        statusMessage = "接続できました";
      });
    } catch (e) {
      setState(() {
        statusMessage = "Error: ${e.toString()}";
      });
    } finally {
      setState(() {
        updating = false;
      });
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
        title: const Text("ｽﾀｯｸﾁｬﾝ ｺﾝﾈｸﾄ"),
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "ｽﾀｯｸﾁｬﾝの IP アドレスを入力してください。",
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              controller: stackchanIpAddressTextArea,
                              decoration: const InputDecoration(
                                hintText: "IP アドレス",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Visibility(
                        visible: canSmartConfig(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "SmartConfig に対応している場合は、以下から自動設定することもできます。",
                            ),
                            ElevatedButton(
                              onPressed: startSmartConfig,
                              child: const Text(
                                "SmartConfig で設定する",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8.0),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Visibility(
                    visible: statusMessage.isNotEmpty,
                    child: Text(
                      statusMessage,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Visibility(
                    visible: updating,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: LinearProgressIndicator(),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ValueListenableBuilder(
                      valueListenable: stackchanIpAddressTextArea,
                      builder: (context, value, child) {
                        return ElevatedButton(
                          onPressed: stackchanIpAddressTextArea.text.isEmpty || updating ? null : test,
                          child: Text(
                            "確認",
                            style: Theme.of(context).textTheme.bodyLarge,
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
      ),
    );
  }
}
