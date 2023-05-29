import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/stackchan.dart';
import '../../repository/stackchan.dart';

class SettingVoicePage extends ConsumerStatefulWidget {
  const SettingVoicePage(this.stackchanConfigProvider, {super.key});

  final StateProvider<StackchanConfig> stackchanConfigProvider;

  @override
  ConsumerState<SettingVoicePage> createState() => _SettingVoicePageState();
}

class _SettingVoicePageState extends ConsumerState<SettingVoicePage> {
  /// Updating flag
  final _updatingProvider = StateProvider((ref) => false);

  /// Status message
  final _statusMessageProvider = StateProvider((ref) => "");

  /// Selecting voice number
  final _voiceProvider = StateProvider<String?>((ref) => null);

  @override
  void initState() {
    super.initState();
    Future(() async {
      await _restoreSettings();
    });
  }

  Future<void> _restoreSettings() async {
    ref.read(_voiceProvider.notifier).state = ref.read(widget.stackchanConfigProvider).config["voice"] as String?;
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
                            [for (var i = 1; i <= 60; i++) i].map((i) {
                              return DropdownMenuItem(value: "$i", child: Text("No. $i"));
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
