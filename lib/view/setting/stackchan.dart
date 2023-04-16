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
  bool _initialized = false;

  /// 設定更新中
  bool _updating = false;

  /// ステータスメッセージ
  String _statusMessage = "";

  /// 音量設定値
  int _volume = 255;

  @override
  void initState() {
    super.initState();
    _restoreSettings();
    _checkStackchan();
  }

  void _restoreSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _volume = prefs.getInt("volume") ?? 255;
    });
  }

  // check existence of apikey setting page
  void _checkStackchan() async {
    setState(() {
      _updating = true;
      _statusMessage = "";
    });
    try {
      if (await Stackchan(widget.stackchanIpAddress).hasSettingApi()) {
        setState(() {
          _initialized = true;
        });
      } else {
        setState(() {
          _statusMessage = "設定できません。";
        });
      }
    } finally {
      setState(() {
        _updating = false;
      });
    }
  }

  void _updateVolume() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("volume", _volume);
    final voice = prefs.getString("voice");

    setState(() {
      _updating = true;
      _statusMessage = "";
    });
    try {
      final stackchan = Stackchan(widget.stackchanIpAddress);
      await stackchan.setting(volume: "$_volume");
      await stackchan.speech("音量を$_volumeに設定しました。", voice: voice);
      setState(() {
        _statusMessage = "設定しました。";
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
                visible: _initialized,
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("音量: "),
                            Text("$_volume"),
                          ],
                        ),
                        Slider(
                          label: "音量",
                          min: 0,
                          max: 255,
                          value: _volume.toDouble(),
                          onChanged: (double value) {
                            setState(() {
                              _volume = value.toInt();
                            });
                          },
                        ),
                      ],
                    ),
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _initialized ? _updateVolume : null,
                      child: Text(
                        "設定",
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
