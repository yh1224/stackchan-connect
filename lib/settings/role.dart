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
  static const maxRoleCount = 5; // TODO: とりあえず固定
  final roleTextAreas = List.generate(maxRoleCount, (int index) => TextEditingController());

  bool isLoading = false;
  bool hasRole = false;
  String errorMessage = '';

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
        errorMessage = "IP アドレスを設定してください。";
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = "";
    });
    try {
      final roles = await Stackchan(stackchanIpAddress).getRoles();
      for (var i = 0; i < min(roleTextAreas.length, roles.length); i++) {
        roleTextAreas[i].text = roles[i];
      }
      setState(() {
        hasRole = true;
      });
      if (roles.length > maxRoleCount) {
        setState(() {
          errorMessage = "現在 ${roles.length} 個のロールが設定されています。このアプリでは $maxRoleCount 個までしか設定できませんのでご注意ください。";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "ロールを設定できません。";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void updateRoles() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });
    final roles = roleTextAreas.map((roleTextArea) => roleTextArea.text).where((text) => text.isNotEmpty).toList();
    try {
      await Stackchan(widget.stackchanIpAddress).setRoles(roles);
      setState(() {
        errorMessage = '設定に成功しました。';
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        isLoading = false;
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
                  children: List.generate(
                      maxRoleCount,
                      (int index) => TextFormField(
                            maxLines: null,
                            decoration: InputDecoration(
                              labelText: "ロール ${index + 1}",
                            ),
                            controller: roleTextAreas[index],
                            style: const TextStyle(fontSize: 20),
                          )),
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
                Visibility(
                  visible: isLoading,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: LinearProgressIndicator(),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: hasRole ? updateRoles : null,
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
