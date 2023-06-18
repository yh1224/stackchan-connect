import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../repository/stackchan.dart';
import 'apikey.dart';
import 'role.dart';
import 'voice.dart';
import 'volume.dart';

class SettingMenuPage extends ConsumerStatefulWidget {
  const SettingMenuPage(this.stackchanConfigProvider, {super.key});

  final StateProvider<StackchanConfig> stackchanConfigProvider;

  @override
  ConsumerState<SettingMenuPage> createState() => _SettingMenuPageState();
}

class _SettingMenuPageState extends ConsumerState<SettingMenuPage> {
  final _stackchanRepository = StackchanRepository();

  @override
  Widget build(BuildContext context) {
    final stackchanConfig = ref.watch(widget.stackchanConfigProvider);
    final ttsService = stackchanConfig.config["ttsService"];

    ref.listen(widget.stackchanConfigProvider, (_, next) {
      _stackchanRepository.save(next);
    });

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Visibility(
              visible: stackchanConfig.ipAddress.isNotEmpty,
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      AppLocalizations.of(context)!.apiSettings,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    subtitle: Text(AppLocalizations.of(context)!.apiSettingsDescription),
                    tileColor: Colors.white,
                    leading: const Icon(Icons.key),
                    onTap: () {
                      Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => SettingApiKeyPage(widget.stackchanConfigProvider)));
                    },
                  ),
                  ListTile(
                    title: Text(
                      AppLocalizations.of(context)!.roleSettings,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    subtitle: Text(AppLocalizations.of(context)!.roleSettingsDescription),
                    tileColor: Colors.white,
                    leading: const Icon(Icons.person),
                    onTap: () {
                      Navigator.of(context)
                          .push(MaterialPageRoute(builder: (context) => SettingRolePage(stackchanConfig)));
                    },
                  ),
                  ListTile(
                    title: Text(
                      AppLocalizations.of(context)!.volumeSettings,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    subtitle: Text(AppLocalizations.of(context)!.volumeSettingsDescription),
                    tileColor: Colors.white,
                    leading: const Icon(Icons.volume_up),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => SettingStackchanPage(widget.stackchanConfigProvider)));
                    },
                  ),
                  Visibility(
                    visible: ttsService == "voicetext" || ttsService == "ttsQuestVoicevox",
                    child: ListTile(
                      title: Text(
                        AppLocalizations.of(context)!.voiceSettings,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      subtitle: Text(AppLocalizations.of(context)!.voiceSettingsDescription),
                      tileColor: Colors.white,
                      leading: const Icon(Icons.record_voice_over),
                      onTap: () {
                        Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => SettingVoicePage(widget.stackchanConfigProvider)));
                      },
                    ),
                  ),
                  ListTile(
                    title: Text(
                      AppLocalizations.of(context)!.openStackchan,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    subtitle: Text(AppLocalizations.of(context)!.openStackchanDescription),
                    tileColor: Colors.white,
                    leading: const Icon(Icons.open_in_browser),
                    onTap: () {
                      launchUrl(Uri.http(stackchanConfig.ipAddress), mode: LaunchMode.externalApplication);
                    },
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
