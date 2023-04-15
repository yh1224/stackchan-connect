import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../infrastructure/stackchan.dart';

class SettingVoicePage extends StatefulWidget {
  const SettingVoicePage(this.stackchanIpAddress, {super.key});

  final String stackchanIpAddress;

  @override
  State<SettingVoicePage> createState() => _SettingVoicePageState();
}

class _SettingVoicePageState extends State<SettingVoicePage> {
  /// テスト中
  bool updating = false;

  /// ステータスメッセージ
  String statusMessage = "";

  /// 声色設定値
  String? voice;

  @override
  void initState() {
    super.initState();
    restoreSettings();
  }

  void restoreSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      voice = prefs.getString("voice");
    });
  }

  void test() async {
    setState(() {
      updating = true;
      statusMessage = "";
    });
    try {
      await Stackchan(widget.stackchanIpAddress).speech("こんにちは。私の声はいかがですか", voice: voice);
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

  void close() async {
    final prefs = await SharedPreferences.getInstance();
    if (voice == null) {
      await prefs.remove("voice");
    } else {
      await prefs.setString("voice", voice!);
    }
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("声色指定に対応していない場合、設定しても効きません。"),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            const Text("声色: "),
                            DropdownButton<String?>(
                              items: const [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text("未指定"),
                                ),
                                DropdownMenuItem(
                                  value: "0",
                                  child: Text("0"),
                                ),
                                DropdownMenuItem(
                                  value: "1",
                                  child: Text("1"),
                                ),
                                DropdownMenuItem(
                                  value: "2",
                                  child: Text("2"),
                                ),
                                DropdownMenuItem(
                                  value: "3",
                                  child: Text("3"),
                                ),
                                DropdownMenuItem(
                                  value: "4",
                                  child: Text("4"),
                                ),
                              ],
                              onChanged: (String? value) {
                                setState(() {
                                  voice = value;
                                });
                              },
                              value: voice,
                            )
                          ],
                        ),
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
                      onPressed: test,
                      child: Text(
                        "テスト",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: close,
                      child: Text(
                        "OK",
                        style: Theme.of(context).textTheme.bodyLarge,
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
