import 'dart:io';

import 'package:camera/camera.dart';
import 'package:eye_health/services/hf_service.dart';
import 'package:eye_health/services/screening_service.dart';
import 'package:eye_health/theme/app_theme.dart';
import 'package:eye_health/utils/utility_methods/color_print.dart';
import 'package:eye_health/widgets/screening_report_card.dart';
import 'package:flutter/material.dart';

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
  Map<String, dynamic>? _analysisResult;
  String? _errorMessage;
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
  static const double _photoDisplaySize = 180.0;
  static const double _multiplePhotoSize = 80.0;

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
    _initializeScreen();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Initialize screen based on whether photos are provided
  void _initializeScreen() {
    if (_hasPhotos) {
      _startProcessing();
    } else {
      _addInitialGreeting();
    }
  }

  /// Check if photos are available
  bool get _hasPhotos => widget.photos?.isNotEmpty ?? false;

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
  Future<void> _startProcessing() async {
    if (!_hasPhotos) return;

    _setProcessingState(true);

    try {
      if (!ScreeningService.isConfigured()) {
        _handleProcessingError(_screeningServerError);
        return;
      }

      final result = await ScreeningService.screenImages(widget.photos!);
      colorPrint('Screening response: $result');
      if (result['success'] == true) {
        _handleProcessingSuccess(result);
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
  void _handleProcessingSuccess(Map<String, dynamic> result) {
    if (!mounted) return;

    setState(() {
      _analysisResult = result;
      _isProcessing = false;
    });

    // Add analysis message after delay
    Future.delayed(_messageDelayDuration, () {
      if (mounted) {
        _addAnalysisCompleteMessage();
      }
    });
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
  void _addAnalysisCompleteMessage() {
    if (!_isAnalysisSuccessful) return;

    final reports = ScreeningService.extractResults(_analysisResult!);
    if (reports.isNotEmpty) {
      // Attach local paths from the uploaded photos if the API omitted them.
      for (var i = 0; i < reports.length; i++) {
        if (reports[i]['local_path'] == null &&
            widget.photos != null &&
            i < widget.photos!.length) {
          reports[i]['local_path'] = widget.photos![i].path;
          reports[i]['filename'] ??= widget.photos![i].name;
        }
      }
      _addScreeningReports(reports);
      return;
    }

    _addAIMessage(_closingMessage);
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
                    if (_hasPhotos) ...[
                      _buildPhotoSection(),
                      const SizedBox(height: 24),
                    ],
                    if (_isProcessing) _buildLoadingIndicator(),
                    if (_messages.isNotEmpty) _buildChatMessages(fontSize),
                  ],
                ),
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  /// Build photo display section
  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPhotoHeader(),
        const SizedBox(height: 12),
        _buildPhotoDisplay(),
      ],
    );
  }

  /// Build photo section header
  Widget _buildPhotoHeader() {
    return const Row(
      children: [
        Icon(Icons.image_outlined, color: AppColors.primaryDark, size: 22),
        SizedBox(width: 8),
        Text(
          _fundusPhotoTakenText,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  /// Build photo display widget
  Widget _buildPhotoDisplay() {
    if (widget.photos?.length == 1) {
      return _buildSinglePhotoDisplay();
    } else {
      return _buildMultiplePhotosDisplay();
    }
  }

  /// Build single photo display
  Widget _buildSinglePhotoDisplay() {
    return Align(
      alignment: Alignment.topRight,
      child: Container(
        width: _photoDisplaySize,
        height: _photoDisplaySize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
        padding: const EdgeInsets.all(8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.file(File(widget.photos!.first.path), fit: BoxFit.cover),
        ),
      ),
    );
  }

  /// Build multiple photos display
  Widget _buildMultiplePhotosDisplay() {
    return SizedBox(
      height: 124,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(top: 6, right: 6),
        clipBehavior: Clip.none,
        itemCount: widget.photos?.length ?? 0,
        itemBuilder: (context, index) => _buildPhotoItem(index),
      ),
    );
  }

  /// Build individual photo item for multiple photos
  Widget _buildPhotoItem(int index) {
    final isLastItem = index == (widget.photos?.length ?? 0) - 1;

    return Container(
      margin: EdgeInsets.only(right: isLastItem ? 0 : 12),
      child: Column(
        children: [
          _buildPhotoThumbnail(index),
          const SizedBox(height: 8),
          _buildPhotoLabel(index),
        ],
      ),
    );
  }

  /// Build photo thumbnail
  Widget _buildPhotoThumbnail(int index) {
    return SizedBox(
      width: _multiplePhotoSize,
      height: _multiplePhotoSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: _multiplePhotoSize,
            height: _multiplePhotoSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(38),
              child: Image.file(
                File(widget.photos![index].path),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          _buildPhotoNumberBadge(index),
        ],
      ),
    );
  }

  /// Floating notification-style number badge
  Widget _buildPhotoNumberBadge(int index) {
    return Positioned(
      top: 2,
      right: -4,
      child: Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          '${index + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }

  /// Build photo label
  Widget _buildPhotoLabel(int index) {
    return Text(
      'Photo ${index + 1}',
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// Build loading indicator
  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  /// Build chat messages list
  Widget _buildChatMessages(double fontSize) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _messages.length + (_isSendingMessage ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isSendingMessage) {
          return _buildTypingIndicator();
        }
        return _buildChatMessageItem(index, fontSize);
      },
    );
  }

  /// Build typing indicator
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAIAvatar(),
          const SizedBox(width: 8),
          _buildTypingBubble(),
        ],
      ),
    );
  }

  /// Build typing bubble
  Widget _buildTypingBubble() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _aiThinkingText,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(width: 8),
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual chat message item
  Widget _buildChatMessageItem(int index, double fontSize) {
    final message = _messages[index];

    if (message.isScreeningReport) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth * 0.8)
                .clamp(0.0, constraints.maxWidth - _avatarSize - 8);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAIAvatar(),
                const SizedBox(width: 8),
                SizedBox(
                  width: cardWidth,
                  child: ScreeningReportCard(
                    result: message.screeningResult!,
                    imagePath: message.imagePath,
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[_buildAIAvatar(), const SizedBox(width: 8)],
          ChatBubble(
            message: message,
            index: index,
            hasImage: _hasPhotos,
            fontSize: fontSize,
            maxLines: _maxChatBubbleLines,
            maxWidthRatio: _maxMessageWidthRatio,
          ),
          if (message.isUser) ...[const SizedBox(width: 8), _buildUserAvatar()],
        ],
      ),
    );
  }

  /// Build AI avatar
  Widget _buildAIAvatar() {
    return Container(
      width: _avatarSize,
      height: _avatarSize,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 6,
            spreadRadius: 0.5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/icons/launcher_icon.png',
          width: _avatarSize,
          height: _avatarSize,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  /// Build user avatar
  Widget _buildUserAvatar() {
    return Container(
      width: _avatarSize + 4,
      height: _avatarSize + 4,
      decoration: const BoxDecoration(
        color: AppColors.primarySoft,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person,
        color: AppColors.primaryDark,
        size: 20,
      ),
    );
  }

  /// Build message input section
  Widget _buildMessageInput() {
    final isTab = !widget.showBackButton;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, isTab ? 8 : 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        // Tab mode: bottom nav handles SafeArea; leave room above the bar.
        bottom: !isTab,
        child: Padding(
          padding: EdgeInsets.only(bottom: isTab ? 72 : 0),
          child: Row(
            children: [
              Expanded(child: _buildTextInput()),
              const SizedBox(width: 12),
              _buildSendButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build text input field
  Widget _buildTextInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: _messageController,
        enabled: !_isProcessing,
        decoration: InputDecoration(
          hintText: _getHintText(),
          hintStyle: TextStyle(color: Colors.grey.shade500),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
        ),
        onSubmitted: (_) => _isProcessing ? null : _sendMessage(),
        maxLines: null,
        textCapitalization: TextCapitalization.sentences,
      ),
    );
  }

  /// Build send button
  Widget _buildSendButton() {
    final isDisabled = _isSendingMessage || _isProcessing;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isDisabled ? Colors.grey : AppColors.primary,
        shape: BoxShape.circle,
      ),
      child:
          isDisabled
              ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
              : IconButton(
                onPressed: isDisabled ? null : _sendMessage,
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
    );
  }
}

/// Data model for chat messages
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Map<String, dynamic>? screeningResult;
  final String? imagePath;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.screeningResult,
    this.imagePath,
  });

  bool get isScreeningReport => screeningResult != null;

  Map<String, dynamic> toMap() {
    return {'text': text, 'isUser': isUser, 'timestamp': timestamp};
  }
}

