FROM debian:latest AS build-env

# Flutter 종속성 설치
RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils zip libglu1-mesa wget \
    && apt-get clean

# Flutter SDK 다운로드
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter

# Flutter 환경변수 설정
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Flutter 설정 및 웹 활성화
RUN flutter channel stable
RUN flutter upgrade
RUN flutter config --enable-web

# 작업 디렉토리 설정
WORKDIR /app

# 종속성 파일 복사 및 설치
COPY pubspec.* ./
RUN flutter pub get

# 나머지 소스 복사
COPY . .

# 웹 빌드
RUN flutter build web --release

# Nginx 컨테이너로 빌드 결과물 복사
FROM nginx:alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html
EXPOSE 80