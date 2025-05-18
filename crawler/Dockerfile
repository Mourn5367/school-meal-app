FROM python:3.10

# 작업 디렉토리 설정
WORKDIR /app

# 필요한 패키지 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 스크립트 복사
COPY crawler.py .

# 크롤러 스크립트 실행
CMD ["python", "crawler.py"]