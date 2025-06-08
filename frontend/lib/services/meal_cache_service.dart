// frontend/lib/services/meal_cache_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/meal_model.dart';
import '../utils/date_utils.dart' as DateUtilsCustom;

class MealCacheService {
  static const String _cacheFileName = 'meal_cache.json';
  static const int _cacheValidityDays = 7; // 캐시 유효 기간: 7일

  // 캐시 파일 경로 가져오기
  Future<String> _getCacheFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_cacheFileName';
  }

  // 메뉴 데이터를 캐시에 저장
  Future<void> cacheMeals(List<Meal> meals) async {
    try {
      final filePath = await _getCacheFilePath();
      final file = File(filePath);

      // 현재 시간과 함께 저장
      final cacheData = {
        'cachedAt': DateTime.now().toIso8601String(),
        'meals': meals.map((meal) => {
          'id': meal.id,
          'date': meal.date,
          'mealType': meal.mealType,
          'content': meal.content,
        }).toList(),
      };

      await file.writeAsString(json.encode(cacheData));
      print('📦 메뉴 데이터 캐시 저장 완료: ${meals.length}개 항목');
    } catch (e) {
      print('❌ 메뉴 캐시 저장 실패: $e');
    }
  }

  // 캐시에서 메뉴 데이터 불러오기
  Future<List<Meal>?> getCachedMeals() async {
    try {
      final filePath = await _getCacheFilePath();
      final file = File(filePath);

      if (!await file.exists()) {
        print('📦 캐시 파일이 존재하지 않음');
        return null;
      }

      final jsonString = await file.readAsString();
      final cacheData = json.decode(jsonString);

      // 캐시 생성 시간 확인
      final cachedAt = DateTime.parse(cacheData['cachedAt']);
      final now = DateTime.now();
      final daysDifference = now.difference(cachedAt).inDays;

      if (daysDifference > _cacheValidityDays) {
        print('📦 캐시가 만료됨 (${daysDifference}일 전 데이터)');
        await _clearCache(); // 만료된 캐시 삭제
        return null;
      }

      // JSON에서 Meal 객체로 변환
      final List<dynamic> mealsJson = cacheData['meals'];
      final meals = mealsJson.map((mealJson) => Meal(
        id: mealJson['id'],
        date: mealJson['date'],
        mealType: mealJson['mealType'],
        content: mealJson['content'],
      )).toList();

      print('📦 캐시에서 메뉴 데이터 로드: ${meals.length}개 항목');
      return meals;
    } catch (e) {
      print('❌ 캐시 데이터 로드 실패: $e');
      await _clearCache(); // 손상된 캐시 삭제
      return null;
    }
  }

  // 현재 주의 메뉴만 필터링
  List<Meal> filterCurrentWeekMeals(List<Meal> meals) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(Duration(days: 6));

    return meals.where((meal) {
      final mealDate = DateUtilsCustom.DateUtils.parseDate(meal.date);
      if (mealDate == null) return false;

      return mealDate.isAfter(startOfWeek.subtract(Duration(days: 1))) &&
             mealDate.isBefore(endOfWeek.add(Duration(days: 1)));
    }).toList();
  }

  // 캐시 상태 확인
  Future<Map<String, dynamic>> getCacheStatus() async {
    try {
      final filePath = await _getCacheFilePath();
      final file = File(filePath);

      if (!await file.exists()) {
        return {
          'exists': false,
          'cachedAt': null,
          'itemCount': 0,
          'isValid': false,
        };
      }

      final jsonString = await file.readAsString();
      final cacheData = json.decode(jsonString);

      final cachedAt = DateTime.parse(cacheData['cachedAt']);
      final now = DateTime.now();
      final daysDifference = now.difference(cachedAt).inDays;
      final isValid = daysDifference <= _cacheValidityDays;

      return {
        'exists': true,
        'cachedAt': cachedAt,
        'itemCount': (cacheData['meals'] as List).length,
        'isValid': isValid,
        'daysOld': daysDifference,
      };
    } catch (e) {
      print('❌ 캐시 상태 확인 실패: $e');
      return {
        'exists': false,
        'cachedAt': null,
        'itemCount': 0,
        'isValid': false,
      };
    }
  }

  // 캐시 삭제
  Future<void> _clearCache() async {
    try {
      final filePath = await _getCacheFilePath();
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
        print('📦 캐시 파일 삭제 완료');
      }
    } catch (e) {
      print('❌ 캐시 삭제 실패: $e');
    }
  }

  // 수동으로 캐시 삭제 (설정에서 사용)
  Future<void> clearCache() async {
    await _clearCache();
  }

  // 만료 여부에 상관없이 캐시된 메뉴 데이터 가져오기 (폴백용)
  Future<List<Meal>?> getExpiredCachedMeals() async {
    try {
      final filePath = await _getCacheFilePath();
      final file = File(filePath);

      if (!await file.exists()) {
        print('📦 만료 캐시 파일이 존재하지 않음');
        return null;
      }

      final jsonString = await file.readAsString();
      final cacheData = json.decode(jsonString);

      // 만료 여부 확인하지 않고 바로 데이터 반환
      final List<dynamic> mealsJson = cacheData['meals'];
      final meals = mealsJson.map((mealJson) => Meal(
        id: mealJson['id'],
        date: mealJson['date'],
        mealType: mealJson['mealType'],
        content: mealJson['content'],
      )).toList();

      final cachedAt = DateTime.parse(cacheData['cachedAt']);
      final daysDifference = DateTime.now().difference(cachedAt).inDays;
      print('📦 만료된 캐시에서 메뉴 데이터 로드: ${meals.length}개 항목 (${daysDifference}일 전)');
      
      return meals;
    } catch (e) {
      print('❌ 만료 캐시 데이터 로드 실패: $e');
      return null;
    }
  }
}