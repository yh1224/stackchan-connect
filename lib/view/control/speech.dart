import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/stackchan.dart';
import '../../repository/speech.dart';
import '../../repository/stackchan.dart';

class SpeechPage extends ConsumerStatefulWidget {
  const SpeechPage(this.stackchanConfig, {super.key});

  final StackchanConfig stackchanConfig;

  @override
  ConsumerState<SpeechPage> createState() => _SpeechPageState();
}

class _SpeechPageState extends ConsumerState<SpeechPage> {
  /// Max number of messages to show
  static const int maxMessages = 100;

  /// Message repository
  final _speechRepository = SpeechRepository();

  /// Message input
  final _textArea = TextEditingController();

  /// Updating flag
  final _updatingProvider = StateProvider((ref) => false);

  /// Status message
  final _statusMessageProvider = StateProvider((ref) => "");

  /// Message history
  final _messagesProvider = StateProvider<List<SpeechMessage>>((ref) => []);

  /// Tapped position
  Offset? _tapPosition;

  @override
  void initState() {
    super.initState();
    Future(() async {
      await _init();
    });
  }

  Future<void> _init() async {
    final messages = await _speechRepository.getMessages(maxMessages);
    ref.read(_messagesProvider.notifier).state = messages;
  }

  @override
  void dispose() {
    _textArea.dispose();
    super.dispose();
  }

  Future<void> _appendMessage(String text) async {
    final message = SpeechMessage(createdAt: DateTime.now(), text: text);
    _speechRepository.append(message);
    final messages = ref.read(_messagesProvider);
    messages.add(message);
    ref.read(_messagesProvider.notifier).state = List.from(messages);
  }

  Future<void> _removeMessage(SpeechMessage message) async {
    _speechRepository.remove(message);
    final messages = ref.read(_messagesProvider);
    messages.remove(message);
    ref.read(_messagesProvider.notifier).state = List.from(messages);
  }

  Future<void> _speech(String message, bool append) async {
    if (append) {
      _appendMessage(message);
    }
    final voice = widget.stackchanConfig.config["voice"] as String?;
    ref.read(_statusMessageProvider.notifier).state = "";
    ref.read(_updatingProvider.notifier).state = true;
    try {
      final stackchan = Stackchan(widget.stackchanConfig.ipAddress);
      await stackchan.speech(message, voice: voice);
    } catch (e) {
      ref.read(_statusMessageProvider.notifier).state = "Error: ${e.toString()}";
    } finally {
      ref.read(_updatingProvider.notifier).state = false;
    }
  }

  void _getTapPosition(TapDownDetails tapPosition) {
    final RenderBox referenceBox = context.findRenderObject() as RenderBox;
    _tapPosition = referenceBox.globalToLocal(tapPosition.globalPosition);
  }

  @override
  Widget build(BuildContext context) {
    _textArea.selection = TextSelection.fromPosition(
      TextPosition(offset: _textArea.text.length),
    );

    final updating = ref.watch(_updatingProvider);
    final statusMessage = ref.watch(_statusMessageProvider);
    final messages = ref.watch(_messagesProvider);

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView(
                  children: messages
                      .map((m) => Card(
                            child: GestureDetector(
                              onTapDown: _getTapPosition,
                              child: ListTile(
                                onTap: () {
                                  _speech(m.text, false);
                                },
                                onLongPress: () async {
                                  HapticFeedback.mediumImpact();
                                  if (_tapPosition == null) return;
                                  final result = await showMenu(
                                    context: context,
                                    position: RelativeRect.fromLTRB(_tapPosition!.dx, _tapPosition!.dy, 0, 0),
                                    items: [
                                      PopupMenuItem(
                                        value: "remove",
                                        child: Text(AppLocalizations.of(context)!.delete),
                                      ),
                                    ],
                                  );
                                  if (result == "remove") {
                                    _removeMessage(m);
                                  }
                                },
                                title: Text(m.text),
                              ),
                            ),
                          ))
                      .toList(),
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
                    padding: EdgeInsets.all(8.0),
                    child: LinearProgressIndicator(),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textArea,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                      ),
                    ),
                    ValueListenableBuilder(
                      valueListenable: _textArea,
                      builder: (context, value, child) {
                        return IconButton(
                          color: Theme.of(context).colorScheme.primary,
                          icon: const Icon(Icons.send),
                          onPressed: updating || _textArea.text.trim().isEmpty
                              ? null
                              : () {
                                  final message = _textArea.text.trim();
                                  _textArea.clear();
                                  _speech(message, true);
                                },
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
