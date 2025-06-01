// frontend/lib/screens/meal_board_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meal_model.dart';
import '../models/post_model.dart';
import '../services/api_service.dart';
import 'post_detail_screen.dart';
import 'package:intl/intl.dart';
import 'post_create_screen.dart';
import '../utils/date_utils.dart' as DateUtilsCustom;
import 'dart:io';
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
      final apiService = Provider.of<ApiService>(context, listen: false);
      
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
                              Icon(Icons.error_outline, size: 48, color: Colors.red),
                              SizedBox(height: 16),
                              Text(
                                '게시글을 불러올 수 없습니다.',
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '${snapshot.error}',
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
                    _formatDateTime(post.createdAt),
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

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();

    print('=== 안드로이드 시간 계산 디버그 ===');
    print('플랫폼: ${Platform.isAndroid ? "Android" : "기타"}');
    print('원본 게시글 시간: $dateTime (UTC: ${dateTime.isUtc})');
    print('현재 시간: $now (UTC: ${now.isUtc})');

    // 안드로이드에서는 더 엄격한 시간 처리
    DateTime finalPostTime;
    DateTime finalNowTime;

    if (Platform.isAndroid) {
      // 안드로이드: 무조건 로컬 시간으로 통일
      finalPostTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;
      finalNowTime = now.isUtc ? now.toLocal() : now;

      print('안드로이드 로컬 변환:');
      print('  게시글: $finalPostTime');
      print('  현재: $finalNowTime');
    } else {
      // 다른 플랫폼: 기존 방식
      finalPostTime = dateTime;
      finalNowTime = now;
    }

    final difference = finalNowTime.difference(finalPostTime);

    print('최종 시간 차이: ${difference.inMinutes}분 (${difference.inHours}시간, ${difference.inDays}일)');
    print('차이가 음수인가? ${difference.isNegative}');
    print('================================');

    // 미래 시간인 경우 (시간대 오류 대응)
    if (difference.isNegative) {
      print('⚠️ 미래 시간 감지 - 절댓값으로 계산');
      final absoluteDifference = difference.abs();

      if (absoluteDifference.inMinutes < 60) {
        return '${absoluteDifference.inMinutes}분 전';
      } else if (absoluteDifference.inHours < 24) {
        return '${absoluteDifference.inHours}시간 전';
      } else {
        return '${absoluteDifference.inDays}일 전';
      }
    }

    // 정상적인 과거 시간 계산
    if (difference.inSeconds < 30) {
      return '방금 전';
    } else if (difference.inMinutes < 1) {
      return '1분 미만';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      // 일주일 이상은 구체적인 날짜 표시
      return DateFormat('MM-dd HH:mm').format(finalPostTime);
    }
  }
}