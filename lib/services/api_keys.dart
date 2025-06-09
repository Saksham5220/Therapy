// lib/config/api_keys.dart

class ApiKeys {
  // OpenAI API Configuration
  static const String openaiApiKey =
      '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';
  static const String openaiAssistantId = 'asst_nh5ldKIY2ZhMsf97JzRUXpLn';

  // Base URLs
  static const String openaiBaseUrl = 'https://api.openai.com/v1';

  // Validation methods
  static bool isValidApiKey() {
    return openaiApiKey.isNotEmpty &&
        (openaiApiKey.startsWith('sk-proj-') ||
            openaiApiKey.startsWith('sk-svcacct-')) &&
        openaiApiKey.length > 50;
  }

  static bool isValidAssistantId() {
    return openaiAssistantId.isNotEmpty &&
        openaiAssistantId.startsWith('asst_');
  }

  // Get credentials as a map
  static Map<String, String> getCredentials() {
    return {
      'apiKey': openaiApiKey,
      'assistantId': openaiAssistantId,
      'baseUrl': openaiBaseUrl,
    };
  }

  // Debug info (safe for logging)
  static void printDebugInfo() {
    print('=== API Key Configuration ===');
    print('API Key valid: ${isValidApiKey()}');
    print('API Key preview: ${openaiApiKey.substring(0, 15)}...');
    print('Assistant ID valid: ${isValidAssistantId()}');
    print('Assistant ID: $openaiAssistantId');
    print('================================');
  }
}
