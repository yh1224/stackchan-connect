import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repository/stackchan.dart';
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

  /// タップ位置
  Offset? _tapPosition;

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
    if (stackchanConfigs.isNotEmpty) {
      ref.read(_stackchanConfigProviderListProvider.notifier).state =
          stackchanConfigs.map((c) => StateProvider<StackchanConfig>((ref) => c)).toList();
    } else {
      await _newStackchanConfig();
    }
  }

  Future<void> _newStackchanConfig({String ipAddress = "", Map<String, Object?> config = const {}}) async {
    final stackchanConfig = await _stackchanRepository
        .save(StackchanConfig(name: "ｽﾀｯｸﾁｬﾝ", ipAddress: ipAddress, config: config));
    final stackchanConfigProviderList = ref.read(_stackchanConfigProviderListProvider);
    stackchanConfigProviderList.add(StateProvider((ref) => stackchanConfig));
    ref.read(_stackchanConfigProviderListProvider.notifier).state = List.from(stackchanConfigProviderList);
  }

  Future<void> _removeStackchanConfig(StateProvider<StackchanConfig> stackchanConfigProvider) async {
    final stackchanConfigProviderList = ref.read(_stackchanConfigProviderListProvider);
    stackchanConfigProviderList.remove(stackchanConfigProvider);
    _stackchanRepository.remove(ref.read(stackchanConfigProvider));
    ref.read(_stackchanConfigProviderListProvider.notifier).state = List.from(stackchanConfigProviderList);
  }

  void _getTapPosition(TapDownDetails tapPosition) {
    final RenderBox referenceBox = context.findRenderObject() as RenderBox;
    _tapPosition = referenceBox.globalToLocal(tapPosition.globalPosition);
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
      body: GestureDetector(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: stackchanConfigList
                        .map(
                          (stackchanConfigProvider) => GestureDetector(
                            onTapDown: _getTapPosition,
                            child: Card(
                              child: ListTile(
                                title: Text(
                                  ref.watch(stackchanConfigProvider).name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                subtitle: Text(ref.watch(stackchanConfigProvider).ipAddress),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                leading: const Icon(Icons.sentiment_neutral, size: 48),
                                onTap: () async {
                                  await Navigator.of(context).push(MaterialPageRoute(
                                      builder: (context) => ControlTabsPage(stackchanConfigProvider)));
                                  _init();
                                },
                                onLongPress: () async {
                                  HapticFeedback.mediumImpact();
                                  if (_tapPosition == null) return;
                                  final result = await showMenu(
                                    context: context,
                                    position: RelativeRect.fromLTRB(_tapPosition!.dx, _tapPosition!.dy, 0, 0),
                                    items: [
                                      const PopupMenuItem(
                                        value: "remove",
                                        child: Text("削除"),
                                      ),
                                    ],
                                  );
                                  if (result == "remove") {
                                    _removeStackchanConfig(stackchanConfigProvider);
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
      ),
    );
  }
}
