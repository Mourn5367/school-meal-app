import os
import time
import schedule
import psycopg2
from datetime import datetime, timedelta
import requests
from bs4 import BeautifulSoup
import logging
import re

# 로깅 설정
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('school-meal-crawler')

# 데이터베이스 연결 정보
DB_HOST = os.environ.get('DB_HOST', 'db')
DB_NAME = os.environ.get('DB_NAME', 'schoolmealdb')
DB_USER = os.environ.get('DB_USER', 'schoolmeal')
DB_PASSWORD = os.environ.get('DB_PASSWORD', 'securepassword')

# 데이터베이스 연결 재시도 함수
def wait_for_db(max_retries=30, delay=5):
    """데이터베이스 연결을 기다립니다."""
    retries = 0
    
    while retries < max_retries:
        try:
            logger.info(f"데이터베이스 연결 시도 중... (시도 {retries+1}/{max_retries})")
            logger.info(f"DB 접속 정보: host={DB_HOST}, db={DB_NAME}, user={DB_USER}")
            
            conn = psycopg2.connect(
                host=DB_HOST,
                database=DB_NAME,
                user=DB_USER,
                password=DB_PASSWORD
            )
            conn.close()
            logger.info("데이터베이스 연결 성공!")
            return True
        except Exception as e:
            retries += 1
            logger.warning(f"데이터베이스 연결 실패 (시도 {retries}/{max_retries}): {e}")
            time.sleep(delay)
    
    logger.error("최대 재시도 횟수를 초과했습니다. 데이터베이스에 연결할 수 없습니다.")
    return False

# Holiday 체크 함수
def get_holiday(*menus):
    count = 0
    for menu in menus:
        if not menu:
            count += 1
    if count == len(menus):
        return True
    else:
        return False

# 날짜 문자열 파싱 함수
def parse_date(date_str, index=0):
    """날짜 문자열을 파싱하여 YYYY-MM-DD 형식으로 반환합니다."""
    # 날짜 형식 확인
    logger.info(f"파싱할 날짜 문자열: {date_str}")
    
    # YYYY-MM-DD 형식인 경우
    date_pattern = r'(\d{4}-\d{2}-\d{2})'
    match = re.search(date_pattern, date_str)
    
    if match:
        return match.group(1)
    
    # 요일만 있는 경우, 현재 날짜로부터 요일에 맞게 계산
    weekday_map = {'월요일': 0, '화요일': 1, '수요일': 2, '목요일': 3, '금요일': 4, '토요일': 5, '일요일': 6}
    if date_str in weekday_map:
        today = datetime.now()
        today_weekday = today.weekday()  # 0=월요일, 1=화요일, ...
        target_weekday = weekday_map[date_str]
        days_diff = (target_weekday - today_weekday) % 7
        target_date = today + timedelta(days=days_diff)
        return target_date.strftime('%Y-%m-%d')
    
    # 다른 형식이거나 날짜를 찾을 수 없는 경우, 현재 날짜 + 인덱스를 사용
    today = datetime.now()
    target_date = today + timedelta(days=index)
    return target_date.strftime('%Y-%m-%d')

# 크롤링 함수
def crawl_menu():
    logger.info("학식 메뉴 크롤링 시작")
    
    try:
        # 요청 라이브러리를 사용하여 페이지 가져오기
        logger.info("페이지 요청 중...")
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36'
        }
        url = 'https://www.kopo.ac.kr/jungsu/content.do?menu=247'
        
        import requests
        response = requests.get(url, headers=headers)
        response.raise_for_status()  # 오류가 있으면 예외 발생
        
        # HTML 파싱
        logger.info("HTML 파싱 중...")
        html = response.text
        soup = BeautifulSoup(html, 'html.parser')
        
        # 테이블 찾기
        table = soup.select_one('#contents > div > div.meal_box > table.tbl_table.menu')
        if not table:
            logger.error("식단표를 찾을 수 없습니다.")
            table_candidates = soup.find_all('table')
            logger.info(f"페이지에서 발견된 테이블 수: {len(table_candidates)}")
            for i, t in enumerate(table_candidates):
                logger.info(f"테이블 {i+1} 클래스: {t.get('class', '없음')}")
            logger.info("더미 데이터를 생성합니다.")
            return generate_dummy_data_and_save()
        
        # tbody 찾기
        tbody = table.select_one('tbody')
        if not tbody:
            logger.error("식단표 본문을 찾을 수 없습니다.")
            logger.info("더미 데이터를 생성합니다.")
            return generate_dummy_data_and_save()
        
        rows = tbody.find_all('tr')
        logger.info(f"발견된 행 수: {len(rows)}")
        
        meal_list = []
        for i, row in enumerate(rows):
            tds = row.find_all('td')
            logger.info(f"행 {i+1}의 셀 수: {len(tds)}")
            
            if len(tds) < 4:
                logger.warning(f"행 {i+1}에 예상보다 적은 셀이 있습니다. 건너뜁니다.")
                continue
            
            # 첫 번째 셀에서 날짜 정보 추출
            date_cell = tds[0].get_text(strip=True)
            logger.info(f"날짜 셀 내용: {date_cell}")
            
            # 날짜 형식 확인 및 변환
            date_only = parse_date(date_cell, i)
            
            # 요일 정보
            weekday = ""
            weekday_match = re.search(r'[월화수목금토일]요일', date_cell)
            if weekday_match:
                weekday = weekday_match.group(0).replace('요일', '')
            
            # 메뉴 내용 추출
            breakfast, lunch, dinner = "", "", ""
            
            try:
                breakfast_span = tds[1].find('span')
                breakfast = breakfast_span.get_text(strip=True).replace('\n', '') if breakfast_span else ""
            except Exception as e:
                logger.warning(f"아침 메뉴 파싱 오류: {e}")
            
            try:
                lunch_span = tds[2].find('span')
                lunch = lunch_span.get_text(strip=True).replace('\n', '') if lunch_span else ""
            except Exception as e:
                logger.warning(f"점심 메뉴 파싱 오류: {e}")
            
            try:
                dinner_span = tds[3].find('span')
                dinner = dinner_span.get_text(strip=True).replace('\n', '') if dinner_span else ""
            except Exception as e:
                logger.warning(f"저녁 메뉴 파싱 오류: {e}")
            
            is_holiday = get_holiday(breakfast, lunch, dinner)
            
            meal_list.append({
                'date': date_only,
                'weekday': weekday,
                'breakfast': breakfast or "정보 없음",
                'lunch': lunch or "정보 없음",
                'dinner': dinner or "정보 없음",
                'is_holiday': is_holiday
            })
        
        # 파싱된 데이터 요약
        logger.info(f"파싱된 메뉴 항목 수: {len(meal_list)}")
        for meal in meal_list:
            logger.info(f"날짜: {meal['date']}, 요일: {meal['weekday']}")
        
        # 데이터베이스 저장
        save_to_database(meal_list)
        
    except Exception as e:
        logger.error(f"크롤링 중 오류 발생: {e}")
        logger.info("더미 데이터 생성 중...")
        generate_dummy_data_and_save()

