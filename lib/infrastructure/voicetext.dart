import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';
import 'package:http/retry.dart';

class VoiceTextApi {
  static const String baseUrl = "https://api.voicetext.jp/v1";

  String apiKey;
  RetryClient httpClient;

  VoiceTextApi({required this.apiKey})
      : httpClient = RetryClient(Client(), retries: 2, whenError: (dynamic error, StackTrace stackTrace) {
          debugPrint(error.toString());
          return true;
        });

  Future<Response> testTts(String text) async {
    const path = "tts";
    final res = await httpClient.post(Uri.parse("$baseUrl/$path"), headers: {
      "Authorization": "Basic ${base64.encode(utf8.encode("$apiKey:"))}",
    }, body: {
      "text": text,
      "speaker": "haruka",
    });
    debugPrint("POST $baseUrl/$path : ${res.statusCode}");
    return res;
  }
}
