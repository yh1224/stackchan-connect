import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'apikey.dart';
import 'ipaddress.dart';
import 'role.dart';
import 'stackchan.dart';
import 'voice.dart';

class SettingMenuPage extends StatefulWidget {
  const SettingMenuPage({super.key});

  @override
  State<SettingMenuPage> createState() => _SettingMenuPageState();
}

class _SettingMenuPageState extends State<SettingMenuPage> {
  /// 初期化完了
  bool _initialized = false;

  /// IP アドレス
  String _stackchanIpAddress = "";

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _stackchanIpAddress = prefs.getString("stackchanIpAddress") ?? "";
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ｽﾀｯｸﾁｬﾝ ｺﾝﾈｸﾄ"),
      ),
      body: GestureDetector(
        child: Visibility(
          visible: _initialized,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Card(
                      child: ListTile(
                        title: Text("IP アドレス設定", style: Theme.of(context).textTheme.titleLarge),
                        subtitle: Text(_stackchanIpAddress),
                        onTap: () async {
                          await Navigator.of(context)
                              .push(MaterialPageRoute(builder: (context) => const SettingIpAddressPage()));
                          _init();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Visibility(
                visible: _stackchanIpAddress.isNotEmpty,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Card(
                        child: ListTile(
                          title: Text("API Key 設定", style: Theme.of(context).textTheme.titleLarge),
                          onTap: () {
                            Navigator.of(context)
                                .push(MaterialPageRoute(builder: (context) => SettingApiKeyPage(_stackchanIpAddress)));
                          },
                        ),
                      ),
                      Card(
                        child: ListTile(
                          title: Text("ロール設定", style: Theme.of(context).textTheme.titleLarge),
                          onTap: () {
                            Navigator.of(context)
                                .push(MaterialPageRoute(builder: (context) => SettingRolePage(_stackchanIpAddress)));
                          },
                        ),
                      ),
                      Card(
                        child: ListTile(
                          title: Text("音量設定", style: Theme.of(context).textTheme.titleLarge),
                          onTap: () {
                            Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => SettingStackchanPage(_stackchanIpAddress)));
                          },
                        ),
                      ),
                      Card(
                        child: ListTile(
                          title: Text("声色設定", style: Theme.of(context).textTheme.titleLarge),
                          onTap: () {
                            Navigator.of(context)
                                .push(MaterialPageRoute(builder: (context) => SettingVoicePage(_stackchanIpAddress)));
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
