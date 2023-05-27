import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../infrastructure/stackchan.dart';
import '../repository/stackchan.dart';
import 'smartconfig.dart';

class StackchanConfigPage extends ConsumerStatefulWidget {
  const StackchanConfigPage(this.stackchanConfigProvider, {super.key});

  final StateProvider<StackchanConfig> stackchanConfigProvider;

  @override
  ConsumerState<StackchanConfigPage> createState() => _StackchanConfigPageState();
}

class _StackchanConfigPageState extends ConsumerState<StackchanConfigPage> {
  /// ｽﾀｯｸﾁｬﾝ 設定リポジトリ
  final _stackchanRepository = StackchanRepository();

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
    _stackchanRepository.save(newStackchanConfig);
    if (context.mounted) {
      Navigator.of(context).pop(newStackchanConfig);
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
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          "名前",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        "この ｽﾀｯｸﾁｬﾝ に名前をつけてください。",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: TextField(
                          controller: _stackchanNameTextArea,
                          decoration: const InputDecoration(
                            hintText: "名前",
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          "IP アドレス",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        "ｽﾀｯｸﾁｬﾝの IP アドレスを入力してください。",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: TextField(
                          controller: _stackchanIpAddressTextArea,
                          decoration: const InputDecoration(
                            hintText: "IP アドレス",
                          ),
                        ),
                      ),
                      ValueListenableBuilder(
                        valueListenable: _stackchanIpAddressTextArea,
                        builder: (context, value, child) {
                          return Visibility(
                            visible: _canSmartConfig() && _stackchanIpAddressTextArea.text.trim().isEmpty,
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _startSmartConfig,
                                child: const Text("SmartConfig で自動設定"),
                              ),
                            ),
                          );
                        },
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
                                    onPressed:
                                        _stackchanIpAddressTextArea.text.trim().isEmpty || updating ? null : _test,
                                    child: const Text("接続確認"),
                                  );
                                },
                              ),
                            ),
                          );
                        },
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
                    child: ValueListenableBuilder(
                      valueListenable: _stackchanIpAddressTextArea,
                      builder: (context, value, child) {
                        return ElevatedButton(
                          onPressed: _close,
                          child: const Text("OK"),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ValueListenableBuilder(
                      valueListenable: _stackchanIpAddressTextArea,
                      builder: (context, value, child) {
                        return ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text("確認"),
                                  content: const Text("この ｽﾀｯｸﾁｬﾝ を一覧から削除します。本当によろしいですか?"),
                                  actions: [
                                    TextButton(
                                      child: const Text("やめる"),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    TextButton(
                                      child: const Text("OK"),
                                      onPressed: () {
                                        _stackchanRepository.remove(ref.watch(widget.stackchanConfigProvider));
                                        Navigator.of(context).pop();
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text("削除"),
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
