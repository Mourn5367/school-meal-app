// lib/config/api_config.dart 파일 수정
class ApiConfig {
  // Docker 환경에서는 서비스 이름을 사용
  static String get baseUrl {
    // 웹 브라우저에서 직접 접근하는 경우 window.location.hostname 사용
    //return 'http://localhost:5000/api';
     return 'http://192.168.137.1:5000/api';
  }
  
  static const String menuEndpoint = '/menu';
  static const String postsEndpoint = '/posts';
}