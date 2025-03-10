from flask import Flask, jsonify
import os
import psycopg2
import redis

app = Flask(__name__)

# Database connection
def get_db_connection():
    conn = psycopg2.connect(
        host='db',
        database=os.environ.get('DB_NAME', 'devdb'),
        user=os.environ.get('DB_USER', 'postgres'),
        password=os.environ.get('DB_PASSWORD', 'postgres')
    )
    conn.autocommit = True
    return conn

# Redis connection
cache = redis.Redis(
    host='cache', 
    port=6379, 
    db=0, 
    decode_responses=True
)

@app.route('/')
def index():
    return jsonify({
        'message': 'DevBox API is running',
        'status': 'success'
    })

@app.route('/health')
def health():
    status = {
        'app': 'healthy',
        'db': 'unhealthy',
        'cache': 'unhealthy'
    }
    
    # Check DB
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute('SELECT 1')
        cursor.close()
        conn.close()
        status['db'] = 'healthy'
    except Exception as e:
        status['db'] = f'unhealthy: {str(e)}'
    
    # Check Cache
    try:
        if cache.ping():
            status['cache'] = 'healthy'
    except Exception as e:
        status['cache'] = f'unhealthy: {str(e)}'
    
    return jsonify(status)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)