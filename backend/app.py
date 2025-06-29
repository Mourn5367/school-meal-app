# backend/app.py - 한국 시간대로 통일
from flask import Flask, jsonify, request, send_from_directory
import psycopg2
from psycopg2.extras import RealDictCursor
from flask_cors import CORS
from datetime import datetime, timezone, timedelta
import os
import base64
import uuid
from werkzeug.utils import secure_filename

import hashlib
import secrets
from datetime import datetime, timedelta

app = Flask(__name__)
CORS(app)

# 한국 시간대 설정
KST = timezone(timedelta(hours=9))

# 업로드 설정
UPLOAD_FOLDER = 'uploads'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}
MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16MB

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MAX_CONTENT_LENGTH'] = MAX_CONTENT_LENGTH

# 업로드 폴더 생성
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# 데이터베이스 연결 함수
def get_db_connection():
    conn = psycopg2.connect(
        host="db",
        database="schoolmealdb",
        user="schoolmeal",
        password="securepassword"
    )
    return conn

# 한국 시간 변환 헬퍼 함수
def convert_to_kst_string(dt):
    """DateTime 객체나 문자열을 한국 시간 문자열로 변환"""
    if dt is None:
        return None
    
    # 문자열인 경우 먼저 DateTime으로 변환
    if isinstance(dt, str):
        try:
            # RFC 2822 형식 처리
            if ',' in dt and ('GMT' in dt or 'UTC' in dt):
                from email.utils import parsedate_to_datetime
                dt = parsedate_to_datetime(dt)
            else:
                dt = datetime.fromisoformat(dt.replace('Z', '+00:00'))
        except Exception as e:
            print(f"날짜 문자열 파싱 실패: {dt} - {e}")
            return dt  # 파싱 실패하면 원본 반환
    
    # UTC 시간이면 KST로 변환
    if dt.tzinfo is None:
        # naive datetime은 UTC로 가정
        dt = dt.replace(tzinfo=timezone.utc)
    
    kst_time = dt.astimezone(KST)
    # ISO 8601 형식으로 반환 (시간대 정보 포함)
    return kst_time.isoformat()

# JSON 응답에서 시간 필드 변환
def process_time_fields(data):
    """응답 데이터의 시간 필드들을 한국 시간으로 변환"""
    if isinstance(data, list):
        return [process_time_fields(item) for item in data]
    elif isinstance(data, dict):
        result = data.copy()
        
        # 시간 관련 필드들 변환
        time_fields = ['created_at', 'updated_at', 'date']
        for field in time_fields:
            if field in result and result[field] is not None:
                if isinstance(result[field], datetime):
                    result[field] = convert_to_kst_string(result[field])
                elif isinstance(result[field], str):
                    try:
                        # 문자열을 datetime으로 파싱 후 KST 변환
                        dt = datetime.fromisoformat(result[field].replace('Z', '+00:00'))
                        result[field] = convert_to_kst_string(dt)
                    except:
                        # 파싱 실패하면 원본 유지
                        pass
        
        return result
    else:
        return data

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
        
        # 시간 필드 변환
        processed_menus = process_time_fields(list(menus))
        
        return jsonify(processed_menus)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 이미지 업로드 API
@app.route('/api/upload-image', methods=['POST'])
def upload_image():
    try:
        if 'image' not in request.files:
            return jsonify({"error": "No image file provided"}), 400
        
        file = request.files['image']
        if file.filename == '':
            return jsonify({"error": "No file selected"}), 400
        
        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            unique_filename = f"{uuid.uuid4().hex}_{filename}"
            filepath = os.path.join(app.config['UPLOAD_FOLDER'], unique_filename)
            
            file.save(filepath)
            
            image_url = f"/images/{unique_filename}"
            
            return jsonify({"image_url": image_url}), 201
        else:
            return jsonify({"error": "Invalid file type. Only PNG, JPG, JPEG, GIF allowed"}), 400
            
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 이미지 서빙 API
@app.route('/api/images/<filename>')
def serve_image(filename):
    try:
        print(f"이미지 요청: {filename}")
        print(f"업로드 폴더: {app.config['UPLOAD_FOLDER']}")
        
        filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        if not os.path.exists(filepath):
            print(f"파일이 존재하지 않음: {filepath}")
            return jsonify({"error": "Image not found"}), 404
            
        return send_from_directory(app.config['UPLOAD_FOLDER'], filename)
    except Exception as e:
        print(f"이미지 서빙 오류: {e}")
        return jsonify({"error": "Image not found"}), 404

