import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'apikey.dart';
import 'ipaddress.dart';
import 'role.dart';
import 'stackchan.dart';
import 'voice.dart';

class SettingMenuPage extends ConsumerStatefulWidget {
  const SettingMenuPage({super.key});

  @override
  ConsumerState<SettingMenuPage> createState() => _SettingMenuPageState();
}

class _SettingMenuPageState extends ConsumerState<SettingMenuPage> {
  /// 初期化完了
  final _initializedProvider = StateProvider((ref) => false);

  /// IP アドレス
  final _stackchanIpAddressProvider = StateProvider((ref) => "");

  @override
  void initState() {
    super.initState();
    Future(() async {
      await _init();
    });
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    ref.read(_stackchanIpAddressProvider.notifier).state = prefs.getString("stackchanIpAddress") ?? "";
    ref.read(_initializedProvider.notifier).state = true;
  }

  @override
  Widget build(BuildContext context) {
    final initialized = ref.watch(_initializedProvider);
    final stackchanIpAddress = ref.watch(_stackchanIpAddressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("ｽﾀｯｸﾁｬﾝ ｺﾝﾈｸﾄ"),
      ),
      body: GestureDetector(
        child: Visibility(
          visible: initialized,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Card(
                        child: ListTile(
                          title: Text("IP アドレス設定", style: Theme.of(context).textTheme.titleLarge),
                          subtitle: Text(stackchanIpAddress),
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
                  visible: stackchanIpAddress.isNotEmpty,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Card(
                          child: ListTile(
                            title: Text("API Key 設定", style: Theme.of(context).textTheme.titleLarge),
                            onTap: () {
                              Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => SettingApiKeyPage(stackchanIpAddress)));
                            },
                          ),
                        ),
                        Card(
                          child: ListTile(
                            title: Text("ロール設定", style: Theme.of(context).textTheme.titleLarge),
                            onTap: () {
                              Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (context) => SettingRolePage(stackchanIpAddress)));
                            },
                          ),
                        ),
                        Card(
                          child: ListTile(
                            title: Text("音量設定", style: Theme.of(context).textTheme.titleLarge),
                            onTap: () {
                              Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => SettingStackchanPage(stackchanIpAddress)));
                            },
                          ),
                        ),
                        Card(
                          child: ListTile(
                            title: Text("声色設定", style: Theme.of(context).textTheme.titleLarge),
                            onTap: () {
                              Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (context) => SettingVoicePage(stackchanIpAddress)));
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
      ),
    );
  }
}
