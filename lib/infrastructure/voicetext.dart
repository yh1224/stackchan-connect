import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';
import 'package:http/retry.dart';

class VoiceTextApi {
  /// VoiceText Endpoint
  static const String endpoint = "https://api.voicetext.jp/v1";

  /// VoiceText API Key
  final String _apiKey;

  /// HTTP Client
  final RetryClient _httpClient;

  VoiceTextApi({required String apiKey})
      : _apiKey = apiKey,
        _httpClient = RetryClient(Client(), retries: 2, whenError: (dynamic error, StackTrace stackTrace) {
          debugPrint(error.toString());
          return true;
        });

  Future<Response> testTts(String text) async {
    const url = "$endpoint/tts";
    final res = await _httpClient.post(Uri.parse(url), headers: {
      "Authorization": "Basic ${base64.encode(utf8.encode("$_apiKey:"))}",
    }, body: {
      "text": text,
      "speaker": "haruka",
    });
    debugPrint("POST $url : ${res.statusCode}");
    return res;
  }
}
