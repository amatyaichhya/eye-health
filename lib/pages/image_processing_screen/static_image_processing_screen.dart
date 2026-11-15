import 'dart:io';

import 'package:camera/camera.dart';
import 'package:eye_health/global_widget/eye_health_appbar.dart';
import 'package:eye_health/utils/utility_methods/color_print.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class StaticImageProcessingScreen extends StatefulWidget {
  final List<XFile>? photos;

  const StaticImageProcessingScreen({super.key, this.photos});

  @override
  State<StaticImageProcessingScreen> createState() =>
      _StaticImageProcessingScreenState();
}

class _StaticImageProcessingScreenState
    extends State<StaticImageProcessingScreen> {
  bool _isProcessing = false;
  Map<String, dynamic>? _analysisResult;
  String? _errorMessage;
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  static const String _appTitle = 'EYEHEALTH';

  @override
  void initState() {
    super.initState();
    _startProcessing();
    showStatusBar();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _startProcessing() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    // Simulate processing delay only if photos are provided
    if (widget.photos != null && widget.photos!.isNotEmpty) {
      await Future.delayed(const Duration(seconds: 2));
    }

    // Demo response - no API call needed
    final demoResult =
        widget.photos != null && widget.photos!.isNotEmpty
            ? {
              'success': true,
              'analysis': {
                'likelihood': 'Moderate',
                'confidence': '85%',
                'possible_condition': 'Diabetic Retinopathy',
                'description':
                    widget.photos?.length == 1
                        ? 'Your fundus examination report has been generated. I can answer any questions you may have.'
                        : 'Analysis of ${widget.photos?.length} fundus images shows consistent evidence of diabetic retinopathy across multiple views. The retinal examination reveals microaneurysms, dot and blot hemorrhages, and hard exudates. The optic discs appear normal with good rim coloration. Multiple angles confirm moderate to severe non-proliferative diabetic retinopathy changes with circumferential macular involvement.',
                'visual_indicators': [
                  'Microaneurysms present',
                  'Dot and blot hemorrhages',
                  'Hard exudates visible',
                  'Vessel changes consistent with diabetic retinopathy',
                  if (widget.photos?.length != null &&
                      widget.photos!.length > 1)
                    'Consistent findings across ${widget.photos!.length} images',
                ],
                'recommendations': [
                  'Consult with ophthalmologist',
                  'Regular eye examinations',
                  'Blood sugar control',
                  'Monitor for progression',
                  if (widget.photos?.length != null &&
                      widget.photos!.length > 1)
                    'Multiple angle analysis confirms diagnosis',
                ],
              },
            }
            : null;

    if (mounted) {
      setState(() {
        _analysisResult = demoResult;
        _isProcessing = false;
      });

      // Add initial AI greeting message
      if (widget.photos != null && widget.photos!.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _messages.add({
              'text':
                  widget.photos != null && widget.photos!.isNotEmpty
                      ? 'The vessels of the right eye are normal; however, there is a peripheral inferior nasal lesion surrounded by extensive cotton wool spots (CWS) in the circumpapillary region and along the retinal arterioles, suggestive of localized retinal ischemia and indicative of moderate to severe non-proliferative diabetic retinopathy (NPDR). Further evaluation with optical coherence tomography (OCT) and fluorescein angiography (FA) is recommended to assess for macular edema, areas of non-perfusion, or early neovascular changes. The patient should be referred to their primary care provider or endocrinologist for optimization of systemic glucose, blood pressure, and lipid levels. A follow-up retinal exam is advised within 4–6 weeks to monitor disease progression. If neovascularization or macular involvement is confirmed, treatment with pan-retinal photocoagulation (PRP) or intravitreal anti-VEGF injections should be considered. Patient education on the importance of regular ophthalmic follow-up and tight systemic control is essential to reduce the risk of vision loss.'
                      : 'Hello! I\'m your AI Eye Health Assistant. I can help you with questions about eye health, diabetic retinopathy, preventive care, and general eye wellness. How can I assist you today?',
              'isUser': false,
              'timestamp': DateTime.now(),
            });
            _messages.add({
              'text':
                  'Your fundus examination report has been generated. I can answer any questions you may have',
              'isUser': false,
              'timestamp': DateTime.now(),
            });

            setState(() {});
          }
        });
      } else {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _messages.add({
              'text':
                  'Hi, I’m your Eye Health Assistant. Ask me anything about your eyes or vision care!',
              'isUser': false,
              'timestamp': DateTime.now(),
            });

            setState(() {});
          }
        });
      }
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    setState(() {
      _messages.add({
        'text': userMessage,
        'isUser': true,
        'timestamp': DateTime.now(),
      });
    });

    _messageController.clear();

    // Simulate AI response delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'text': _getDemoResponse(userMessage),
            'isUser': false,
            'timestamp': DateTime.now(),
          });
        });
      }
    });
  }

  String _getDemoResponse(String userMessage) {
    final message = userMessage.toLowerCase();

    if (message.contains('treatment') || message.contains('cure')) {
      return 'For diabetic retinopathy, treatment options include laser therapy, anti-VEGF injections, and strict blood sugar control. Please consult with your ophthalmologist for personalized treatment recommendations.';
    } else if (message.contains('serious') || message.contains('dangerous')) {
      return 'Diabetic retinopathy can be serious if left untreated, but with proper management and regular monitoring, vision loss can often be prevented or slowed.';
    } else if (message.contains('diet') || message.contains('food')) {
      return 'A diabetic-friendly diet with controlled carbohydrates, regular meals, and avoiding high sugar foods can help manage blood sugar levels and slow retinopathy progression.';
    } else if (message.contains('exercise')) {
      return 'Regular moderate exercise can help control blood sugar levels. However, avoid high-intensity activities that might increase eye pressure. Consult your doctor before starting any exercise program.';
    } else {
      return 'Based on your fundus scan, I recommend regular monitoring and maintaining good blood sugar control. For specific medical advice, please consult with your healthcare provider.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    final fontSize =
        screenWidth < 360
            ? 14.0
            : screenWidth < 480
            ? 16.0
            : screenWidth < 600
            ? 18.0
            : 32.0;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: EyeHealthAppbar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fundus photo section - only show if photos exist
                  if (widget.photos != null && widget.photos!.isNotEmpty) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.green[900],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 8),

                            const Text(
                              'Fundus photo taken:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Photo display
                        if (widget.photos?.length == 1)
                          // Single photo - circular display
                          Align(
                            alignment: Alignment.topRight,
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 2,
                                ),
                              ),
                              padding: EdgeInsets.all(8),

                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.file(
                                  File(widget.photos!.first.path),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          )
                        else
                          // Multiple photos - horizontal list
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: widget.photos?.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  margin: EdgeInsets.only(
                                    right:
                                        index < widget.photos!.length - 1
                                            ? 12
                                            : 0,
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            40,
                                          ),
                                          border: Border.all(
                                            color: Colors.teal,
                                            width: 2,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            38,
                                          ),
                                          child: Stack(
                                            children: [
                                              Image.file(
                                                File(
                                                  widget.photos![index].path,
                                                ),
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: double.infinity,
                                              ),
                                              // Photo number overlay
                                              Positioned(
                                                top: 4,
                                                right: 4,
                                                child: Container(
                                                  width: 20,
                                                  height: 20,
                                                  decoration: BoxDecoration(
                                                    color: Colors.teal,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: Colors.white,
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      '${index + 1}',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Photo ${index + 1}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),

                        const SizedBox(height: 24),
                      ],
                    ),

                    // Scan report section
                    if (false)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green[900],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/icons/launcher_icon.png',
                                width: 20,
                                height: 20,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Fundus exam report:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Text(
                                'Your fundus examination report has been generated.\nI can answer any questions you may have.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ],
                      ),
                    // const SizedBox(height: 12),

                    // Report content
                    if (_isProcessing)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(color: Colors.teal),
                        ),
                      )
                    else if (false ?? _analysisResult != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          _analysisResult!['analysis']['description'],
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                      ),

                    // const SizedBox(height: 24),
                  ],
                  // const SizedBox(height: 12),
                  // Messages section
                  if (_messages.isNotEmpty) ...[
                    // if (widget.photos != null && widget.photos!.isNotEmpty)
                    // const Divider(),
                    // const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isUser = message['isUser'] as bool;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            mainAxisAlignment:
                                isUser
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                            children: [
                              if (!isUser) ...[
                                // AI avatar aligned to bottom
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    // if(index != 0)
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.green[900],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: ClipOval(
                                        child: Image.asset(
                                          'assets/icons/launcher_icon.png',
                                          width: 30,
                                          height: 30,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                              ],

                              ChatBubble(
                                message: message,
                                isUser: isUser,
                                index: index,
                                hasImage:
                                    widget.photos != null &&
                                    widget.photos!.isNotEmpty,
                                fontSize: fontSize,
                              ),

                              // Message bubble
                              // Flexible(
                              //   child: Container(
                              //     constraints: BoxConstraints(
                              //       maxWidth: MediaQuery.of(context).size.width * 0.75,
                              //     ),
                              //     padding: const EdgeInsets.symmetric(
                              //       horizontal: 16,
                              //       vertical: 12,
                              //     ),
                              //     decoration: BoxDecoration(
                              //       color: isUser ? Colors.teal : Colors.grey.shade200,
                              //       borderRadius: BorderRadius.only(
                              //         topLeft: const Radius.circular(18),
                              //         topRight: const Radius.circular(18),
                              //         bottomLeft: Radius.circular(isUser ? 18 : 4),
                              //         bottomRight: Radius.circular(isUser ? 4 : 18),
                              //       ),
                              //     ),
                              //     child: Text(
                              //       message['text'],
                              //       style: TextStyle(
                              //         fontSize: 14,
                              //         height: 1.4,
                              //         color: isUser ? Colors.white : Colors.black87,
                              //       ),
                              //     ),
                              //   ),
                              // ),
                              if (isUser) ...[
                                const SizedBox(width: 8),
                                // User avatar aligned to bottom
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Message input section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                spacing: 6,
                children: [
                  //  Hi, I’m your Eye Health Assistant. Ask me anything about your eyes or vision care!
                  if (false)
                    Column(
                      children: [
                        Text(
                          (widget.photos?.isNotEmpty ?? false)
                              ? 'Your fundus examination report has been generated. I can answer any questions you may have'
                              : 'Hi, I’m your Eye Health Assistant. Ask me anything about your eyes or vision care!',
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              // Your fundus examination report has been generated. I can answer any questions you may have
                              hintText: 'Ask a question',
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ),
                      ),

                      SizedBox(width: 12),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Colors.teal,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _sendMessage,
                          icon: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatBubble extends StatefulWidget {
  final Map<String, dynamic> message;
  final bool isUser;
  final int index;
  final bool hasImage;
  final double fontSize;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    required this.index,
    required this.hasImage,
    this.fontSize = 14.0,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool isExpanded = false;
  bool needsExpansion = false;
  final int maxLines = 4;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfExpansionNeeded();
    });
  }

  void _checkIfExpansionNeeded() {
    final String text = widget.message['text'];
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 14, height: 1.4),
      ),
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
    );

    final maxWidth =
        MediaQuery.of(context).size.width * 0.75 - 32; // Account for padding
    textPainter.layout(maxWidth: maxWidth);

    if (mounted) {
      setState(() {
        needsExpansion = textPainter.didExceedMaxLines;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String text = widget.message['text'];

    return Flexible(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: widget.isUser ? Colors.teal : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(widget.isUser ? 18 : 4),
            bottomRight: Radius.circular(widget.isUser ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.index == 0 && !widget.isUser && widget.hasImage)
              Padding(
                padding: const EdgeInsets.only(bottom: 2.0),
                child: Text(
                  'Fundus exam report:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: widget.isUser ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            Text(
              text,
              style: TextStyle(
                fontSize: widget.fontSize,
                height: 1.4,
                color: widget.isUser ? Colors.white : Colors.black87,
              ),
              maxLines: isExpanded ? null : maxLines,
              overflow:
                  isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (needsExpansion)
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () => setState(() => isExpanded = !isExpanded),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      isExpanded ? 'Read less' : 'more',
                      style: TextStyle(
                        color: widget.isUser ? Colors.white70 : Colors.blue,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
