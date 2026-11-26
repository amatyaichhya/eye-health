import 'package:eye_health/pages/image_processing_screen/chat_message.dart';
import 'package:flutter/material.dart';

/// Expandable text bubble for a user or assistant message.
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
          color: widget.message.isUser ? Colors.white : Colors.grey.shade200,
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

  Widget _buildMessageText() {
    return Text(
      widget.message.text,
      style: TextStyle(
        fontSize: widget.fontSize,
        height: 1.4,
        color: Colors.black87,
      ),
      maxLines: isExpanded ? null : widget.maxLines,
      overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
    );
  }

  Widget _buildExpandToggle() {
    return Align(
      alignment: Alignment.centerRight,
      child: InkWell(
        onTap: _toggleExpansion,
        child: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Text(
            isExpanded ? 'Read less' : 'more',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
