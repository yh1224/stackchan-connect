import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'smart_config.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String stackchanIpAddress = '';

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      stackchanIpAddress = prefs.getString('stackchanIpAddress') ?? '';
    });
  }

  void openStackchanIpAddressSettings() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const StackchanIpAddressSettingsPage()));
    init();
  }

  void openStackchanApiKeysSettings() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => StackchanApiKeysSettingsPage(stackchanIpAddress)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ｽﾀｯｸﾁｬﾝ ｺﾝﾈｸﾄ'),
      ),
      body: Column(
        children: [
          ListTile(
            title: const Text("IP アドレス設定", style: TextStyle(fontSize: 20)),
            subtitle: Text(stackchanIpAddress),
            onTap: openStackchanIpAddressSettings,
          ),
          ListTile(
            title: const Text("API Key 設定", style: TextStyle(fontSize: 20)),
            onTap: openStackchanApiKeysSettings,
          ),
        ],
      ),
    );
  }
}

class StackchanIpAddressSettingsPage extends StatefulWidget {
  const StackchanIpAddressSettingsPage({super.key});

  @override
  State<StackchanIpAddressSettingsPage> createState() => _StackchanIpAddressSettingsPageState();
}

class _StackchanIpAddressSettingsPageState extends State<StackchanIpAddressSettingsPage> {
  final stackchanIpAddressTextArea = TextEditingController();

  String errorMessage = '';
  bool isLoading = false;
  String? apiKeySettingUrl;

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
          apiKeySettingUrl = null;
          isLoading = true;
        });

        // check existence of apikey setting page
        bool hasApiKeySetting = false;
        try {
          final res = await http.get(Uri.http(stackchanIpAddress, "/apikey"));
          hasApiKeySetting = res.statusCode == 200;
        } catch (e) {
          debugPrint(e.toString());
        }

        // try speech API
        final res = await http.post(Uri.http(stackchanIpAddress, "/speech"), body: {
          "say": "接続できました",
        });
        if (res.statusCode != 200) {
          setState(() {
            errorMessage = 'Error: ${res.statusCode}';
          });
        }

        setState(() {
          apiKeySettingUrl = hasApiKeySetting ? "http://$stackchanIpAddress/apikey" : null;
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
                    const Text("ｽﾀｯｸﾁｬﾝの IP アドレスを入力してください"),
                    TextField(
                      controller: stackchanIpAddressTextArea,
                      style: const TextStyle(fontSize: 20),
                    ),
                    ValueListenableBuilder(
                      valueListenable: stackchanIpAddressTextArea,
                      builder: (context, value, child) {
                        return ElevatedButton(
                          onPressed: stackchanIpAddressTextArea.text.isEmpty || isLoading ? null : test,
                          child: const Text(
                            '接続確認',
                            style: TextStyle(fontSize: 20),
                          ),
                        );
                      },
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
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              errorMessage,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class StackchanApiKeysSettingsPage extends StatefulWidget {
  const StackchanApiKeysSettingsPage(this.stackchanIpAddress, {super.key});

  final String stackchanIpAddress;

  @override
  State<StackchanApiKeysSettingsPage> createState() => _StackchanApiKeysSettingsPageState();
}

class _StackchanApiKeysSettingsPageState extends State<StackchanApiKeysSettingsPage> {
  final openaiApiKeyTextArea = TextEditingController();
  final voicetextApiKeyTextArea = TextEditingController();

  bool hasApiKeySetting = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    openaiApiKeyTextArea.addListener(onUpdate);
    voicetextApiKeyTextArea.addListener(onUpdate);
    restoreSettings();
    checkStackchan();
  }

  @override
  void dispose() {
    openaiApiKeyTextArea.dispose();
    voicetextApiKeyTextArea.dispose();
    super.dispose();
  }

  void restoreSettings() async {
    final prefs = await SharedPreferences.getInstance();
    openaiApiKeyTextArea.text = prefs.getString('openaiApiKey') ?? '';
    voicetextApiKeyTextArea.text = prefs.getString('voicetextApiKey') ?? '';
  }

  void onUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('openaiApiKey', openaiApiKeyTextArea.text);
    await prefs.setString('voicetextApiKey', voicetextApiKeyTextArea.text);
  }

  // check existence of apikey setting page
  void checkStackchan() async {
    final stackchanIpAddress = widget.stackchanIpAddress;
    if (stackchanIpAddress.isEmpty) {
      setState(() {
        errorMessage = "IP アドレスを設定してください。";
      });
      return;
    }

    setState(() {
      errorMessage = "確認中です...";
    });
    var ok = false;
    try {
      final res = await http.get(Uri.http(stackchanIpAddress, "/apikey"));
      ok = res.statusCode == 200;
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (ok) {
        setState(() {
          hasApiKeySetting = true;
          errorMessage = "";
        });
      } else {
        setState(() {
          errorMessage = "API Key を設定できません。";
        });
      }
    }
  }

  void updateApiKeys() async {
    final openaiApiKey = openaiApiKeyTextArea.text;
    final voicetextApiKey = voicetextApiKeyTextArea.text;
    // try speech API
    try {
      final res = await http.post(Uri.http(widget.stackchanIpAddress, "/apikey_set"), body: {
        "openai": openaiApiKey,
        "voicetext": voicetextApiKey,
      });
      if (res.statusCode != 200) {
        setState(() {
          errorMessage = 'Error: ${res.statusCode}';
        });
      }

      setState(() {
        errorMessage = '設定に成功しました。';
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ｽﾀｯｸﾁｬﾝ ｺﾝﾈｸﾄ'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: "OpenAI API Key",
                      ),
                      controller: openaiApiKeyTextArea,
                      style: const TextStyle(fontSize: 20),
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: "VOICETEXT API Key",
                      ),
                      controller: voicetextApiKeyTextArea,
                      style: const TextStyle(fontSize: 20),
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
                Text(errorMessage),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: hasApiKeySetting ? updateApiKeys : null,
                    child: const Text(
                      '設定',
                      style: TextStyle(fontSize: 20),
                    ),
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
