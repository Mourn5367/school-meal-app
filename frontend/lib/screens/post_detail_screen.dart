// frontend/lib/screens/post_detail_screen.dart - 시간 표시 개선
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../utils/date_utils.dart' as DateUtilsCustom;

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({Key? key, required this.post}) : super(key: key);

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Future<Map<String, dynamic>> _postDetailFuture;
  TextEditingController _commentController = TextEditingController();
  TextEditingController _authorController = TextEditingController();
  bool isLiked = false;
  int likeCount = 0;
  Map<int, bool> commentLikedStatus = {}; // 댓글별 좋아요 상태

  @override
  void initState() {
    super.initState();
    likeCount = widget.post.likes;
    _loadPostDetail();
  }

  void _loadPostDetail() {
    setState(() {
      _postDetailFuture = _fetchPostDetail();
    });
  }

  Future<Map<String, dynamic>> _fetchPostDetail() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      return await apiService.getPostDetail(widget.post.id);
    } catch (e) {
      print('게시글 상세 조회 오류: $e');
      // 오류 발생 시 기본 데이터 반환
      return {
        'post': widget.post,
        'comments': <Comment>[],
      };
    }
  }

  Future<void> _toggleLike() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.togglePostLike(widget.post.id);

      setState(() {
        isLiked = result['liked'];
        likeCount = result['likes'];
      });
    } catch (e) {
      print('좋아요 처리 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('좋아요 처리 중 오류가 발생했습니다')),
      );
    }
  }

  Future<void> _toggleCommentLike(int commentId, int currentLikes) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.toggleCommentLike(commentId);

      setState(() {
        commentLikedStatus[commentId] = result['liked'];
      });

      // 댓글 목록 새로고침
      _loadPostDetail();

    } catch (e) {
      print('댓글 좋아요 처리 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('댓글 좋아요 처리 중 오류가 발생했습니다')),
      );
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty || _authorController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('닉네임과 댓글 내용을 모두 입력해주세요')),
      );
      return;
    }

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.createComment(
        postId: widget.post.id,
        content: _commentController.text.trim(),
        author: _authorController.text.trim(),
      );

      _commentController.clear();
      _authorController.clear();

      // 키보드 숨기기
      FocusScope.of(context).unfocus();

      // 댓글 목록 새로고침
      _loadPostDetail();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('댓글이 작성되었습니다')),
      );
    } catch (e) {
      print('댓글 작성 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('댓글 작성 중 오류가 발생했습니다')),
      );
    }
  }

  // 이미지 표시를 위한 개선된 위젯
  Widget _buildImageWidget(String? imageUrl) {
    if (imageUrl == null) return SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          '${ApiConfig.baseUrl}$imageUrl',
          fit: BoxFit.scaleDown, // 너비에 맞추고 높이는 자동 조절
          alignment: Alignment.center,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                      Icons.broken_image_outlined,
                      size: 48,
                      color: Colors.grey[400]
                  ),
                  SizedBox(height: 8),
                  Text(
                    '이미지를 불러올 수 없습니다',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                    SizedBox(height: 12),
                    Text(
                      '이미지 로딩 중...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('게시글'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadPostDetail,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _postDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text('게시글을 불러올 수 없습니다.'),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loadPostDetail,
                    child: Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          final post = data['post'] as Post;
          final comments = data['comments'] as List<Comment>;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 게시글 내용
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.title,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  post.author,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  // 수정된 부분: DateUtils의 상대 시간 함수 사용
                                  DateUtilsCustom.DateUtils.formatRelativeTime(post.createdAt),
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),

                            Text(
                              post.content,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),

                            // 개선된 이미지 표시
                            _buildImageWidget(post.imageUrl),

                            SizedBox(height: 20),

                            // 좋아요/댓글 버튼
                            Row(
                              children: [
                                InkWell(
                                  onTap: _toggleLike,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isLiked ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                                          color: isLiked ? Colors.blue : Colors.grey[600],
                                          size: 20,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          '$likeCount',
                                          style: TextStyle(
                                            color: isLiked ? Colors.blue : Colors.grey[600],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(width: 20),
                                Row(
                                  children: [
                                    Icon(Icons.comment_outlined, color: Colors.grey[600], size: 20),
                                    SizedBox(width: 4),
                                    Text(
                                      '${comments.length}',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      Divider(thickness: 8, color: Colors.grey[100]),

                      // 댓글 섹션
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Text(
                          '댓글 ${comments.length}개',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // 댓글 리스트
                      if (comments.isEmpty)
                        Container(
                          padding: EdgeInsets.all(40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.comment_outlined, size: 48, color: Colors.grey[400]),
                                SizedBox(height: 16),
                                Text(
                                  '아직 댓글이 없습니다.',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '첫 번째 댓글을 작성해보세요!',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            return _buildCommentItem(comment);
                          },
                        ),

                      SizedBox(height: 100), // 댓글 입력창 공간 확보
                    ],
                  ),
                ),
              ),

              // 댓글 입력창
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: Offset(0, -1),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      // 닉네임 입력
                      TextField(
                        controller: _authorController,
                        decoration: InputDecoration(
                          hintText: '닉네임을 입력하세요',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                      ),
                      SizedBox(height: 8),
                      // 댓글 입력
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              decoration: InputDecoration(
                                hintText: '댓글을 입력하세요...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              maxLines: null,
                            ),
                          ),
                          SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: IconButton(
                              icon: Icon(Icons.send, color: Colors.white, size: 20),
                              onPressed: _addComment,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCommentItem(Comment comment) {
    final isLiked = commentLikedStatus[comment.id] ?? false;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[300],
            child: Text(
              comment.author.substring(0, 1).toUpperCase(),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.author,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      // 수정된 부분: DateUtils의 상대 시간 함수 사용
                      DateUtilsCustom.DateUtils.formatRelativeTime(comment.createdAt),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  comment.content,
                  style: TextStyle(fontSize: 14, height: 1.4),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    InkWell(
                      onTap: () => _toggleCommentLike(comment.id, comment.likes),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isLiked ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                                isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                                size: 14,
                                color: isLiked ? Colors.blue : Colors.grey[500]
                            ),
                            SizedBox(width: 4),
                            Text(
                                '${comment.likes}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isLiked ? Colors.blue : Colors.grey[500],
                                  fontWeight: isLiked ? FontWeight.bold : FontWeight.normal,
                                )
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _authorController.dispose();
    super.dispose();
  }
}