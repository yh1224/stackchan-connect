import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings/apikeys.dart';
import 'settings/face.dart';
import 'settings/ipaddress.dart';
import 'settings/role.dart';
import 'settings/stackchan.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String stackchanIpAddress = "";

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      stackchanIpAddress = prefs.getString("stackchanIpAddress") ?? "";
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

  void openStackchanSettings() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => StackchanSettingsPage(stackchanIpAddress)));
  }

  void openStackchanFaceSettings() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => StackchanFaceSettingsPage(stackchanIpAddress)));
  }

  void openStackchanRoleSettings() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => StackchanRoleSettingsPage(stackchanIpAddress)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ｽﾀｯｸﾁｬﾝ ｺﾝﾈｸﾄ"),
      ),
      body: GestureDetector(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Card(
                child: ListTile(
                  title: Text("IP アドレス設定", style: Theme.of(context).textTheme.titleLarge),
                  subtitle: Text(stackchanIpAddress),
                  onTap: openStackchanIpAddressSettings,
                ),
              ),
              Card(
                child: ListTile(
                  title: Text("API Key 設定", style: Theme.of(context).textTheme.titleLarge),
                  onTap: openStackchanApiKeysSettings,
                ),
              ),
              Card(
                child: ListTile(
                  title: Text("ロール設定", style: Theme.of(context).textTheme.titleLarge),
                  onTap: openStackchanRoleSettings,
                ),
              ),
              Card(
                child: ListTile(
                  title: Text("音量設定", style: Theme.of(context).textTheme.titleLarge),
                  onTap: openStackchanSettings,
                ),
              ),
              Card(
                child: ListTile(
                  title: Text("表情設定", style: Theme.of(context).textTheme.titleLarge),
                  onTap: openStackchanFaceSettings,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
