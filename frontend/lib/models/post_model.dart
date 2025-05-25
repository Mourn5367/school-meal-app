// frontend/lib/models/post_model.dart
import '../utils/date_utils.dart' as DateUtilsCustom;

class Post {
  final int id;
  final String title;
  final String content;
  final String author;
  final DateTime createdAt;
  final int likes;
  final int commentCount;
  final String? imageUrl;

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.createdAt,
    required this.likes,
    required this.commentCount,
    this.imageUrl,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    // 안전한 날짜 파싱
    DateTime createdAt;
    try {
      final dateStr = json['created_at'];
      final parsedDate = DateUtilsCustom.DateUtils.parseDate(dateStr);
      createdAt = parsedDate ?? DateTime.now();
    } catch (e) {
      print('Post 날짜 파싱 오류: $e');
      createdAt = DateTime.now();
    }

    return Post(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      author: json['author'],
      createdAt: createdAt,
      likes: json['likes'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      imageUrl: json['image_url'],
    );
  }
}