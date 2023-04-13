import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../control.dart';

class StackchanSettingsPage extends StatefulWidget {
  const StackchanSettingsPage(this.stackchanIpAddress, {super.key});

  final String stackchanIpAddress;

  @override
  State<StackchanSettingsPage> createState() => _StackchanSettingsPageState();
}

class _StackchanSettingsPageState extends State<StackchanSettingsPage> {
  int volume = 255;
  bool isLoading = false;
  bool hasSettingApi = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    restoreSettings();
    checkStackchan();
  }

  void restoreSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      volume = prefs.getInt('volume') ?? 255;
    });
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
      if (await Stackchan(stackchanIpAddress).hasSettingApi()) {
        setState(() {
          hasSettingApi = true;
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

  void updateVolume() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('volume', volume);

    setState(() {
      isLoading = true;
      errorMessage = "";
    });
    try {
      await Stackchan(widget.stackchanIpAddress).setting(volume: "$volume");
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
                    const Text(
                      "ボリューム",
                    ),
                    Text(
                      "$volume",
                    ),
                    Slider(
                      label: "ボリューム",
                      min: 0,
                      max: 255,
                      value: volume.toDouble(),
                      onChanged: (double value) {
                        setState(() {
                          volume = value.toInt();
                        });
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(errorMessage),
                Visibility(
                  visible: isLoading,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: LinearProgressIndicator(),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: hasSettingApi ? updateVolume : null,
                    child: const Text(
                      "設定",
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
