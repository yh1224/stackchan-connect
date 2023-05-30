import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
  const SettingApiKeyPage(this.stackchanConfigProvider, {super.key});

  final StateProvider<StackchanConfig> stackchanConfigProvider;

  @override
  ConsumerState<SettingApiKeyPage> createState() => _SettingApiKeyPageState();
}

class _SettingApiKeyPageState extends ConsumerState<SettingApiKeyPage> {
  /// Initialized flag
  final _initializedProvider = StateProvider((ref) => false);

  /// Updating flag
  final _updatingProvider = StateProvider((ref) => false);

  /// Status message
  final _statusMessageProvider = StateProvider((ref) => "");

  /// OpenAI API Key input
  final _openaiApiKeyTextArea = TextEditingController();
  final _openaiApiKeyIsObscureProvider = StateProvider((ref) => true);

  /// Google Cloud API Key input
  final _googleCloudApiKeyTextArea = TextEditingController();
  final _googleCloudApiKeyIsObscureProvider = StateProvider((ref) => true);

  /// VoiceText API Key input
  final _voicetextApiKeyTextArea = TextEditingController();
  final _voicetextApiKeyIsObscureProvider = StateProvider((ref) => true);

  /// Voicevox API Key input
  final _voicevoxApiKeyTextArea = TextEditingController();
  final _voicevoxApiKeyIsObscureProvider = StateProvider((ref) => true);

  /// Selected service for STT
  final _sttServiceProvider = StateProvider((ref) => "whisper");

