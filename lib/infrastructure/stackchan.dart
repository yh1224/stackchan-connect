import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';
import 'package:http/retry.dart';

import '../core/stackchan.dart';

class Stackchan extends StackchanInterface {
  /// ｽﾀｯｸﾁｬﾝ IP アドレス
  final String _stackchanIpAddress;

  /// HTTP Client
  final RetryClient _httpClient;

  Stackchan(this._stackchanIpAddress)
      : _httpClient = RetryClient(Client(), retries: 2, whenError: (dynamic error, StackTrace stackTrace) {
          debugPrint(error.toString());
          return true;
        });

  /// Check existence of API
  Future<bool> _hasApi(String path) async {
    try {
      final res = await _httpClient.get(Uri.http(_stackchanIpAddress, path));
      debugPrint("GET $path : ${res.statusCode}");
      return res.statusCode == 200;
    } catch (e) {
      debugPrint("GET $path : ${e.toString()}");
      return false;
    }
  }

  @override
  Future<bool> hasApiKeysApi() async {
    return _hasApi("/apikey");
  }

  @override
  Future<bool> hasRoleApi() async {
    return _hasApi("/role");
  }

  @override
  Future<bool> hasFaceApi() async {
    return _hasApi("/face");
  }

  @override
  Future<bool> hasSettingApi() async {
    return _hasApi("/setting");
  }

  @override
  Future<void> setApiKeys({String? openai, String? sttapikey, String? voicetext, String? voicevox}) async {
    final params = {};
    if (openai != null) {
      params["openai"] = openai;
    }
    if (sttapikey != null) {
      params["sttapikey"] = sttapikey;
    }
    if (voicetext != null) {
      params["voicetext"] = voicetext;
    }
    if (voicevox != null) {
      params["voicevox"] = voicevox;
    }
    final res = await _httpClient.post(Uri.http(_stackchanIpAddress, "/apikey_set"), body: params);
    debugPrint("POST /apikey_set ${jsonEncode(params)} : ${res.statusCode}");
    if (res.statusCode != 200) {
      throw UnexpectedResponseError(res.statusCode);
    }
  }

  @override
  Future<String?> getRole() async {
    final res = await _httpClient.get(Uri.http(_stackchanIpAddress, "/role_get"));
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
    if (resultBody == "null") {
      // handle "null" response
      return null;
    }
    try {
      final json = jsonDecode(resultBody);
      String? result;
      if (json["roles"] != null) {
        result = json["roles"].join("\n");
      } else if (json["messages"] != null) {
        result = json["messages"]
            .where((message) => message["role"] == "system")
            .map((message) => message["content"])
            .join("\n");
      }
      return result;
    } catch (e) {
      debugPrint(e.toString());
      throw UnexpectedResponseError(res.statusCode, message: e.toString());
    }
  }

  @override
  Future<void> setRole(String? role) async {
    await getRole(); // 連続で POST すると正常にクリアされないため、一度 GET してから POST する
    await deleteRole();
    if (role != null && role.isNotEmpty) {
      final res = await _httpClient.post(Uri.http(_stackchanIpAddress, "/role_set"), body: role);
      debugPrint("POST /role_set $role : ${res.statusCode}");
      if (res.statusCode != 200) {
        throw UnexpectedResponseError(res.statusCode);
      }
    }
  }

  @override
  Future<void> deleteRole() async {
    final res = await _httpClient.post(Uri.http(_stackchanIpAddress, "/role_set"));
    debugPrint("POST /role_set : ${res.statusCode}");
    if (res.statusCode != 200) {
      throw UnexpectedResponseError(res.statusCode);
    }
  }

  String _getSpeechResult(Response res) {
    var resultBody = utf8.decode(res.bodyBytes);
    // pick from <body> to </body>
    var si = resultBody.indexOf("<body>");
    var ei = resultBody.indexOf("</body>");
    if (si >= 0 && ei >= 0) {
      resultBody = resultBody.substring(si + 6, ei);
    }
    return resultBody.trim();
  }

  @override
  Future<String> speech(String say, {String? voice, String? lang}) async {
    final params = {"say": say};
    if (voice != null) {
      params["voice"] = voice;
    }
    if (lang != null) {
      params["lang"] = lang;
    }
    final res = await _httpClient.post(Uri.http(_stackchanIpAddress, "/speech"), body: params);
    debugPrint("POST /speech ${jsonEncode(params)} : ${res.statusCode}");
    if (res.statusCode != 200) {
      throw UnexpectedResponseError(res.statusCode);
    }
    return _getSpeechResult(res);
  }

  @override
  Future<String> chat(String text, {String? voice, String? lang}) async {
    final params = {"text": text};
    if (voice != null) {
      params["voice"] = voice;
    }
    if (lang != null) {
      params["lang"] = lang;
    }
    final res = await _httpClient.post(Uri.http(_stackchanIpAddress, "/chat"), body: params);
    debugPrint("POST /chat ${jsonEncode(params)} : ${res.statusCode}");
    if (res.statusCode != 200) {
      throw UnexpectedResponseError(res.statusCode);
    }
    return _getSpeechResult(res);
  }

  @override
  Future<void> face(String expression) async {
    final params = {
      "expression": expression,
    };
    final res = await _httpClient.post(Uri.http(_stackchanIpAddress, "/face"), body: params);
    debugPrint("POST /face ${jsonEncode(params)} : ${res.statusCode}");
    if (res.statusCode != 200) {
      throw UnexpectedResponseError(res.statusCode);
    }
  }

  @override
  Future<void> setting({String? voice, String? volume}) async {
    final params = {};
    if (voice != null) {
      params["voice"] = voice;
    }
    if (volume != null) {
      params["volume"] = volume;
    }
    final res = await _httpClient.post(Uri.http(_stackchanIpAddress, "/setting"), body: params);
    debugPrint("POST /setting ${jsonEncode(params)} : ${res.statusCode}");
    if (res.statusCode != 200) {
      throw UnexpectedResponseError(res.statusCode);
    }
  }
}
