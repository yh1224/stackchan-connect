import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/stackchan.dart';
import '../../repository/stackchan.dart';

class SettingRolePage extends ConsumerStatefulWidget {
  const SettingRolePage(this.stackchanConfig, {super.key});

  final StackchanConfig stackchanConfig;

  @override
  ConsumerState<SettingRolePage> createState() => _SettingRolePageState();
}

class _SettingRolePageState extends ConsumerState<SettingRolePage> {
  /// Initialized flag
  final _initializedProvider = StateProvider((ref) => false);

  /// Updating flag
  final _updatingProvider = StateProvider((ref) => false);

  /// Status message
  final _statusMessageProvider = StateProvider((ref) => "");

  /// Role input
  final _roleTextAreas = <TextEditingController>[];

  @override
  void initState() {
    super.initState();
    Future(() async {
      await _getRole();
    });
  }

  @override
  void dispose() {
    for (var roleTextArea in _roleTextAreas) {
      roleTextArea.dispose();
    }
    super.dispose();
  }

  // check existence of role setting API
  Future<void> _getRole() async {
    ref.read(_updatingProvider.notifier).state = true;
    ref.read(_statusMessageProvider.notifier).state = "";
    try {
      final roles = await Stackchan(widget.stackchanConfig.ipAddress).getRoles();
      for (var i = 0; i < roles.length; i++) {
        final textEditingController = TextEditingController();
        textEditingController.text = roles[i];
        _roleTextAreas.add(textEditingController);
      }
      if (roles.isEmpty) {
        _roleTextAreas.add(TextEditingController());
      }
      ref.read(_initializedProvider.notifier).state = true;
    } catch (e) {
      ref.read(_statusMessageProvider.notifier).state = AppLocalizations.of(context)!.unsupportedSettings;
    } finally {
      ref.read(_updatingProvider.notifier).state = false;
    }
  }

  Future<void> _updateRoles() async {
    if (ref.read(_updatingProvider)) return;

    FocusManager.instance.primaryFocus?.unfocus();
    ref.read(_updatingProvider.notifier).state = true;
    ref.read(_statusMessageProvider.notifier).state = "";
    final roles =
        _roleTextAreas.map((roleTextArea) => roleTextArea.text.trim()).where((text) => text.isNotEmpty).toList();
    try {
      await Stackchan(widget.stackchanConfig.ipAddress).setRoles(roles);
      if (context.mounted) {
        ref.read(_statusMessageProvider.notifier).state = AppLocalizations.of(context)!.applySettingsSuccess;
      }
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

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.roleSettings),
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
                        Text(
                          AppLocalizations.of(context)!.roleDescription,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: List.generate(
                                _roleTextAreas.length,
                                (int index) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: TextFormField(
                                        maxLines: null,
                                        decoration: InputDecoration(labelText: AppLocalizations.of(context)!.role),
                                        controller: _roleTextAreas[index],
                                        style: Theme.of(context).textTheme.bodyLarge,
                                      ),
                                    )),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _roleTextAreas.add(TextEditingController());
                              });
                            },
                            child: Text(AppLocalizations.of(context)!.add),
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
                      onPressed: (initialized && !updating) ? _updateRoles : null,
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
