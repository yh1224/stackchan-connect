import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../infrastructure/stackchan.dart';
import 'smartconfig.dart';

class SettingIpAddressPage extends StatefulWidget {
  const SettingIpAddressPage({super.key});

  @override
  State<SettingIpAddressPage> createState() => _SettingIpAddressPageState();
}

class _SettingIpAddressPageState extends State<SettingIpAddressPage> {
  /// 設定更新中
  bool updating = false;

  /// ステータスメッセージ
  String statusMessage = "";

  /// IP アドレス入力
  final stackchanIpAddressTextArea = TextEditingController();

  @override
  void initState() {
    super.initState();
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

  void close() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("stackchanIpAddress", stackchanIpAddressTextArea.text);
    if (context.mounted) {
      Navigator.of(context).pop();
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
                  ValueListenableBuilder(
                    valueListenable: stackchanIpAddressTextArea,
                    builder: (context, value, child) {
                      return Visibility(
                        visible: stackchanIpAddressTextArea.text.isNotEmpty,
                        child: SizedBox(
                          width: double.infinity,
                          child: ValueListenableBuilder(
                            valueListenable: stackchanIpAddressTextArea,
                            builder: (context, value, child) {
                              return ElevatedButton(
                                onPressed: stackchanIpAddressTextArea.text.isEmpty || updating ? null : test,
                                child: Text(
                                  "接続確認",
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ValueListenableBuilder(
                      valueListenable: stackchanIpAddressTextArea,
                      builder: (context, value, child) {
                        return ElevatedButton(
                          onPressed: close,
                          child: Text(
                            "OK",
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
