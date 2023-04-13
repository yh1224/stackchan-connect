import 'package:flutter/material.dart';

import '../control.dart';

class StackchanFaceSettingsPage extends StatefulWidget {
  const StackchanFaceSettingsPage(this.stackchanIpAddress, {super.key});

  final String stackchanIpAddress;

  @override
  State<StackchanFaceSettingsPage> createState() => _StackchanFaceSettingsPageState();
}

class _StackchanFaceSettingsPageState extends State<StackchanFaceSettingsPage> {
  bool isLoading = false;
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
      isLoading = true;
      errorMessage = "";
    });
    try {
      if (await Stackchan(stackchanIpAddress).hasFaceApi()) {
        setState(() {
          hasFaceApi = true;
        });
      } else {
        setState(() {
          errorMessage = "設定できません。";
        });
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void updateFace(int value) async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });
    try {
      await Stackchan(widget.stackchanIpAddress).face("$value");
      setState(() {
        errorMessage = '設定に成功しました。';
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
            child: Column(
              children: [
                Text(errorMessage),
                Visibility(
                  visible: isLoading,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: LinearProgressIndicator(),
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