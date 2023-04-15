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
  const ChatPage(this.stackchanIpAddress, {super.key});

  final String stackchanIpAddress;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  /// メッセージ表示最大数
  static const int maxMessages = 100;

  /// 設定更新中
  bool updating = false;

  /// 音声認識中
  bool listening = false;

  /// 音声認識状態
  String listeningStatus = "";

  /// メッセージリポジトリ
  final messageRepository = ChatRepository();

  /// メッセージ履歴
  List<ChatMessage> messages = [];

  /// 選択中のモード
  String mode = "chat";

  /// 選択中の声色
  String voice = "1";

  /// メッセージ入力
  final textArea = TextEditingController();

  /// 音声認識
  final SpeechToText speechToText = SpeechToText();

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    final savedMessages = await messageRepository.getMessages(maxMessages);
    setState(() {
      messages.addAll(savedMessages);
    });
  }

  @override
  void dispose() {
    textArea.dispose();
    super.dispose();
  }

  void clearMessages() {
    messageRepository.clearAll();
    setState(() {
      messages.clear();
    });
  }

  void appendMessage(String kind, String text) async {
    final message = ChatMessage(createdAt: DateTime.now(), kind: kind, text: text);
    messageRepository.append(message);
    setState(() {
      messages.add(message);
      if (messages.length > maxMessages) {
        messages.removeAt(0);
      }
    });
  }

  // 音声入力開始
  Future<void> startListening() async {
    // Unfocus
    final FocusScopeNode currentScope = FocusScope.of(context);
    if (!currentScope.hasPrimaryFocus && currentScope.hasFocus) {
      FocusManager.instance.primaryFocus!.unfocus();
    }

    bool available = await speechToText.initialize(
      onError: errorListener,
      onStatus: statusListener,
    );
    if (available) {
      speechToText.listen(onResult: resultListener);
      setState(() {
        listeningStatus = "音声入力中...";
        listening = true;
      });
    } else {
      listeningStatus = "音声入力が拒否されました。";
    }
  }

  // 音声入力停止
  Future<void> stopListening() async {
    await speechToText.stop();
    setState(() {
      listening = false;
    });
  }

  // 音声入力結果
  void resultListener(SpeechRecognitionResult result) {
    debugPrint("resultListener: ${jsonEncode(result)}");
    if (listening) {
      setState(() {
        textArea.text = result.recognizedWords;
        listeningStatus = "";
        if (result.finalResult) {
          listening = false;
        }
      });
    }
  }

  // 音声入力エラー
  void errorListener(SpeechRecognitionError error) {
    debugPrint("errorListener: ${jsonEncode(error)}");
    setState(() {
      listeningStatus = "${error.errorMsg} - ${error.permanent}";
      listening = false;
    });
  }

  // 音声入力状態
  void statusListener(String status) {
    debugPrint("statusListener: $status");
    setState(() {
      if (status == "done") {
        listeningStatus = "";
      } else {
        listeningStatus = status;
      }
    });
  }

  // ｽﾀｯｸﾁｬﾝ API を呼ぶ
  void callStackchan() async {
    await stopListening();
    var prefs = await SharedPreferences.getInstance();
    try {
      final request = textArea.text.trim();
      setState(() {
        textArea.clear();
        updating = true;
      });
      final stackchan = Stackchan(widget.stackchanIpAddress);
      String reply;
      if (mode == "chat") {
        appendMessage(ChatMessage.kindRequest, request);
        reply = await stackchan.chat(request, voice: voice);
        appendMessage(ChatMessage.kindReply, reply);
      } else {
        // echo
        reply = await stackchan.speech(request, voice: voice);
        appendMessage(ChatMessage.kindReply, request);
      }
    } catch (e) {
      appendMessage(ChatMessage.kindError, "Error: ${e.toString()}");
    } finally {
      setState(() {
        updating = false;
      });
    }
  }

  // 入力をクリア
  void clear() {
    setState(() {
      textArea.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    textArea.selection = TextSelection.fromPosition(
      TextPosition(offset: textArea.text.length),
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
                      clearMessages();
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
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: DropdownButton(
                            items: const [
                              DropdownMenuItem(
                                value: "speech",
                                child: Text("しゃべって"),
                              ),
                              DropdownMenuItem(
                                value: "chat",
                                child: Text("会話する"),
                              ),
                            ],
                            onChanged: (String? value) {
                              setState(() {
                                if (value != null) {
                                  mode = value;
                                }
                              });
                            },
                            value: mode,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: DropdownButton(
                            items: const [
                              DropdownMenuItem(
                                value: "0",
                                child: Text("声: 0"),
                              ),
                              DropdownMenuItem(
                                value: "1",
                                child: Text("声: 1"),
                              ),
                              DropdownMenuItem(
                                value: "2",
                                child: Text("声: 2"),
                              ),
                              DropdownMenuItem(
                                value: "3",
                                child: Text("声: 3"),
                              ),
                              DropdownMenuItem(
                                value: "4",
                                child: Text("声: 4"),
                              ),
                            ],
                            onChanged: (String? value) {
                              setState(() {
                                if (value != null) {
                                  voice = value;
                                }
                              });
                            },
                            value: voice,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Flexible(
                        child: Focus(
                          onFocusChange: (hasFocus) {
                            if (hasFocus) {
                              stopListening();
                            }
                          },
                          child: TextField(
                            controller: textArea,
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      ValueListenableBuilder(
                        valueListenable: textArea,
                        builder: (context, value, child) {
                          return IconButton(
                            color: Theme.of(context).colorScheme.primary,
                            icon: textArea.text.isEmpty
                                ? (listening ? const Icon(Icons.stop) : const Icon(Icons.mic))
                                : const Icon(Icons.send),
                            onPressed: updating
                                ? null
                                : (textArea.text.isEmpty
                                    ? listening
                                        ? stopListening
                                        : startListening
                                    : callStackchan),
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
