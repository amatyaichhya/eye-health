/// One row in the eye-health assistant chat.
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Map<String, dynamic>? screeningResult;
  final String? imagePath;
  final List<String>? imagePaths;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.screeningResult,
    this.imagePath,
    this.imagePaths,
  });

  bool get isScreeningReport => screeningResult != null;
  bool get isUserPhotoUpload =>
      isUser && imagePaths != null && imagePaths!.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {'text': text, 'isUser': isUser, 'timestamp': timestamp};
  }
}
