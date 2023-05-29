import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackchan_connect/view/setting/menu.dart';

import '../../repository/stackchan.dart';
import 'chat.dart';
import 'face.dart';
import 'speech.dart';

class ControlTabsPage extends ConsumerStatefulWidget {
  const ControlTabsPage(this.stackchanConfigProvider, {super.key});

  final StateProvider<StackchanConfig> stackchanConfigProvider;

  @override
  ConsumerState<ControlTabsPage> createState() => _ControlPageState();
}

class _ControlPageState extends ConsumerState<ControlTabsPage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final stackchanConfig = ref.watch(widget.stackchanConfigProvider);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(stackchanConfig.name),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                icon: const Icon(Icons.message),
                text: AppLocalizations.of(context)!.talk,
                iconMargin: const EdgeInsets.all(4.0),
              ),
              Tab(
                icon: const Icon(Icons.volume_up),
                text: AppLocalizations.of(context)!.speech,
                iconMargin: const EdgeInsets.all(4.0),
              ),
              Tab(
                icon: const Icon(Icons.face),
                text: AppLocalizations.of(context)!.face,
                iconMargin: const EdgeInsets.all(4.0),
              ),
              Tab(
                icon: const Icon(Icons.settings),
                text: AppLocalizations.of(context)!.settings,
                iconMargin: const EdgeInsets.all(4.0),
              ),
            ],
            labelStyle: Theme.of(context).textTheme.labelSmall,
            padding: const EdgeInsets.all(0),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            ChatPage(stackchanConfig),
            SpeechPage(stackchanConfig),
            FacePage(stackchanConfig),
            SettingMenuPage(widget.stackchanConfigProvider),
          ],
        ),
      ),
    );
  }
}
