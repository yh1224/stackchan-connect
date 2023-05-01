import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../infrastructure/stackchan.dart';

class SettingStackchanPage extends ConsumerStatefulWidget {
  const SettingStackchanPage(this.stackchanIpAddress, {super.key});

  final String stackchanIpAddress;

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
    final prefs = await SharedPreferences.getInstance();
    ref.read(_volumeProvider.notifier).state = prefs.getInt("volume") ?? 255;
  }

  // check existence of apikey setting page
  Future<void> _checkStackchan() async {
    ref.read(_updatingProvider.notifier).state = true;
    ref.read(_statusMessageProvider.notifier).state = "";
    try {
      if (await Stackchan(widget.stackchanIpAddress).hasSettingApi()) {
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("volume", ref.read(_volumeProvider));
    final voice = prefs.getString("voice");

    ref.read(_updatingProvider.notifier).state = true;
    ref.read(_statusMessageProvider.notifier).state = "";
    try {
      final stackchan = Stackchan(widget.stackchanIpAddress);
      await stackchan.setting(volume: "${ref.read(_volumeProvider)}");
      await stackchan.speech("音量を${ref.read(_volumeProvider)}に設定しました。", voice: voice);
      ref.read(_statusMessageProvider.notifier).state = "設定しました。";
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
