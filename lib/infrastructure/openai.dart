import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';
import 'package:http/retry.dart';

class OpenAIApi {
  /// OpenAI Endpoint
  static const String endpoint = "https://api.openai.com/v1";

  /// OpenAI API Key
  final String _apiKey;

  /// HTTP Client
  final RetryClient _httpClient;

  OpenAIApi({required String apiKey})
      : _apiKey = apiKey,
        _httpClient = RetryClient(Client(), retries: 2, whenError: (dynamic error, StackTrace stackTrace) {
          debugPrint(error.toString());
          return true;
        });

  Future<Response> testChat(String content) async {
    const url = "$endpoint/chat/completions";
    final res = await _httpClient.post(Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_apiKey",
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": [
            {"role": "user", "content": "こんにちは"}
          ],
        }));
    debugPrint("POST $url : ${res.statusCode}");
    return res;
  }

  Future<String> chat(String content, String? role) async {
    const url = "$endpoint/chat/completions";
    final List<Map<String, String>> messages = [];
    if (role != null && role.isNotEmpty) {
      messages.add({"role": "system", "content": role});
    }
    messages.add({"role": "user", "content": content});
    final res = await _httpClient.post(Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_apiKey",
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": messages,
        }));
    debugPrint("POST $url : ${res.statusCode}");
    final result = jsonDecode(utf8.decode(res.bodyBytes));
    return result["choices"][0]["message"]["content"];
  }
}
