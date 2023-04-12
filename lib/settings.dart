import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings/apikeys.dart';
import 'settings/ipaddress.dart';
import 'settings/role.dart';
import 'settings/stackchan.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String stackchanIpAddress = '';

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      stackchanIpAddress = prefs.getString('stackchanIpAddress') ?? '';
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

  void openStackchanRoleSettings() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => StackchanRoleSettingsPage(stackchanIpAddress)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ｽﾀｯｸﾁｬﾝ ｺﾝﾈｸﾄ'),
      ),
      body: Column(
        children: [
          ListTile(
            title: const Text("IP アドレス設定", style: TextStyle(fontSize: 20)),
            subtitle: Text(stackchanIpAddress),
            onTap: openStackchanIpAddressSettings,
          ),
          ListTile(
            title: const Text("API Key 設定", style: TextStyle(fontSize: 20)),
            onTap: openStackchanApiKeysSettings,
          ),
          ListTile(
            title: const Text("ボリューム設定", style: TextStyle(fontSize: 20)),
            onTap: openStackchanSettings,
          ),
          // ListTile(
          //   title: const Text("ロール設定", style: TextStyle(fontSize: 20)),
          //   onTap: openStackchanRoleSettings,
          // ),
        ],
      ),
    );
  }
}