# Base64 이미지 업로드 API
@app.route('/api/upload-image-base64', methods=['POST'])
def upload_image_base64():
    try:
        data = request.get_json()
        
        if 'image_data' not in data or 'filename' not in data:
            return jsonify({"error": "image_data and filename are required"}), 400
        
        image_data = data['image_data']
        filename = data['filename']
        
        print(f"이미지 업로드 요청: {filename}")
        
        try:
            if ',' in image_data:
                image_data = image_data.split(',')[1]
            
            image_bytes = base64.b64decode(image_data)
            print(f"이미지 크기: {len(image_bytes)} bytes")
        except Exception as e:
            return jsonify({"error": "Invalid base64 image data"}), 400
        
        file_ext = filename.rsplit('.', 1)[1].lower() if '.' in filename else ''
        if file_ext not in ALLOWED_EXTENSIONS:
            return jsonify({"error": "Invalid file type"}), 400
        
        unique_filename = f"{uuid.uuid4().hex}.{file_ext}"
        filepath = os.path.join(app.config['UPLOAD_FOLDER'], unique_filename)
        
        print(f"저장할 파일 경로: {filepath}")
        
        with open(filepath, 'wb') as f:
            f.write(image_bytes)
        
        if os.path.exists(filepath):
            print(f"파일 저장 성공: {filepath}")
        else:
            print(f"파일 저장 실패: {filepath}")
            return jsonify({"error": "Failed to save image"}), 500
        
        image_url = f"/images/{unique_filename}"
        print(f"생성된 이미지 URL: {image_url}")
        
        return jsonify({"image_url": image_url}), 201
        
    except Exception as e:
        print(f"이미지 업로드 오류: {e}")
        return jsonify({"error": str(e)}), 500

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
        
        # 시간 필드 변환
        processed_posts = process_time_fields(list(posts))
        
        return jsonify(processed_posts)
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
        
        # 한국 시간으로 created_at 설정
        kst_now = datetime.now(KST)
        
        query = """
        INSERT INTO posts (title, content, author, meal_date, meal_type, image_url, created_at)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
        RETURNING *
        """
        
        cur.execute(query, (
            data['title'],
            data['content'], 
            data['author'],
            data['meal_date'],
            data['meal_type'],
            data.get('image_url'),
            kst_now  # 한국 시간으로 저장
        ))
        
        new_post = cur.fetchone()
        conn.commit()
        cur.close()
        conn.close()
        
        # 시간 필드 변환
        processed_post = process_time_fields(dict(new_post))
        
        return jsonify(processed_post), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/posts/<int:post_id>', methods=['GET'])
