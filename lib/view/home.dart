import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repository/stackchan.dart';
import 'config.dart';
import 'control/tabs.dart';
import 'drawer.dart';

class AppHomePage extends ConsumerStatefulWidget {
  const AppHomePage({super.key});

  @override
  ConsumerState<AppHomePage> createState() => _AppHomePageState();
}

class _AppHomePageState extends ConsumerState<AppHomePage> with TickerProviderStateMixin {
  /// ｽﾀｯｸﾁｬﾝ 設定リポジトリ
  final _stackchanRepository = StackchanRepository();

  /// ｽﾀｯｸﾁｬﾝ 設定
  final _stackchanConfigProviderListProvider = StateProvider<List<StateProvider<StackchanConfig>>>((ref) => []);

  @override
  void initState() {
    super.initState();
    Future(() async {
      await _migrate();
      await _init();
    });
  }

  // Preference から移行
  Future<void> _migrate() async {
    final prefs = await SharedPreferences.getInstance();
    final stackchanIpAddress = prefs.getString("stackchanIpAddress") ?? "";
    if (stackchanIpAddress.isNotEmpty) {
      await _newStackchanConfig(ipAddress: stackchanIpAddress, config: {
        "voice": prefs.getString("voice"),
        "volume": prefs.getInt("volume"),
      });
      prefs.remove("stackchanIpAddress");
      prefs.remove("voice");
      prefs.remove("volume");
    }
  }

  Future<void> _init() async {
    final stackchanConfigs = await _stackchanRepository.getStackchanConfigs();
    ref.read(_stackchanConfigProviderListProvider.notifier).state =
        stackchanConfigs.map((c) => StateProvider<StackchanConfig>((ref) => c)).toList();
    if (stackchanConfigs.isEmpty) {
      await _newStackchanConfig();
    }
  }

  Future<void> _newStackchanConfig({String ipAddress = "", Map<String, Object?> config = const {}}) async {
    final stackchanConfig =
        await _stackchanRepository.save(StackchanConfig(name: "ｽﾀｯｸﾁｬﾝ", ipAddress: ipAddress, config: config));
    final stackchanConfigProviderList = ref.read(_stackchanConfigProviderListProvider);
    stackchanConfigProviderList.add(StateProvider((ref) => stackchanConfig));
    ref.read(_stackchanConfigProviderListProvider.notifier).state = List.from(stackchanConfigProviderList);
  }

  @override
  Widget build(BuildContext context) {
    final stackchanConfigList = ref.watch(_stackchanConfigProviderListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("ｽﾀｯｸﾁｬﾝ ｺﾝﾈｸﾄ"),
        actions: [
          PopupMenuButton(
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  child: const Text("追加"),
                  onTap: () {
                    _newStackchanConfig();
                  },
                )
              ];
            },
          )
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: stackchanConfigList
                      .map(
                        (stackchanConfigProvider) => Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              title: Text(
                                ref.watch(stackchanConfigProvider).name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              subtitle: Text(ref.watch(stackchanConfigProvider).ipAddress),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.settings, size: 32),
                                    padding: const EdgeInsets.all(12),
                                    onPressed: () async {
                                      await Navigator.of(context).push(MaterialPageRoute(
                                          builder: (context) => StackchanConfigPage(stackchanConfigProvider)));
                                      _init();
                                    },
                                  ),
                                ],
                              ),
                              leading: const Image(image: AssetImage('assets/images/stackchan-lightorange.png')),
                              onTap: () async {
                                if (ref.watch(stackchanConfigProvider).ipAddress.isEmpty) {
                                  await Navigator.of(context).push(MaterialPageRoute(
                                      builder: (context) => StackchanConfigPage(stackchanConfigProvider)));
                                  _init();
                                } else {
                                  await Navigator.of(context).push(MaterialPageRoute(
                                      builder: (context) => ControlTabsPage(stackchanConfigProvider)));
                                }
                              },
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
