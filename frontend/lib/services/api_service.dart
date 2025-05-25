// frontend/lib/services/api_service.dart - 전체 교체
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/meal_model.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../utils/date_utils.dart' as DateUtilsCustom;

class ApiService {
  // 기존 메뉴 관련 API
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

  // 게시판 관련 API들
  
  // 특정 날짜/식사의 게시글 목록 조회
  Future<List<Post>> getPosts(String date, String mealType) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/posts').replace(
        queryParameters: {
          'date': date,
          'meal_type': mealType,
        },
      );
      
      print('게시글 목록 요청: $uri');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 10));

      print('게시글 응답 상태: ${response.statusCode}');
      print('게시글 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Post.fromJson(json)).toList();
      } else {
        throw Exception('게시글 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('게시글 API 오류: $e');
      throw Exception('게시글 조회 오류: $e');
    }
  }

  // 게시글 상세 조회 (댓글 포함)
  Future<Map<String, dynamic>> getPostDetail(int postId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/posts/$postId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'post': Post.fromJson(data),
          'comments': (data['comments'] as List)
              .map((json) => Comment.fromJson(json))
              .toList(),
        };
      } else {
        throw Exception('게시글 상세 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('게시글 상세 API 오류: $e');
      throw Exception('게시글 상세 조회 오류: $e');
    }
  }

  // 게시글 작성
  Future<Post> createPost({
    required String title,
    required String content,
    required String author,
    required String mealDate,
    required String mealType,
    String? imageUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/posts'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'title': title,
          'content': content,
          'author': author,
          'meal_date': mealDate,
          'meal_type': mealType,
          'image_url': imageUrl,
        }),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Post.fromJson(data);
      } else {
        throw Exception('게시글 작성 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('게시글 작성 API 오류: $e');
      throw Exception('게시글 작성 오류: $e');
    }
  }

  // 게시글 좋아요 토글
  Future<Map<String, dynamic>> togglePostLike(int postId, {String? userIdentifier}) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/posts/$postId/like'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'user_identifier': userIdentifier ?? 'anonymous',
        }),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('좋아요 처리 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('좋아요 API 오류: $e');
      throw Exception('좋아요 처리 오류: $e');
    }
  }

  // 댓글 작성
  Future<Comment> createComment({
    required int postId,
    required String content,
    required String author,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/posts/$postId/comments'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'content': content,
          'author': author,
        }),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Comment.fromJson(data);
      } else {
        throw Exception('댓글 작성 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('댓글 작성 API 오류: $e');
      throw Exception('댓글 작성 오류: $e');
    }
  }
}