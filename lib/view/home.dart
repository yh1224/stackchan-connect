import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/link.dart';

import 'control/chat.dart';
import 'control/face.dart';
import 'control/speech.dart';
import 'setting/menu.dart';

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key});

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  /// 初期化完了
  final _initializedProvider = StateProvider((ref) => false);

  /// ｽﾀｯｸﾁｬﾝ IP アドレス
  final _stackchanIpAddressProvider = StateProvider((ref) => "");

  @override
  void initState() {
    super.initState();
    _init();
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
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
              child: Text(
                "ｽﾀｯｸﾁｬﾝ ｺﾝﾈｸﾄ",
                style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
              ),
            ),
            Link(
              uri: Uri.parse("https://notes.yh1224.com/stackchan-connect/"),
              target: LinkTarget.blank,
              builder: (BuildContext ctx, FollowLink? openLink) {
                return ListTile(
                  title: const Text("アプリについて／使い方"),
                  onTap: openLink,
                );
              },
            ),
            Link(
              uri: Uri.parse("https://notes.yh1224.com/privacy/"),
              target: LinkTarget.blank,
              builder: (BuildContext ctx, FollowLink? openLink) {
                return ListTile(
                  title: const Text("プライバシーポリシー"),
                  onTap: openLink,
                );
              },
            ),
          ],
        ),
      ),
      body: GestureDetector(
        child: Visibility(
          visible: initialized,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Visibility(
                    visible: stackchanIpAddress.isNotEmpty,
                    child: Column(
                      children: [
                        Card(
                          child: ListTile(
                            title: Text("おしゃべり", style: Theme.of(context).textTheme.titleLarge),
                            subtitle: Text("ｽﾀｯｸﾁｬﾝ とお話します。", style: Theme.of(context).textTheme.titleMedium),
                            leading: const Icon(Icons.message, size: 48),
                            onTap: () {
                              Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (context) => ChatPage(stackchanIpAddress)));
                            },
                          ),
                        ),
                        Card(
                          child: ListTile(
                            title: Text("しゃべって", style: Theme.of(context).textTheme.titleLarge),
                            subtitle: Text("ｽﾀｯｸﾁｬﾝ にしゃべってもらいます。", style: Theme.of(context).textTheme.titleMedium),
                            leading: const Icon(Icons.volume_up, size: 48),
                            onTap: () {
                              Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (context) => SpeechPage(stackchanIpAddress)));
                            },
                          ),
                        ),
                        Card(
                          child: ListTile(
                            title: Text("表情変更", style: Theme.of(context).textTheme.titleLarge),
                            subtitle: Text("ｽﾀｯｸﾁｬﾝ の表情を変えます。", style: Theme.of(context).textTheme.titleMedium),
                            leading: const Icon(Icons.face, size: 48),
                            onTap: () {
                              Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (context) => FacePage(stackchanIpAddress)));
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Card(
                    child: ListTile(
                      title: Text("設定", style: Theme.of(context).textTheme.titleLarge),
                      subtitle: Text("ｽﾀｯｸﾁｬﾝ を接続・設定します。", style: Theme.of(context).textTheme.titleMedium),
                      leading: const Icon(Icons.settings, size: 48),
                      onTap: () async {
                        await Navigator.of(context)
                            .push(MaterialPageRoute(builder: (context) => const SettingMenuPage()));
                        _init();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
