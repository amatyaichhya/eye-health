import 'package:camera/camera.dart';
import 'package:eye_health/pages/image_processing_screen/chat_message.dart';
import 'package:eye_health/pages/image_processing_screen/widgets/chat_composer.dart';
import 'package:eye_health/pages/image_processing_screen/widgets/chat_thread.dart';
import 'package:eye_health/services/health_statistics_store.dart';
import 'package:eye_health/services/hf_service.dart';
import 'package:eye_health/services/screening_service.dart';
import 'package:eye_health/theme/app_theme.dart';
import 'package:eye_health/utils/utility_methods/app_toast.dart';
import 'package:eye_health/utils/utility_methods/color_print.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' as img_picker;

/// Screen for processing fundus photos and providing AI-powered eye health analysis
/// Supports both image analysis and interactive chat consultation
class PhotoProcessingScreen extends StatefulWidget {
  final List<XFile>? photos;
  final bool showBackButton;

  const PhotoProcessingScreen({
    super.key,
    required this.photos,
    this.showBackButton = true,
  });

  @override
  State<PhotoProcessingScreen> createState() => _PhotoProcessingScreenState();
}

class _PhotoProcessingScreenState extends State<PhotoProcessingScreen> {
  // State variables
  bool _isProcessing = false;
  bool _isSendingMessage = false;
  bool _isPickingMore = false;
  Map<String, dynamic>? _analysisResult;
  String? _errorMessage;
  late List<XFile> _photos;
  final List<ChatMessage> _messages = [];

  // Controllers
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // UI Constants
  static const Duration _scrollAnimationDuration = Duration(milliseconds: 300);
  static const Duration _messageDelayDuration = Duration(milliseconds: 500);
  static const int _maxChatBubbleLines = 4;
  static const double _maxMessageWidthRatio = 0.75;
  static const double _avatarSize = 30.0;
  static const int _maxPhotos = 5;

  // Text Constants

  static const String _closingMessage =
      "Feel free to ask me any questions about these results or about general eye health!";
  static const String _initialGreeting =
      'Hello! I\'m your AI Eye Health Assistant. I can help you with questions about eye health, diabetic retinopathy, preventive care, and general eye wellness. How can I assist you today?';
  static const String _screeningServerError =
      'Screening is unavailable right now.\n\n'
      'Please make sure the local screening server is running, then try again.';
  static const String _analysisFailedPrefix = 'Analysis failed: ';
  static const String _aiThinkingText = 'AI is thinking';
  static const String _fundusPhotoTakenText = 'Fundus photo taken:';

