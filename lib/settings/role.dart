import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../control.dart';

class StackchanRoleSettingsPage extends StatefulWidget {
  const StackchanRoleSettingsPage(this.stackchanIpAddress, {super.key});

  final String stackchanIpAddress;

  @override
  State<StackchanRoleSettingsPage> createState() => _StackchanRoleSettingsPageState();
}

class _StackchanRoleSettingsPageState extends State<StackchanRoleSettingsPage> {
  final roleTextArea = TextEditingController();

  bool hasRole = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    roleTextArea.addListener(onUpdate);
    getRole();
  }

  @override
  void dispose() {
    roleTextArea.dispose();
    super.dispose();
  }

  void onUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', roleTextArea.text);
  }

  // check existence of apikey setting page
  void getRole() async {
    final stackchanIpAddress = widget.stackchanIpAddress;
    if (stackchanIpAddress.isEmpty) {
      setState(() {
        errorMessage = "IP アドレスを設定してください。";
      });
      return;
    }

    setState(() {
      errorMessage = "確認中です...";
    });
    try {
      final roles = await Stackchan(stackchanIpAddress).getRoles();
      if (roles.isNotEmpty) {
        roleTextArea.text = roles[0];
      }
      setState(() {
        hasRole = true;
        errorMessage = "";
      });
    } catch (e) {
      setState(() {
        errorMessage = "ロールを設定できません。";
      });
    }
  }

  void updateRole() async {
    final role = roleTextArea.text;
    try {
      await Stackchan(widget.stackchanIpAddress).setRoles([role]);
      setState(() {
        errorMessage = '設定に成功しました。';
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ｽﾀｯｸﾁｬﾝ ｺﾝﾈｸﾄ'),
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
                    TextFormField(
                      maxLines: null,
                      decoration: const InputDecoration(
                        labelText: "ロール",
                      ),
                      controller: roleTextArea,
                      style: const TextStyle(fontSize: 20),
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
                Text(errorMessage),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: hasRole ? updateRole : null,
                    child: const Text(
                      '設定',
                      style: TextStyle(fontSize: 20),
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