/// Reusable chat bubble widget with expand/collapse functionality
class ChatBubble extends StatefulWidget {
  final ChatMessage message;
  final int index;
  final bool hasImage;
  final double fontSize;
  final int maxLines;
  final double maxWidthRatio;

  const ChatBubble({
    super.key,
    required this.message,
    required this.index,
    required this.hasImage,
    this.fontSize = 14.0,
    this.maxLines = 4,
    this.maxWidthRatio = 0.75,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool isExpanded = false;
  bool needsExpansion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfExpansionNeeded();
    });
  }

  /// Check if text needs expansion toggle
  void _checkIfExpansionNeeded() {
    final textPainter = TextPainter(
      text: TextSpan(
        text: widget.message.text,
        style: const TextStyle(fontSize: 14, height: 1.4),
      ),
      maxLines: widget.maxLines,
      textDirection: TextDirection.ltr,
    );

    final maxWidth =
        MediaQuery.of(context).size.width * widget.maxWidthRatio - 32;
    textPainter.layout(maxWidth: maxWidth);

    if (mounted) {
      setState(() {
        needsExpansion = textPainter.didExceedMaxLines;
      });
    }
  }

  /// Toggle expansion state
  void _toggleExpansion() {
    setState(() => isExpanded = !isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * widget.maxWidthRatio,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: widget.message.isUser ? AppColors.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(widget.message.isUser ? 18 : 4),
            bottomRight: Radius.circular(widget.message.isUser ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMessageText(),
            if (needsExpansion) _buildExpandToggle(),
          ],
        ),
      ),
    );
  }

  /// Build message text
  Widget _buildMessageText() {
    return Text(
      widget.message.text,
      style: TextStyle(
        fontSize: widget.fontSize,
        height: 1.4,
        color: widget.message.isUser ? Colors.white : Colors.black87,
      ),
      maxLines: isExpanded ? null : widget.maxLines,
      overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
    );
  }

  /// Build expand/collapse toggle
  Widget _buildExpandToggle() {
    return Align(
      alignment: Alignment.centerRight,
      child: InkWell(
        onTap: _toggleExpansion,
        child: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Text(
            isExpanded ? 'Read less' : 'more',
            style: TextStyle(
              color: widget.message.isUser ? Colors.white70 : Colors.blue,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

// Example local screening API response (POST /screen):
// {
//   "success": true,
//   "filename": "20170413112758639.jpg",
//   "diabetic_retinopathy": {
//     "grade": 1,
//     "label": "Mild NPDR",
//     "probabilities": {
//       "0": 0.1878,
//       "1": 0.2225,
//       "2": 0.1925,
//       "3": 0.1754,
//       "4": 0.2218
//     }
//   },
//   "glaucoma": {
//     "positive": true,
//     "class_index": 1,
//     "label": "Suggestive of glaucoma",
//     "probabilities": {
//       "negative": 0.0,
//       "positive": 1.0
//     }
//   }
// }