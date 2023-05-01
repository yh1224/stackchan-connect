import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../infrastructure/stackchan.dart';
import '../../repository/speech.dart';

class SpeechPage extends ConsumerStatefulWidget {
  const SpeechPage(this.stackchanIpAddress, {super.key});

  final String stackchanIpAddress;

  @override
  ConsumerState<SpeechPage> createState() => _SpeechPageState();
}

class _SpeechPageState extends ConsumerState<SpeechPage> {
  /// メッセージ表示最大数
  static const int maxMessages = 100;

  /// メッセージリポジトリ
  final _speechRepository = SpeechRepository();

  /// メッセージ入力
  final _textArea = TextEditingController();

  /// 設定更新中
  final _updatingProvider = StateProvider((ref) => false);

  /// ステータスメッセージ
  final _statusMessageProvider = StateProvider((ref) => "");

  /// メッセージ履歴
  final _messagesProvider = StateProvider<List<SpeechMessage>>((ref) => []);

  /// タップ位置
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
    var prefs = await SharedPreferences.getInstance();
    final voice = prefs.getString("voice");
    ref.read(_statusMessageProvider.notifier).state = "";
    ref.read(_updatingProvider.notifier).state = true;
    try {
      final stackchan = Stackchan(widget.stackchanIpAddress);
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
      ),
    );
  }
}
