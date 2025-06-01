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

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)