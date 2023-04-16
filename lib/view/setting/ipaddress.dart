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
  bool _updating = false;

  /// ステータスメッセージ
  String _statusMessage = "";

  /// IP アドレス入力
  final _stackchanIpAddressTextArea = TextEditingController();

  @override
  void initState() {
    super.initState();
    _restoreSettings();
  }

  @override
  void dispose() {
    _stackchanIpAddressTextArea.dispose();
    super.dispose();
  }

  void _restoreSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _stackchanIpAddressTextArea.text = prefs.getString("stackchanIpAddress") ?? "";
  }

  void _test() async {
    final stackchanIpAddress = _stackchanIpAddressTextArea.text.trim();
    if (stackchanIpAddress.isEmpty) {
      return;
    }

    setState(() {
      _updating = true;
      _statusMessage = "";
    });
    try {
      await Stackchan(stackchanIpAddress).speech("接続できました");
      setState(() {
        _statusMessage = "接続できました";
      });
    } catch (e) {
      setState(() {
        _statusMessage = "Error: ${e.toString()}";
      });
    } finally {
      setState(() {
        _updating = false;
      });
    }
  }

  bool _canSmartConfig() {
    return Platform.isAndroid;
  }

  void _startSmartConfig() async {
    final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SmartConfigPage()));
    debugPrint("SmartConfig result: $result");
    if (result != null) {
      _stackchanIpAddressTextArea.text = result;
    }
  }

  void _close() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("stackchanIpAddress", _stackchanIpAddressTextArea.text.trim());
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
                              controller: _stackchanIpAddressTextArea,
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
                        visible: _canSmartConfig(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "SmartConfig に対応している場合は、以下から自動設定することもできます。",
                            ),
                            ElevatedButton(
                              onPressed: _startSmartConfig,
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
                    visible: _statusMessage.isNotEmpty,
                    child: Text(
                      _statusMessage,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Visibility(
                    visible: _updating,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: LinearProgressIndicator(),
                    ),
                  ),
                  ValueListenableBuilder(
                    valueListenable: _stackchanIpAddressTextArea,
                    builder: (context, value, child) {
                      return Visibility(
                        visible: _stackchanIpAddressTextArea.text.trim().isNotEmpty,
                        child: SizedBox(
                          width: double.infinity,
                          child: ValueListenableBuilder(
                            valueListenable: _stackchanIpAddressTextArea,
                            builder: (context, value, child) {
                              return ElevatedButton(
                                onPressed: _stackchanIpAddressTextArea.text.trim().isEmpty || _updating ? null : _test,
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
                      valueListenable: _stackchanIpAddressTextArea,
                      builder: (context, value, child) {
                        return ElevatedButton(
                          onPressed: _close,
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
