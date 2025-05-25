import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/meal_model.dart';

class ApiService {
  Future<List<Meal>> getMeals() async {
    final url = '${ApiConfig.baseUrl}${ApiConfig.menuEndpoint}';
    
    // 요청 URL 로깅
    debugPrint('API 요청: $url');
    
    try {
      // 타임아웃 늘리기
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // CORS 이슈 해결을 위한 추가 헤더
          'Access-Control-Allow-Origin': '*',
        },
      ).timeout(Duration(seconds: 30)); // 타임아웃 30초로 늘림

      // 응답 상태 및 본문 로깅
      debugPrint('응답 상태 코드: ${response.statusCode}');
      debugPrint('응답 헤더: ${response.headers}');
      
      // 응답 본문 앞부분만 로깅 (너무 길 수 있으므로)
      final previewLength = response.body.length > 200 ? 200 : response.body.length;
      debugPrint('응답 본문 미리보기: ${response.body.substring(0, previewLength)}...');

      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = json.decode(response.body);
          return data.map((json) => Meal.fromJson(json)).toList();
        } catch (parseError) {
          debugPrint('JSON 파싱 오류: $parseError');
          debugPrint('파싱 실패한 데이터: ${response.body}');
          throw Exception('데이터 파싱 오류: $parseError');
        }
      } else {
        debugPrint('서버 오류 응답: ${response.body}');
        throw Exception('서버 오류: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('API 호출 오류: $e');
      
      // 네트워크 오류 상세 정보 제공
      if (e is http.ClientException) {
        debugPrint('HTTP 클라이언트 오류: ${e.message}');
        throw Exception('네트워크 연결 오류: ${e.message}');
      }
      
      throw Exception('네트워크 오류: $e');
    }
  }
  
  // API 서버 상태 확인 메소드 추가
  Future<bool> checkHealth() async {
    final url = '${ApiConfig.baseUrl}/health';
    debugPrint('서버 상태 확인: $url');
    
    try {
      final response = await http.get(Uri.parse(url))
          .timeout(Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('서버 상태 확인 오류: $e');
      return false;
    }
  }
}