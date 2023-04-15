import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../infrastructure/openai.dart';
import '../../infrastructure/stackchan.dart';
import '../../infrastructure/voicetext.dart';

class SettingApiKeyPage extends StatefulWidget {
  const SettingApiKeyPage(this.stackchanIpAddress, {super.key});

  final String stackchanIpAddress;

  @override
  State<SettingApiKeyPage> createState() => _SettingApiKeyPageState();
}

class _SettingApiKeyPageState extends State<SettingApiKeyPage> {
  /// 初期化完了
  bool initialized = false;

  /// 設定更新中
  bool updating = false;

  /// ステータスメッセージ
  String statusMessage = "";

  /// OpenAI API Key 入力
  final openaiApiKeyTextArea = TextEditingController();
  bool openaiApiKeyIsObscure = true;

  /// VoiceText API Key 入力
  final voicetextApiKeyTextArea = TextEditingController();
  bool voicetextApiKeyIsObscure = true;

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
    openaiApiKeyTextArea.text = prefs.getString("openaiApiKey") ?? "";
    voicetextApiKeyTextArea.text = prefs.getString("voicetextApiKey") ?? "";
  }

  void onUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("openaiApiKey", openaiApiKeyTextArea.text);
    await prefs.setString("voicetextApiKey", voicetextApiKeyTextArea.text);
  }

  // check existence of apikey setting page
  void checkStackchan() async {
    setState(() {
      updating = true;
      statusMessage = "";
    });
    try {
      if (await Stackchan(widget.stackchanIpAddress).hasApiKeysApi()) {
        setState(() {
          initialized = true;
        });
      } else {
        setState(() {
          statusMessage = "設定できません。";
        });
      }
    } finally {
      setState(() {
        updating = false;
      });
    }
  }

  void showMessageForStatusCode(Response res) {
    const Map<int, String> statusMessages = {
      401: "認証に失敗しました。不正な API Key です。",
      403: "アクセス権限がありません。",
      429: "利用量が制限を超過している可能性があります。利用可能枠を確認してください。",
    };
    var message = "${res.statusCode} ${res.reasonPhrase}";
    if (statusMessages[res.statusCode] != null) {
      message += "\n${statusMessages[res.statusCode]}";
    }
    setState(() {
      statusMessage = message;
    });
  }

  Future<void> testOpenAIApi() async {
    setState(() {
      updating = true;
      statusMessage = "";
    });
    try {
      final res = await OpenAIApi(apiKey: openaiApiKeyTextArea.text).testChat("test");
      if (res.statusCode == 200) {
        setState(() {
          statusMessage = "OpenAI API を使用できます。";
        });
      } else {
        showMessageForStatusCode(res);
      }
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

  Future<void> testVoiceTextApi() async {
    setState(() {
      updating = true;
      statusMessage = "";
    });
    try {
      final res = await VoiceTextApi(apiKey: voicetextApiKeyTextArea.text).testTts("test");
      if (res.statusCode == 200) {
        setState(() {
          statusMessage = "VoiceText API を使用できます。";
        });
      } else {
        showMessageForStatusCode(res);
      }
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

  Future<void> updateApiKeys() async {
    final openaiApiKey = openaiApiKeyTextArea.text;
    final voicetextApiKey = voicetextApiKeyTextArea.text;
    setState(() {
      updating = true;
      statusMessage = "";
    });
    try {
      await Stackchan(widget.stackchanIpAddress).setApiKeys(openai: openaiApiKey, voicetext: voicetextApiKey);
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
                      children: [
                        Text(
                          "OpenAI",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "OpenAI",
                                style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.blue),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    launchUrl(Uri.parse("https://platform.openai.com"),
                                        mode: LaunchMode.externalApplication);
                                  },
                              ),
                              TextSpan(
                                text: " から API Key を発行し、入力してください。",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          child: TextFormField(
                            obscureText: openaiApiKeyIsObscure,
                            decoration: InputDecoration(
                              labelText: "OpenAI API Key",
                              suffixIcon: IconButton(
                                icon: Icon(openaiApiKeyIsObscure ? Icons.visibility_off : Icons.visibility),
                                onPressed: () {
                                  setState(() {
                                    openaiApiKeyIsObscure = !openaiApiKeyIsObscure;
                                  });
                                },
                              ),
                            ),
                            controller: openaiApiKeyTextArea,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: testOpenAIApi,
                            child: Text(
                              "テスト",
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        Text(
                          "VoiceText",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "音声合成エンジン ",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              TextSpan(
                                text: "VoiceText Web API",
                                style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.blue),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    launchUrl(Uri.parse("https://cloud.voicetext.jp"),
                                        mode: LaunchMode.externalApplication);
                                  },
                              ),
                              TextSpan(
                                text: " から API Key を発行し、入力してください。",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          child: TextFormField(
                            obscureText: voicetextApiKeyIsObscure,
                            decoration: InputDecoration(
                              labelText: "VoiceText API Key",
                              suffixIcon: IconButton(
                                icon: Icon(voicetextApiKeyIsObscure ? Icons.visibility_off : Icons.visibility),
                                onPressed: () {
                                  setState(() {
                                    voicetextApiKeyIsObscure = !voicetextApiKeyIsObscure;
                                  });
                                },
                              ),
                            ),
                            controller: voicetextApiKeyTextArea,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: testVoiceTextApi,
                            child: Text(
                              "テスト",
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ),
                      ],
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
                      onPressed: initialized ? updateApiKeys : null,
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
