import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:eye_health/api_configs/hf_api_config.dart';
import 'package:eye_health/constants/medical_prompt.dart';
import 'package:eye_health/utils/utility_methods/color_print.dart';
import 'package:eye_health/utils/utility_methods/image_converter.dart';
import 'package:http/http.dart' as http;

/// Service for handling OpenRouter API interactions for image analysis and chat
class HfService {
  // Constants for better maintainability
  static const Duration _apiTimeout = Duration(seconds: 30);
  static const int _maxTokens = 1000;
  static const double _chatTemperature = 0.7;
  static const String _imageContentType = "image_url";
  static const String _textContentType = "text";
  static const String _userRole = "user";
  static const String _assistantRole = "assistant";
  static const String _systemRole = "system";
  static const String _jsonMarkdownPrefix = '```json';
  static const String _jsonMarkdownSuffix = '```';

  /// Analyzes fundus images for educational purposes using OpenRouter Vision API
  static Future<Map<String, dynamic>> analyzeFungalInfection(
    List<XFile> images,
  ) async {
    try {
      _validateApiConfiguration();

      colorPrint(
        'Starting OpenRouter analysis for ${images.length} images...',
      );

      final imageContents = await _convertImagesToBase64(images);
      final requestBody = _buildAnalysisRequestBody(imageContents);
      final response = await _makeApiRequest(requestBody);

      return _processAnalysisResponse(response);
    } catch (e) {
      colorPrint('Error in OpenRouter analysis: $e');
      return _buildErrorResponse(e.toString());
    }
  }

  /// Sends a chat message with full conversation context and analysis results
  static Future<Map<String, dynamic>> sendChatMessage({
    required String userMessage,
    required List<Map<String, dynamic>> chatHistory,
    Map<String, dynamic>? analysisContext,
  }) async {
    try {
      _validateApiConfiguration();

      colorPrint('Starting OpenRouter chat request...');

      final messages = _buildChatMessages(
        userMessage,
        chatHistory,
        analysisContext,
      );
      final requestBody = _buildChatRequestBody(messages);
      final response = await _makeApiRequest(requestBody);

      return _processChatResponse(response);
    } catch (e) {
      colorPrint('Error in OpenRouter chat: $e');
      final errorText = e.toString().replaceFirst('Exception: ', '');
      return {
        'success': false,
        'error': errorText,
        'message': errorText.startsWith('OpenRouter')
            ? errorText
            : _getFallbackResponse(userMessage, analysisContext != null),
      };
    }
  }

  /// Validates if the service is properly configured
  static bool isConfigured() {
    return HfApiConfig.isApiKeyConfigured;
  }

  // Private helper methods

  /// Validates API configuration before making requests
  static void _validateApiConfiguration() {
    if (!HfApiConfig.isApiKeyConfigured) {
      throw Exception(
        'OpenRouter API key not configured. Set OPENROUTER_API_KEY in config.dev.json.',
      );
    }
  }

  /// Converts list of XFile images to base64 format for API
  static Future<List<Map<String, dynamic>>> _convertImagesToBase64(
    List<XFile> images,
  ) async {
    final imageContents = <Map<String, dynamic>>[];

    for (int i = 0; i < images.length; i++) {
      final base64Image = await convertImageToBase64(images[i]);
      imageContents.add({
        "type": _imageContentType,
        "image_url": {
          "url": "data:image/jpeg;base64,$base64Image",
          "detail": "high",
        },
      });
      colorPrint('Converted image ${i + 1} to base64');
    }

    return imageContents;
  }

  /// Builds the request body for image analysis
  static Map<String, dynamic> _buildAnalysisRequestBody(
    List<Map<String, dynamic>> imageContents,
  ) {
    return {
      "model": HfApiConfig.openRouterModel,
      "messages": [
        {
          "role": _userRole,
          "content": [
            {"type": _textContentType, "text": medicalPrompt},
            ...imageContents,
          ],
        },
      ],
    };
  }

  /// Builds the request body for chat messages
  static Map<String, dynamic> _buildChatRequestBody(
    List<Map<String, dynamic>> messages,
  ) {
    return {
      "model": HfApiConfig.openRouterModel,
      "messages": messages,
      "max_tokens": _maxTokens,
      "temperature": _chatTemperature,
    };
  }

