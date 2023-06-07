import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';
import 'package:http/retry.dart';

class VoicevoxApi {
  /// VOICEVOX Endpoint
  static const String endpoint = "https://api.tts.quest/v3";

  /// VOICEVOX API Key
  final String? _apiKey;

  /// HTTP Client
  final RetryClient _httpClient;

  VoicevoxApi({String? apiKey})
      : _apiKey = apiKey,
        _httpClient = RetryClient(Client(), retries: 2, whenError: (dynamic error, StackTrace stackTrace) {
          debugPrint(error.toString());
          return true;
        });

  Future<int?> getKeyPoints() async {
    const url = "$endpoint/key/points";
    final res = await _httpClient.get(Uri.parse(url).replace(queryParameters: {"key": _apiKey}));
    debugPrint("GET $url : ${res.statusCode}");
    if (res.statusCode == 200) {
      final result = jsonDecode(res.body);
      if (result["isApiKeyValid"]) {
        return result["points"];
      }
    }
    return null;
  }

  Future<List<String>?> getSpeakers() async {
    const url = "$endpoint/voicevox/speakers_array";
    final res = await _httpClient.get(Uri.parse(url).replace(queryParameters: {"key": _apiKey}));
    debugPrint("GET $url : ${res.statusCode}");
    if (res.statusCode == 200) {
      final result = jsonDecode(res.body);
      if (result["success"] == true && result["speakers"] != null) {
        return List<String>.from(result["speakers"]);
      }
    }
    return null;
  }
}
