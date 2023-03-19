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
        sttStatus = status;
        isListening = false;
      });
    }
  }

  // ｽﾀｯｸﾁｬﾝ API を呼ぶ
  void callStackchan() async {
    var prefs = await SharedPreferences.getInstance();
    try {
      setState(() {
        isLoading = true;
      });
      var stackchanIpAddress = prefs.getString('stackchanIpAddress');
      if (stackchanIpAddress != null) {
        await http.post(Uri.http(stackchanIpAddress, widget.apiPath), body: {
          widget.parameterKey: textArea.text,
        });
      }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('ｽﾀｯｸﾁｬﾝ ｺﾝﾈｸﾄ'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(widget.message),
            TextField(
              autofocus: true,
              controller: textArea,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              style: const TextStyle(fontSize: 20),
            ),
            Row(
              children: [
                ValueListenableBuilder(
                  valueListenable: textArea,
                  builder: (context, value, child) {
                    return ElevatedButton(
                      onPressed: textArea.text.isEmpty || isListening || isLoading ? null : callStackchan,
                      child: const Text(
                        'OK',
                        style: TextStyle(fontSize: 20),
                      ),
                    );
                  },
                ),
                const Spacer(),
                ValueListenableBuilder(
                    valueListenable: textArea,
                    builder: (context, value, child) {
                      return ElevatedButton(
                        onPressed: textArea.text.isEmpty || isListening || isLoading ? null : clear,
                        child: const Text(
                          'Clear',
                          style: TextStyle(fontSize: 20),
                        ),
                      );
                    }),
              ],
            ),
            const Spacer(),
            Text(sttStatus, style: const TextStyle(fontSize: 40)),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: isListening ? stopListening : startListening,
            child: isListening ? const Icon(Icons.stop) : const Icon(Icons.record_voice_over_rounded),
          ),
        ],
      ),
    );
  }
}
