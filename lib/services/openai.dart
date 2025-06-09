import 'package:shared_preferences/shared_preferences.dart';

class OpenAIStorage {
  static const _apiKeyKey = 'openai_api_key';        
  static const _assistantIdKey = 'openai_assistant_id';

  static Future<void> saveCredentials({
    required String apiKey,
    required String assistantId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, apiKey);
    await prefs.setString(_assistantIdKey, assistantId);
    print('[OpenAIStorage] Saved API key: ${apiKey.substring(0, 20)}...${apiKey.substring(apiKey.length - 4)}');
  }

  static Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_apiKeyKey);
    if (key != null) {
      print('[OpenAIStorage] Retrieved API key: ${key.substring(0, 20)}...${key.substring(key.length - 4)}');
    }
    return key;
  }

  static Future<String?> getAssistantId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_assistantIdKey);
  }

  static Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiKeyKey);
    await prefs.remove(_assistantIdKey);
    print('[OpenAIStorage] ✅ Credentials cleared');
  }
}