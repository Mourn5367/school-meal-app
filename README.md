# 🍽️ School Meal App

학교 급식 정보를 자동으로 수집하고 제공하는 크로스 플랫폼 애플리케이션입니다.

## ✨ 주요 기능

- **급식 메뉴 조회**: 실시간 급식 정보 확인
- **자동 데이터 수집**: 크롤러를 통한 급식 정보 자동 업데이트
- **게시글 및 이미지 업로드**: 급식 후기 및 사진 업로드
- **스케줄 기반 업데이트**: 정기적인 데이터 갱신
- **오프라인 지원**: 인터넷 연결 없이도 캐시된 급식 정보 확인 (최대 7일간 유효) 

## 🛠️ 기술 스택

### Frontend
- **Flutter** (Dart) - 크로스 플랫폼 UI 프레임워크
- **Provider** - 상태 관리
- **HTTP** - API 통신
- **Image Picker** - 이미지 선택 및 업로드

### Backend
- **Flask** (Python) - 웹 프레임워크
- **PostgreSQL** - 데이터베이스

### Crawler
- **BeautifulSoup4** - HTML 파싱
- **Selenium** - 브라우저 자동화
- **Requests** - HTTP 요청
- **Schedule** - 작업 스케줄링

### DevOps
- **Docker & Docker Compose** - 컨테이너화

## 🏗️ 아키텍처

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Frontend  │───▶│   Backend   │───▶│  Database   │
│  (Flutter)  │    │   (Flask)   │    │(PostgreSQL) │
└─────────────┘    └─────────────┘    └─────────────┘
                           ▲                   ▲
                           │                   │
                   ┌─────────────┐             │
                   │   Crawler   │─────────────┘
                   │  (Python)   │
                   └─────────────┘
```

### 시스템 동작 흐름

1. **Crawler** → 정수캠퍼스 홈페이지에서 급식 정보 수집 → **Database**에 저장
2. **Frontend** → 사용자가 급식 정보 요청 → **Backend** API 호출
3. **Backend** → **Database**에서 데이터 조회 → **Frontend**로 응답 전달
4. **Schedule** → 정기적으로 Crawler 실행하여 최신 정보 유지

## 🚀 설치 및 실행

### Docker를 이용한 실행

```bash
# 저장소 클론
git clone https://github.com/Mourn5367/school-meal-app.git
cd school-meal-app

# 개발 환경 실행
docker-compose up -d

# 운영 환경 실행
docker-compose -f docker-compose.prod.yml up -d

# Frontend는 Flutter로 로컬 실행                                                                   
cd frontend                                                                                         
lutter pub get                                                                                       
flutter run   
```

## 🖥️ 주요 화면
---
# 메인 화면
<img src="https://velog.velcdn.com/images/mourn5367/post/d73fb89c-fc99-4f03-b914-4a65b4caf12e/image.png"
alt="메인 화면" width="300">

# 요일 선택
<img src="https://velog.velcdn.com/images/mourn5367/post/306f8c8a-39cb-450c-9c6b-10eb4759a95f/image.png"
alt="요일 선택" width="300">

# 메뉴 선택
<img src="https://velog.velcdn.com/images/mourn5367/post/c2b3c380-022c-4abe-9b9e-0cb312bc9a66/image.png"
alt="메뉴 선택" width="300">

# 게시글 선택
<img src="https://velog.velcdn.com/images/mourn5367/post/b16ba940-d58c-445c-9459-4bb5fcda6f8e/image.png"
alt="게시글 선택" width="300">

# 게시글 작성
<img src="https://velog.velcdn.com/images/mourn5367/post/8d74525f-6c19-45d3-a959-cb645e924964/image.png"
alt="게시글 작성" width="300">

# 인터넷 없을 시 저장된 일주일 데이터를 사용하여 출력
<img src="https://velog.velcdn.com/images/mourn5367/post/ae31311c-ad25-40d5-9f4d-b1ec04d32d0d/image.png"
alt="인터넷 없을 시" width="300">
