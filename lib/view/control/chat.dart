import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../infrastructure/stackchan.dart';
import '../../repository/chat.dart';

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
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge!
                  .copyWith(color: me ? Colors.black : Theme.of(context).colorScheme.onPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  final String stackchanIpAddress;

  const ChatPage(this.stackchanIpAddress, {super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  /// メッセージ表示最大数
  static const int maxMessages = 100;

  /// 設定更新中
  bool _updating = false;

  /// 音声認識中
  bool _listening = false;

  /// 音声認識状態
  String _listeningStatus = "";

  /// メッセージリポジトリ
  final _messageRepository = ChatRepository();

  /// メッセージ履歴
  final List<ChatMessage> _messages = [];

  /// メッセージ入力
  final _textArea = TextEditingController();

  /// 音声認識
  final SpeechToText _speechToText = SpeechToText();

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    // await messageRepository.prepareTestData();
    final savedMessages = await _messageRepository.getMessages(maxMessages);
    setState(() {
      _messages.addAll(savedMessages);
    });
  }

  @override
  void dispose() {
    _textArea.dispose();
    super.dispose();
  }

  void _clearMessages() {
    _messageRepository.clearAll();
    setState(() {
      _messages.clear();
    });
  }

  void _appendMessage(String kind, String text) async {
    final message = ChatMessage(createdAt: DateTime.now(), kind: kind, text: text);
    _messageRepository.append(message);
    setState(() {
      _messages.add(message);
      if (_messages.length > maxMessages) {
        _messages.removeAt(0);
      }
    });
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
      setState(() {
        _listeningStatus = "音声入力中...";
        _listening = true;
      });
    } else {
      _listeningStatus = "音声入力が拒否されました。";
    }
  }

  // 音声入力停止
  Future<void> _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _listening = false;
    });
  }

  // 音声入力結果
  void _resultListener(SpeechRecognitionResult result) {
    debugPrint("resultListener: ${jsonEncode(result)}");
    if (_listening) {
      setState(() {
        _textArea.text = result.recognizedWords;
        _listeningStatus = "";
        if (result.finalResult) {
          _listening = false;
        }
      });
    }
  }

  // 音声入力エラー
  void _errorListener(SpeechRecognitionError error) {
    debugPrint("errorListener: ${jsonEncode(error)}");
    setState(() {
      _listeningStatus = "${error.errorMsg} - ${error.permanent}";
      _listening = false;
    });
  }

  // 音声入力状態
  void _statusListener(String status) {
    debugPrint("statusListener: $status");
    setState(() {
      if (status == "done") {
        _listeningStatus = "";
      } else {
        _listeningStatus = status;
      }
    });
  }

  // ｽﾀｯｸﾁｬﾝ API を呼ぶ
  void _callStackchan() async {
    await _stopListening();
    var prefs = await SharedPreferences.getInstance();
    final voice = prefs.getString("voice");
    try {
      final request = _textArea.text.trim();
      setState(() {
        _textArea.clear();
        _updating = true;
      });
      final stackchan = Stackchan(widget.stackchanIpAddress);
      _appendMessage(ChatMessage.kindRequest, request);
      final reply = await stackchan.chat(request, voice: voice);
      _appendMessage(ChatMessage.kindReply, reply);
    } catch (e) {
      _appendMessage(ChatMessage.kindError, "Error: ${e.toString()}");
    } finally {
      setState(() {
        _updating = false;
      });
    }
  }

  // 入力をクリア
  void _clear() {
    setState(() {
      _textArea.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    _textArea.selection = TextSelection.fromPosition(
      TextPosition(offset: _textArea.text.length),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("ｽﾀｯｸﾁｬﾝ ｺﾝﾈｸﾄ"),
        actions: [
          PopupMenuButton(
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  child: const Text("クリア"),
                  onTap: () {
                    setState(() {
                      _clearMessages();
                    });
                  },
                )
              ];
            },
          )
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(8.0),
                      reverse: true,
                      children: _messages.reversed
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
                    visible: _updating,
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: LinearProgressIndicator(),
                    ),
                  ),
                  Visibility(
                    visible: _listeningStatus.isNotEmpty,
                    child: Text(_listeningStatus),
                  ),
                ],
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
                            icon: _textArea.text.isEmpty
                                ? (_listening ? const Icon(Icons.stop) : const Icon(Icons.mic))
                                : const Icon(Icons.send),
                            onPressed: _updating
                                ? null
                                : (_textArea.text.isEmpty
                                    ? _listening
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
      ),
    );
  }
}
