-- database/init.sql 파일에 추가할 테이블들

-- 기존 meal_menu 테이블은 그대로 유지하고 아래 테이블들을 추가

-- 게시글 테이블
CREATE TABLE IF NOT EXISTS posts (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    author VARCHAR(100) NOT NULL,
    meal_date DATE NOT NULL,
    meal_type VARCHAR(10) NOT NULL CHECK (meal_type IN ('아침', '점심', '저녁')),
    likes INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    image_url VARCHAR(500)
);

-- 댓글 테이블
CREATE TABLE IF NOT EXISTS comments (
    id SERIAL PRIMARY KEY,
    post_id INTEGER NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    author VARCHAR(100) NOT NULL,
    likes INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 좋아요 테이블 (중복 방지를 위해)
CREATE TABLE IF NOT EXISTS post_likes (
    id SERIAL PRIMARY KEY,
    post_id INTEGER NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_identifier VARCHAR(100) NOT NULL, -- IP 주소 또는 사용자 ID
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(post_id, user_identifier)
);

CREATE TABLE IF NOT EXISTS comment_likes (
    id SERIAL PRIMARY KEY,
    comment_id INTEGER NOT NULL REFERENCES comments(id) ON DELETE CASCADE,
    user_identifier VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(comment_id, user_identifier)
);

-- 인덱스 추가 (성능 향상)
CREATE INDEX IF NOT EXISTS idx_posts_meal_date_type ON posts(meal_date, meal_type);
CREATE INDEX IF NOT EXISTS idx_comments_post_id ON comments(post_id);
CREATE INDEX IF NOT EXISTS idx_post_likes_post_id ON post_likes(post_id);

-- 더미 데이터 삽입
INSERT INTO posts (title, content, author, meal_date, meal_type, likes) VALUES
('오늘 아침 토스트 넘로웠어요', '오늘 아침 토스트가 너무 따뜻했어요. 쫄 더 신경써주셨으면 좋겠습니다.', 'user1', '2025-05-26', '아침', 5),
('오늘 점심 비빔밥 맛있었어요!', '오늘 점심에 나온 비빔밥이 정말 맛있었습니다. 특히 고추장이 잘 어울렸어요. 밥도 적당히 고슬고슬하고 나물들도 신선했습니다. 다음에도 또 나왔으면 좋겠어요!', 'user2', '2025-05-26', '점심', 15),
('샐러드 드레싱 추천해주세요', '오늘 샐러드가 좀 심심했는데, 어떤 드레싱이 잘 어울릴까요?', 'user3', '2025-05-26', '저녁', 3),
('카레라이스 정말 맛있네요', '오늘 점심 카레라이스가 정말 맛있었어요. 야채도 많이 들어있고 매콤한 정도도 딱 좋았습니다.', 'user4', '2025-05-27', '점심', 8),
('미소된장국 너무 짜요', '오늘 아침 미소된장국이 너무 짠 것 같아요. 조금 더 연하게 해주셨으면 좋겠습니다.', 'user5', '2025-05-27', '아침', 2);

INSERT INTO comments (post_id, content, author, likes) VALUES
(1, '저도 오늘 토스트 먹었는데 정말 맛있었어요!', 'user6', 3),
(1, '다음에도 또 나왔으면 좋겠네요', 'user7', 1),
(2, '고추장이 정말 잘 어울렸죠! 저도 인정합니다 👍', 'user8', 2),
(2, '비빔밥 정말 맛있었어요. 매주 나왔으면 좋겠네요', 'user9', 4),
(2, '나물들이 정말 신선했어요', 'user10', 1),
(3, '참깨 드레싱 추천드려요!', 'user11', 2),
(4, '저도 카레라이스 정말 좋아해요', 'user12', 1),
(5, '저도 그렇게 생각해요. 좀 더 연하게 해주시면 좋을 것 같아요', 'user13', 3);