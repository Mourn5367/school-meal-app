from flask import Flask, jsonify
import psycopg2
from psycopg2.extras import RealDictCursor
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # 모든 경로에 CORS 허용

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

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)