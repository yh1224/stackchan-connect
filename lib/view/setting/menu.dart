import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repository/stackchan.dart';
import 'apikey.dart';
import 'config.dart';
import 'role.dart';
import 'stackchan.dart';
import 'voice.dart';

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
      body: GestureDetector(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Card(
                      child: ListTile(
                        title: Text("ｽﾀｯｸﾁｬﾝ 設定", style: Theme.of(context).textTheme.titleLarge),
                        subtitle: Text(stackchanConfig.ipAddress),
                        onTap: () async {
                          await Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => SettingIpConfigPage(widget.stackchanConfigProvider)));
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Visibility(
                visible: stackchanConfig.ipAddress.isNotEmpty,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Card(
                        child: ListTile(
                          title: Text("API Key 設定", style: Theme.of(context).textTheme.titleLarge),
                          onTap: () {
                            Navigator.of(context)
                                .push(MaterialPageRoute(builder: (context) => SettingApiKeyPage(stackchanConfig)));
                          },
                        ),
                      ),
                      Card(
                        child: ListTile(
                          title: Text("ロール設定", style: Theme.of(context).textTheme.titleLarge),
                          onTap: () {
                            Navigator.of(context)
                                .push(MaterialPageRoute(builder: (context) => SettingRolePage(stackchanConfig)));
                          },
                        ),
                      ),
                      Card(
                        child: ListTile(
                          title: Text("音量設定", style: Theme.of(context).textTheme.titleLarge),
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => SettingStackchanPage(widget.stackchanConfigProvider)));
                          },
                        ),
                      ),
                      Card(
                        child: ListTile(
                          title: Text("声色設定", style: Theme.of(context).textTheme.titleLarge),
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => SettingVoicePage(widget.stackchanConfigProvider)));
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
