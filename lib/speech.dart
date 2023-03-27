import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechPage extends StatefulWidget {
  const SpeechPage(this.message, this.apiPath, this.parameterKey, {super.key});

  final String message;
  final String apiPath;
  final String parameterKey;

  @override
  State<SpeechPage> createState() => _SpeechPageState();
}

class _SpeechPageState extends State<SpeechPage> {
  final textArea = TextEditingController();
  final List<String> result = [];
  String sttStatus = '';
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
    speech.stop();
    setState(() {
      isListening = false;
    });
  }

  // 音声入力結果
  void resultListener(SpeechRecognitionResult result) {
    setState(() {
      textArea.text = result.recognizedWords;
      sttStatus = '';
    });
  }

  // 音声入力エラー
  void errorListener(SpeechRecognitionError error) {
    setState(() {
      sttStatus = '${error.errorMsg} - ${error.permanent}';
      isListening = false;
    });
  }

  // 音声入力状態
  void statusListener(String status) {
    if (status == 'done') {
      setState(() {
        sttStatus = '';
        isListening = false;
      });
    } else {
      setState(() {
        sttStatus = status;
      });
    }
  }

  // ｽﾀｯｸﾁｬﾝ API を呼ぶ
  void callStackchan() async {
    var prefs = await SharedPreferences.getInstance();
    try {
      var stackchanIpAddress = prefs.getString('stackchanIpAddress');
      if (stackchanIpAddress != null && stackchanIpAddress.isNotEmpty) {
        setState(() {
          isLoading = true;
        });
        var message = textArea.text;
        textArea.text = '';
        result.add('> $message');
        var res = await http.post(Uri.http(stackchanIpAddress, widget.apiPath), body: {
          widget.parameterKey: message,
        });
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
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(widget.message),
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
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Flexible(
                      child: TextField(
                        autofocus: true,
                        controller: textArea,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        style: const TextStyle(fontSize: 20),
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
    );
  }
}
