import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'control.dart';
import 'messages.dart';

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

class SpeechPage extends StatefulWidget {
  const SpeechPage({super.key});

  @override
  State<SpeechPage> createState() => _SpeechPageState();
}

class _SpeechPageState extends State<SpeechPage> {
  static const int maxMessages = 100;

  final textArea = TextEditingController();
  final messageRepository = MessageRepository();
  List<Message> messages = [];
  String sttStatus = '';
  String mode = 'chat';
  String voice = '1';
  bool isListening = false;
  bool isLoading = false;
  final stt.SpeechToText speech = stt.SpeechToText();

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
    final message = Message(createdAt: DateTime.now(), kind: kind, text: text);
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

    bool available = await speech.initialize(
      onError: errorListener,
      onStatus: statusListener,
    );
    if (available) {
      speech.listen(onResult: resultListener);
      setState(() {
        sttStatus = '音声入力中...';
        isListening = true;
      });
    } else {
      sttStatus = "音声入力が拒否されました。";
    }
  }

  // 音声入力停止
  Future<void> stopListening() async {
    await speech.stop();
    setState(() {
      isListening = false;
    });
  }

  // 音声入力結果
  void resultListener(SpeechRecognitionResult result) {
    debugPrint('resultListener: ${jsonEncode(result)}');
    if (isListening) {
      setState(() {
        textArea.text = result.recognizedWords;
        sttStatus = '';
        if (result.finalResult) {
          isListening = false;
        }
      });
    }
  }

  // 音声入力エラー
  void errorListener(SpeechRecognitionError error) {
    debugPrint('errorListener: ${jsonEncode(error)}');
    setState(() {
      sttStatus = '${error.errorMsg} - ${error.permanent}';
      isListening = false;
    });
  }

  // 音声入力状態
  void statusListener(String status) {
    debugPrint('statusListener: $status');
    setState(() {
      if (status == 'done') {
        sttStatus = '';
      } else {
        sttStatus = status;
      }
    });
  }

  // ｽﾀｯｸﾁｬﾝ API を呼ぶ
  void callStackchan() async {
    await stopListening();
    var prefs = await SharedPreferences.getInstance();
    try {
      var stackchanIpAddress = prefs.getString('stackchanIpAddress');
      if (stackchanIpAddress != null && stackchanIpAddress.isNotEmpty) {
        final request = textArea.text.trim();
        setState(() {
          textArea.clear();
          isLoading = true;
        });
        final stackchan = Stackchan(stackchanIpAddress);
        String reply;
        if (mode == 'chat') {
          appendMessage(Message.kindRequest, request);
          reply = await stackchan.chat(request, voice: voice);
          appendMessage(Message.kindReply, reply);
        } else {
          // echo
          reply = await stackchan.speech(request, voice: voice);
          appendMessage(Message.kindReply, request);
        }
      } else {
        appendMessage(Message.kindError, 'ｽﾀｯｸﾁｬﾝ の IP アドレスが設定されていません');
      }
    } catch (e) {
      appendMessage(Message.kindError, 'Error: ${e.toString()}');
    } finally {
      setState(() {
        isLoading = false;
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
        title: const Text('ｽﾀｯｸﾁｬﾝ ｺﾝﾈｸﾄ'),
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
                          .map((r) => r.kind == Message.kindError
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
                                  me: r.kind == Message.kindRequest,
                                ))
                          .toList(),
                    ),
                  ),
                  Visibility(
                    visible: isLoading,
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: LinearProgressIndicator(),
                    ),
                  ),
                  Visibility(
                    visible: sttStatus.isNotEmpty,
                    child: Text(sttStatus),
                  ),
                ],
              ),
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
                              value: 'speech',
                              child: Text("しゃべって"),
                            ),
                            DropdownMenuItem(
                              value: 'chat',
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
                              value: '0',
                              child: Text("Voice: Neutral"),
                            ),
                            DropdownMenuItem(
                              value: '1',
                              child: Text("Voice: Happy"),
                            ),
                            DropdownMenuItem(
                              value: '2',
                              child: Text("Voice: Sleepy"),
                            ),
                            DropdownMenuItem(
                              value: '3',
                              child: Text("Voice: Doubt"),
                            ),
                            DropdownMenuItem(
                              value: '4',
                              child: Text("Voice: Sad"),
                            ),
                            DropdownMenuItem(
                              value: '5',
                              child: Text("Voice: Angry"),
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
                              ? (isListening ? const Icon(Icons.stop) : const Icon(Icons.mic))
                              : const Icon(Icons.send),
                          onPressed: isLoading
                              ? null
                              : (textArea.text.isEmpty
                                  ? isListening
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
    );
  }
}
