import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final stackchanIpAddressTextArea = TextEditingController();

  String errorMessage = '';
  bool isLoading = false;

  @override
  void initState() {
    restoreSettings();
    super.initState();
  }

  void saveSettings() async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.setString('stackchanIpAddress', stackchanIpAddressTextArea.text);
  }

  void restoreSettings() async {
    var prefs = await SharedPreferences.getInstance();
    setState(() {
      stackchanIpAddressTextArea.text = prefs.getString('stackchanIpAddress') ?? '';
    });
  }

  void test() async {
    var stackchanIpAddress = stackchanIpAddressTextArea.text;
    if (stackchanIpAddress.isNotEmpty) {
      try {
        setState(() {
          errorMessage = 'Connecting...';
          isLoading = true;
        });
        var res = await http.post(Uri.http(stackchanIpAddress, "/speech"), body: {
          "say": "接続できました",
        });
        if (res.statusCode != 200) {
          setState(() {
            errorMessage = 'Error: ${res.statusCode}';
          });
        }
        setState(() {
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("ｽﾀｯｸﾁｬﾝの IP アドレスを入力してください"),
            TextField(
              autofocus: true,
              controller: stackchanIpAddressTextArea,
              style: const TextStyle(fontSize: 20),
              onChanged: (String value) {
                saveSettings();
              },
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
          ],
        ),
      ),
    );
  }
}
