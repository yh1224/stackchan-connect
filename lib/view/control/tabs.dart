import 'package:flutter/material.dart';
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
    _init();
  }

  Future<void> _init() async {
    if (ref.read(widget.stackchanConfigProvider).ipAddress.isEmpty) {
      _tabController.animateTo(3);
    }
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
            tabs: const [
              Tab(icon: Icon(Icons.message), text: "会話", iconMargin: EdgeInsets.all(4.0)),
              Tab(icon: Icon(Icons.volume_up), text: "セリフ", iconMargin: EdgeInsets.all(4.0)),
              Tab(icon: Icon(Icons.face), text: "表情", iconMargin: EdgeInsets.all(4.0)),
              Tab(icon: Icon(Icons.settings), text: "設定", iconMargin: EdgeInsets.all(4.0)),
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
