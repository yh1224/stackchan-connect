import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../infrastructure/stackchan.dart';
import '../../repository/speech.dart';

class SpeechPage extends StatefulWidget {
  final String stackchanIpAddress;

  const SpeechPage(this.stackchanIpAddress, {super.key});

  @override
  State<SpeechPage> createState() => _SpeechPageState();
}

class _SpeechPageState extends State<SpeechPage> {
  /// メッセージ表示最大数
  static const int maxMessages = 100;

  /// 設定更新中
  bool _updating = false;

  /// ステータスメッセージ
  String _statusMessage = "";

  /// メッセージリポジトリ
  final _speechRepository = SpeechRepository();

  /// メッセージ履歴
  final List<SpeechMessage> _messages = [];

  /// メッセージ入力
  final _textArea = TextEditingController();

  /// タップ位置
  Offset? _tapPosition;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    final savedMessages = await _speechRepository.getMessages(maxMessages);
    setState(() {
      _messages.addAll(savedMessages);
    });
  }

  @override
  void dispose() {
    _textArea.dispose();
    super.dispose();
  }

  void _appendMessage(String text) async {
    final message = SpeechMessage(createdAt: DateTime.now(), text: text);
    _speechRepository.append(message);
    setState(() {
      _messages.add(message);
    });
  }

  void _removeMessage(SpeechMessage message) async {
    _speechRepository.remove(message);
    setState(() {
      _messages.remove(message);
    });
  }

  void _speech(String message, bool append) async {
    if (append) {
      _appendMessage(message);
    }
    var prefs = await SharedPreferences.getInstance();
    final voice = prefs.getString("voice");
    setState(() {
      _statusMessage = "";
      _updating = true;
    });
    try {
      final stackchan = Stackchan(widget.stackchanIpAddress);
      await stackchan.speech(message, voice: voice);
    } catch (e) {
      setState(() {
        _statusMessage = "Error: ${e.toString()}";
      });
    } finally {
      setState(() {
        _updating = false;
      });
    }
  }

  void _getTapPosition(TapDownDetails tapPosition) {
    final RenderBox referenceBox = context.findRenderObject() as RenderBox;
    setState(() {
      _tapPosition = referenceBox.globalToLocal(tapPosition.globalPosition);
      print(_tapPosition);
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
                  children: _messages
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
                                  final RenderObject? overlay = Overlay.of(context).context.findRenderObject();
                                  final result = await showMenu(
                                    context: context,
                                    position: RelativeRect.fromLTRB(_tapPosition!.dx, _tapPosition!.dy, 0, 0),
                                    items: [
                                      const PopupMenuItem(
                                        value: "remove",
                                        child: Text("削除"),
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
            Container(
              padding: const EdgeInsets.all(8.0),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Visibility(
                    visible: _statusMessage.isNotEmpty,
                    child: Text(
                      _statusMessage,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Visibility(
                    visible: _updating,
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
                            onPressed: _updating || _textArea.text.trim().isEmpty
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
      ),
    );
  }
}
