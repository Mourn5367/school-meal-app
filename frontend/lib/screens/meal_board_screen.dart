// frontend/lib/screens/meal_board_screen.dart
import 'package:flutter/material.dart';
import '../models/meal_model.dart';
import '../models/post_model.dart';
import 'post_detail_screen.dart';
import 'package:intl/intl.dart';
import 'post_create_screen.dart';
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
  List<Post> posts = [];

  @override
  void initState() {
    super.initState();
    _loadDummyPosts();
  }

  void _loadDummyPosts() {
    // 더미 게시글 데이터 (실제로는 API에서 가져올 것)
    posts = [
      Post(
        id: 1,
        title: "오늘 아침 토스트 넘로웠어요",
        content: "오늘 아침 토스트가 너무 따뜻했어요. 쫄 더 신경써주셨으면 좋겠습니다.",
        author: "user1",
        createdAt: DateTime.now().subtract(Duration(hours: 2)),
        likes: 5,
        commentCount: 2,
      ),
      Post(
        id: 2,
        title: "오늘 점심 비빔밥 맛있었어요!",
        content: "오늘 점심에 나온 비빔밥이 정말 맛있었습니다. 특히 고추장이 잘 어울렸어요. 밥도 적당히 고슬고슬하고 나물들도 신선했습니다. 다음에도 또 나왔으면 좋겠어요!",
        author: "user2",
        createdAt: DateTime.now().subtract(Duration(hours: 5)),
        likes: 15,
        commentCount: 3,
      ),
      Post(
        id: 3,
        title: "샐러드 드레싱 추천해주세요",
        content: "오늘 샐러드가 좀 심심했는데, 어떤 드레싱이 잘 어울릴까요?",
        author: "user3",
        createdAt: DateTime.now().subtract(Duration(hours: 1)),
        likes: 3,
        commentCount: 1,
      ),
    ];
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
      final weekday = weekdays[date.weekday - 1];
      return '${date.month}월 ${date.day}일 ($weekday)';
    } catch (e) {
      return dateStr;
    }
  }
  
  // RFC 2822 형식 날짜를 파싱하는 함수 (메뉴 화면과 동일)
  DateTime? _parseDate(String dateStr) {
    try {
      // 기본 ISO 형식 시도 (yyyy-MM-dd)
      if (dateStr.contains('-') && !dateStr.contains(',')) {
        return DateTime.parse(dateStr);
      }
      
      // RFC 2822 형식 파싱 (예: "Mon, 26 May 2025 00:00:00 GMT")
      if (dateStr.contains(',')) {
        final parts = dateStr.split(' ');
        if (parts.length >= 4) {
          final day = int.tryParse(parts[1]);
          final monthStr = parts[2];
          final year = int.tryParse(parts[3]);
          
          final monthMap = {
            'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
            'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
          };
          
          final month = monthMap[monthStr];
          
          if (day != null && month != null && year != null) {
            return DateTime(year, month, day);
          }
        }
      }
      
      return null;
    } catch (e) {
      print('날짜 파싱 실패: $dateStr - $e');
      return null;
    }
  }
  
  String _formatDateForDisplay(String dateStr) {
    // RFC 2822 형식인 경우 먼저 파싱
    final parsedDate = _parseDate(dateStr);
    if (parsedDate != null) {
      final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
      final weekday = weekdays[parsedDate.weekday - 1];
      return '${parsedDate.month}월 ${parsedDate.day}일 ($weekday)';
    }
    
    // 기존 방식으로 폴백
    return _formatDate(dateStr);
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
                      _formatDateForDisplay(widget.date),
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
                      Text(
                        '게시글 ${posts.length}개',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
ElevatedButton.icon(
  onPressed: () {
    // 게시글 작성 화면으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostCreateScreen(
          meal: widget.meal,
          date: widget.date,
        ),
      ),
    ).then((result) {
      // 게시글이 작성되었다면 목록 새로고침
      if (result == true) {
        // 실제 API 연결 시 아래 부분 구현
        // _loadPosts();
        _loadDummyPosts(); // 임시로 더미 데이터 다시 로드
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
                  child: ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      return _buildPostCard(post);
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
                    DateFormat('HH:mm').format(post.createdAt),
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