import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/stackchan.dart';
import '../../repository/stackchan.dart';

class SettingStackchanPage extends ConsumerStatefulWidget {
  const SettingStackchanPage(this.stackchanConfigProvider, {super.key});

  final StateProvider<StackchanConfig> stackchanConfigProvider;

  @override
  ConsumerState<SettingStackchanPage> createState() => _SettingStackchanPageState();
}

class _SettingStackchanPageState extends ConsumerState<SettingStackchanPage> {
  /// 初期化完了
  final _initializedProvider = StateProvider((ref) => false);

  /// 設定更新中
  final _updatingProvider = StateProvider((ref) => false);

  /// ステータスメッセージ
  final _statusMessageProvider = StateProvider((ref) => "");

  /// 音量設定値
  final _volumeProvider = StateProvider((ref) => 255);

  @override
  void initState() {
    super.initState();
    Future(() async {
      await _restoreSettings();
      await _checkStackchan();
    });
  }

  Future<void> _restoreSettings() async {
    ref.read(_volumeProvider.notifier).state =
        (ref.read(widget.stackchanConfigProvider).config["volume"] ?? 255) as int;
  }

  // check existence of apikey setting page
  Future<void> _checkStackchan() async {
    ref.read(_updatingProvider.notifier).state = true;
    ref.read(_statusMessageProvider.notifier).state = "";
    try {
      if (await Stackchan(ref.read(widget.stackchanConfigProvider).ipAddress).hasSettingApi()) {
        ref.read(_initializedProvider.notifier).state = true;
      } else {
        ref.read(_statusMessageProvider.notifier).state = "設定できません。";
      }
    } finally {
      ref.read(_updatingProvider.notifier).state = false;
    }
  }

  Future<void> _updateVolume() async {
    if (ref.read(_updatingProvider)) return;

    final voice = ref.read(widget.stackchanConfigProvider).config["voice"] as String?;
    ref.read(_updatingProvider.notifier).state = true;
    ref.read(_statusMessageProvider.notifier).state = "";
    try {
      final stackchan = Stackchan(ref.read(widget.stackchanConfigProvider).ipAddress);
      await stackchan.setting(volume: "${ref.read(_volumeProvider)}");
      await stackchan.speech("音量を${ref.read(_volumeProvider)}に設定しました。", voice: voice);
      ref.read(_statusMessageProvider.notifier).state = "設定しました。";
    } catch (e) {
      ref.read(_statusMessageProvider.notifier).state = "Error: ${e.toString()}";
    } finally {
      ref.read(_updatingProvider.notifier).state = false;
    }

    final stackchanConfig = ref.read(widget.stackchanConfigProvider);
    final config = stackchanConfig.config;
    config["volume"] = ref.read(_volumeProvider);
    ref.read(widget.stackchanConfigProvider.notifier).state = stackchanConfig.copyWith(config: config);
  }

  @override
  Widget build(BuildContext context) {
    final initialized = ref.watch(_initializedProvider);
    final updating = ref.watch(_updatingProvider);
    final statusMessage = ref.watch(_statusMessageProvider);
    final volume = ref.watch(_volumeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("ｽﾀｯｸﾁｬﾝ ｺﾝﾈｸﾄ"),
      ),
      body: GestureDetector(
        child: Column(
          children: [
            Expanded(
              child: Visibility(
                visible: initialized,
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("音量: "),
                            Text("$volume"),
                          ],
                        ),
                        Slider(
                          label: "音量",
                          min: 0,
                          max: 255,
                          value: volume.toDouble(),
                          onChanged: (double value) {
                            ref.read(_volumeProvider.notifier).state = value.toInt();
                          },
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (initialized && !updating) ? _updateVolume : null,
                      child: Text(
                        "設定",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
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
