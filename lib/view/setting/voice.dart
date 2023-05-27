import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/stackchan.dart';
import '../../repository/stackchan.dart';

class SettingVoicePage extends ConsumerStatefulWidget {
  const SettingVoicePage(this.stackchanConfigProvider, {super.key});

  final StateProvider<StackchanConfig> stackchanConfigProvider;

  @override
  ConsumerState<SettingVoicePage> createState() => _SettingVoicePageState();
}

class _SettingVoicePageState extends ConsumerState<SettingVoicePage> {
  /// テスト中
  final _updatingProvider = StateProvider((ref) => false);

  /// ステータスメッセージ
  final _statusMessageProvider = StateProvider((ref) => "");

  /// 声色設定値
  final _voiceProvider = StateProvider<String?>((ref) => null);

  @override
  void initState() {
    super.initState();
    Future(() async {
      await _restoreSettings();
    });
  }

  Future<void> _restoreSettings() async {
    ref.read(_voiceProvider.notifier).state = ref.read(widget.stackchanConfigProvider).config["voice"] as String?;
  }

  Future<void> _test() async {
    ref.read(_updatingProvider.notifier).state = true;
    ref.read(_statusMessageProvider.notifier).state = "";
    try {
      await Stackchan(ref.read(widget.stackchanConfigProvider).ipAddress)
          .speech("こんにちは。スタックチャンです。", voice: ref.read(_voiceProvider));
    } catch (e) {
      ref.read(_statusMessageProvider.notifier).state = "Error: ${e.toString()}";
    } finally {
      ref.read(_updatingProvider.notifier).state = false;
    }
  }

  Future<void> _close() async {
    final stackchanConfig = ref.read(widget.stackchanConfigProvider);
    final config = stackchanConfig.config;
    config["voice"] = ref.read(_voiceProvider);
    ref.read(widget.stackchanConfigProvider.notifier).state = stackchanConfig.copyWith(config: config);
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final updating = ref.watch(_updatingProvider);
    final statusMessage = ref.watch(_statusMessageProvider);
    final voice = ref.watch(_voiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("声色設定"),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        "声色",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      "声色の番号を選択してください。声色指定に対応していない場合、設定は無効です。",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: DropdownButtonFormField<String?>(
                        isExpanded: true,
                        items: const <DropdownMenuItem<String>>[
                              DropdownMenuItem(
                                value: null,
                                child: Text("指定しない"),
                              ),
                            ] +
                            [for (var i = 1; i <= 60; i++) i].map((i) {
                              return DropdownMenuItem(value: "$i", child: Text("No. $i"));
                            }).toList(),
                        onChanged: (String? value) {
                          ref.read(_voiceProvider.notifier).state = value;
                        },
                        value: voice,
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _test,
                        child: const Text("聞いてみる"),
                      ),
                    ),
                  ],
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
                    onPressed: _close,
                    child: const Text("OK"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
