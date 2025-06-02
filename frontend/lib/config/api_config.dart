// // lib/config/api_config.dart 파일 수정
// class ApiConfig {
//   // Docker 환경에서는 서비스 이름을 사용
//   static String get baseUrl {
//     // 웹 브라우저에서 직접 접근하는 경우 window.location.hostname 사용
//     //return 'http://localhost:5000/api';
//      return 'http://192.168.24.189:5000/api';
//   }
  
//   static const String menuEndpoint = '/menu';
//   static const String postsEndpoint = '/posts';
// }

class ApiConfig {
  static String get baseUrl {
    // 환경변수 또는 현재 호스트 기반으로 API URL 결정
    const bool kIsWeb = identical(0, 0.0);
    
    if (kIsWeb) {
      // 웹에서 실행시 현재 호스트의 5000 포트 사용
      return '${Uri.base.origin.replaceAll(':80', '')}:5000/api';
    } else {
      // 모바일에서는 서버 IP 사용 (환경변수로 설정)
      const serverIp = String.fromEnvironment('SERVER_IP', defaultValue: 'localhost');
      return 'http://$serverIp:5000/api';
    }
  }
  
  static const String menuEndpoint = '/menu';
  static const String postsEndpoint = '/posts';
}