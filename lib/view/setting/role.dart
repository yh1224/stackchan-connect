import 'dart:math';

import 'package:flutter/material.dart';

import '../../infrastructure/stackchan.dart';

class SettingRolePage extends StatefulWidget {
  const SettingRolePage(this.stackchanIpAddress, {super.key});

  final String stackchanIpAddress;

  @override
  State<SettingRolePage> createState() => _SettingRolePageState();
}

class _SettingRolePageState extends State<SettingRolePage> {
  /// ロール設定可能数  TODO: とりあえず固定
  static const maxRoleCount = 5;

  /// 初期化完了
  bool _initialized = false;

  /// 設定更新中
  bool _updating = false;

  /// ステータスメッセージ
  String _statusMessage = "";

  /// ロール入力
  final _roleTextAreas = List.generate(maxRoleCount, (int index) => TextEditingController());

  @override
  void initState() {
    super.initState();
    _getRole();
  }

  @override
  void dispose() {
    for (var roleTextArea in _roleTextAreas) {
      roleTextArea.dispose();
    }
    super.dispose();
  }

  // check existence of apikey setting page
  void _getRole() async {
    setState(() {
      _updating = true;
      _statusMessage = "";
    });
    try {
      final roles = await Stackchan(widget.stackchanIpAddress).getRoles();
      for (var i = 0; i < min(_roleTextAreas.length, roles.length); i++) {
        _roleTextAreas[i].text = roles[i];
      }
      setState(() {
        _initialized = true;
      });
      if (roles.length > maxRoleCount) {
        setState(() {
          _statusMessage = "現在 ${roles.length} 個のロールが設定されています。このアプリでは $maxRoleCount 個までしか設定できませんのでご注意ください。";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "設定できません。";
      });
    } finally {
      setState(() {
        _updating = false;
      });
    }
  }

  void _updateRoles() async {
    if (_updating) return;

    setState(() {
      _updating = true;
      _statusMessage = "";
    });
    final roles = _roleTextAreas.map((roleTextArea) => roleTextArea.text).where((text) => text.isNotEmpty).toList();
    try {
      await Stackchan(widget.stackchanIpAddress).setRoles(roles);
      setState(() {
        _statusMessage = "設定しました。";
      });
    } catch (e) {
      setState(() {
        _statusMessage = "Error: ${e.toString()}";
      });
    } finally {
      setState(() {
        _updating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                visible: _initialized,
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
                    visible: _statusMessage.isNotEmpty,
                    child: Text(
                      _statusMessage,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Visibility(
                    visible: _updating,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: LinearProgressIndicator(),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_initialized && !_updating) ? _updateRoles : null,
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
