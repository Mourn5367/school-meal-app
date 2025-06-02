#!/bin/bash

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 학식 앱 배포 시작${NC}"

# 환경변수 파일 확인
if [ ! -f .env ]; then
    echo -e "${RED}❌ .env 파일이 없습니다. 먼저 .env 파일을 생성해주세요.${NC}"
    exit 1
fi

# Docker 및 Docker Compose 설치 확인
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker가 설치되지 않았습니다.${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose가 설치되지 않았습니다.${NC}"
    exit 1
fi

# 기존 컨테이너 정지 및 제거
echo -e "${YELLOW}📦 기존 컨테이너 정리 중...${NC}"
docker-compose -f docker-compose.prod.yml down

# Docker 이미지 빌드
echo -e "${YELLOW}🔨 Docker 이미지 빌드 중...${NC}"
docker-compose -f docker-compose.prod.yml build --no-cache

# 컨테이너 시작
echo -e "${YELLOW}🚀 컨테이너 시작 중...${NC}"
docker-compose -f docker-compose.prod.yml up -d

# 헬스체크
echo -e "${YELLOW}🩺 서비스 상태 확인 중...${NC}"
sleep 10

# 백엔드 헬스체크
if curl -f http://localhost:5000/api/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 백엔드 서비스 정상${NC}"
else
    echo -e "${RED}❌ 백엔드 서비스 오류${NC}"
fi

# 프론트엔드 헬스체크
if curl -f http://localhost:80 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 프론트엔드 서비스 정상${NC}"
else
    echo -e "${RED}❌ 프론트엔드 서비스 오류${NC}"
fi

# 컨테이너 상태 확인
echo -e "${YELLOW}📊 컨테이너 상태:${NC}"
docker-compose -f docker-compose.prod.yml ps

echo -e "${GREEN}🎉 배포 완료!${NC}"
echo -e "${GREEN}🌐 앱 접속: http://$(hostname -I | awk '{print $1}')${NC}"
echo -e "${GREEN}🔧 API 접속: http://$(hostname -I | awk '{print $1}'):5000/api${NC}"