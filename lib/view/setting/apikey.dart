import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../infrastructure/googlecloud.dart';
import '../../infrastructure/openai.dart';
import '../../infrastructure/stackchan.dart';
import '../../infrastructure/voicetext.dart';
import '../../infrastructure/voicevox.dart';
import '../../repository/stackchan.dart';

class SettingApiKeyPage extends ConsumerStatefulWidget {
  const SettingApiKeyPage(this.stackchanConfig, {super.key});

  final StackchanConfig stackchanConfig;

  @override
  ConsumerState<SettingApiKeyPage> createState() => _SettingApiKeyPageState();
}

class _SettingApiKeyPageState extends ConsumerState<SettingApiKeyPage> {
  /// 初期化完了
  final _initializedProvider = StateProvider((ref) => false);

  /// 設定更新中
  final _updatingProvider = StateProvider((ref) => false);

  /// ステータスメッセージ
  final _statusMessageProvider = StateProvider((ref) => "");

  /// OpenAI API Key 入力
  final _openaiApiKeyTextArea = TextEditingController();
  final _openaiApiKeyIsObscureProvider = StateProvider((ref) => true);

  /// Google Cloud API Key 入力
  final _googleCloudApiKeyTextArea = TextEditingController();
  final _googleCloudApiKeyIsObscureProvider = StateProvider((ref) => true);

  /// VoiceText API Key 入力
  final _voicetextApiKeyTextArea = TextEditingController();
  final _voicetextApiKeyIsObscureProvider = StateProvider((ref) => true);

  /// Voicevox API Key 入力
  final _voicevoxApiKeyTextArea = TextEditingController();
  final _voicevoxApiKeyIsObscureProvider = StateProvider((ref) => true);

  @override
  void initState() {
    super.initState();
    _openaiApiKeyTextArea.addListener(_onUpdate);
    _googleCloudApiKeyTextArea.addListener(_onUpdate);
    _voicetextApiKeyTextArea.addListener(_onUpdate);
    _voicevoxApiKeyTextArea.addListener(_onUpdate);
    Future(() async {
      await _restoreSettings();
      await _checkStackchan();
    });
  }

  @override
  void dispose() {
    _openaiApiKeyTextArea.dispose();
    _googleCloudApiKeyTextArea.dispose();
    _voicetextApiKeyTextArea.dispose();
    _voicevoxApiKeyTextArea.dispose();
    super.dispose();
  }

