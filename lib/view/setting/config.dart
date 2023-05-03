import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/stackchan.dart';
import '../../repository/stackchan.dart';
import 'smartconfig.dart';

class SettingIpConfigPage extends ConsumerStatefulWidget {
  const SettingIpConfigPage(this.stackchanConfigProvider, {super.key});

  final StateProvider<StackchanConfig> stackchanConfigProvider;

  @override
  ConsumerState<SettingIpConfigPage> createState() => _SettingIpAddressPageState();
}

class _SettingIpAddressPageState extends ConsumerState<SettingIpConfigPage> {
  /// 設定更新中
  final _updatingProvider = StateProvider((ref) => false);

  /// ステータスメッセージ
  final _statusMessageProvider = StateProvider((ref) => "");

  /// 名前入力
  final _stackchanNameTextArea = TextEditingController();

  /// IP アドレス入力
  final _stackchanIpAddressTextArea = TextEditingController();

  @override
  void initState() {
    super.initState();
    _stackchanNameTextArea.text = ref.read(widget.stackchanConfigProvider).name;
    _stackchanIpAddressTextArea.text = ref.read(widget.stackchanConfigProvider).ipAddress;
  }

  @override
  void dispose() {
    _stackchanNameTextArea.dispose();
    _stackchanIpAddressTextArea.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    final stackchanIpAddress = _stackchanIpAddressTextArea.text.trim();
    if (stackchanIpAddress.isEmpty) {
      return;
    }

    ref.read(_updatingProvider.notifier).state = true;
    ref.read(_statusMessageProvider.notifier).state = "";
    try {
      await Stackchan(stackchanIpAddress).speech("接続できました");
      ref.read(_statusMessageProvider.notifier).state = "接続できました";
    } catch (e) {
      ref.read(_statusMessageProvider.notifier).state = "Error: ${e.toString()}";
    } finally {
      ref.read(_updatingProvider.notifier).state = false;
    }
  }

  bool _canSmartConfig() {
    return Platform.isAndroid;
  }

  Future<void> _startSmartConfig() async {
    final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SmartConfigPage()));
    debugPrint("SmartConfig result: $result");
    if (result != null) {
      _stackchanIpAddressTextArea.text = result;
    }
  }

  Future<void> _close() async {
    final stackchanConfig = ref.read(widget.stackchanConfigProvider);
    final newStackchanConfig = stackchanConfig.copyWith(
      name: _stackchanNameTextArea.text.trim(),
      ipAddress: _stackchanIpAddressTextArea.text.trim(),
    );
    ref.read(widget.stackchanConfigProvider.notifier).state = newStackchanConfig;
    if (context.mounted) {
      Navigator.of(context).pop(_stackchanIpAddressTextArea.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final updating = ref.watch(_updatingProvider);
    final statusMessage = ref.watch(_statusMessageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("ｽﾀｯｸﾁｬﾝ ｺﾝﾈｸﾄ"),
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "この ｽﾀｯｸﾁｬﾝ に名前をつけてください。",
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              controller: _stackchanNameTextArea,
                              decoration: const InputDecoration(
                                hintText: "名前",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "ｽﾀｯｸﾁｬﾝの IP アドレスを入力してください。",
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              controller: _stackchanIpAddressTextArea,
                              decoration: const InputDecoration(
                                hintText: "IP アドレス",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Visibility(
                        visible: _canSmartConfig(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "SmartConfig に対応している場合は、以下から自動設定することもできます。",
                            ),
                            ElevatedButton(
                              onPressed: _startSmartConfig,
                              child: const Text(
                                "SmartConfig で設定する",
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
                  ValueListenableBuilder(
                    valueListenable: _stackchanIpAddressTextArea,
                    builder: (context, value, child) {
                      return Visibility(
                        visible: _stackchanIpAddressTextArea.text.trim().isNotEmpty,
                        child: SizedBox(
                          width: double.infinity,
                          child: ValueListenableBuilder(
                            valueListenable: _stackchanIpAddressTextArea,
                            builder: (context, value, child) {
                              return ElevatedButton(
                                onPressed: _stackchanIpAddressTextArea.text.trim().isEmpty || updating ? null : _test,
                                child: Text(
                                  "接続確認",
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ValueListenableBuilder(
                      valueListenable: _stackchanIpAddressTextArea,
                      builder: (context, value, child) {
                        return ElevatedButton(
                          onPressed: _close,
                          child: Text(
                            "OK",
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        );
                      },
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
