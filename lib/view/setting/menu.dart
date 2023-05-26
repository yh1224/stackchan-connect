import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repository/stackchan.dart';
import 'apikey.dart';
import 'role.dart';
import 'voice.dart';
import 'volume.dart';

class SettingMenuPage extends ConsumerStatefulWidget {
  const SettingMenuPage(this.stackchanConfigProvider, {super.key});

  final StateProvider<StackchanConfig> stackchanConfigProvider;

  @override
  ConsumerState<SettingMenuPage> createState() => _SettingMenuPageState();
}

class _SettingMenuPageState extends ConsumerState<SettingMenuPage> {
  final _stackchanRepository = StackchanRepository();

  @override
  Widget build(BuildContext context) {
    final stackchanConfig = ref.watch(widget.stackchanConfigProvider);

    ref.listen(widget.stackchanConfigProvider, (_, next) {
      _stackchanRepository.save(next);
    });

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Visibility(
              visible: stackchanConfig.ipAddress.isNotEmpty,
              child: Column(
                children: [
                  ListTile(
                    title: Text("API 設定", style: Theme.of(context).textTheme.titleLarge),
                    subtitle: const Text("外部 API を使用するための設定をします"),
                    tileColor: Colors.white,
                    leading: const Icon(Icons.key),
                    onTap: () {
                      Navigator.of(context)
                          .push(MaterialPageRoute(builder: (context) => SettingApiKeyPage(stackchanConfig)));
                    },
                  ),
                  ListTile(
                    title: Text("ChatGPT ロール設定", style: Theme.of(context).textTheme.titleLarge),
                    subtitle: const Text("ｽﾀｯｸﾁｬﾝ のキャラクターを変更します"),
                    tileColor: Colors.white,
                    leading: const Icon(Icons.person),
                    onTap: () {
                      Navigator.of(context)
                          .push(MaterialPageRoute(builder: (context) => SettingRolePage(stackchanConfig)));
                    },
                  ),
                  ListTile(
                    title: Text("音量設定", style: Theme.of(context).textTheme.titleLarge),
                    subtitle: const Text("読み上げの音量を調整します"),
                    tileColor: Colors.white,
                    leading: const Icon(Icons.volume_up),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => SettingStackchanPage(widget.stackchanConfigProvider)));
                    },
                  ),
                  ListTile(
                    title: Text("声色設定", style: Theme.of(context).textTheme.titleLarge),
                    subtitle: const Text("読み上げの声色を選択します"),
                    tileColor: Colors.white,
                    leading: const Icon(Icons.record_voice_over),
                    onTap: () {
                      Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => SettingVoicePage(widget.stackchanConfigProvider)));
                    },
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
