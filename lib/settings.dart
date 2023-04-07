import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/link.dart';

import 'smart_config.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final stackchanIpAddressTextArea = TextEditingController();

  String errorMessage = '';
  bool isLoading = false;
  String? apiKeySettingUrl;

  @override
  void initState() {
    restoreSettings();
    stackchanIpAddressTextArea.addListener(onUpdate);
    super.initState();
  }

  @override
  void dispose() {
    stackchanIpAddressTextArea.dispose();
    super.dispose();
  }

  void restoreSettings() async {
    var prefs = await SharedPreferences.getInstance();
    stackchanIpAddressTextArea.text = prefs.getString('stackchanIpAddress') ?? '';
  }

  void onUpdate() async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.setString('stackchanIpAddress', stackchanIpAddressTextArea.text);
  }

  void test() async {
    final stackchanIpAddress = stackchanIpAddressTextArea.text;
    if (stackchanIpAddress.isNotEmpty) {
      try {
        setState(() {
          errorMessage = 'Connecting...';
          apiKeySettingUrl = null;
          isLoading = true;
        });

        // check existence of apikey setting page
        bool hasApiKeySetting = false;
        try {
          var res = await http.get(Uri.http(stackchanIpAddress, "/apikey"));
          hasApiKeySetting = res.statusCode == 200;
        } catch (e) {
          debugPrint(e.toString());
        }

        // try speech API
        var res = await http.post(Uri.http(stackchanIpAddress, "/speech"), body: {
          "say": "接続できました",
        });
        if (res.statusCode != 200) {
          setState(() {
            errorMessage = 'Error: ${res.statusCode}';
          });
        }

        setState(() {
          apiKeySettingUrl = hasApiKeySetting ? "http://$stackchanIpAddress/apikey" : null;
          errorMessage = 'OK';
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("ｽﾀｯｸﾁｬﾝの IP アドレスを入力してください"),
              TextField(
                autofocus: true,
                controller: stackchanIpAddressTextArea,
                style: const TextStyle(fontSize: 20),
              ),
              ValueListenableBuilder(
                valueListenable: stackchanIpAddressTextArea,
                builder: (context, value, child) {
                  return ElevatedButton(
                    onPressed: stackchanIpAddressTextArea.text.isEmpty || isLoading ? null : test,
                    child: const Text(
                      'Test',
                      style: TextStyle(fontSize: 20),
                    ),
                  );
                },
              ),
              Text(errorMessage),
              Visibility(
                visible: apiKeySettingUrl != null,
                child: Link(
                  uri: apiKeySettingUrl != null ? Uri.parse(apiKeySettingUrl!) : null,
                  builder: (BuildContext context, FollowLink? openLink) {
                    return TextButton(
                      onPressed: openLink,
                      child: const Text("API Key 設定"),
                    );
                  },
                ),
              ),
              Visibility(
                visible: canSmartConfig(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("M5Burner 版の AI ｽﾀｯｸﾁｬﾝ など SmartConfig に対応している場合は、以下から自動設定できます。"),
                    ElevatedButton(
                      onPressed: startSmartConfig,
                      child: const Text(
                        'SmartConfig で設定する',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