  /// Builds conversation messages for chat requests
  static List<Map<String, dynamic>> _buildChatMessages(
    String userMessage,
    List<Map<String, dynamic>> chatHistory,
    Map<String, dynamic>? analysisContext,
  ) {
    final messages = <Map<String, dynamic>>[
      {"role": _systemRole, "content": _buildChatSystemPrompt(analysisContext)},
    ];

    // Add chat history
    for (var message in chatHistory) {
      messages.add({
        "role": message['isUser'] ? _userRole : _assistantRole,
        "content": message['text'],
      });
    }

    // Add current user message
    messages.add({"role": _userRole, "content": userMessage});

    return messages;
  }

  /// Makes HTTP request to OpenRouter API
  static Future<http.Response> _makeApiRequest(
    Map<String, dynamic> requestBody,
  ) async {
    colorPrint('Sending request to OpenRouter...');
    colorPrint('Endpoint: ${HfApiConfig.chatCompletionsEndpoint}');
    colorPrint('Model: ${HfApiConfig.openRouterModel}');

    const maxAttempts = 3;
    http.Response? response;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      response = await http
          .post(
            Uri.parse(HfApiConfig.chatCompletionsEndpoint),
            headers: {
              'Authorization': 'Bearer ${HfApiConfig.openRouterApiKey}',
              'HTTP-Referer': HfApiConfig.httpReferer,
              'X-Title': HfApiConfig.appTitle,
              'Content-Type': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(_apiTimeout);

      if (response.statusCode != 429 || attempt == maxAttempts) {
        return response;
      }

      colorPrint(
        'OpenRouter rate limited the free model. Retrying ($attempt/$maxAttempts)...',
      );
      await Future.delayed(Duration(seconds: attempt * 2));
    }

    return response!;
  }

  /// Processes the API response for image analysis
  static Map<String, dynamic> _processAnalysisResponse(http.Response response) {
    colorPrint('Received response with status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final content = responseData['choices'][0]['message']['content'];

      colorPrint('OpenRouter analysis completed successfully');

      final analysisResult = _parseJsonResponse(content);

      return {
        'success': true,
        'analysis': analysisResult,
        'raw_response': content,
        'usage': responseData['usage'],
      };
    } else {
      final errorMessage = _openRouterErrorMessage(response);
      colorPrint(
        'OpenRouter API error - Status: ${response.statusCode} - $errorMessage',
      );
      throw Exception('OpenRouter API error: $errorMessage');
    }
  }

  /// Processes the API response for chat messages
  static Map<String, dynamic> _processChatResponse(http.Response response) {
    colorPrint('Received chat response with status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final content = responseData['choices'][0]['message']['content'];

      colorPrint('Chat response received successfully');

      return {
        'success': true,
        'message': content,
        'usage': responseData['usage'],
      };
    } else {
      final errorMessage = _openRouterErrorMessage(response);
      colorPrint(
        'OpenRouter chat error - Status: ${response.statusCode} - $errorMessage',
      );
      throw Exception('OpenRouter chat error: $errorMessage');
    }
  }

  /// Reads OpenRouter's error message, including the upstream provider detail.
  static String _openRouterErrorMessage(http.Response response) {
    try {
      final errorData = jsonDecode(response.body);
      final error = errorData['error'];
      if (error is Map) {
        final raw = error['metadata']?['raw'];
        if (raw is String && raw.trim().isNotEmpty) return raw.trim();
        final message = error['message'];
        if (message is String && message.trim().isNotEmpty) return message.trim();
      }
    } catch (_) {}
    return 'API request failed with status ${response.statusCode}';
  }

  /// Parses JSON response, handling markdown formatting
  static dynamic _parseJsonResponse(String content) {
    try {
      // Clean the content - remove markdown code blocks if present
      String cleanContent = content.trim();
      if (cleanContent.startsWith(_jsonMarkdownPrefix)) {
        cleanContent = cleanContent.substring(_jsonMarkdownPrefix.length);
        if (cleanContent.endsWith(_jsonMarkdownSuffix)) {
          cleanContent = cleanContent.substring(
            0,
            cleanContent.length - _jsonMarkdownSuffix.length,
          );
        }
        cleanContent = cleanContent.trim();
      }

      return jsonDecode(cleanContent);
    } catch (e) {
      // If JSON parsing fails, return fallback structure
      colorPrint('Failed to parse JSON response: $e');

      return _buildFallbackAnalysis(content);
    }
  }

  /// Builds fallback analysis structure when JSON parsing fails
  static Map<String, dynamic> _buildFallbackAnalysis(String content) {
    return {
      'analysis': {
        'likelihood': 'Unable to assess - text response received',
        'confidence': 'N/A - OpenRouter returned plain text',
        'visual_indicators': ['OpenRouter declined to analyze the image'],
        'possible_condition': 'Analysis not performed',
        'description': content,
        'recommendations': [
          'Consult a healthcare professional for proper diagnosis',
          'This response indicates OpenRouter\'s safety guidelines prevented analysis',
        ],
      },
      'note':
          'OpenRouter returned plain text instead of JSON - likely due to safety guidelines',
    };
  }

  /// Builds error response structure
  static Map<String, dynamic> _buildErrorResponse(String error) {
    return {
      'success': false,
      'error': error,
      'analysis': {
        'likelihood': 'Unknown',
        'confidence': '0%',
        'visual_indicators': [],
        'possible_condition': 'Analysis failed',
        'description': 'Unable to analyze images due to error: $error',
        'recommendations': [
          'Please try again later',
          'Consult a healthcare professional for proper diagnosis',
        ],
      },
    };
  }

  /// Builds the system prompt for chat conversations
  static String _buildChatSystemPrompt(Map<String, dynamic>? analysisContext) {
    String basePrompt = '''
You are an AI Eye Health Assistant specialized in fundus (retinal) photography analysis and general eye health guidance. You provide educational information to help users understand their eye health.

Your expertise includes:
- Fundus/retinal image analysis interpretation
- Diabetic retinopathy detection and stages
- Age-related macular degeneration (AMD)
- Glaucoma indicators
- General eye health and preventive care
- When to seek professional medical attention

Guidelines:
- Provide clear, educational explanations
- Always emphasize that you provide educational information, not medical diagnosis
- Recommend consulting eye care professionals for concerns
- Be supportive and informative
- Use simple language that patients can understand
''';

    if (analysisContext != null) {
      final outerData = analysisContext['analysis'];
      final analysis = outerData?['analysis'];
      if (analysis != null) {
        basePrompt += '''

CURRENT FUNDUS ANALYSIS CONTEXT:
The user has just received an analysis of their fundus photographs with the following results:

Likelihood: ${analysis['likelihood'] ?? 'Not specified'}
Confidence: ${analysis['confidence'] ?? 'Not specified'}
Possible Condition: ${analysis['possible_condition'] ?? 'Not specified'}
Description: ${analysis['description'] ?? 'Not specified'}

Visual Indicators: ${analysis['visual_indicators']?.join(', ') ?? 'None specified'}

Recommendations: ${analysis['recommendations']?.join(', ') ?? 'None specified'}

Use this analysis context to answer questions about their results, explain findings, and provide relevant guidance.
''';
      }
    }

    basePrompt += '''

Remember: Always emphasize that this is educational information and professional medical consultation is essential for proper diagnosis and treatment.
''';

    return basePrompt;
  }

  /// Provides fallback responses when API fails
  static String _getFallbackResponse(String userMessage, bool hasAnalysis) {
    if (hasAnalysis) {
      return "I apologize, but I'm having trouble connecting to the AI service right now. However, I can see you have fundus analysis results. Please feel free to ask me any specific questions about your results, and I'll do my best to help. You can also try sending your message again in a moment.";
    } else {
      return "I apologize, but I'm experiencing connection issues right now. As your Eye Health Assistant, I'm here to help with questions about eye health, diabetic retinopathy, and general eye care. Please try sending your message again in a moment, or you can visit an eye care professional for immediate assistance.";
    }
  }
}
