import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/stackchan.dart';
import '../../infrastructure/voicevox.dart';
import '../../repository/stackchan.dart';

class SettingVoicePage extends ConsumerStatefulWidget {
  const SettingVoicePage(this.stackchanConfigProvider, {super.key});

  final StateProvider<StackchanConfig> stackchanConfigProvider;

  @override
  ConsumerState<SettingVoicePage> createState() => _SettingVoicePageState();
}

class _SettingVoicePageState extends ConsumerState<SettingVoicePage> {
  /// Initialized flag
  final _initializedProvider = StateProvider((ref) => false);

  /// Updating flag
  final _updatingProvider = StateProvider((ref) => false);

  /// Status message
  final _statusMessageProvider = StateProvider((ref) => "");

  /// Selecting voice number
  final _voiceProvider = StateProvider<String?>((ref) => null);

  /// Voice choices
  final _voiceChoicesProvider = StateProvider<Map<String, String>>((ref) => {});

  @override
  void initState() {
    super.initState();
    Future(() async {
      await _initializeVoices();
      await _restoreSettings();
    });
  }

  Future<void> _initializeVoices() async {
    ref.read(_updatingProvider.notifier).state = true;
    final stackchanConfig = ref.read(widget.stackchanConfigProvider);
    final config = stackchanConfig.config;
    final Map<String, String> voiceList = {};
    if (config["ttsService"] == "ttsQuestVoicevox") {
      // TTS QUEST VOICEVOX API
      final speakers = await VoicevoxApi().getSpeakers();
      if (speakers != null) {
        speakers.asMap().forEach((i, e) {
          voiceList[i.toString()] = "No. $i: $e";
        });
      } else {
        // fallback
        for (var i = 0; i <= 66; i++) {
          voiceList[i.toString()] = "No. $i";
        }
      }
    } else {
      // VoiceText Web API
      for (var i = 0; i <= 4; i++) {
        voiceList[i.toString()] = "No. $i";
      }
    }
    ref.read(_voiceChoicesProvider.notifier).state = voiceList;
    ref.read(_initializedProvider.notifier).state = true;
    ref.read(_updatingProvider.notifier).state = false;
  }

  Future<void> _restoreSettings() async {
    final voice = ref.read(widget.stackchanConfigProvider).config["voice"] as String?;
    if (ref.read(_voiceChoicesProvider).containsKey(voice)) {
      ref.read(_voiceProvider.notifier).state = voice;
    }
  }

  Future<void> _test() async {
    ref.read(_updatingProvider.notifier).state = true;
    ref.read(_statusMessageProvider.notifier).state = "";
    try {
      await Stackchan(ref.read(widget.stackchanConfigProvider).ipAddress)
          .speech(AppLocalizations.of(context)!.hello, voice: ref.read(_voiceProvider));
    } catch (e) {
      ref.read(_statusMessageProvider.notifier).state = "Error: ${e.toString()}";
    } finally {
      ref.read(_updatingProvider.notifier).state = false;
    }
  }

  Future<void> _close() async {
    final stackchanConfig = ref.read(widget.stackchanConfigProvider);
    final config = stackchanConfig.config;
    config["voice"] = ref.read(_voiceProvider);
    ref.read(widget.stackchanConfigProvider.notifier).state = stackchanConfig.copyWith(config: config);
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialized = ref.watch(_initializedProvider);
    final updating = ref.watch(_updatingProvider);
    final statusMessage = ref.watch(_statusMessageProvider);
    final voice = ref.watch(_voiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.voiceSettings),
      ),
      body: Column(
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
                          AppLocalizations.of(context)!.voice,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.voiceDescription,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: DropdownButtonFormField<String?>(
                          isExpanded: true,
                          items: <DropdownMenuItem<String>>[
                                DropdownMenuItem(
                                  value: null,
                                  child: Text(AppLocalizations.of(context)!.unspecified),
                                ),
                              ] +
                              ref.watch(_voiceChoicesProvider).entries.map((e) {
                                return DropdownMenuItem(value: e.key, child: Text(e.value));
                              }).toList(),
                          onChanged: (String? value) {
                            ref.read(_voiceProvider.notifier).state = value;
                          },
                          value: voice,
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _test,
                          child: Text(AppLocalizations.of(context)!.tryToListen),
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
                    onPressed: _close,
                    child: Text(AppLocalizations.of(context)!.ok),
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
