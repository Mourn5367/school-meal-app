import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/meal_model.dart';

class ApiService {
  Future<List<Meal>> getMeals() async {
    try {
      print('API 요청 시도: ${ApiConfig.baseUrl}${ApiConfig.menuEndpoint}');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.menuEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 10));

      print('응답 상태 코드: ${response.statusCode}');
      print('응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Meal.fromJson(json)).toList();
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('API 호출 오류: $e');
      throw Exception('네트워크 오류: $e');
    }
  }
}