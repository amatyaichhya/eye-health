import 'dart:io';

import 'package:eye_health/pages/image_processing_screen/chat_message.dart';
import 'package:eye_health/pages/image_processing_screen/widgets/chat_bubble.dart';
import 'package:eye_health/theme/app_theme.dart';
import 'package:eye_health/widgets/screening_report_card.dart';
import 'package:flutter/material.dart';

/// Scrollable list of chat rows, including the typing indicator.
class ChatThread extends StatelessWidget {
  final List<ChatMessage> messages;
  final bool isSending;
  final bool hasPhotos;
  final double fontSize;
  final int maxLines;
  final double maxWidthRatio;
  final double avatarSize;
  final String thinkingText;

  const ChatThread({
    super.key,
    required this.messages,
    required this.isSending,
    required this.hasPhotos,
    required this.fontSize,
    required this.thinkingText,
    this.maxLines = 4,
    this.maxWidthRatio = 0.75,
    this.avatarSize = 30,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: messages.length + (isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length && isSending) {
          return _TypingIndicator(
            avatarSize: avatarSize,
            thinkingText: thinkingText,
          );
        }
        return _ChatMessageRow(
          message: messages[index],
          index: index,
          hasPhotos: hasPhotos,
          fontSize: fontSize,
          maxLines: maxLines,
          maxWidthRatio: maxWidthRatio,
          avatarSize: avatarSize,
        );
      },
    );
  }
}

class _ChatMessageRow extends StatelessWidget {
  final ChatMessage message;
  final int index;
  final bool hasPhotos;
  final double fontSize;
  final int maxLines;
  final double maxWidthRatio;
  final double avatarSize;

  const _ChatMessageRow({
    required this.message,
    required this.index,
    required this.hasPhotos,
    required this.fontSize,
    required this.maxLines,
    required this.maxWidthRatio,
    required this.avatarSize,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isScreeningReport) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth * 0.8).clamp(
              0.0,
              constraints.maxWidth - avatarSize - 8,
            );
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AiAvatar(size: avatarSize),
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

    if (message.isUserPhotoUpload) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: _UserPhotoBubble(
                message: message,
                fontSize: fontSize,
                maxWidthRatio: maxWidthRatio,
              ),
            ),
            const SizedBox(width: 8),
            _UserAvatar(size: avatarSize),
          ],
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
          if (!message.isUser) ...[
            _AiAvatar(size: avatarSize),
            const SizedBox(width: 8),
          ],
          ChatBubble(
            message: message,
            index: index,
            hasImage: hasPhotos,
            fontSize: fontSize,
            maxLines: maxLines,
            maxWidthRatio: maxWidthRatio,
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            _UserAvatar(size: avatarSize),
          ],
        ],
      ),
    );
  }
}

class _UserPhotoBubble extends StatelessWidget {
  final ChatMessage message;
  final double fontSize;
  final double maxWidthRatio;

  const _UserPhotoBubble({
    required this.message,
    required this.fontSize,
    required this.maxWidthRatio,
  });

  @override
  Widget build(BuildContext context) {
    final paths = message.imagePaths ?? const <String>[];
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * maxWidthRatio,
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
          if (paths.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final path in paths)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(path),
                      width: paths.length == 1 ? 140 : 72,
                      height: paths.length == 1 ? 140 : 72,
                      fit: BoxFit.cover,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AiAvatar extends StatelessWidget {
  final double size;

  const _AiAvatar({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
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
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final double size;

  const _UserAvatar({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 4,
      height: size + 4,
      decoration: const BoxDecoration(
        color: AppColors.primarySoft,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person, color: AppColors.primaryDark, size: 20),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  final double avatarSize;
  final String thinkingText;

  const _TypingIndicator({
    required this.avatarSize,
    required this.thinkingText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AiAvatar(size: avatarSize),
          const SizedBox(width: 8),
          Container(
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
                  thinkingText,
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
          ),
        ],
      ),
    );
  }
}