def get_post_detail(post_id):
    """게시글 상세 조회"""
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        cur.execute('SELECT * FROM posts WHERE id = %s', (post_id,))
        post = cur.fetchone()
        
        if not post:
            return jsonify({"error": "Post not found"}), 404
        
        cur.execute("""
            SELECT c.*, COALESCE(cl.like_count, 0) as likes
            FROM comments c
            LEFT JOIN (
                SELECT comment_id, COUNT(*) as like_count 
                FROM comment_likes 
                GROUP BY comment_id
            ) cl ON c.id = cl.comment_id
            WHERE c.post_id = %s 
            ORDER BY c.created_at ASC
        """, (post_id,))
        comments = cur.fetchall()
        
        cur.close()
        conn.close()
        
        result = dict(post)
        result['comments'] = list(comments)
        
        # 시간 필드 변환
        processed_result = process_time_fields(result)
        
        return jsonify(processed_result)
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
        
        cur.execute("""
            SELECT id FROM post_likes 
            WHERE post_id = %s AND user_identifier = %s
        """, (post_id, user_identifier))
        
        existing_like = cur.fetchone()
        
        if existing_like:
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
            cur.execute("""
                INSERT INTO post_likes (post_id, user_identifier)
                VALUES (%s, %s)
            """, (post_id, user_identifier))
            
            cur.execute("""
                UPDATE posts SET likes = likes + 1 
                WHERE id = %s
            """, (post_id,))
            
            liked = True
        
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
        
        # 한국 시간으로 created_at 설정
        kst_now = datetime.now(KST)
        
        query = """
        INSERT INTO comments (post_id, content, author, created_at)
        VALUES (%s, %s, %s, %s)
        RETURNING *, 0 as likes
        """
        
        cur.execute(query, (post_id, data['content'], data['author'], kst_now))
        new_comment = cur.fetchone()
        
        conn.commit()
        cur.close()
        conn.close()
        
        # 시간 필드 변환
        processed_comment = process_time_fields(dict(new_comment))
        
        return jsonify(processed_comment), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/comments/<int:comment_id>/like', methods=['POST'])
