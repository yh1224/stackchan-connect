import 'package:stackchan_connect/infrastructure/openai.dart';

import '../../core/stackchan.dart';

class Stackchan extends StackchanInterface {
  /// OpenAI API Key
  String? _openaiApiKey;

  /// VoiceText API Key
  String? _voicetextApiKey;

  /// ロール設定
  final List<String> _roles = [];

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
    _openaiApiKey = openai;
    _voicetextApiKey = voicetext;
  }

  @override
  Future<List<String>> getRoles() async => _roles;

  @override
  Future<void> setRoles(List<String> roles) async {
    this._roles.clear();
    this._roles.addAll(roles);
  }

  @override
  Future<void> deleteRoles() async {
    _roles.clear();
  }

  @override
  Future<String> speech(String say, {String? voice}) async {
    if (_voicetextApiKey == null) {
      throw UnexpectedResponseError(401);
    }
    return "OK";
  }

  @override
  Future<String> chat(String text, {String? voice}) async {
    if (_openaiApiKey == null) {
      throw UnexpectedResponseError(401);
    }
    return await OpenAIApi(apiKey: _openaiApiKey!).chat(text, _roles);
  }

  @override
  Future<void> face(String expression) async {}

  @override
  Future<void> setting({String? volume}) async {}
}
