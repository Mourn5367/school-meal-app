-- 학식 메뉴 테이블
CREATE TABLE IF NOT EXISTS meal_menu (
    id SERIAL PRIMARY KEY,
    date DATE NOT NULL,
    meal_type VARCHAR(10) NOT NULL, -- '아침', '점심', '저녁'
    content TEXT NOT NULL,
    UNIQUE(date, meal_type)
);

-- 간단한 테스트 데이터 추가
INSERT INTO meal_menu (date, meal_type, content)
VALUES
    (CURRENT_DATE, '아침', '토스트 & 계란프라이, 우유 & 시리얼, 샐러드'),
    (CURRENT_DATE, '점심', '비빔밥, 된장국, 김치, 단무지'),
    (CURRENT_DATE, '저녁', '제육볶음, 미역국, 계란찜, 김치');