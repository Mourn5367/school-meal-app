// frontend/lib/models/post_model.dart
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
    return Post(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      author: json['author'],
      createdAt: DateTime.parse(json['created_at']),
      likes: json['likes'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      imageUrl: json['image_url'],
    );
  }
}