import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
            color: me ? Colors.grey[300] : Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
              child: Text(
                text,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge!
                    .copyWith(color: me ? Colors.black : Theme.of(context).colorScheme.onPrimary),
              ),
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: text));
                Fluttertoast.showToast(msg: "Copied to clipboard");
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
  /// メッセージ表示最大数
  static const int maxMessages = 100;

  /// メッセージリポジトリ
  final _messageRepository = ChatRepository();

  /// メッセージ入力
  final _textArea = TextEditingController();

  /// 音声認識
  final SpeechToText _speechToText = SpeechToText();

  /// 設定更新中
  final _updatingProvider = StateProvider((ref) => false);

  /// 音声認識中
  final _listeningProvider = StateProvider((ref) => false);

  /// 音声認識状態
  final _listeningStatusProvider = StateProvider((ref) => "");

  /// メッセージ履歴
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

  // 音声入力開始
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
      ref.read(_listeningStatusProvider.notifier).state = "音声入力中...";
      ref.read(_listeningProvider.notifier).state = true;
    } else {
      ref.read(_listeningStatusProvider.notifier).state = "音声入力が拒否されました。";
    }
  }

  // 音声入力停止
  Future<void> _stopListening() async {
    await _speechToText.stop();
    ref.read(_listeningProvider.notifier).state = false;
  }

  // 音声入力結果
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

  // 音声入力エラー
  void _errorListener(SpeechRecognitionError error) {
    debugPrint("errorListener: ${jsonEncode(error)}");
    ref.read(_listeningStatusProvider.notifier).state = "${error.errorMsg} - ${error.permanent}";
    ref.read(_listeningProvider.notifier).state = false;
  }

  // 音声入力状態
  void _statusListener(String status) {
    debugPrint("statusListener: $status");
    if (status == "done") {
      ref.read(_listeningStatusProvider.notifier).state = "";
    } else {
      ref.read(_listeningStatusProvider.notifier).state = status;
    }
  }

  // ｽﾀｯｸﾁｬﾝ API を呼ぶ
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
