// frontend/lib/screens/meal_board_screen.dart - 캐시 서비스 적용
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meal_model.dart';
import '../models/post_model.dart';
import '../services/cached_api_service.dart';
import 'post_detail_screen.dart';
import 'post_create_screen.dart';
import '../utils/date_utils.dart' as DateUtilsCustom;

class MealBoardScreen extends StatefulWidget {
  final Meal meal;
  final String date;

  const MealBoardScreen({
    Key? key,
    required this.meal,
    required this.date,
  }) : super(key: key);

  @override
  _MealBoardScreenState createState() => _MealBoardScreenState();
}

class _MealBoardScreenState extends State<MealBoardScreen> {
  late Future<List<Post>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  void _loadPosts() {
    setState(() {
      _postsFuture = _fetchPosts();
    });
  }

  Future<List<Post>> _fetchPosts() async {
    try {
      final apiService = Provider.of<CachedApiService>(context, listen: false);

      // 날짜를 API 형식으로 변환
      final formattedDate = DateUtilsCustom.DateUtils.formatToApiDate(widget.date);

      print('게시글 조회 - 날짜: $formattedDate, 식사: ${widget.meal.mealType}');

      final posts = await apiService.getPosts(formattedDate, widget.meal.mealType);
      return posts;
    } catch (e) {
      print('게시글 로드 오류: $e');
      // 오류 발생 시 빈 리스트 반환
      return [];
    }
  }

  Color _getMealTypeColor(String mealType) {
    switch (mealType) {
      case '아침':
        return Colors.orange;
      case '점심':
        return Colors.green;
      case '저녁':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.meal.mealType} 메뉴'),
        backgroundColor: _getMealTypeColor(widget.meal.mealType),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 메뉴 정보 헤더
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _getMealTypeColor(widget.meal.mealType).withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getMealTypeColor(widget.meal.mealType),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        widget.meal.mealType,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      DateUtilsCustom.DateUtils.formatForDisplay(widget.date),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.meal.mealType} 메뉴',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getMealTypeColor(widget.meal.mealType),
                        ),
                      ),
                      SizedBox(height: 8),
                      // 메뉴를 리스트 형태로 표시
                      ...widget.meal.content.split(',').map((item) =>
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Text('• ', style: TextStyle(color: _getMealTypeColor(widget.meal.mealType))),
                                Expanded(child: Text(item.trim(), style: TextStyle(fontSize: 15))),
                              ],
                            ),
                          ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 게시글 섹션
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FutureBuilder<List<Post>>(
                        future: _postsFuture,
                        builder: (context, snapshot) {
                          final count = snapshot.hasData ? snapshot.data!.length : 0;
                          return Text(
                            '게시글 ${count}개',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PostCreateScreen(
                                meal: widget.meal,
                                date: widget.date,
                              ),
                            ),
                          ).then((result) {
                            if (result == true) {
                              // 게시글 작성 후 새로고침
                              _loadPosts();
                            }
                          });
                        },
                        icon: Icon(Icons.edit, size: 16),
                        label: Text('글쓰기'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getMealTypeColor(widget.meal.mealType),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<Post>>(
                    future: _postsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.wifi_off, size: 48, color: Colors.orange),
                              SizedBox(height: 16),
                              Text(
                                '게시글을 불러올 수 없습니다.',
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '인터넷 연결을 확인해주세요.',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadPosts,
                                child: Text('다시 시도'),
                              ),
                            ],
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.article_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                '아직 게시글이 없습니다.',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '첫 번째 게시글을 작성해보세요!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        final posts = snapshot.data!;
                        return RefreshIndicator(
                          onRefresh: () async {
                            _loadPosts();
                          },
                          child: ListView.builder(
                            itemCount: posts.length,
                            itemBuilder: (context, index) {
                              final post = posts[index];
                              return _buildPostCard(post);
                            },
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(post: post),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              Text(
                post.content,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    post.author,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    DateUtilsCustom.DateUtils.formatRelativeTime(post.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  Spacer(),
                  Row(
                    children: [
                      Icon(Icons.thumb_up_outlined, size: 16, color: Colors.grey[500]),
                      SizedBox(width: 4),
                      Text('${post.likes}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      SizedBox(width: 12),
                      Icon(Icons.comment_outlined, size: 16, color: Colors.grey[500]),
                      SizedBox(width: 4),
                      Text('${post.commentCount}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}