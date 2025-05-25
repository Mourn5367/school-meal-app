import 'package:flutter/material.dart';
import '../models/meal_model.dart';
import 'package:intl/intl.dart';

class MealCard extends StatelessWidget {
  final Meal meal;

  const MealCard({Key? key, required this.meal}) : super(key: key);

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      
      // 요일 배열 (영어 -> 한글)
      final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
      
      // 요일 구하기 (1: 월요일, 7: 일요일이므로 -1 해줌)
      final weekday = weekdays[date.weekday - 1];
      
      // 'yyyy년 MM월 dd일 (요일)' 형식으로 변환
      return '${date.year}년 ${date.month}월 ${date.day}일 ($weekday)';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(meal.date),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getMealTypeColor(meal.mealType),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    meal.mealType,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              meal.content,
              style: TextStyle(fontSize: 15),
            ),
          ],
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