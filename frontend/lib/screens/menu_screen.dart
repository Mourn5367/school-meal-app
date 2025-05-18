import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/meal_model.dart';
import '../widgets/meal_card.dart';

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
    return apiService.getMeals();
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
                  return Center(child: Text('메뉴 정보가 없습니다.'));
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