  /// Selected service for TTS
  final _ttsServiceProvider = StateProvider((ref) => "googleTranslation");

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
    ref.read(_sttServiceProvider.notifier).state =
        (ref.read(widget.stackchanConfigProvider).config["sttService"] ?? "whisper") as String;
    ref.read(_ttsServiceProvider.notifier).state =
        (ref.read(widget.stackchanConfigProvider).config["ttsService"] ?? "googleTranslationTts") as String;
  }

  Future<void> _onUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("openaiApiKey", _openaiApiKeyTextArea.text.trim());
    await prefs.setString("googleCloudApiKey", _googleCloudApiKeyTextArea.text.trim());
    await prefs.setString("voicetextApiKey", _voicetextApiKeyTextArea.text.trim());
    await prefs.setString("voicevoxApiKey", _voicevoxApiKeyTextArea.text.trim());
  }

  // check existence of apikey setting API
  Future<void> _checkStackchan() async {
    ref.read(_updatingProvider.notifier).state = true;
    ref.read(_statusMessageProvider.notifier).state = "";
    try {
      if (await Stackchan(ref.read(widget.stackchanConfigProvider).ipAddress).hasApiKeysApi()) {
        ref.read(_initializedProvider.notifier).state = true;
      } else {
        if (context.mounted) {
          ref.read(_statusMessageProvider.notifier).state = AppLocalizations.of(context)!.unsupportedSettings;
        }
      }
    } finally {
      ref.read(_updatingProvider.notifier).state = false;
    }
  }

  void _showMessageForStatusCode(BuildContext context, Response res) {
    Map<int, String> statusMessages = {
      401: AppLocalizations.of(context)!.error401,
      403: AppLocalizations.of(context)!.error401,
      429: AppLocalizations.of(context)!.error401,
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
        if (context.mounted) {
          ref.read(_statusMessageProvider.notifier).state = AppLocalizations.of(context)!.openaiApiKeyIsValid;
        }
      } else {
        if (context.mounted) _showMessageForStatusCode(context, res);
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
        if (context.mounted) {
          ref.read(_statusMessageProvider.notifier).state =
              AppLocalizations.of(context)!.googleCloudApiKeyIsValidForStt;
        }
      } else {
        if (context.mounted) _showMessageForStatusCode(context, res);
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
        if (context.mounted) {
          ref.read(_statusMessageProvider.notifier).state = AppLocalizations.of(context)!.voiceTextApiKeyIsValid;
        }
      } else {
        if (context.mounted) _showMessageForStatusCode(context, res);
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
        if (context.mounted) {
          ref.read(_statusMessageProvider.notifier).state =
              AppLocalizations.of(context)!.ttsQuestVoicevoxApiKeyIsValid(result);
        }
      } else {
        if (context.mounted) {
          ref.read(_statusMessageProvider.notifier).state =
              AppLocalizations.of(context)!.ttsQuestVoicevoxApiKeyIsInvalid;
        }
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
    final sttService = ref.read(_sttServiceProvider);
    final ttsService = ref.read(_ttsServiceProvider);
    final openaiApiKey = _openaiApiKeyTextArea.text.trim();
    String sttApiKey;
    if (sttService == "googleCloudStt") {
      sttApiKey = _googleCloudApiKeyTextArea.text.trim();
    } else {
      sttApiKey = openaiApiKey;
    }
    String voicetextApiKey = "";
    String voicevoxApiKey = "";
    if (ttsService == "voicetext") {
      voicetextApiKey = _voicetextApiKeyTextArea.text.trim();
    } else if (ttsService == "ttsQuestVoicevox") {
      voicevoxApiKey = _voicevoxApiKeyTextArea.text.trim();
    }
    ref.read(_updatingProvider.notifier).state = true;
    ref.read(_statusMessageProvider.notifier).state = "";
    try {
      await Stackchan(ref.read(widget.stackchanConfigProvider).ipAddress)
          .setApiKeys(openai: openaiApiKey, sttapikey: sttApiKey, voicetext: voicetextApiKey, voicevox: voicevoxApiKey);
      if (context.mounted) {
        ref.read(_statusMessageProvider.notifier).state = AppLocalizations.of(context)!.applySettingsSuccess;
      }
    } catch (e) {
      ref.read(_statusMessageProvider.notifier).state = "Error: ${e.toString()}";
    } finally {
      ref.read(_updatingProvider.notifier).state = false;
    }
    final stackchanConfig = ref.read(widget.stackchanConfigProvider);
    final config = stackchanConfig.config;
    config["sttService"] = ref.read(_sttServiceProvider);
    config["ttsService"] = ref.read(_ttsServiceProvider);
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
        title: Text(AppLocalizations.of(context)!.apiSettings),
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
                            AppLocalizations.of(context)!.sttService,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(AppLocalizations.of(context)!.sttServiceDescription),
                        ),
                        DropdownButtonFormField<String?>(
                          isExpanded: true,
                          items: [
                            DropdownMenuItem(
                              value: "whisper",
                              child: Text(AppLocalizations.of(context)!.openAiWhisperApi),
                            ),
                            DropdownMenuItem(
                              value: "googleCloudStt",
                              child: Text(AppLocalizations.of(context)!.googleCloudSttApi),
                            ),
                          ],
                          onChanged: (String? value) {
                            ref.read(_sttServiceProvider.notifier).state = value!;
                          },
                          value: ref.watch(_sttServiceProvider),
                        ),
                        const SizedBox(height: 8.0),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            AppLocalizations.of(context)!.ttsService,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(AppLocalizations.of(context)!.ttsServiceDescription),
                        ),
                        DropdownButtonFormField<String?>(
                          isExpanded: true,
                          items: [
                            DropdownMenuItem(
                              value: "googleTranslationTts",
                              child: Text(AppLocalizations.of(context)!.googleTranslationTtsApi),
                            ),
                            DropdownMenuItem(
                              value: "voicetext",
                              child: Text(AppLocalizations.of(context)!.voicetextApi),
                            ),
                            DropdownMenuItem(
                              value: "ttsQuestVoicevox",
                              child: Text(AppLocalizations.of(context)!.ttsQuestVoicevoxApi),
                            ),
                          ],
                          onChanged: (String? value) {
                            ref.read(_ttsServiceProvider.notifier).state = value!;
                          },
                          value: ref.watch(_ttsServiceProvider),
                        ),
                        const SizedBox(height: 20.0),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            AppLocalizations.of(context)!.openAi,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "${AppLocalizations.of(context)!.openAiApiDescriptionPrefix} ",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              TextSpan(
                                text: AppLocalizations.of(context)!.openAi,
                                style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.blue),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    launchUrl(Uri.parse("https://platform.openai.com"),
                                        mode: LaunchMode.externalApplication);
                                  },
                              ),
                              TextSpan(
                                text: " ${AppLocalizations.of(context)!.openAiApiDescriptionSuffix}",
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
                              labelText: AppLocalizations.of(context)!.openAiApiKey,
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
                            child: Text(AppLocalizations.of(context)!.checkValidity),
                          ),
                        ),
                        Visibility(
                          visible: ref.watch(_sttServiceProvider) == "googleCloudStt",
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20.0),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(
                                  AppLocalizations.of(context)!.googleCloud,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "${AppLocalizations.of(context)!.googleCloudApiDescriptionPrefix} ",
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    TextSpan(
                                      text: AppLocalizations.of(context)!.googleCloud,
                                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.blue),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          launchUrl(Uri.parse("https://cloud.google.com"),
                                              mode: LaunchMode.externalApplication);
                                        },
                                    ),
                                    TextSpan(
                                      text: " ${AppLocalizations.of(context)!.googleCloudApiDescriptionSuffix}",
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
                                    labelText: AppLocalizations.of(context)!.googleCloudApiKey,
                                    suffixIcon: IconButton(
                                      icon: Icon(googleCloudApiKeyIsObscure ? Icons.visibility_off : Icons.visibility),
                                      onPressed: () {
                                        ref
                                            .read(_googleCloudApiKeyIsObscureProvider.notifier)
                                            .update((state) => !state);
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
                                  child: Text(AppLocalizations.of(context)!.checkValidity),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Visibility(
                          visible: ref.watch(_ttsServiceProvider) == "voicetext",
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20.0),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(
                                  AppLocalizations.of(context)!.voicetextApi,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "${AppLocalizations.of(context)!.voicetextApiDescriptionPrefix} ",
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    TextSpan(
                                      text: AppLocalizations.of(context)!.voicetextApi,
                                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.blue),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          launchUrl(Uri.parse("https://cloud.voicetext.jp"),
                                              mode: LaunchMode.externalApplication);
                                        },
                                    ),
                                    TextSpan(
                                      text: " ${AppLocalizations.of(context)!.voicetextApiDescriptionSuffix}",
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
                                    labelText: AppLocalizations.of(context)!.voicetextApiKey,
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
                                  child: Text(AppLocalizations.of(context)!.checkValidity),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Visibility(
                          visible: ref.watch(_ttsServiceProvider) == "ttsQuestVoicevox",
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20.0),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(
                                  AppLocalizations.of(context)!.ttsQuestVoicevoxApi,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "${AppLocalizations.of(context)!.ttsQuestVoicevoxApiDescriptionPrefix} ",
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    TextSpan(
                                      text: AppLocalizations.of(context)!.ttsQuestVoicevoxApi,
                                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.blue),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          launchUrl(Uri.parse("https://voicevox.su-shiki.com/su-shikiapis/"),
                                              mode: LaunchMode.externalApplication);
                                        },
                                    ),
                                    TextSpan(
                                      text: " ${AppLocalizations.of(context)!.ttsQuestVoicevoxApiDescriptionSuffix}",
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
                                    labelText: AppLocalizations.of(context)!.ttsQuestVoicevoxApiKey,
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
                                  child: Text(AppLocalizations.of(context)!.checkValidity),
                                ),
                              ),
                            ],
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
                      child: Text(AppLocalizations.of(context)!.applySettings),
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
