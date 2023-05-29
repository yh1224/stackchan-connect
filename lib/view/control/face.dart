import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../infrastructure/stackchan.dart';
import '../../repository/stackchan.dart';

class FacePage extends ConsumerStatefulWidget {
  const FacePage(this.stackchanConfig, {super.key});

  final StackchanConfig stackchanConfig;

  @override
  ConsumerState<FacePage> createState() => _FacePageState();
}

class _FacePageState extends ConsumerState<FacePage> {
  /// Initialized flag
  final _initializedProvider = StateProvider((ref) => false);

  /// Updating flag
  final _updatingProvider = StateProvider((ref) => false);

  /// Status message
  final _statusMessageProvider = StateProvider((ref) => "");

  @override
  void initState() {
    super.initState();
    Future(() async {
      await _checkStackchan();
    });
  }

  // check existence of face setting API
  Future<void> _checkStackchan() async {
    ref.read(_updatingProvider.notifier).state = true;
    ref.read(_statusMessageProvider.notifier).state = "";
    try {
      if (await Stackchan(widget.stackchanConfig.ipAddress).hasFaceApi()) {
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

  Future<void> _updateFace(int value) async {
    if (ref.read(_updatingProvider)) return;

    ref.read(_updatingProvider.notifier).state = true;
    ref.read(_statusMessageProvider.notifier).state = "";
    try {
      await Stackchan(widget.stackchanConfig.ipAddress).face("$value");
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
      body: Column(
        children: [
          Expanded(
            child: Visibility(
              visible: initialized,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Card(
                        child: ListTile(
                          title: Text("😐 ${AppLocalizations.of(context)!.neutralFace}",
                              style: Theme.of(context).textTheme.titleLarge),
                          // subtitle: Text("Neutral Face", style: Theme.of(context).textTheme.titleMedium),
                          onTap: () {
                            _updateFace(0);
                          },
                        ),
                      ),
                      Card(
                        child: ListTile(
                          title: Text("😘 ${AppLocalizations.of(context)!.neutralFace}",
                              style: Theme.of(context).textTheme.titleLarge),
                          // subtitle: Text("Happy Face", style: Theme.of(context).textTheme.titleMedium),
                          onTap: () {
                            _updateFace(1);
                          },
                        ),
                      ),
                      Card(
                        child: ListTile(
                          title: Text("😪 ${AppLocalizations.of(context)!.sleepyFace}",
                              style: Theme.of(context).textTheme.titleLarge),
                          // subtitle: Text("Sleepy Face", style: Theme.of(context).textTheme.titleMedium),
                          onTap: () {
                            _updateFace(2);
                          },
                        ),
                      ),
                      Card(
                        child: ListTile(
                          title: Text("😥 ${AppLocalizations.of(context)!.doubtFace}",
                              style: Theme.of(context).textTheme.titleLarge),
                          // subtitle: Text("Doubt Face", style: Theme.of(context).textTheme.titleMedium),
                          onTap: () {
                            _updateFace(3);
                          },
                        ),
                      ),
                      Card(
                        child: ListTile(
                          title: Text("😢 ${AppLocalizations.of(context)!.sadFace}",
                              style: Theme.of(context).textTheme.titleLarge),
                          // subtitle: Text("Sad Face", style: Theme.of(context).textTheme.titleMedium),
                          onTap: () {
                            _updateFace(4);
                          },
                        ),
                      ),
                      Card(
                        child: ListTile(
                          title: Text("😠 ${AppLocalizations.of(context)!.angryFace}",
                              style: Theme.of(context).textTheme.titleLarge),
                          // subtitle: Text("Angry Face", style: Theme.of(context).textTheme.titleMedium),
                          onTap: () {
                            _updateFace(5);
                          },
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
