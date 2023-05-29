import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../infrastructure/stackchan.dart';
import '../../repository/chat.dart';
import '../../repository/stackchan.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    Key? key,
    required this.dateTime,
    required this.text,
    required this.me,
  }) : super(key: key);
  final DateTime dateTime;
  final String text;
  final bool me;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(me ? 32.0 : 8.0, 4, me ? 8.0 : 32.0, 4),
      child: Align(
        alignment: me ? Alignment.centerRight : Alignment.centerLeft,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: me ? Colors.green[100] : Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.black),
              ),
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: text));
                Fluttertoast.showToast(msg: AppLocalizations.of(context)!.copiedToClipboard);
              },
            ),
          ),
        ),
      ),
    );
  }
}

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage(this.stackchanConfig, {super.key});

  final StackchanConfig stackchanConfig;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  /// Max number of messages to show
  static const int maxMessages = 100;

  /// Message repository
  final _messageRepository = ChatRepository();

  /// Message input
  final _textArea = TextEditingController();

  /// Speech recognizer
  final SpeechToText _speechToText = SpeechToText();

  /// Updating flag
  final _updatingProvider = StateProvider((ref) => false);

  /// Listening flag
  final _listeningProvider = StateProvider((ref) => false);

  /// Listening status
  final _listeningStatusProvider = StateProvider((ref) => "");

  /// Message history
  final _messagesProvider = StateProvider<List<ChatMessage>>((ref) => []);

  @override
  void initState() {
    super.initState();
    Future(() async {
      await _init();
    });
  }

  Future<void> _init() async {
    // await messageRepository.prepareTestData();
    final messages = await _messageRepository.getMessages(widget.stackchanConfig.id!, maxMessages);
    ref.read(_messagesProvider.notifier).state = messages;
  }

  @override
  void dispose() {
    _textArea.dispose();
    super.dispose();
  }

  Future<void> _appendMessage(String kind, String text) async {
    final message = ChatMessage(createdAt: DateTime.now(), kind: kind, text: text);
    _messageRepository.append(widget.stackchanConfig.id!, message);
    final messages = ref.read(_messagesProvider);
    if (messages.length >= maxMessages) {
      messages.removeAt(0);
    }
    messages.add(message);
    ref.read(_messagesProvider.notifier).state = List.from(messages);
  }

  Future<void> _startListening() async {
    // Unfocus
    final FocusScopeNode currentScope = FocusScope.of(context);
    if (!currentScope.hasPrimaryFocus && currentScope.hasFocus) {
      FocusManager.instance.primaryFocus!.unfocus();
    }

    bool available = await _speechToText.initialize(
      onError: _errorListener,
      onStatus: _statusListener,
    );
    if (available) {
      _speechToText.listen(onResult: _resultListener);
      if (context.mounted) {
        ref.read(_listeningStatusProvider.notifier).state = AppLocalizations.of(context)!.listeningSpeech;
      }
      ref.read(_listeningProvider.notifier).state = true;
    } else {
      if (context.mounted) {
        ref.read(_listeningStatusProvider.notifier).state = AppLocalizations.of(context)!.listeningSpeechRejected;
      }
    }
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    ref.read(_listeningProvider.notifier).state = false;
  }

  /// Callback on listening result
  void _resultListener(SpeechRecognitionResult result) {
    debugPrint("resultListener: ${jsonEncode(result)}");
    if (ref.read(_listeningProvider)) {
      _textArea.text = result.recognizedWords;
      ref.read(_listeningStatusProvider.notifier).state = "";
      if (result.finalResult) {
        ref.read(_listeningProvider.notifier).state = false;
      }
    }
  }

  /// Callback on listening error
  void _errorListener(SpeechRecognitionError error) {
    debugPrint("errorListener: ${jsonEncode(error)}");
    ref.read(_listeningStatusProvider.notifier).state = "${error.errorMsg} - ${error.permanent}";
    ref.read(_listeningProvider.notifier).state = false;
  }

  /// Callback on listening status
  void _statusListener(String status) {
    debugPrint("statusListener: $status");
    if (status == "done") {
      ref.read(_listeningStatusProvider.notifier).state = "";
    } else {
      ref.read(_listeningStatusProvider.notifier).state = status;
    }
  }

  Future<void> _callStackchan() async {
    await _stopListening();
    final voice = widget.stackchanConfig.config["voice"] as String?;
    try {
      final request = _textArea.text.trim();
      _textArea.clear();
      ref.read(_updatingProvider.notifier).state = true;
      final stackchan = Stackchan(widget.stackchanConfig.ipAddress);
      _appendMessage(ChatMessage.kindRequest, request);
      final reply = await stackchan.chat(request, voice: voice);
      _appendMessage(ChatMessage.kindReply, reply);
    } catch (e) {
      _appendMessage(ChatMessage.kindError, "Error: ${e.toString()}");
    } finally {
      ref.read(_updatingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    _textArea.selection = TextSelection.fromPosition(
      TextPosition(offset: _textArea.text.length),
    );

    final updating = ref.watch(_updatingProvider);
    final listening = ref.watch(_listeningProvider);
    final listeningStatus = ref.watch(_listeningStatusProvider);
    final messages = ref.watch(_messagesProvider);

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(8.0),
                      reverse: true,
                      children: messages.reversed
                          .map((r) => r.kind == ChatMessage.kindError
                              ? Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    r.text,
                                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                                  ),
                                )
                              : ChatBubble(
                                  dateTime: r.createdAt,
                                  text: r.text,
                                  me: r.kind == ChatMessage.kindRequest,
                                ))
                          .toList(),
                    ),
                  ),
                  Visibility(
                    visible: updating,
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: LinearProgressIndicator(),
                    ),
                  ),
                  Visibility(
                    visible: listeningStatus.isNotEmpty,
                    child: Text(listeningStatus),
                  ),
                ],
              ),
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Flexible(
                      child: Focus(
                        onFocusChange: (hasFocus) {
                          if (hasFocus) {
                            _stopListening();
                          }
                        },
                        child: TextField(
                          controller: _textArea,
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                        ),
                      ),
                    ),
                    ValueListenableBuilder(
                      valueListenable: _textArea,
                      builder: (context, value, child) {
                        return IconButton(
                          color: Theme.of(context).colorScheme.primary,
                          icon: _textArea.text.trim().isEmpty
                              ? (listening ? const Icon(Icons.stop) : const Icon(Icons.mic))
                              : const Icon(Icons.send),
                          onPressed: updating
                              ? null
                              : (_textArea.text.trim().isEmpty
                                  ? listening
                                      ? _stopListening
                                      : _startListening
                                  : _callStackchan),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
