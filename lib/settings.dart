import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/link.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final stackchanIpAddressTextArea = TextEditingController();

  String stackchanIpAddress = '';
  String errorMessage = '';
  bool isLoading = false;
  String? apiKeySettingUrl;

  @override
  void initState() {
    restoreSettings();
    super.initState();
  }

  @override
  void dispose() {
    stackchanIpAddressTextArea.dispose();
    super.dispose();
  }

  void setStackchanIpAddress(String value) async {
    setState(() {
      stackchanIpAddress = value;
    });
    var prefs = await SharedPreferences.getInstance();
    await prefs.setString('stackchanIpAddress', stackchanIpAddress);
  }

  void restoreSettings() async {
    var prefs = await SharedPreferences.getInstance();
    setState(() {
      stackchanIpAddress = prefs.getString('stackchanIpAddress') ?? '';
    });
    stackchanIpAddressTextArea.text = stackchanIpAddress;
  }

  void test() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ｽﾀｯｸﾁｬﾝ ｺﾝﾈｸﾄ'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("ｽﾀｯｸﾁｬﾝの IP アドレスを入力してください"),
              TextField(
                autofocus: true,
                controller: stackchanIpAddressTextArea,
                style: const TextStyle(fontSize: 20),
                onChanged: (String value) {
                  setStackchanIpAddress(value);
                },
              ),
              ElevatedButton(
                onPressed: stackchanIpAddress.isEmpty || isLoading ? null : test,
                child: const Text(
                  'Test',
                  style: TextStyle(fontSize: 20),
                ),
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
            ],
          ),
        ),
      ),
    );
  }
}
