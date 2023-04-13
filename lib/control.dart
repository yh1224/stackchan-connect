import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';
import 'package:http/retry.dart';

class UnexpectedResponseError implements Exception {
  int statusCode;
  String? message;

  UnexpectedResponseError(this.statusCode, {this.message});
}

class Stackchan {
  String stackchanIpAddress;
  RetryClient httpClient;

  Stackchan(this.stackchanIpAddress)
      : httpClient = RetryClient(Client(), retries: 2, whenError: (dynamic error, StackTrace stackTrace) {
          debugPrint(error.toString());
          return true;
        });

  /// Check existence of API
  Future<bool> hasApi(String path) async {
    try {
      final res = await httpClient.get(Uri.http(stackchanIpAddress, path));
      debugPrint("GET $path : ${res.statusCode}");
      return res.statusCode == 200;
    } catch (e) {
      debugPrint("GET $path : ${e.toString()}");
      return false;
    }
  }

  /// Check existence of API Keys API
  Future<bool> hasApiKeysApi() async {
    return hasApi("/apikey");
  }

  /// Check existence of Role API
  Future<bool> hasRoleApi() async {
    return hasApi("/role");
  }

  /// Check existence of Face API
  Future<bool> hasFaceApi() async {
    return hasApi("/face");
  }

  /// Check existence of Face API
  Future<bool> hasSettingApi() async {
    return hasApi("/setting");
  }

  /// Set API Keys
  Future<void> setApiKeys({String? openai, String? voicetext}) async {
    final params = {};
    if (openai != null) {
      params["openai"] = openai;
    }
    if (voicetext != null) {
      params["voicetext"] = voicetext;
    }
    final res = await httpClient.post(Uri.http(stackchanIpAddress, "/apikey_set"), body: params);
    debugPrint("POST /apikey_set ${jsonEncode(params)} : ${res.statusCode}");
    if (res.statusCode != 200) {
      throw UnexpectedResponseError(res.statusCode);
    }
  }

  /// Get roles
  Future<List<String>> getRoles() async {
    final res = await httpClient.get(Uri.http(stackchanIpAddress, "/role_get"));
    debugPrint("GET /role_get : ${res.statusCode}");
    if (res.statusCode != 200) {
      throw UnexpectedResponseError(res.statusCode);
    }
    var resultBody = utf8.decode(res.bodyBytes);
    // pick from <pre> to </pre>
    var si = resultBody.indexOf("<pre>");
    var ei = resultBody.indexOf("</pre>");
    if (si >= 0 && ei >= 0) {
      resultBody = resultBody.substring(si + 5, ei);
    }
    try {
      final result = jsonDecode(resultBody)["messages"]
          .where((message) => message["role"] == "system")
          .map((role) => role["content"] as String)
          .toList();
      return List<String>.from(result);
    } catch (e) {
      debugPrint(e.toString());
      throw UnexpectedResponseError(res.statusCode, message: e.toString());
    }
  }

  /// Set roles
  Future<void> setRoles(List<String> roles) async {
    await deleteRoles();
    for (var role in roles) {
      final res = await httpClient.post(Uri.http(stackchanIpAddress, "/role_set"), body: role);
      debugPrint("POST /role_set $role : ${res.statusCode}");
      if (res.statusCode != 200) {
        throw UnexpectedResponseError(res.statusCode);
      }
    }
  }

  /// Delete roles
  Future<void> deleteRoles() async {
    final res = await httpClient.post(Uri.http(stackchanIpAddress, "/role_set"));
    debugPrint("POST /role_set : ${res.statusCode}");
    if (res.statusCode != 200) {
      throw UnexpectedResponseError(res.statusCode);
    }
  }

  String getSpeechResult(Response res) {
    var resultBody = utf8.decode(res.bodyBytes);
    // pick from <body> to </body>
    var si = resultBody.indexOf("<body>");
    var ei = resultBody.indexOf("</body>");
    if (si >= 0 && ei >= 0) {
      resultBody = resultBody.substring(si + 6, ei);
    }
    return resultBody;
  }

  /// Speech API
  Future<String> speech(String say, {String voice = "1"}) async {
    final params = {
      "say": say,
      "voice": voice,
    };
    final res = await httpClient.post(Uri.http(stackchanIpAddress, "/speech"), body: params);
    debugPrint("POST /speech ${jsonEncode(params)} : ${res.statusCode}");
    if (res.statusCode != 200) {
      throw UnexpectedResponseError(res.statusCode);
    }
    return getSpeechResult(res);
  }

  /// Chat API
  Future<String> chat(String text, {String voice = "1"}) async {
    final params = {
      "text": text,
      "voice": voice,
    };
    final res = await httpClient.post(Uri.http(stackchanIpAddress, "/chat"), body: params);
    debugPrint("POST /chat ${jsonEncode(params)} : ${res.statusCode}");
    if (res.statusCode != 200) {
      throw UnexpectedResponseError(res.statusCode);
    }
    return getSpeechResult(res);
  }

  /// Face API
  Future<void> face(String expression) async {
    final params = {
      "expression": expression,
    };
    final res = await httpClient.post(Uri.http(stackchanIpAddress, "/face"), body: params);
    debugPrint("POST /face ${jsonEncode(params)} : ${res.statusCode}");
    if (res.statusCode != 200) {
      throw UnexpectedResponseError(res.statusCode);
    }
  }

  /// Setting API
  Future<void> setting({String? volume}) async {
    final params = {};
    if (volume != null) {
      params["volume"] = volume;
    }
    final res = await httpClient.post(Uri.http(stackchanIpAddress, "/setting"), body: params);
    debugPrint("POST /setting ${jsonEncode(params)} : ${res.statusCode}");
    if (res.statusCode != 200) {
      throw UnexpectedResponseError(res.statusCode);
    }
  }
}