  @override
  void initState() {
    super.initState();
    _photos = List<XFile>.from(widget.photos ?? const <XFile>[]);
    _initializeScreen();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Initialize screen based on whether photos are provided
  Future<void> _initializeScreen() async {
    if (_hasPhotos) {
      await _addUserPhotoMessage(_photos);
      if (!mounted) return;
      _startProcessing();
    } else {
      _addInitialGreeting();
    }
  }

  /// Check if photos are available
  bool get _hasPhotos => _photos.isNotEmpty;

  /// Scroll to bottom of chat with animation
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: _scrollAnimationDuration,
          curve: Curves.easeOut,
        );
      });
    }
  }

  /// Add initial greeting message
  void _addInitialGreeting() {
    _addAIMessage(_initialGreeting);
  }

  /// Add AI message to chat
  void _addAIMessage(String text) {
    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: false, timestamp: DateTime.now()),
      );
    });
    _scrollToBottom();
  }

  /// Add screening report card(s) to chat
  void _addScreeningReports(List<Map<String, dynamic>> results) {
    colorPrint('Screening report messages: $results');
    setState(() {
      for (final item in results) {
        _messages.add(
          ChatMessage(
            text: ScreeningService.formatResultMessage({'results': [item]}),
            isUser: false,
            timestamp: DateTime.now(),
            screeningResult: item,
            imagePath: item['local_path']?.toString(),
          ),
        );
      }
      _messages.add(
        ChatMessage(
          text: _closingMessage,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
    _scrollToBottom();
  }

  /// Add user message to chat
  void _addUserMessage(String text) {
    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
      );
    });
    _scrollToBottom();
  }

  /// Add a right-aligned user message with fundus photo thumbnails.
  /// Copies each photo into personal health statistics.
  Future<void> _addUserPhotoMessage(List<XFile> photos) async {
    if (photos.isEmpty) return;
    final savedPaths = <String>[];
    for (final photo in photos) {
      final saved = await HealthStatisticsStore.saveChatImage(photo);
      savedPaths.add(saved.imagePath);
    }
    if (!mounted) return;

    final countLabel =
        photos.length == 1
            ? _fundusPhotoTakenText
            : 'Fundus photos taken (${photos.length}):';
    setState(() {
      _messages.add(
        ChatMessage(
          text: countLabel,
          isUser: true,
          timestamp: DateTime.now(),
          imagePaths: savedPaths,
        ),
      );
    });
    _scrollToBottom();
  }

  /// Get appropriate hint text for message input
  String _getHintText() {
    if (_analysisResult != null) {
      return 'Ask about your results or eye health...';
    } else if (_hasPhotos) {
      return 'Analysis in progress...';
    } else {
      return 'Ask about eye health, diabetes, prevention...';
    }
  }

  /// Start photo processing workflow (local screening models)
  Future<void> _startProcessing({List<XFile>? onlyPhotos}) async {
    final toScreen = onlyPhotos ?? _photos;
    if (toScreen.isEmpty) return;

    _setProcessingState(true);

    try {
      if (!ScreeningService.isConfigured()) {
        _handleProcessingError(_screeningServerError);
        return;
      }

      final result = await ScreeningService.screenImages(toScreen);
      colorPrint('Screening response: $result');
      if (result['success'] == true) {
        _handleProcessingSuccess(result, screenedPhotos: toScreen);
      } else {
        final error =
            result['error']?.toString() ??
            'Something went wrong while screening this image.';
        _handleProcessingError(error);
      }
    } catch (e) {
      _handleProcessingError('$_analysisFailedPrefix${e.toString()}');
    }
  }

  /// Pick additional fundus photos from chat and screen them.
  Future<void> _uploadMorePhotos() async {
    if (_isProcessing || _isSendingMessage || _isPickingMore) return;

    final remaining = _maxPhotos - _photos.length;
    if (remaining <= 0) {
      showAppToast(
        context,
        'Maximum $_maxPhotos photos already added',
        type: AppToastType.error,
      );
      return;
    }

    setState(() => _isPickingMore = true);
    try {
      final picked = await img_picker.ImagePicker().pickMultiImage(
        imageQuality: 80,
        limit: remaining,
      );
      if (!mounted || picked.isEmpty) return;

      final newPhotos =
          picked.take(remaining).map((x) => XFile(x.path)).toList();
      setState(() => _photos.addAll(newPhotos));
      await _addUserPhotoMessage(newPhotos);
      if (!mounted) return;
      await _startProcessing(onlyPhotos: newPhotos);
    } catch (e) {
      colorPrint('Chat upload more error: $e');
      if (mounted) {
        showAppToast(
          context,
          'Could not open the photo picker. Please try again.',
          type: AppToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingMore = false);
    }
  }

  /// Set processing state
  void _setProcessingState(bool isProcessing) {
    if (mounted) {
      setState(() {
        _isProcessing = isProcessing;
        if (isProcessing) _errorMessage = null;
      });
    }
  }

  /// Handle successful processing result
  void _handleProcessingSuccess(
    Map<String, dynamic> result, {
    List<XFile>? screenedPhotos,
  }) {
    if (!mounted) return;

    setState(() {
      _analysisResult = _mergeAnalysisResults(result);
      _isProcessing = false;
    });

    // Add analysis message after delay
    Future.delayed(_messageDelayDuration, () {
      if (mounted) {
        _addAnalysisCompleteMessage(
          screenedPhotos: screenedPhotos,
          batchResult: result,
        );
      }
    });
  }

  /// Merge new screening results into existing analysis context for chat.
  Map<String, dynamic> _mergeAnalysisResults(Map<String, dynamic> incoming) {
    final existing = _analysisResult;
    if (existing == null || existing['success'] != true) {
      return incoming;
    }

    final merged = List<Map<String, dynamic>>.from(
      ScreeningService.extractResults(existing),
    );
    merged.addAll(ScreeningService.extractResults(incoming));

    return {
      'success': true,
      'source': 'local_screening',
      'results': merged,
      if (merged.isNotEmpty) 'primary': merged.first,
    };
  }

  /// Handle processing error
  void _handleProcessingError(String error) {
    if (!mounted) return;
    setState(() {
      _errorMessage = error;
      _isProcessing = false;
    });
    _addAIMessage(error);
  }

  /// Add formatted analysis results message to chat
  Future<void> _addAnalysisCompleteMessage({
    List<XFile>? screenedPhotos,
    Map<String, dynamic>? batchResult,
  }) async {
    if (!_isAnalysisSuccessful) return;

    final photosForAttach = screenedPhotos ?? _photos;
    final reports = ScreeningService.extractResults(
      batchResult ?? _analysisResult!,
    );

    if (reports.isNotEmpty) {
      for (var i = 0; i < reports.length; i++) {
        if (reports[i]['local_path'] == null && i < photosForAttach.length) {
          reports[i]['local_path'] = photosForAttach[i].path;
          reports[i]['filename'] ??= photosForAttach[i].name;
        }
        final sourcePath = reports[i]['local_path']?.toString();
        if (sourcePath != null) {
          final savedPath = await HealthStatisticsStore.savedPathFor(sourcePath);
          if (savedPath != null) reports[i]['local_path'] = savedPath;
          await HealthStatisticsStore.updateScreening(
            sourcePath: sourcePath,
            drLabel: _labelOf(reports[i]['diabetic_retinopathy']),
            glaucomaLabel: _labelOf(reports[i]['glaucoma']),
          );
        }
      }
      if (!mounted) return;
      _addScreeningReports(reports);
      return;
    }

    _addAIMessage(_closingMessage);
  }

  String? _labelOf(dynamic section) {
    if (section is Map) return section['label']?.toString();
    return null;
  }

  /// Check if analysis was successful
  bool get _isAnalysisSuccessful =>
      _analysisResult != null && _analysisResult!['success'] == true;

  /// Send user message to AI service
  Future<void> _sendMessage() async {
    final userMessage = _messageController.text.trim();
    if (userMessage.isEmpty || _isSendingMessage) return;

    _addUserMessage(userMessage);
    _messageController.clear();

    setState(() => _isSendingMessage = true);

    try {
      await _processUserMessage(userMessage);
    } catch (e) {
      _handleMessageError(e);
    } finally {
      if (mounted) {
        setState(() => _isSendingMessage = false);
      }
    }
  }

  /// Process user message with AI service
  Future<void> _processUserMessage(String userMessage) async {
    if (!HfService.isConfigured()) {
      _addAIMessage(
        'I apologize, but the AI service is not configured. Please check your API settings and try again.',
      );
      return;
    }

    final response = await HfService.sendChatMessage(
      userMessage: userMessage,
      chatHistory: _getChatHistoryForApi(),
      analysisContext: _analysisResult,
    );

    final aiMessage = _extractResponseMessage(response);
    _addAIMessage(aiMessage);
  }

  /// Get chat history formatted for API
  List<Map<String, dynamic>> _getChatHistoryForApi() {
    return _messages
        .take(_messages.length - 1) // Exclude current user message
        .map((msg) => msg.toMap())
        .toList();
  }

  /// Extract message from API response
  String _extractResponseMessage(Map<String, dynamic> response) {
    if (response['success'] == true) {
      return response['message'] ?? 'No response received.';
    } else {
      return response['message'] ??
          'I apologize, but I encountered an error processing your message. Please try again.';
    }
  }

  /// Handle message sending error
  void _handleMessageError(dynamic error) {
    final errorMessage =
        'I apologize, but I encountered an error: ${error.toString()}. Please try again in a moment.';
    _addAIMessage(errorMessage);
  }

  /// Calculate responsive font size based on screen width
  double _getResponsiveFontSize(double screenWidth) {
    if (screenWidth < 360) return 14.0;
    if (screenWidth < 480) return 16.0;
    if (screenWidth < 600) return 18.0;
    return 32.0;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final fontSize = _getResponsiveFontSize(screenWidth);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading:
            widget.showBackButton
                ? IconButton(
                  icon: const Icon(Icons.chevron_left, size: 32),
                  onPressed: () => Navigator.pop(context),
                )
                : null,
        automaticallyImplyLeading: false,
        title: const Text(
          'Eye Health Assistant',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        titleSpacing: widget.showBackButton ? 0 : 16,
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_messages.isNotEmpty)
                      ChatThread(
                        messages: _messages,
                        isSending: _isSendingMessage,
                        hasPhotos: _hasPhotos,
                        fontSize: fontSize,
                        thinkingText: _aiThinkingText,
                        maxLines: _maxChatBubbleLines,
                        maxWidthRatio: _maxMessageWidthRatio,
                        avatarSize: _avatarSize,
                      ),
                    if (_isProcessing) const _ScreeningProgress(),
                  ],
                ),
              ),
            ),
            ChatComposer(
              controller: _messageController,
              hintText: _getHintText(),
              inputEnabled: !_isProcessing,
              sendEnabled: !_isSendingMessage && !_isProcessing,
              attachEnabled:
                  !_isProcessing && !_isSendingMessage && !_isPickingMore,
              isAttaching: _isPickingMore,
              isTab: !widget.showBackButton,
              onSend: _sendMessage,
              onAttach: _uploadMorePhotos,
            ),
          ],
        ),
      ),
    );
  }

}

class _ScreeningProgress extends StatelessWidget {
  const _ScreeningProgress();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}
