import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';
import 'package:http/retry.dart';

class GoogleCloudApi {
  /// Google Cloud API Key
  final String _apiKey;

  /// HTTP Client
  final RetryClient _httpClient;

  GoogleCloudApi({required String apiKey})
      : _apiKey = apiKey,
        _httpClient = RetryClient(Client(), retries: 2, whenError: (dynamic error, StackTrace stackTrace) {
          debugPrint(error.toString());
          return true;
        });

  Future<Response> getSpeechOperations() async {
    const url = "https://speech.googleapis.com/v1/operations";
    final res = await _httpClient.get(Uri.parse(url).replace(queryParameters: {"key": _apiKey}));
    debugPrint("POST $url : ${res.statusCode}");
    return res;
  }
}
