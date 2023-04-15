import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../infrastructure/stackchan.dart';
import '../../repository/speech.dart';

class SpeechPage extends StatefulWidget {
  const SpeechPage(this.stackchanIpAddress, {super.key});

  final String stackchanIpAddress;

  @override
  State<SpeechPage> createState() => _SpeechPageState();
}

class _SpeechPageState extends State<SpeechPage> {
  /// メッセージ表示最大数
  static const int maxMessages = 100;

  /// 設定更新中
  bool updating = false;

  /// 音声認識中
  bool listening = false;

  /// ステータスメッセージ
  String statusMessage = "";

  /// メッセージリポジトリ
  final speechRepository = SpeechRepository();

  /// メッセージ履歴
  List<SpeechMessage> messages = [];

  /// メッセージ入力
  final textArea = TextEditingController();

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    final savedMessages = await speechRepository.getMessages(maxMessages);
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
    speechRepository.clearAll();
    setState(() {
      messages.clear();
    });
  }

  void appendMessage(String text) async {
    final message = SpeechMessage(createdAt: DateTime.now(), text: text);
    speechRepository.append(message);
    setState(() {
      messages.add(message);
    });
  }

  void removeMessage(SpeechMessage message) async {
    speechRepository.remove(message);
    setState(() {
      messages.remove(message);
    });
  }

  void speech(String message, bool append) async {
    if (append) {
      appendMessage(message);
    }
    var prefs = await SharedPreferences.getInstance();
    final voice = prefs.getString("voice");
    setState(() {
      statusMessage = "";
      updating = true;
    });
    try {
      final stackchan = Stackchan(widget.stackchanIpAddress);
      await stackchan.speech(message, voice: voice);
    } catch (e) {
      setState(() {
        statusMessage = "Error: ${e.toString()}";
      });
    } finally {
      setState(() {
        updating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    textArea.selection = TextSelection.fromPosition(
      TextPosition(offset: textArea.text.length),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("ｽﾀｯｸﾁｬﾝ ｺﾝﾈｸﾄ"),
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView(
                  children: messages
                      .map((m) => Card(
                            child: ListTile(
                              title: Text(m.text),
                              trailing: GestureDetector(
                                child: const Icon(Icons.more_vert),
                                onTapDown: (details) async {
                                  final position = details.globalPosition;
                                  final result = await showMenu(
                                    context: context,
                                    position: RelativeRect.fromLTRB(position.dx, position.dy, 0, 0),
                                    items: [
                                      const PopupMenuItem(
                                        value: "remove",
                                        child: Text("削除"),
                                      ),
                                    ],
                                  );
                                  if (result == "remove") {
                                    removeMessage(m);
                                  }
                                },
                              ),
                              onTap: () {
                                speech(m.text, false);
                              },
                            ),
                          ))
                      .toList(),
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
                          controller: textArea,
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                        ),
                      ),
                      ValueListenableBuilder(
                        valueListenable: textArea,
                        builder: (context, value, child) {
                          return IconButton(
                            color: Theme.of(context).colorScheme.primary,
                            icon: const Icon(Icons.send),
                            onPressed: updating || textArea.text.isEmpty
                                ? null
                                : () {
                                    final message = textArea.text.trim();
                                    textArea.clear();
                                    speech(message, true);
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
      ),
    );
  }
}