  Future<void> _restoreSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _openaiApiKeyTextArea.text = prefs.getString("openaiApiKey") ?? "";
    _googleCloudApiKeyTextArea.text = prefs.getString("googleCloudApiKey") ?? "";
    _voicetextApiKeyTextArea.text = prefs.getString("voicetextApiKey") ?? "";
    _voicevoxApiKeyTextArea.text = prefs.getString("voicevoxApiKey") ?? "";
  }

  Future<void> _onUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("openaiApiKey", _openaiApiKeyTextArea.text.trim());
    await prefs.setString("googleCloudApiKey", _googleCloudApiKeyTextArea.text.trim());
    await prefs.setString("voicetextApiKey", _voicetextApiKeyTextArea.text.trim());
    await prefs.setString("voicevoxApiKey", _voicevoxApiKeyTextArea.text.trim());
  }

  // check existence of apikey setting page
  Future<void> _checkStackchan() async {
    ref.read(_updatingProvider.notifier).state = true;
    ref.read(_statusMessageProvider.notifier).state = "";
    try {
      if (await Stackchan(widget.stackchanConfig.ipAddress).hasApiKeysApi()) {
        ref.read(_initializedProvider.notifier).state = true;
      } else {
        ref.read(_statusMessageProvider.notifier).state = "設定できません。";
      }
    } finally {
      ref.read(_updatingProvider.notifier).state = false;
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
    ref.read(_statusMessageProvider.notifier).state = message;
  }

  Future<void> _testOpenAIApi() async {
    ref.read(_updatingProvider.notifier).state = true;
    ref.read(_statusMessageProvider.notifier).state = "";
    try {
      final res = await OpenAIApi(apiKey: _openaiApiKeyTextArea.text.trim()).testChat("test");
      if (res.statusCode == 200) {
        ref.read(_statusMessageProvider.notifier).state = "OpenAI API を使用できます。";
      } else {
        _showMessageForStatusCode(res);
      }
    } catch (e) {
      ref.read(_statusMessageProvider.notifier).state = "Error: ${e.toString()}";
    } finally {
      ref.read(_updatingProvider.notifier).state = false;
    }
  }

  Future<void> _testGoogleCloudApi() async {
    ref.read(_updatingProvider.notifier).state = true;
    ref.read(_statusMessageProvider.notifier).state = "";
    try {
      final res = await GoogleCloudApi(apiKey: _googleCloudApiKeyTextArea.text.trim()).getSpeechOperations();
      if (res.statusCode == 200) {
        ref.read(_statusMessageProvider.notifier).state = "Google Cloud Speech-to-Text API を使用できます。";
      } else {
        _showMessageForStatusCode(res);
      }
    } catch (e) {
      ref.read(_statusMessageProvider.notifier).state = "Error: ${e.toString()}";
    } finally {
      ref.read(_updatingProvider.notifier).state = false;
    }
  }

  Future<void> _testVoiceTextApi() async {
    ref.read(_updatingProvider.notifier).state = true;
    ref.read(_statusMessageProvider.notifier).state = "";
    try {
      final res = await VoiceTextApi(apiKey: _voicetextApiKeyTextArea.text.trim()).testTts("test");
      if (res.statusCode == 200) {
        ref.read(_statusMessageProvider.notifier).state = "VoiceText API を使用できます。";
      } else {
        _showMessageForStatusCode(res);
      }
    } catch (e) {
      ref.read(_statusMessageProvider.notifier).state = "Error: ${e.toString()}";
    } finally {
      ref.read(_updatingProvider.notifier).state = false;
    }
  }

  Future<void> _testVoicevoxApi() async {
    ref.read(_updatingProvider.notifier).state = true;
    ref.read(_statusMessageProvider.notifier).state = "";
    try {
      final result = await VoicevoxApi(apiKey: _voicevoxApiKeyTextArea.text.trim()).getKeyPoints();
      if (result != null && result > 0) {
        ref.read(_statusMessageProvider.notifier).state = "VOICEVOX API を使用できます。(残: $result ポイント)";
      } else {
        ref.read(_statusMessageProvider.notifier).state = "VOICEVOX API を使用できません。";
      }
    } catch (e) {
      ref.read(_statusMessageProvider.notifier).state = "Error: ${e.toString()}";
    } finally {
      ref.read(_updatingProvider.notifier).state = false;
    }
  }

  Future<void> _updateApiKeys() async {
    if (ref.read(_updatingProvider)) return;

    FocusManager.instance.primaryFocus?.unfocus();
    final openaiApiKey = _openaiApiKeyTextArea.text.trim();
    final googleCloudApiKey = _googleCloudApiKeyTextArea.text.trim();
    final voicetextApiKey = _voicetextApiKeyTextArea.text.trim();
    final voicevoxApiKey = _voicevoxApiKeyTextArea.text.trim();
    ref.read(_updatingProvider.notifier).state = true;
    ref.read(_statusMessageProvider.notifier).state = "";
    try {
      await Stackchan(widget.stackchanConfig.ipAddress).setApiKeys(
          openai: openaiApiKey, sttapikey: googleCloudApiKey, voicetext: voicetextApiKey, voicevox: voicevoxApiKey);
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
    final openaiApiKeyIsObscure = ref.watch(_openaiApiKeyIsObscureProvider);
    final googleCloudApiKeyIsObscure = ref.watch(_googleCloudApiKeyIsObscureProvider);
    final voicetextApiKeyIsObscure = ref.watch(_voicetextApiKeyIsObscureProvider);
    final voicevoxApiKeyIsObscure = ref.watch(_voicevoxApiKeyIsObscureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("API 設定"),
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
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            "OpenAI",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "ｽﾀｯｸﾁｬﾝ と会話するために、",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
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
                                text: " から ChatGPT を使用するための API Key を発行して、設定してください。",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: TextFormField(
                            obscureText: openaiApiKeyIsObscure,
                            decoration: InputDecoration(
                              labelText: "OpenAI API Key",
                              suffixIcon: IconButton(
                                icon: Icon(openaiApiKeyIsObscure ? Icons.visibility_off : Icons.visibility),
                                onPressed: () {
                                  ref.read(_openaiApiKeyIsObscureProvider.notifier).update((state) => !state);
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
                            child: const Text("有効性を確認"),
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            "Google Cloud API",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "音声による入力をおこなうには、",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              TextSpan(
                                text: "Google Cloud",
                                style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.blue),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    launchUrl(Uri.parse("https://cloud.google.com"),
                                        mode: LaunchMode.externalApplication);
                                  },
                              ),
                              TextSpan(
                                text: " から Text-to-Speech API を使用するための API Key を発行して、設定してください。",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: TextFormField(
                            obscureText: googleCloudApiKeyIsObscure,
                            decoration: InputDecoration(
                              labelText: "Google Cloud API Key",
                              suffixIcon: IconButton(
                                icon: Icon(googleCloudApiKeyIsObscure ? Icons.visibility_off : Icons.visibility),
                                onPressed: () {
                                  ref.read(_googleCloudApiKeyIsObscureProvider.notifier).update((state) => !state);
                                },
                              ),
                            ),
                            controller: _googleCloudApiKeyTextArea,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _testGoogleCloudApi,
                            child: const Text("有効性を確認"),
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            "VoiceText",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
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
                                text: " から API Key を発行して、設定してください。",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              TextSpan(
                                text: "★現在無料版の新規登録は停止しています。",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: TextFormField(
                            obscureText: voicetextApiKeyIsObscure,
                            decoration: InputDecoration(
                              labelText: "VoiceText API Key",
                              suffixIcon: IconButton(
                                icon: Icon(voicetextApiKeyIsObscure ? Icons.visibility_off : Icons.visibility),
                                onPressed: () {
                                  ref.read(_voicetextApiKeyIsObscureProvider.notifier).update((state) => !state);
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
                            child: const Text("有効性を確認"),
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            "WEB 版 VOICEVOX",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "音声合成エンジン ",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              TextSpan(
                                text: "WEB 版 VOICEVOX API",
                                style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.blue),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    launchUrl(Uri.parse("https://voicevox.su-shiki.com/su-shikiapis/"),
                                        mode: LaunchMode.externalApplication);
                                  },
                              ),
                              TextSpan(
                                text: " から API Key を発行して、設定してください。",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: TextFormField(
                            obscureText: voicevoxApiKeyIsObscure,
                            decoration: InputDecoration(
                              labelText: "WEB 版 VOICEVOX API Key",
                              suffixIcon: IconButton(
                                icon: Icon(voicevoxApiKeyIsObscure ? Icons.visibility_off : Icons.visibility),
                                onPressed: () {
                                  ref.read(_voicevoxApiKeyIsObscureProvider.notifier).update((state) => !state);
                                },
                              ),
                            ),
                            controller: _voicevoxApiKeyTextArea,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _testVoicevoxApi,
                            child: const Text("有効性を確認"),
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
                      onPressed: (initialized && !updating) ? _updateApiKeys : null,
                      child: const Text("設定"),
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
