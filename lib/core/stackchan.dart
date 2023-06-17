class UnexpectedResponseError implements Exception {
  final int statusCode;
  final String? message;

  UnexpectedResponseError(this.statusCode, {this.message});

  @override
  String toString() => message ?? "Response: $statusCode";
}

abstract class StackchanInterface {
  /// Check existence of API Keys API
  Future<bool> hasApiKeysApi();

  /// Check existence of Role API
  Future<bool> hasRoleApi();

  /// Check existence of Face API
  Future<bool> hasFaceApi();

  /// Check existence of Face API
  Future<bool> hasSettingApi();

  /// Set API Keys
  Future<void> setApiKeys({String? openai, String? voicetext});

  /// Get role
  Future<String?> getRole();

  /// Set role
  Future<void> setRole(String role);

  /// Delete role
  Future<void> deleteRole();

  /// Speech API
  Future<String> speech(String say, {String? voice});

  /// Chat API
  Future<String> chat(String text, {String? voice});

  /// Face API
  Future<void> face(String expression);

  /// Setting API
  Future<void> setting({String? volume});
}
