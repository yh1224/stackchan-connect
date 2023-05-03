import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/stackchan.dart';
import '../../repository/stackchan.dart';

class SettingRolePage extends ConsumerStatefulWidget {
  const SettingRolePage(this.stackchanConfig, {super.key});

  final StackchanConfig stackchanConfig;

  @override
  ConsumerState<SettingRolePage> createState() => _SettingRolePageState();
}

class _SettingRolePageState extends ConsumerState<SettingRolePage> {
  /// ロール設定可能数  TODO: とりあえず固定
  static const maxRoleCount = 5;

  /// 初期化完了
  final _initializedProvider = StateProvider((ref) => false);

  /// 設定更新中
  final _updatingProvider = StateProvider((ref) => false);

  /// ステータスメッセージ
  final _statusMessageProvider = StateProvider((ref) => "");

  /// ロール入力
  final _roleTextAreas = List.generate(maxRoleCount, (int index) => TextEditingController());

  @override
  void initState() {
    super.initState();
    Future(() async {
      await _getRole();
    });
  }

  @override
  void dispose() {
    for (var roleTextArea in _roleTextAreas) {
      roleTextArea.dispose();
    }
    super.dispose();
  }

  // check existence of apikey setting page
  Future<void> _getRole() async {
    ref.read(_updatingProvider.notifier).state = true;
    ref.read(_statusMessageProvider.notifier).state = "";
    try {
      final roles = await Stackchan(widget.stackchanConfig.ipAddress).getRoles();
      for (var i = 0; i < min(_roleTextAreas.length, roles.length); i++) {
        _roleTextAreas[i].text = roles[i];
      }
      ref.read(_initializedProvider.notifier).state = true;
      if (roles.length > maxRoleCount) {
        ref.read(_statusMessageProvider.notifier).state =
            "現在 ${roles.length} 個のロールが設定されています。このアプリでは $maxRoleCount 個までしか設定できませんのでご注意ください。";
      }
    } catch (e) {
      ref.read(_statusMessageProvider.notifier).state = "設定できません。";
    } finally {
      ref.read(_updatingProvider.notifier).state = false;
    }
  }

  Future<void> _updateRoles() async {
    if (ref.read(_updatingProvider)) return;

    FocusManager.instance.primaryFocus?.unfocus();
    ref.read(_updatingProvider.notifier).state = true;
    ref.read(_statusMessageProvider.notifier).state = "";
    final roles =
        _roleTextAreas.map((roleTextArea) => roleTextArea.text.trim()).where((text) => text.isNotEmpty).toList();
    try {
      await Stackchan(widget.stackchanConfig.ipAddress).setRoles(roles);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("ｽﾀｯｸﾁｬﾝ ｺﾝﾈｸﾄ"),
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Expanded(
              child: Visibility(
                visible: initialized,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                            const Text("ロール(役割)を設定することで、ｽﾀｯｸﾁｬﾝ の振る舞いを変更することができます。設定が多いと返答に時間がかかったり、失敗しやすくなります。"),
                          ] +
                          List.generate(
                              maxRoleCount,
                              (int index) => Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                    child: TextFormField(
                                      maxLines: null,
                                      decoration: InputDecoration(
                                        labelText: "ロール ${index + 1}",
                                      ),
                                      controller: _roleTextAreas[index],
                                      style: Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  )),
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
                      onPressed: (initialized && !updating) ? _updateRoles : null,
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
