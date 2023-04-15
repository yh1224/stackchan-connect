import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../infrastructure/stackchan.dart';

class SettingStackchanPage extends StatefulWidget {
  const SettingStackchanPage(this.stackchanIpAddress, {super.key});

  final String stackchanIpAddress;

  @override
  State<SettingStackchanPage> createState() => _SettingStackchanPageState();
}

class _SettingStackchanPageState extends State<SettingStackchanPage> {
  /// 初期化完了
  bool initialized = false;

  /// 設定更新中
  bool updating = false;

  /// ステータスメッセージ
  String statusMessage = "";

  /// 音量設定値
  int volume = 255;

  @override
  void initState() {
    super.initState();
    restoreSettings();
    checkStackchan();
  }

  void restoreSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      volume = prefs.getInt("volume") ?? 255;
    });
  }

  // check existence of apikey setting page
  void checkStackchan() async {
    final stackchanIpAddress = widget.stackchanIpAddress;
    if (stackchanIpAddress.isEmpty) {
      setState(() {
        statusMessage = "IP アドレスを設定してください。";
      });
      return;
    }

    setState(() {
      updating = true;
      statusMessage = "";
    });
    try {
      if (await Stackchan(stackchanIpAddress).hasSettingApi()) {
        setState(() {
          initialized = true;
        });
      } else {
        setState(() {
          statusMessage = "設定できません。";
        });
      }
    } finally {
      setState(() {
        updating = false;
      });
    }
  }

  void updateVolume() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("volume", volume);

    setState(() {
      updating = true;
      statusMessage = "";
    });
    try {
      await Stackchan(widget.stackchanIpAddress).setting(volume: "$volume");
      setState(() {
        statusMessage = "設定しました。";
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ｽﾀｯｸﾁｬﾝ ｺﾝﾈｸﾄ"),
      ),
      body: GestureDetector(
        child: Column(
          children: [
            Expanded(
              child: Visibility(
                visible: initialized,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("音量: "),
                          Text("$volume"),
                        ],
                      ),
                      Slider(
                        label: "音量",
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
                    child: ElevatedButton(
                      onPressed: initialized ? updateVolume : null,
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
      ),
    );
  }
}
