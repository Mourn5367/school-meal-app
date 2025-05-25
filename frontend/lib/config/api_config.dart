class ApiConfig {
  // Docker 환경에서는 서비스 이름을 사용
  // 로컬 개발 시에는 localhost 사용
  // static const String baseUrl = 'http://backend:5000/api';
  // 만약 브라우저에서 직접 테스트할 때는 다음을 사용:
  static const String baseUrl = 'http://localhost:5000/api';
  
  static const String menuEndpoint = '/menu';
  static const String postsEndpoint = '/posts';
}

