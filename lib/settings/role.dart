import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
    var ok = false;
    try {
      final res = await http.get(Uri.http(stackchanIpAddress, "/role_get"));
      ok = res.statusCode == 200;
      if (ok) {
        var body = utf8.decode(res.bodyBytes);
        var si = body.indexOf("<pre>");
        var ei = body.indexOf("</pre>");
        if (si >= 0 && ei >= 0) {
          body = body.substring(si + 5, ei);
        }
        final json = jsonDecode(body);
        final role = json['messages'].firstWhere((message) => message['role'] == 'system');
        if (role != null) {
          roleTextArea.text = role['content'];
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (ok) {
        setState(() {
          hasRole = true;
          errorMessage = "";
        });
      } else {
        setState(() {
          errorMessage = "ロールを設定できません。";
        });
      }
    }
  }

  void updateRole() async {
    final role = roleTextArea.text;
    // try speech API
    try {
      final res = await http.post(Uri.http(widget.stackchanIpAddress, "/role_set"), body: role);
      if (res.statusCode != 200) {
        setState(() {
          errorMessage = 'Error: ${res.statusCode}';
        });
      }

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
