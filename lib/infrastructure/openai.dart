import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';
import 'package:http/retry.dart';

class OpenAIApi {
  static const String baseUrl = "https://api.openai.com/v1";

  final String apiKey;
  final RetryClient httpClient;

  OpenAIApi({required this.apiKey})
      : httpClient = RetryClient(Client(), retries: 2, whenError: (dynamic error, StackTrace stackTrace) {
          debugPrint(error.toString());
          return true;
        });

  Future<Response> testChat(String content) async {
    const path = "chat/completions";
    final res = await httpClient.post(Uri.parse("$baseUrl/$path"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": [
            {"role": "user", "content": "こんにちは"}
          ],
        }));
    debugPrint("POST $baseUrl/$path : ${res.statusCode}");
    return res;
  }

  Future<String> chat(String content, List<String> roles) async {
    const path = "chat/completions";
    final List<Map<String, String>> messages = [];
    for (var role in roles) {
      messages.add({"role": "system", "content": role});
    }
    messages.add({"role": "user", "content": content});
    final res = await httpClient.post(Uri.parse("$baseUrl/$path"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": messages,
        }));
    debugPrint("POST $baseUrl/$path : ${res.statusCode}");
    final result = jsonDecode(utf8.decode(res.bodyBytes));
    return result["choices"][0]["message"]["content"];
  }
}
