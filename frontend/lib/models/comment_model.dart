// frontend/lib/models/comment_model.dart
import '../utils/date_utils.dart' as DateUtilsCustom;

class Comment {
  final int id;
  final String content;
  final String author;
  final DateTime createdAt;
  final int likes;

  Comment({
    required this.id,
    required this.content,
    required this.author,
    required this.createdAt,
    required this.likes,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    // 안전한 날짜 파싱
    DateTime createdAt;
    try {
      final dateStr = json['created_at'];
      final parsedDate = DateUtilsCustom.DateUtils.parseDate(dateStr);
      createdAt = parsedDate ?? DateTime.now();
    } catch (e) {
      print('Comment 날짜 파싱 오류: $e');
      createdAt = DateTime.now();
    }

    return Comment(
      id: json['id'],
      content: json['content'],
      author: json['author'],
      createdAt: createdAt,
      likes: json['likes'] ?? 0,
    );
  }
}