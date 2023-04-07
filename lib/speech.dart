import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechPage extends StatefulWidget {
  const SpeechPage({super.key});

  @override
  State<SpeechPage> createState() => _SpeechPageState();
}

class _SpeechPageState extends State<SpeechPage> {
  final textArea = TextEditingController();
  final List<String> result = [];
  String sttStatus = '';
  String mode = 'chat';
  String voice = '0';
  bool isListening = false;
  bool isLoading = false;
  final stt.SpeechToText speech = stt.SpeechToText();

  @override
  void dispose() {
    textArea.dispose();
    super.dispose();
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
        final message = textArea.text;
        setState(() {
          textArea.clear();
          isLoading = true;
        });
        result.add('> $message');
        Response res;
        if (mode == 'chat') {
          res = await http.post(Uri.http(stackchanIpAddress, '/chat'), body: {'text': message, 'voice': voice});
        } else {
          // echo
          res = await http.post(Uri.http(stackchanIpAddress, '/speech'), body: {'say': message, 'voice': voice});
        }
        if (res.statusCode != 200) {
          setState(() {
            result.add('Error: ${res.statusCode}');
          });
        }
        var body = utf8.decode(res.bodyBytes);
        var si = body.indexOf("<body>");
        var ei = body.indexOf("</body>");
        if (si >= 0 && ei >= 0) {
          result.add(body.substring(si + 6, ei));
        }
      } else {
        result.add('ｽﾀｯｸﾁｬﾝ の IP アドレスが設定されていません');
      }
    } catch (e) {
      setState(() {
        result.add('Error: ${e.toString()}');
      });
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
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(8.0),
                        children: result.map((r) => Text(r, style: const TextStyle(fontSize: 16))).toList(),
                      ),
                    ),
                    Text(sttStatus),
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
                                child: Text("声: 0"),
                              ),
                              DropdownMenuItem(
                                value: '1',
                                child: Text("声: 1"),
                              ),
                              DropdownMenuItem(
                                value: '2',
                                child: Text("声: 2"),
                              ),
                              DropdownMenuItem(
                                value: '3',
                                child: Text("声: 3"),
                              ),
                              DropdownMenuItem(
                                value: '4',
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
                            color: Colors.blue,
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
      ),
    );
  }
}
