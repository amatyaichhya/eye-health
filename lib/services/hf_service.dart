import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:eye_health/api_configs/hf_api_config.dart';
import 'package:eye_health/constants/medical_prompt.dart';
import 'package:eye_health/utils/utility_methods/color_print.dart';
import 'package:eye_health/utils/utility_methods/image_converter.dart';
import 'package:http/http.dart' as http;

/// Service for handling HuggingFace API interactions for image analysis and chat
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

  /// Analyzes fundus images for educational purposes using HuggingFace Vision API
  static Future<Map<String, dynamic>> analyzeFungalInfection(
    List<XFile> images,
  ) async {
    try {
      _validateApiConfiguration();

      colorPrint(
        'Starting HuggingFace analysis for ${images.length} images...',
      );

      final imageContents = await _convertImagesToBase64(images);
      final requestBody = _buildAnalysisRequestBody(imageContents);
      final response = await _makeApiRequest(requestBody);

      return _processAnalysisResponse(response);
    } catch (e) {
      colorPrint('Error in HuggingFace analysis: $e');
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

      colorPrint('Starting HuggingFace chat request...');

      final messages = _buildChatMessages(
        userMessage,
        chatHistory,
        analysisContext,
      );
      final requestBody = _buildChatRequestBody(messages);
      final response = await _makeApiRequest(requestBody);

      return _processChatResponse(response);
    } catch (e) {
      colorPrint('Error in HuggingFace chat: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': _getFallbackResponse(userMessage, analysisContext != null),
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
        'Hugging Face API key not configured. Please add your API key to lib/config/open_api_config.dart',
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
      "model": HfApiConfig.hfModel,
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
      "model": HfApiConfig.hfModel,
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

  /// Makes HTTP request to HuggingFace API
  static Future<http.Response> _makeApiRequest(
    Map<String, dynamic> requestBody,
  ) async {
    colorPrint('Sending request to HuggingFace API...');
    colorPrint('Model: ${HfApiConfig.hfModel}');

    return await http
        .post(
          Uri.parse(HfApiConfig.chatCompletionsEndpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${HfApiConfig.hfApiKey}',
          },
          body: jsonEncode(requestBody),
        )
        .timeout(_apiTimeout);
  }

  /// Processes the API response for image analysis
  static Map<String, dynamic> _processAnalysisResponse(http.Response response) {
    colorPrint('Received response with status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final content = responseData['choices'][0]['message']['content'];

      colorPrint('HuggingFace analysis completed successfully');

      final analysisResult = _parseJsonResponse(content);

      return {
        'success': true,
        'analysis': analysisResult,
        'raw_response': content,
        'usage': responseData['usage'],
      };
    } else {
      colorPrint('HuggingFace API Error - Status: ${response.statusCode}');
      final errorData = jsonDecode(response.body);
      throw Exception(
        'HuggingFace API Error: ${errorData['error']['message']}',
      );
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
      colorPrint('HuggingFace Chat API Error - Status: ${response.statusCode}');

      String errorMessage;
      try {
        final errorData = jsonDecode(response.body);
        errorMessage = errorData['error']['message'] ?? 'Unknown API error';
      } catch (e) {
        errorMessage = 'API request failed with status ${response.statusCode}';
      }

      throw Exception('HuggingFace Chat API Error: $errorMessage');
    }
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
        'confidence': 'N/A - HuggingFace returned plain text',
        'visual_indicators': ['HuggingFace declined to analyze the image'],
        'possible_condition': 'Analysis not performed',
        'description': content,
        'recommendations': [
          'Consult a healthcare professional for proper diagnosis',
          'This response indicates HuggingFace\'s safety guidelines prevented analysis',
        ],
      },
      'note':
          'HuggingFace returned plain text instead of JSON - likely due to safety guidelines',
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
