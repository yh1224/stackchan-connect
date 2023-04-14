import 'dart:math';

import 'package:flutter/material.dart';

import '../control.dart';

class StackchanRoleSettingsPage extends StatefulWidget {
  const StackchanRoleSettingsPage(this.stackchanIpAddress, {super.key});

  final String stackchanIpAddress;

  @override
  State<StackchanRoleSettingsPage> createState() => _StackchanRoleSettingsPageState();
}

class _StackchanRoleSettingsPageState extends State<StackchanRoleSettingsPage> {
  /// ロール設定可能数  TODO: とりあえず固定
  static const maxRoleCount = 5;

  /// 初期化完了
  bool initialized = false;

  /// 設定更新中
  bool updating = false;

  /// ステータスメッセージ
  String statusMessage = "";

  /// ロール入力
  final roleTextAreas = List.generate(maxRoleCount, (int index) => TextEditingController());

  @override
  void initState() {
    super.initState();
    getRole();
  }

  @override
  void dispose() {
    for (var roleTextArea in roleTextAreas) {
      roleTextArea.dispose();
    }
    super.dispose();
  }

  // check existence of apikey setting page
  void getRole() async {
    final stackchanIpAddress = widget.stackchanIpAddress;
    if (stackchanIpAddress.isEmpty) {
      setState(() {
        statusMessage = "IP アドレスを設定してください。";
      });
      return;
    }

    setState(() {
      updating = true;
      statusMessage = "";
    });
    try {
      final roles = await Stackchan(stackchanIpAddress).getRoles();
      for (var i = 0; i < min(roleTextAreas.length, roles.length); i++) {
        roleTextAreas[i].text = roles[i];
      }
      setState(() {
        initialized = true;
      });
      if (roles.length > maxRoleCount) {
        setState(() {
          statusMessage = "現在 ${roles.length} 個のロールが設定されています。このアプリでは $maxRoleCount 個までしか設定できませんのでご注意ください。";
        });
      }
    } catch (e) {
      setState(() {
        statusMessage = "設定できません。";
      });
    } finally {
      setState(() {
        updating = false;
      });
    }
  }

  void updateRoles() async {
    setState(() {
      updating = true;
      statusMessage = "";
    });
    final roles = roleTextAreas.map((roleTextArea) => roleTextArea.text).where((text) => text.isNotEmpty).toList();
    try {
      await Stackchan(widget.stackchanIpAddress).setRoles(roles);
      setState(() {
        statusMessage = "設定しました。";
      });
    } catch (e) {
      setState(() {
        statusMessage = "Error: ${e.toString()}";
      });
    } finally {
      setState(() {
        updating = false;
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
                                      controller: roleTextAreas[index],
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
                      onPressed: initialized ? updateRoles : null,
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
