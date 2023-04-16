import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../infrastructure/openai.dart';
import '../../infrastructure/stackchan.dart';
import '../../infrastructure/voicetext.dart';

class SettingApiKeyPage extends StatefulWidget {
  final String stackchanIpAddress;

  const SettingApiKeyPage(this.stackchanIpAddress, {super.key});

  @override
  State<SettingApiKeyPage> createState() => _SettingApiKeyPageState();
}

class _SettingApiKeyPageState extends State<SettingApiKeyPage> {
  /// 初期化完了
  bool _initialized = false;

  /// 設定更新中
  bool _updating = false;

  /// ステータスメッセージ
  String _statusMessage = "";

  /// OpenAI API Key 入力
  final _openaiApiKeyTextArea = TextEditingController();
  bool _openaiApiKeyIsObscure = true;

  /// VoiceText API Key 入力
  final _voicetextApiKeyTextArea = TextEditingController();
  bool _voicetextApiKeyIsObscure = true;

  @override
  void initState() {
    super.initState();
    _openaiApiKeyTextArea.addListener(_onUpdate);
    _voicetextApiKeyTextArea.addListener(_onUpdate);
    _restoreSettings();
    _checkStackchan();
  }

  @override
  void dispose() {
    _openaiApiKeyTextArea.dispose();
    _voicetextApiKeyTextArea.dispose();
    super.dispose();
  }

  void _restoreSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _openaiApiKeyTextArea.text = prefs.getString("openaiApiKey") ?? "";
    _voicetextApiKeyTextArea.text = prefs.getString("voicetextApiKey") ?? "";
  }

  void _onUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("openaiApiKey", _openaiApiKeyTextArea.text.trim());
    await prefs.setString("voicetextApiKey", _voicetextApiKeyTextArea.text.trim());
  }

  // check existence of apikey setting page
  void _checkStackchan() async {
    setState(() {
      _updating = true;
      _statusMessage = "";
    });
    try {
      if (await Stackchan(widget.stackchanIpAddress).hasApiKeysApi()) {
        setState(() {
          _initialized = true;
        });
      } else {
        setState(() {
          _statusMessage = "設定できません。";
        });
      }
    } finally {
      setState(() {
        _updating = false;
      });
    }
  }

  void _showMessageForStatusCode(Response res) {
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
      _statusMessage = message;
    });
  }

  Future<void> _testOpenAIApi() async {
    setState(() {
      _updating = true;
      _statusMessage = "";
    });
    try {
      final res = await OpenAIApi(apiKey: _openaiApiKeyTextArea.text.trim()).testChat("test");
      if (res.statusCode == 200) {
        setState(() {
          _statusMessage = "OpenAI API を使用できます。";
        });
      } else {
        _showMessageForStatusCode(res);
      }
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

  Future<void> _testVoiceTextApi() async {
    setState(() {
      _updating = true;
      _statusMessage = "";
    });
    try {
      final res = await VoiceTextApi(apiKey: _voicetextApiKeyTextArea.text.trim()).testTts("test");
      if (res.statusCode == 200) {
        setState(() {
          _statusMessage = "VoiceText API を使用できます。";
        });
      } else {
        _showMessageForStatusCode(res);
      }
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

  Future<void> _updateApiKeys() async {
    if (_updating) return;

    FocusManager.instance.primaryFocus?.unfocus();
    final openaiApiKey = _openaiApiKeyTextArea.text.trim();
    final voicetextApiKey = _voicetextApiKeyTextArea.text.trim();
    setState(() {
      _updating = true;
      _statusMessage = "";
    });
    try {
      await Stackchan(widget.stackchanIpAddress).setApiKeys(openai: openaiApiKey, voicetext: voicetextApiKey);
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
                            obscureText: _openaiApiKeyIsObscure,
                            decoration: InputDecoration(
                              labelText: "OpenAI API Key",
                              suffixIcon: IconButton(
                                icon: Icon(_openaiApiKeyIsObscure ? Icons.visibility_off : Icons.visibility),
                                onPressed: () {
                                  setState(() {
                                    _openaiApiKeyIsObscure = !_openaiApiKeyIsObscure;
                                  });
                                },
                              ),
                            ),
                            controller: _openaiApiKeyTextArea,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _testOpenAIApi,
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
                            obscureText: _voicetextApiKeyIsObscure,
                            decoration: InputDecoration(
                              labelText: "VoiceText API Key",
                              suffixIcon: IconButton(
                                icon: Icon(_voicetextApiKeyIsObscure ? Icons.visibility_off : Icons.visibility),
                                onPressed: () {
                                  setState(() {
                                    _voicetextApiKeyIsObscure = !_voicetextApiKeyIsObscure;
                                  });
                                },
                              ),
                            ),
                            controller: _voicetextApiKeyTextArea,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _testVoiceTextApi,
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
                      onPressed: (_initialized && !_updating) ? _updateApiKeys : null,
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
