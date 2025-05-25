// frontend/lib/screens/post_detail_screen.dart
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import 'package:intl/intl.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({Key? key, required this.post}) : super(key: key);

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  List<Comment> comments = [];
  TextEditingController _commentController = TextEditingController();
  bool isLiked = false;
  int likeCount = 0;

  @override
  void initState() {
    super.initState();
    likeCount = widget.post.likes;
    _loadDummyComments();
  }

  void _loadDummyComments() {
    // 더미 댓글 데이터
    comments = [
      Comment(
        id: 1,
        content: "저도 오늘 토스트 먹었는데 정말 맛있었어요!",
        author: "user1",
        createdAt: DateTime.now().subtract(Duration(hours: 1)),
        likes: 3,
      ),
      Comment(
        id: 2,
        content: "다음에도 또 나왔으면 좋겠네요",
        author: "user2",
        createdAt: DateTime.now().subtract(Duration(minutes: 30)),
        likes: 1,
      ),
      Comment(
        id: 3,
        content: "고추장이 정말 잘 어울렸죠! 저도 인정합니다 👍",
        author: "user3",
        createdAt: DateTime.now().subtract(Duration(minutes: 15)),
        likes: 2,
      ),
    ];
  }

  void _toggleLike() {
    setState(() {
      if (isLiked) {
        likeCount--;
        isLiked = false;
      } else {
        likeCount++;
        isLiked = true;
      }
    });
  }

  void _addComment() {
    if (_commentController.text.trim().isNotEmpty) {
      setState(() {
        comments.add(
          Comment(
            id: comments.length + 1,
            content: _commentController.text.trim(),
            author: "나",
            createdAt: DateTime.now(),
            likes: 0,
          ),
        );
      });
      _commentController.clear();
      
      // 키보드 숨기기
      FocusScope.of(context).unfocus();
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else {
      return DateFormat('MM-dd HH:mm').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('게시글'),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {
              // 더보기 메뉴
            },
          ),
        ],
      ),
      body: Column(
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
                          widget.post.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              widget.post.author,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              _formatDateTime(widget.post.createdAt),
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        
                        // 이미지가 있다면 표시
                        if (widget.post.imageUrl != null) ...[
                          Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.image,
                              size: 50,
                              color: Colors.grey[400],
                            ),
                          ),
                          SizedBox(height: 16),
                        ],
                        
                        Text(
                          widget.post.content,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 20),
                        
                        // 좋아요/댓글 버튼
                        Row(
                          children: [
                            InkWell(
                              onTap: _toggleLike,
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
            ),
            child: SafeArea(
              child: Row(
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Comment comment) {
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
                      _formatDateTime(comment.createdAt),
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
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        // 댓글 좋아요 기능
                      },
                      child: Row(
                        children: [
                          Icon(Icons.thumb_up_outlined, size: 14, color: Colors.grey[500]),
                          SizedBox(width: 4),
                          Text('${comment.likes}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    InkWell(
                      onTap: () {
                        // 답글 기능
                      },
                      child: Text(
                        '답글',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
    super.dispose();
  }
}