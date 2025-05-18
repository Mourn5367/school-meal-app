import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/meal_model.dart';

class ApiService {
  Future<List<Meal>> getMeals() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.menuEndpoint}'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Meal.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load meals: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching meals: $e');
    }
  }
}