def toggle_comment_like(comment_id):
    """댓글 좋아요 토글"""
    try:
        data = request.get_json()
        user_identifier = data.get('user_identifier', request.remote_addr)
        
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        cur.execute("""
            SELECT id FROM comment_likes 
            WHERE comment_id = %s AND user_identifier = %s
        """, (comment_id, user_identifier))
        
        existing_like = cur.fetchone()
        
        if existing_like:
            cur.execute("""
                DELETE FROM comment_likes 
                WHERE comment_id = %s AND user_identifier = %s
            """, (comment_id, user_identifier))
            liked = False
        else:
            cur.execute("""
                INSERT INTO comment_likes (comment_id, user_identifier)
                VALUES (%s, %s)
            """, (comment_id, user_identifier))
            liked = True
        
        cur.execute("""
            SELECT COUNT(*) as like_count 
            FROM comment_likes 
            WHERE comment_id = %s
        """, (comment_id,))
        result = cur.fetchone()
        
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({
            "liked": liked,
            "likes": result['like_count']
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500
# 비밀번호 해시 함수
def hash_password(password):
    """비밀번호를 SHA-256으로 해시화"""
    return hashlib.sha256(password.encode()).hexdigest()

def verify_password(password, hashed):
    """비밀번호 검증"""
    return hash_password(password) == hashed

# 세션 토큰 생성
def generate_session_token():
    """세션 토큰 생성"""
    return secrets.token_urlsafe(32)

# 회원가입 API
@app.route('/api/auth/register', methods=['POST'])
def register():
    """회원가입"""
    try:
        data = request.get_json()
        
        required_fields = ['username', 'password', 'email']
        for field in required_fields:
            if field not in data:
                return jsonify({"error": f"{field} is required"}), 400
        
        username = data['username']
        password = data['password']
        email = data['email']
        
        # 비밀번호 길이 검증
        if len(password) < 6:
            return jsonify({"error": "Password must be at least 6 characters"}), 400
        
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        # 중복 확인
        cur.execute("SELECT id FROM users WHERE username = %s OR email = %s", (username, email))
        if cur.fetchone():
            return jsonify({"error": "Username or email already exists"}), 409
        
        # 사용자 생성
        hashed_password = hash_password(password)
        kst_now = datetime.now(KST)
        
        cur.execute("""
            INSERT INTO users (username, password, email, created_at)
            VALUES (%s, %s, %s, %s)
            RETURNING id, username, email, created_at
        """, (username, hashed_password, email, kst_now))
        
        new_user = cur.fetchone()
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({
            "message": "User registered successfully",
            "user": dict(new_user)
        }), 201
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 로그인 API
@app.route('/api/auth/login', methods=['POST'])
def login():
    """로그인"""
    try:
        data = request.get_json()
        
        if 'username' not in data or 'password' not in data:
            return jsonify({"error": "Username and password are required"}), 400
        
        username = data['username']
        password = data['password']
        
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        # 사용자 조회
        cur.execute("SELECT id, username, password, email FROM users WHERE username = %s", (username,))
        user = cur.fetchone()
        
        if not user or not verify_password(password, user['password']):
            return jsonify({"error": "Invalid username or password"}), 401
        
        # 세션 토큰 생성 및 저장
        session_token = generate_session_token()
        expires_at = datetime.now(KST) + timedelta(days=7)  # 7일 후 만료
        
        cur.execute("""
            INSERT INTO user_sessions (user_id, session_token, expires_at, created_at)
            VALUES (%s, %s, %s, %s)
        """, (user['id'], session_token, expires_at, datetime.now(KST)))
        
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({
            "message": "Login successful",
            "user": {
                "id": user['id'],
                "username": user['username'],
                "email": user['email']
            },
            "session_token": session_token
        }), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 로그아웃 API
@app.route('/api/auth/logout', methods=['POST'])
def logout():
    """로그아웃"""
    try:
        data = request.get_json()
        session_token = data.get('session_token')
        
        if not session_token:
            return jsonify({"error": "Session token is required"}), 400
        
        conn = get_db_connection()
        cur = conn.cursor()
        
        # 세션 삭제
        cur.execute("DELETE FROM user_sessions WHERE session_token = %s", (session_token,))
        
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({"message": "Logout successful"}), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 세션 검증 함수
def verify_session(session_token):
    """세션 토큰 검증"""
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        cur.execute("""
            SELECT u.id, u.username, u.email 
            FROM users u
            JOIN user_sessions s ON u.id = s.user_id
            WHERE s.session_token = %s AND s.expires_at > %s
        """, (session_token, datetime.now(KST)))
        
        user = cur.fetchone()
        cur.close()
        conn.close()
        
        return dict(user) if user else None
        
    except Exception as e:
        print(f"Session verification error: {e}")
        return None

# ===== 게시글 수정/삭제 API =====

# 게시글 수정 API
@app.route('/api/posts/<int:post_id>', methods=['PUT'])
def update_post(post_id):
    """게시글 수정"""
    try:
        data = request.get_json()
        
        # 세션 검증
        session_token = data.get('session_token')
        if not session_token:
            return jsonify({"error": "Session token is required"}), 401
        
        user = verify_session(session_token)
        if not user:
            return jsonify({"error": "Invalid or expired session"}), 401
        
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        # 게시글 존재 및 작성자 확인
        cur.execute("SELECT author FROM posts WHERE id = %s", (post_id,))
        post = cur.fetchone()
        
        if not post:
            return jsonify({"error": "Post not found"}), 404
        
        if post['author'] != user['username']:
            return jsonify({"error": "You can only edit your own posts"}), 403
        
        # 수정할 필드들
        title = data.get('title')
        content = data.get('content')
        image_url = data.get('image_url')
        
        update_fields = []
        update_values = []
        
        if title:
            update_fields.append("title = %s")
            update_values.append(title)
        
        if content:
            update_fields.append("content = %s")
            update_values.append(content)
        
        if image_url is not None:  # None과 빈 문자열 구분
            update_fields.append("image_url = %s")
            update_values.append(image_url)
        
        if not update_fields:
            return jsonify({"error": "No fields to update"}), 400
        
        # 수정 시간 추가
        update_fields.append("updated_at = %s")
        update_values.append(datetime.now(KST))
        update_values.append(post_id)
        
        query = f"UPDATE posts SET {', '.join(update_fields)} WHERE id = %s RETURNING *"
        cur.execute(query, update_values)
        
        updated_post = cur.fetchone()
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({
            "message": "Post updated successfully",
            "post": process_time_fields(dict(updated_post))
        }), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 게시글 삭제 API
@app.route('/api/posts/<int:post_id>', methods=['DELETE'])
def delete_post(post_id):
    """게시글 삭제"""
    try:
        data = request.get_json()
        
        # 세션 검증
        session_token = data.get('session_token')
        if not session_token:
            return jsonify({"error": "Session token is required"}), 401
        
        user = verify_session(session_token)
        if not user:
            return jsonify({"error": "Invalid or expired session"}), 401
        
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        # 게시글 존재 및 작성자 확인
        cur.execute("SELECT author FROM posts WHERE id = %s", (post_id,))
        post = cur.fetchone()
        
        if not post:
            return jsonify({"error": "Post not found"}), 404
        
        if post['author'] != user['username']:
            return jsonify({"error": "You can only delete your own posts"}), 403
        
        # 관련 데이터 삭제 (외래 키 제약으로 인해)
        cur.execute("DELETE FROM comment_likes WHERE comment_id IN (SELECT id FROM comments WHERE post_id = %s)", (post_id,))
        cur.execute("DELETE FROM comments WHERE post_id = %s", (post_id,))
        cur.execute("DELETE FROM post_likes WHERE post_id = %s", (post_id,))
        cur.execute("DELETE FROM posts WHERE id = %s", (post_id,))
        
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({"message": "Post deleted successfully"}), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# ===== 댓글 수정/삭제 API =====

# 댓글 수정 API
@app.route('/api/comments/<int:comment_id>', methods=['PUT'])
def update_comment(comment_id):
    """댓글 수정"""
    try:
        data = request.get_json()
        
        # 세션 검증
        session_token = data.get('session_token')
        if not session_token:
            return jsonify({"error": "Session token is required"}), 401
        
        user = verify_session(session_token)
        if not user:
            return jsonify({"error": "Invalid or expired session"}), 401
        
        content = data.get('content')
        if not content:
            return jsonify({"error": "Content is required"}), 400
        
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        # 댓글 존재 및 작성자 확인
        cur.execute("SELECT author FROM comments WHERE id = %s", (comment_id,))
        comment = cur.fetchone()
        
        if not comment:
            return jsonify({"error": "Comment not found"}), 404
        
        if comment['author'] != user['username']:
            return jsonify({"error": "You can only edit your own comments"}), 403
        
        # 댓글 수정
        cur.execute("""
            UPDATE comments 
            SET content = %s, updated_at = %s 
            WHERE id = %s 
            RETURNING *
        """, (content, datetime.now(KST), comment_id))
        
        updated_comment = cur.fetchone()
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({
            "message": "Comment updated successfully",
            "comment": process_time_fields(dict(updated_comment))
        }), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 댓글 삭제 API
@app.route('/api/comments/<int:comment_id>', methods=['DELETE'])
def delete_comment(comment_id):
    """댓글 삭제"""
    try:
        data = request.get_json()
        
        # 세션 검증
        session_token = data.get('session_token')
        if not session_token:
            return jsonify({"error": "Session token is required"}), 401
        
        user = verify_session(session_token)
        if not user:
            return jsonify({"error": "Invalid or expired session"}), 401
        
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        # 댓글 존재 및 작성자 확인
        cur.execute("SELECT author FROM comments WHERE id = %s", (comment_id,))
        comment = cur.fetchone()
        
        if not comment:
            return jsonify({"error": "Comment not found"}), 404
        
        if comment['author'] != user['username']:
            return jsonify({"error": "You can only delete your own comments"}), 403
        
        # 관련 좋아요 삭제 후 댓글 삭제
        cur.execute("DELETE FROM comment_likes WHERE comment_id = %s", (comment_id,))
        cur.execute("DELETE FROM comments WHERE id = %s", (comment_id,))
        
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({"message": "Comment deleted successfully"}), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

        
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)