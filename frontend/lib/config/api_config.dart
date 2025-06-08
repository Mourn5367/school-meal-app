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
    const bool kIsWeb = identical(0, 0.0);

    if (kIsWeb) {
      // 웹에서는 현재 호스트의 5000 포트 사용
      return '${Uri.base.origin.replaceAll(':80', '')}:5000/api';
    } else {
      // 모바일에서는 실제 서버 IP 사용
      // 여기를 실제 서버 IP로 변경하세요!
      const serverIp = String.fromEnvironment('192.168.26.165',
          defaultValue: '192.168.26.165'); // localhost 대신 실제 IP
      return 'http://$serverIp:5000/api';
    }
  }

  static const String menuEndpoint = '/menu';
  static const String postsEndpoint = '/posts';
}