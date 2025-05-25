// frontend/lib/screens/menu_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/meal_model.dart';
import '../widgets/meal_card.dart';
import 'package:intl/intl.dart';

class MenuScreen extends StatefulWidget {
  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late Future<List<Meal>> _mealsFuture;
  String _selectedMealType = '전체';
  
  @override
  void initState() {
    super.initState();
    _mealsFuture = _loadMeals();
  }
  
 Future<List<Meal>> _loadMeals() async {
  final apiService = Provider.of<ApiService>(context, listen: false);
  final meals = await apiService.getMeals();
  
  // 현재 날짜 구하기
  final today = DateTime.now();
  final todayStr = DateFormat('yyyy-MM-dd').format(today);
  
  // 현재 날짜 이후의 메뉴만 필터링하고, 주말(토, 일) 제외
  final filteredMeals = meals.where((meal) {
    // 날짜 형식 변환
    final mealDate = DateTime.parse(meal.date);
    
    // 주말 체크 (6: 토요일, 7: 일요일)
    final isWeekend = mealDate.weekday == 6 || mealDate.weekday == 7;
    
    // 오늘 이후의 날짜이며 주말이 아닌 경우만 포함
    return meal.date.compareTo(todayStr) >= 0 && !isWeekend;
  }).toList();
  
  return filteredMeals;
}
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _mealsFuture = _loadMeals();
              });
            },
            child: FutureBuilder<List<Meal>>(
              future: _mealsFuture,
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
                        Text('데이터를 불러올 수 없습니다.\n${snapshot.error}'),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _mealsFuture = _loadMeals();
                            });
                          },
                          child: Text('다시 시도'),
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('현재 및 향후 메뉴 정보가 없습니다.'));
                } else {
                  final meals = snapshot.data!;
                  final filteredMeals = _selectedMealType == '전체'
                      ? meals
                      : meals.where((meal) => meal.mealType == _selectedMealType).toList();
                  
                  if (filteredMeals.isEmpty) {
                    return Center(child: Text('선택한 조건에 맞는 메뉴가 없습니다.'));
                  }
                  
                  return ListView.builder(
                    itemCount: filteredMeals.length,
                    itemBuilder: (context, index) {
                      return MealCard(meal: filteredMeals[index]);
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
  
  Widget _buildFilterBar() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.grey[200],
      child: Row(
        children: [
          Text('식사 유형: '),
          SizedBox(width: 8),
          DropdownButton<String>(
            value: _selectedMealType,
            items: ['전체', '아침', '점심', '저녁'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedMealType = newValue!;
              });
            },
          ),
        ],
      ),
    );
  }
}