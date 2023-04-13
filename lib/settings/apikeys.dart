import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../control.dart';

class StackchanApiKeysSettingsPage extends StatefulWidget {
  const StackchanApiKeysSettingsPage(this.stackchanIpAddress, {super.key});

  final String stackchanIpAddress;

  @override
  State<StackchanApiKeysSettingsPage> createState() => _StackchanApiKeysSettingsPageState();
}

class _StackchanApiKeysSettingsPageState extends State<StackchanApiKeysSettingsPage> {
  final openaiApiKeyTextArea = TextEditingController();
  final voicetextApiKeyTextArea = TextEditingController();

  bool isLoading = false;
  bool hasApiKeySetting = false;
  bool isOpenaiApiKeyObscure = true;
  bool isVoicetextApiKeyObscure = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    openaiApiKeyTextArea.addListener(onUpdate);
    voicetextApiKeyTextArea.addListener(onUpdate);
    restoreSettings();
    checkStackchan();
  }

  @override
  void dispose() {
    openaiApiKeyTextArea.dispose();
    voicetextApiKeyTextArea.dispose();
    super.dispose();
  }

  void restoreSettings() async {
    final prefs = await SharedPreferences.getInstance();
    openaiApiKeyTextArea.text = prefs.getString('openaiApiKey') ?? '';
    voicetextApiKeyTextArea.text = prefs.getString('voicetextApiKey') ?? '';
  }

  void onUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('openaiApiKey', openaiApiKeyTextArea.text);
    await prefs.setString('voicetextApiKey', voicetextApiKeyTextArea.text);
  }

  // check existence of apikey setting page
  void checkStackchan() async {
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
      if (await Stackchan(stackchanIpAddress).hasApiKeysApi()) {
        setState(() {
          hasApiKeySetting = true;
        });
      } else {
        setState(() {
          errorMessage = "API Key を設定できません。";
        });
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void updateApiKeys() async {
    final openaiApiKey = openaiApiKeyTextArea.text;
    final voicetextApiKey = voicetextApiKeyTextArea.text;
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      await Stackchan(widget.stackchanIpAddress).setApiKeys(openai: openaiApiKey, voicetext: voicetextApiKey);
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
                  children: [
                    TextFormField(
                      obscureText: isOpenaiApiKeyObscure,
                      decoration: InputDecoration(
                        labelText: "OpenAI API Key",
                        suffixIcon: IconButton(
                          icon: Icon(isOpenaiApiKeyObscure ? Icons.visibility_off : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              isOpenaiApiKeyObscure = !isOpenaiApiKeyObscure;
                            });
                          },
                        ),
                      ),
                      controller: openaiApiKeyTextArea,
                      style: const TextStyle(fontSize: 20),
                    ),
                    TextFormField(
                      obscureText: isVoicetextApiKeyObscure,
                      decoration: InputDecoration(
                        labelText: "VOICETEXT API Key",
                        suffixIcon: IconButton(
                          icon: Icon(isVoicetextApiKeyObscure ? Icons.visibility_off : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              isVoicetextApiKeyObscure = !isVoicetextApiKeyObscure;
                            });
                          },
                        ),
                      ),
                      controller: voicetextApiKeyTextArea,
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
                    onPressed: hasApiKeySetting ? updateApiKeys : null,
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
