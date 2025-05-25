-- database/init.sql
CREATE TABLE IF NOT EXISTS meal_menu (
    id SERIAL PRIMARY KEY,
    date DATE NOT NULL,
    meal_type VARCHAR(10) NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(date, meal_type)
);

CREATE TABLE IF NOT EXISTS posts (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    author VARCHAR(100) NOT NULL,
    meal_date DATE NOT NULL,
    meal_type VARCHAR(10) NOT NULL,
    image_url TEXT,
    likes INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS comments (
    id SERIAL PRIMARY KEY,
    post_id INTEGER REFERENCES posts(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    author VARCHAR(100) NOT NULL,
    likes INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS post_likes (
    id SERIAL PRIMARY KEY,
    post_id INTEGER REFERENCES posts(id) ON DELETE CASCADE,
    user_identifier VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(post_id, user_identifier)
);

-- 샘플 데이터 추가
INSERT INTO meal_menu (date, meal_type, content)
VALUES 
    (CURRENT_DATE, '아침', '토스트, 계란프라이, 우유, 샐러드'),
    (CURRENT_DATE, '점심', '비빔밥, 된장국, 김치, 단무지'),
    (CURRENT_DATE, '저녁', '돈까스, 미역국, 김치, 샐러드')
ON CONFLICT (date, meal_type) DO NOTHING;