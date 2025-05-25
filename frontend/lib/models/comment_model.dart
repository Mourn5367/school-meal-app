// frontend/lib/models/comment_model.dart
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
    return Comment(
      id: json['id'],
      content: json['content'],
      author: json['author'],
      createdAt: DateTime.parse(json['created_at']),
      likes: json['likes'] ?? 0,
    );
  }
}