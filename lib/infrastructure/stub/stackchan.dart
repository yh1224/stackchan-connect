import 'package:stackchan_connect/infrastructure/openai.dart';

import '../../core/stackchan.dart';

class Stackchan extends StackchanInterface {
  String? openaiApiKey;
  String? voicetextApiKey;
  final List<String> roles = [];

  @override
  Future<bool> hasApiKeysApi() async => true;

  @override
  Future<bool> hasRoleApi() async => true;

  @override
  Future<bool> hasFaceApi() async => true;

  @override
  Future<bool> hasSettingApi() async => true;

  @override
  Future<void> setApiKeys({String? openai, String? voicetext}) async {
    openaiApiKey = openai;
    voicetextApiKey = voicetext;
  }

  @override
  Future<List<String>> getRoles() async => roles;

  @override
  Future<void> setRoles(List<String> roles) async {
    this.roles.clear();
    this.roles.addAll(roles);
  }

  @override
  Future<void> deleteRoles() async {
    roles.clear();
  }

  @override
  Future<String> speech(String say, {String? voice}) async {
    if (voicetextApiKey == null) {
      throw UnexpectedResponseError(401);
    }
    return "OK";
  }

  @override
  Future<String> chat(String text, {String? voice}) async {
    if (openaiApiKey == null) {
      throw UnexpectedResponseError(401);
    }
    return await OpenAIApi(apiKey: openaiApiKey!).chat(text, roles);
  }

  @override
  Future<void> face(String expression) async {}

  @override
  Future<void> setting({String? volume}) async {}
}
