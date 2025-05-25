# backend/app.py - 기존 코드에 추가할 부분들
from flask import Flask, jsonify, request
import psycopg2
from psycopg2.extras import RealDictCursor
from flask_cors import CORS
from datetime import datetime
import os

app = Flask(__name__)
CORS(app)

# 데이터베이스 연결 함수
def get_db_connection():
    conn = psycopg2.connect(
        host="db",
        database="schoolmealdb",
        user="schoolmeal",
        password="securepassword"
    )
    return conn

@app.route('/')
def hello():
    return "Hello, World!"

@app.route('/api/health')
def health_check():
    return jsonify({"status": "healthy"})

@app.route('/api/menu')
def get_menu():
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute('SELECT * FROM meal_menu ORDER BY date DESC;')
        menus = cur.fetchall()
        cur.close()
        conn.close()
        
        return jsonify(list(menus))
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 게시판 관련 API들 추가

@app.route('/api/posts', methods=['GET'])
def get_posts():
    """특정 날짜와 식사 유형의 게시글 목록 조회"""
    try:
        meal_date = request.args.get('date')
        meal_type = request.args.get('meal_type')
        
        if not meal_date or not meal_type:
            return jsonify({"error": "date and meal_type parameters are required"}), 400
        
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        # 댓글 수도 함께 조회
        query = """
        SELECT p.*, 
               COALESCE(c.comment_count, 0) as comment_count
        FROM posts p
        LEFT JOIN (
            SELECT post_id, COUNT(*) as comment_count 
            FROM comments 
            GROUP BY post_id
        ) c ON p.id = c.post_id
        WHERE p.meal_date = %s AND p.meal_type = %s
        ORDER BY p.created_at DESC
        """
        
        cur.execute(query, (meal_date, meal_type))
        posts = cur.fetchall()
        cur.close()
        conn.close()
        
        return jsonify(list(posts))
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/posts', methods=['POST'])
def create_post():
    """새 게시글 작성"""
    try:
        data = request.get_json()
        
        required_fields = ['title', 'content', 'author', 'meal_date', 'meal_type']
        for field in required_fields:
            if field not in data:
                return jsonify({"error": f"{field} is required"}), 400
        
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        query = """
        INSERT INTO posts (title, content, author, meal_date, meal_type, image_url)
        VALUES (%s, %s, %s, %s, %s, %s)
        RETURNING *
        """
        
        cur.execute(query, (
            data['title'],
            data['content'], 
            data['author'],
            data['meal_date'],
            data['meal_type'],
            data.get('image_url')
        ))
        
        new_post = cur.fetchone()
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify(dict(new_post)), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/posts/<int:post_id>', methods=['GET'])
def get_post_detail(post_id):
    """게시글 상세 조회"""
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        # 게시글 조회
        cur.execute('SELECT * FROM posts WHERE id = %s', (post_id,))
        post = cur.fetchone()
        
        if not post:
            return jsonify({"error": "Post not found"}), 404
        
        # 댓글 조회
        cur.execute("""
            SELECT * FROM comments 
            WHERE post_id = %s 
            ORDER BY created_at ASC
        """, (post_id,))
        comments = cur.fetchall()
        
        cur.close()
        conn.close()
        
        result = dict(post)
        result['comments'] = list(comments)
        
        return jsonify(result)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/posts/<int:post_id>/like', methods=['POST'])
def toggle_post_like(post_id):
    """게시글 좋아요 토글"""
    try:
        data = request.get_json()
        user_identifier = data.get('user_identifier', request.remote_addr)
        
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        # 이미 좋아요를 눌렀는지 확인
        cur.execute("""
            SELECT id FROM post_likes 
            WHERE post_id = %s AND user_identifier = %s
        """, (post_id, user_identifier))
        
        existing_like = cur.fetchone()
        
        if existing_like:
            # 좋아요 취소
            cur.execute("""
                DELETE FROM post_likes 
                WHERE post_id = %s AND user_identifier = %s
            """, (post_id, user_identifier))
            
            cur.execute("""
                UPDATE posts SET likes = likes - 1 
                WHERE id = %s
            """, (post_id,))
            
            liked = False
        else:
            # 좋아요 추가
            cur.execute("""
                INSERT INTO post_likes (post_id, user_identifier)
                VALUES (%s, %s)
            """, (post_id, user_identifier))
            
            cur.execute("""
                UPDATE posts SET likes = likes + 1 
                WHERE id = %s
            """, (post_id,))
            
            liked = True
        
        # 업데이트된 좋아요 수 조회
        cur.execute('SELECT likes FROM posts WHERE id = %s', (post_id,))
        result = cur.fetchone()
        
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({
            "liked": liked,
            "likes": result['likes']
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/posts/<int:post_id>/comments', methods=['POST'])
def create_comment(post_id):
    """댓글 작성"""
    try:
        data = request.get_json()
        
        if 'content' not in data or 'author' not in data:
            return jsonify({"error": "content and author are required"}), 400
        
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        query = """
        INSERT INTO comments (post_id, content, author)
        VALUES (%s, %s, %s)
        RETURNING *
        """
        
        cur.execute(query, (post_id, data['content'], data['author']))
        new_comment = cur.fetchone()
        
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify(dict(new_comment)), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)