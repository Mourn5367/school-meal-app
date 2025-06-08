// frontend/lib/screens/menu_screen.dart - 초기화 오류 수정 버전
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cached_api_service.dart';
import '../models/meal_model.dart';
import 'meal_board_screen.dart';
import 'package:intl/intl.dart';
import '../utils/date_utils.dart' as DateUtilsCustom;

class MenuScreen extends StatefulWidget {
  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late Future<Map<String, List<Meal>>> _weeklyMealsFuture;
  bool _isRefreshing = false;
  Map<String, dynamic>? _cacheStatus;

  @override
  void initState() {
    super.initState();
    // 여기서 직접 Future를 초기화
    _weeklyMealsFuture = _fetchWeeklyMeals();
    _checkCacheStatus();
  }

  Future<void> _checkCacheStatus() async {
    final apiService = Provider.of<CachedApiService>(context, listen: false);
    final status = await apiService.getCacheStatus();
    if (mounted) {
      setState(() {
        _cacheStatus = status;
      });
    }
  }

  // 실제 데이터를 가져오는 메서드 (메서드명 변경)
  Future<Map<String, List<Meal>>> _fetchWeeklyMeals() async {
    final apiService = Provider.of<CachedApiService>(context, listen: false);
    final meals = await apiService.getMeals();

    // 현재 날짜 구하기
    final today = DateTime.now();

    // 현재 날짜 이후의 메뉴만 필터링하고, 주말(토, 일) 제외
    final filteredMeals = meals.where((meal) {
      final mealDate = DateUtilsCustom.DateUtils.parseDate(meal.date);
      if (mealDate == null) return false;

      final isWeekend = mealDate.weekday == 6 || mealDate.weekday == 7;
      final isToday = mealDate.isAfter(today.subtract(Duration(days: 1)));

      return isToday && !isWeekend;
    }).toList();

    // 날짜별로 그룹화
    Map<String, List<Meal>> groupedMeals = {};
    for (var meal in filteredMeals) {
      final mealDate = DateUtilsCustom.DateUtils.parseDate(meal.date);
      if (mealDate != null) {
        final dateKey = DateFormat('yyyy-MM-dd').format(mealDate);
        if (!groupedMeals.containsKey(dateKey)) {
          groupedMeals[dateKey] = [];
        }
        groupedMeals[dateKey]!.add(meal);
      }
    }

    // 날짜순으로 정렬
    var sortedKeys = groupedMeals.keys.toList()..sort();
    Map<String, List<Meal>> sortedGroupedMeals = {};
    for (var key in sortedKeys) {
      sortedGroupedMeals[key] = groupedMeals[key]!;
      // 각 날짜 내에서 식사 순서대로 정렬
      sortedGroupedMeals[key]!.sort((a, b) {
        const mealOrder = {'아침': 1, '점심': 2, '저녁': 3};
        return (mealOrder[a.mealType] ?? 4).compareTo(mealOrder[b.mealType] ?? 4);
      });
    }

    return sortedGroupedMeals;
  }

  // UI에서 새로고침을 트리거하는 메서드 (메서드명 변경)
  Future<void> _refreshData({bool forceRefresh = false}) async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final apiService = Provider.of<CachedApiService>(context, listen: false);

      if (forceRefresh) {
        // 강제 새로고침 (캐시 삭제 후 네트워크에서 가져오기)
        await apiService.refreshMeals();
      }

      setState(() {
        _weeklyMealsFuture = _fetchWeeklyMeals(); // 새로운 Future 생성
      });

      await _checkCacheStatus();
    } catch (e) {
      print('새로고침 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('새로고침 중 오류가 발생했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  String _formatDateHeader(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
      final weekday = weekdays[date.weekday - 1];
      return '${date.month}월 ${date.day}일 ($weekday)';
    } catch (e) {
      print('날짜 포맷 오류: $dateStr - $e');
      return dateStr;
    }
  }

  Color _getWeekdayColor(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final colors = [
        Colors.red.shade300,    // 월
        Colors.orange.shade300, // 화
        Colors.green.shade300,  // 수
        Colors.blue.shade300,   // 목
        Colors.purple.shade300, // 금
        Colors.grey.shade300,   // 토
        Colors.grey.shade300,   // 일
      ];
      return colors[date.weekday - 1];
    } catch (e) {
      print('날짜 색상 처리 오류: $dateStr - $e');
      return Colors.grey.shade300;
    }
  }

  // 캐시 상태 표시 위젯
  Widget _buildCacheStatusWidget() {
    if (_cacheStatus == null) return SizedBox.shrink();

    final isValid = _cacheStatus!['isValid'] ?? false;
    final exists = _cacheStatus!['exists'] ?? false;
    final itemCount = _cacheStatus!['itemCount'] ?? 0;
    final daysOld = _cacheStatus!['daysOld'] ?? 0;

    if (!exists) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isValid ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isValid ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.wifi_off : Icons.update,
            size: 16,
            color: isValid ? Colors.green : Colors.orange,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              isValid
                  ? '오프라인 모드 - 캐시된 메뉴 ($itemCount개 항목)'
                  : '캐시된 데이터 사용 중 (${daysOld}일 전)',
              style: TextStyle(
                fontSize: 12,
                color: isValid ? Colors.green[700] : Colors.orange[700],
              ),
            ),
          ),
          if (!isValid)
            InkWell(
              onTap: () => _refreshData(forceRefresh: true),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '새로고침',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 캐시 상태 표시
        _buildCacheStatusWidget(),

        // 메인 컨텐츠
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _refreshData(forceRefresh: false),
            child: FutureBuilder<Map<String, List<Meal>>>(
              future: _weeklyMealsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !_isRefreshing) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('메뉴를 불러오는 중...'),
                        if (_cacheStatus?['exists'] == true)
                          Text(
                            '캐시된 데이터 확인 중',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                        SizedBox(height: 16),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            '데이터를 불러올 수 없습니다.\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: _isRefreshing ? null : () => _refreshData(forceRefresh: false),
                              child: _isRefreshing
                                  ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                                  : Text('다시 시도'),
                            ),
                            SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: _isRefreshing ? null : () => _refreshData(forceRefresh: true),
                              child: Text('강제 새로고침'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant_menu, size: 48, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text('현재 및 향후 메뉴 정보가 없습니다.'),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _refreshData(forceRefresh: true),
                          child: Text('새로고침'),
                        ),
                      ],
                    ),
                  );
                } else {
                  final weeklyMeals = snapshot.data!;

                  return ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: weeklyMeals.length,
                    itemBuilder: (context, index) {
                      final date = weeklyMeals.keys.elementAt(index);
                      final mealsForDay = weeklyMeals[date]!;

                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                          ),
                          child: ExpansionTile(
                            backgroundColor: _getWeekdayColor(date).withOpacity(0.1),
                            collapsedBackgroundColor: _getWeekdayColor(date).withOpacity(0.05),
                            iconColor: _getWeekdayColor(date),
                            collapsedIconColor: _getWeekdayColor(date),
                            title: Container(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _getWeekdayColor(date),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _formatDateHeader(date),
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          '${mealsForDay.length}개 식사',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            children: mealsForDay.map((meal) => _buildMealItem(meal)).toList(),
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealItem(Meal meal) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          // 해당 식사의 게시판으로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MealBoardScreen(
                meal: meal,
                date: meal.date,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getMealTypeColor(meal.mealType),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      meal.mealType,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                meal.content,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
}