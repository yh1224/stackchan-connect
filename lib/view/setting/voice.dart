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
          .speech("こんにちは。私の声はいかがですか", voice: ref.read(_voiceProvider));
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
        title: const Text("ｽﾀｯｸﾁｬﾝ ｺﾝﾈｸﾄ"),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("声色指定に対応していない場合、設定しても効きません。"),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          const Text("声色: "),
                          DropdownButton<String?>(
                            items: const [
                              DropdownMenuItem(
                                value: null,
                                child: Text("未指定"),
                              ),
                              DropdownMenuItem(
                                value: "0",
                                child: Text("0"),
                              ),
                              DropdownMenuItem(
                                value: "1",
                                child: Text("1"),
                              ),
                              DropdownMenuItem(
                                value: "2",
                                child: Text("2"),
                              ),
                              DropdownMenuItem(
                                value: "3",
                                child: Text("3"),
                              ),
                              DropdownMenuItem(
                                value: "4",
                                child: Text("4"),
                              ),
                            ],
                            onChanged: (String? value) {
                              ref.read(_voiceProvider.notifier).state = value;
                            },
                            value: voice,
                          )
                        ],
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
                    onPressed: _test,
                    child: Text(
                      "テスト",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _close,
                    child: Text(
                      "OK",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
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
