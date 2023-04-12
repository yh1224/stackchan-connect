import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class StackchanFaceSettingsPage extends StatefulWidget {
  const StackchanFaceSettingsPage(this.stackchanIpAddress, {super.key});

  final String stackchanIpAddress;

  @override
  State<StackchanFaceSettingsPage> createState() => _StackchanFaceSettingsPageState();
}

class _StackchanFaceSettingsPageState extends State<StackchanFaceSettingsPage> {
  bool hasFaceApi = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    checkStackchan();
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
      final res = await http.get(Uri.http(stackchanIpAddress, "/face"));
      ok = res.statusCode == 200;
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (ok) {
        setState(() {
          hasFaceApi = true;
          errorMessage = "";
        });
      } else {
        setState(() {
          errorMessage = "設定できません。";
        });
      }
    }
  }

  void updateFace(int value) async {
    // try speech API
    try {
      final res = await http.post(Uri.http(widget.stackchanIpAddress, "/face"), body: {
        "expression": "$value",
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
                  children: [
                    ListTile(
                      title: const Text("Neutral", style: TextStyle(fontSize: 20)),
                      onTap: () {
                        updateFace(0);
                      },
                    ),
                    ListTile(
                      title: const Text("Happy", style: TextStyle(fontSize: 20)),
                      onTap: () {
                        updateFace(1);
                      },
                    ),
                    ListTile(
                      title: const Text("Sleepy", style: TextStyle(fontSize: 20)),
                      onTap: () {
                        updateFace(2);
                      },
                    ),
                    ListTile(
                      title: const Text("Doubt", style: TextStyle(fontSize: 20)),
                      onTap: () {
                        updateFace(3);
                      },
                    ),
                    ListTile(
                      title: const Text("Sad", style: TextStyle(fontSize: 20)),
                      onTap: () {
                        updateFace(4);
                      },
                    ),
                    ListTile(
                      title: const Text("Angry", style: TextStyle(fontSize: 20)),
                      onTap: () {
                        updateFace(5);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            width: double.infinity,
            child: Text(errorMessage),
          ),
        ],
      ),
    );
  }
}
