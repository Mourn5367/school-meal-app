// frontend/lib/services/cached_api_service.dart - 캐시 기능 통합
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/meal_model.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import 'meal_cache_service.dart';

class CachedApiService {
  final MealCacheService _cacheService = MealCacheService();

  // 메뉴 가져오기 (캐시 우선, 실패 시 네트워크)
  Future<List<Meal>> getMeals() async {
    try {
      print('🔄 메뉴 데이터 요청 시작');

      // 1. 먼저 캐시에서 시도
      final cachedMeals = await _cacheService.getCachedMeals();
      if (cachedMeals != null && cachedMeals.isNotEmpty) {
        print('📦 캐시에서 메뉴 데이터 로드 성공');
        // 캐시 데이터를 백그라운드에서 업데이트
        _updateCacheInBackground();
        return cachedMeals;
      }

      // 2. 캐시가 없으면 네트워크에서 가져오기
      print('🌐 네트워크에서 메뉴 데이터 요청');
      final networkMeals = await _fetchMealsFromNetwork();
      
      if (networkMeals.isNotEmpty) {
        // 네트워크에서 성공적으로 가져왔으면 캐시에 저장
        await _cacheService.cacheMeals(networkMeals);
        print('✅ 네트워크에서 가져온 데이터를 캐시에 저장');
      }

      return networkMeals;

    } catch (e) {
      print('❌ 네트워크 요청 실패: $e');

      // 3. 네트워크 실패 시 캐시에서 다시 시도 (만료되었어도)
      final fallbackMeals = await _getFallbackCachedMeals();
      if (fallbackMeals != null && fallbackMeals.isNotEmpty) {
        print('📦 만료된 캐시 데이터 사용');
        return fallbackMeals;
      }

      // 4. 모든 시도 실패 시 예외 발생
      throw Exception('인터넷 연결을 확인해주세요. 캐시된 데이터도 없습니다.');
    }
  }

  // 네트워크에서 메뉴 데이터 가져오기
  Future<List<Meal>> _fetchMealsFromNetwork() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.menuEndpoint}'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ).timeout(Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Meal.fromJson(json)).toList();
    } else {
      throw Exception('서버 오류: ${response.statusCode}');
    }
  }

  // 백그라운드에서 캐시 업데이트 (비동기)
  void _updateCacheInBackground() {
    Future.delayed(Duration.zero, () async {
      try {
        print('🔄 백그라운드에서 캐시 업데이트 시작');
        final networkMeals = await _fetchMealsFromNetwork();
        await _cacheService.cacheMeals(networkMeals);
        print('✅ 백그라운드 캐시 업데이트 완료');
      } catch (e) {
        print('⚠️ 백그라운드 캐시 업데이트 실패: $e');
      }
    });
  }

  // 만료된 캐시 데이터도 가져오기 (네트워크 실패 시 폴백용)
  Future<List<Meal>?> _getFallbackCachedMeals() async {
    try {
      // 새로 추가한 getExpiredCachedMeals 메서드 사용
      return await _cacheService.getExpiredCachedMeals();
    } catch (e) {
      print('❌ 폴백 캐시 로드 실패: $e');
      return null;
    }
  }

  // 캐시 상태 확인
  Future<Map<String, dynamic>> getCacheStatus() async {
    return await _cacheService.getCacheStatus();
  }

  // 캐시 삭제
  Future<void> clearCache() async {
    await _cacheService.clearCache();
  }

  // 캐시 강제 새로고침
  Future<List<Meal>> refreshMeals() async {
    try {
      print('🔄 메뉴 데이터 강제 새로고침');
      
      // 캐시 삭제
      await _cacheService.clearCache();
      
      // 네트워크에서 새로 가져오기
      final networkMeals = await _fetchMealsFromNetwork();
      
      // 새 데이터를 캐시에 저장
      if (networkMeals.isNotEmpty) {
        await _cacheService.cacheMeals(networkMeals);
      }
      
      return networkMeals;
    } catch (e) {
      print('❌ 강제 새로고침 실패: $e');
      rethrow;
    }
  }

  // === 기존 게시판 관련 메서드들 (캐싱 없음) ===
  
  // 이미지 업로드 API
  Future<String> uploadImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final filename = imageFile.path.split('/').last;
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/upload-image-base64'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'image_data': 'data:image/${_getImageExtension(filename)};base64,$base64Image',
          'filename': filename,
        }),
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['image_url'];
      } else {
        throw Exception('이미지 업로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('이미지 업로드 오류: $e');
      throw Exception('이미지 업로드 오류: $e');
    }
  }

  String _getImageExtension(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'png':
        return 'png';
      case 'gif':
        return 'gif';
      default:
        return 'jpeg';
    }
  }

  // 게시글 목록 조회 (캐싱 없음 - 실시간 데이터 필요)
  Future<List<Post>> getPosts(String date, String mealType) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/posts').replace(
        queryParameters: {
          'date': date,
          'meal_type': mealType,
        },
      );
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 10));

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

  // 게시글 상세 조회
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

  // 댓글 좋아요 토글
  Future<Map<String, dynamic>> toggleCommentLike(int commentId, {String? userIdentifier}) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/comments/$commentId/like'),
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
        throw Exception('댓글 좋아요 처리 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('댓글 좋아요 API 오류: $e');
      throw Exception('댓글 좋아요 처리 오류: $e');
    }
  }
}