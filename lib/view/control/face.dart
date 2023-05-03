import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/stackchan.dart';
import '../../repository/stackchan.dart';

class FacePage extends ConsumerStatefulWidget {
  const FacePage(this.stackchanConfig, {super.key});

  final StackchanConfig stackchanConfig;

  @override
  ConsumerState<FacePage> createState() => _FacePageState();
}

class _FacePageState extends ConsumerState<FacePage> {
  /// 初期化完了
  final _initializedProvider = StateProvider((ref) => false);

  /// 設定更新中
  final _updatingProvider = StateProvider((ref) => false);

  /// ステータスメッセージ
  final _statusMessageProvider = StateProvider((ref) => "");

  @override
  void initState() {
    super.initState();
    Future(() async {
      await _checkStackchan();
    });
  }

  // check existence of apikey setting page
  Future<void> _checkStackchan() async {
    ref.read(_updatingProvider.notifier).state = true;
    ref.read(_statusMessageProvider.notifier).state = "";
    try {
      if (await Stackchan(widget.stackchanConfig.ipAddress).hasFaceApi()) {
        ref.read(_initializedProvider.notifier).state = true;
      } else {
        ref.read(_statusMessageProvider.notifier).state = "設定できません。";
      }
    } finally {
      ref.read(_updatingProvider.notifier).state = false;
    }
  }

  Future<void> _updateFace(int value) async {
    if (ref.read(_updatingProvider)) return;

    ref.read(_updatingProvider.notifier).state = true;
    ref.read(_statusMessageProvider.notifier).state = "";
    try {
      await Stackchan(widget.stackchanConfig.ipAddress).face("$value");
    } catch (e) {
      ref.read(_statusMessageProvider.notifier).state = "Error: ${e.toString()}";
    } finally {
      ref.read(_updatingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialized = ref.watch(_initializedProvider);
    final updating = ref.watch(_updatingProvider);
    final statusMessage = ref.watch(_statusMessageProvider);

    return Scaffold(
      body: GestureDetector(
        child: Column(
          children: [
            Expanded(
              child: Visibility(
                visible: initialized,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Card(
                          child: ListTile(
                            title: Text("😐 おすまし", style: Theme.of(context).textTheme.titleLarge),
                            // subtitle: Text("Neutral Face", style: Theme.of(context).textTheme.titleMedium),
                            onTap: () {
                              _updateFace(0);
                            },
                          ),
                        ),
                        Card(
                          child: ListTile(
                            title: Text("😘 たのしい", style: Theme.of(context).textTheme.titleLarge),
                            // subtitle: Text("Happy Face", style: Theme.of(context).textTheme.titleMedium),
                            onTap: () {
                              _updateFace(1);
                            },
                          ),
                        ),
                        Card(
                          child: ListTile(
                            title: Text("😪 ねむい", style: Theme.of(context).textTheme.titleLarge),
                            // subtitle: Text("Sleepy Face", style: Theme.of(context).textTheme.titleMedium),
                            onTap: () {
                              _updateFace(2);
                            },
                          ),
                        ),
                        Card(
                          child: ListTile(
                            title: Text("😥 あやしい", style: Theme.of(context).textTheme.titleLarge),
                            // subtitle: Text("Doubt Face", style: Theme.of(context).textTheme.titleMedium),
                            onTap: () {
                              _updateFace(3);
                            },
                          ),
                        ),
                        Card(
                          child: ListTile(
                            title: Text("😢 かなしい", style: Theme.of(context).textTheme.titleLarge),
                            // subtitle: Text("Sad Face", style: Theme.of(context).textTheme.titleMedium),
                            onTap: () {
                              _updateFace(4);
                            },
                          ),
                        ),
                        Card(
                          child: ListTile(
                            title: Text("😠 おこ", style: Theme.of(context).textTheme.titleLarge),
                            // subtitle: Text("Angry Face", style: Theme.of(context).textTheme.titleMedium),
                            onTap: () {
                              _updateFace(5);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8.0),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Visibility(
                    visible: statusMessage.isNotEmpty,
                    child: Text(
                      statusMessage,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Visibility(
                    visible: updating,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: LinearProgressIndicator(),
                    ),
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