# 데이터베이스에 저장
def save_to_database(meal_list):
    conn = None
    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD
        )
        
        # 커서 생성
        cur = conn.cursor()
        
        # 데이터를 DB에 삽입
        inserted_count = 0
        for meal in meal_list:
            # 날짜가 YYYY-MM-DD 형식인지 확인
            date_str = meal['date']
            if len(date_str) != 10 or date_str.count('-') != 2:
                # 현재 날짜로 대체
                date_str = datetime.now().strftime('%Y-%m-%d')
                logger.warning(f"유효하지 않은 날짜 형식: {meal['date']}, 현재 날짜로 대체: {date_str}")
            
            # 아침, 점심, 저녁 메뉴 삽입
            for meal_type, db_meal_type in [('breakfast', '아침'), ('lunch', '점심'), ('dinner', '저녁')]:
                menu = meal[meal_type]
                
                # meal_menu 테이블에 맞게 수정
                cur.execute(
                    "INSERT INTO meal_menu (date, meal_type, content) VALUES (%s, %s, %s) "
                    "ON CONFLICT (date, meal_type) DO UPDATE SET content = EXCLUDED.content;",
                    (date_str, db_meal_type, menu)
                )
                inserted_count += 1
        
        # 변경사항 커밋
        conn.commit()
        cur.close()
        
        logger.info(f"{inserted_count}개의 메뉴 항목이 데이터베이스에 저장되었습니다.")
        
    except Exception as e:
        logger.error(f"데이터베이스 작업 중 오류 발생: {e}")
    finally:
        if conn:
            conn.close()

# 더미 데이터 생성
def generate_dummy_data():
    from datetime import datetime, timedelta
    import random
    
    breakfast_items = ["토스트 & 계란프라이", "우유 & 시리얼", "샐러드", "요거트", "과일", "빵 & 잼", "죽"]
    lunch_items = ["비빔밥", "된장국", "김치", "단무지", "불고기", "잡채", "제육볶음", "김치찌개", "냉면"]
    dinner_items = ["돈까스", "미역국", "계란찜", "김치", "치킨", "피자", "스파게티", "햄버거", "샐러드"]
    
    weekdays = ['월', '화', '수', '목', '금']
    
    meal_list = []
    
    # 오늘부터 5일간의 메뉴 생성
    for i in range(5):
        menu_date = datetime.now() + timedelta(days=i)
        weekday = weekdays[i % 5]
        
        # 아침 메뉴
        breakfast = ", ".join(random.sample(breakfast_items, 3))
        # 점심 메뉴
        lunch = ", ".join(random.sample(lunch_items, 4))
        # 저녁 메뉴
        dinner = ", ".join(random.sample(dinner_items, 4))
        
        meal_list.append({
            'date': menu_date.strftime('%Y-%m-%d'),
            'weekday': weekday,
            'breakfast': breakfast,
            'lunch': lunch,
            'dinner': dinner,   
            'is_holiday': False
        })
    
    return meal_list

# 더미 데이터 생성 및 데이터베이스 저장
def generate_dummy_data_and_save():
    meal_list = generate_dummy_data()
    
    logger.info("더미 데이터 생성 완료, 데이터베이스에 저장 중...")
    save_to_database(meal_list)
    return meal_list

if __name__ == "__main__":
    logger.info("크롤러 서비스 시작")
    
    # 데이터베이스 연결을 기다립니다
    if not wait_for_db(max_retries=30, delay=5):
        logger.error("데이터베이스에 연결할 수 없어 크롤러를 종료합니다.")
        exit(1)
    
    # 시작할 때 한 번 크롤링 실행
    crawl_menu()
    
    # 매일 자정에 크롤링 스케줄링
    schedule.every().day.at("00:00").do(crawl_menu)
    
    # 스케줄러 실행
    while True:
        schedule.run_pending()
        time.sleep(60)  # 1분마다 스케줄 확인