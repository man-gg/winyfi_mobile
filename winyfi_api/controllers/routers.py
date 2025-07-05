from flask import Blueprint, jsonify
from db_config import get_db_connection
from datetime import datetime, timedelta

routers_bp = Blueprint('routers', __name__)

@routers_bp.route('/routers', methods=['GET'])
def get_routers():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    # Get all routers
    cursor.execute("SELECT * FROM routers")
    routers = cursor.fetchall()

    # Get last status log per router
    latest_status = {}
    cursor.execute("""
        SELECT router_id, status, MAX(timestamp) as latest_time
        FROM router_status_log
        GROUP BY router_id
    """)
    for row in cursor.fetchall():
        router_id = row['router_id']
        status = row['status']
        last_time = row['latest_time']

        # Consider offline if last online > 60 seconds ago
        if status == 'online':
            last_time_dt = last_time if isinstance(last_time, datetime) else datetime.strptime(last_time, "%Y-%m-%d %H:%M:%S")
            if datetime.utcnow() - last_time_dt > timedelta(seconds=60):
                status = 'offline'

        latest_status[router_id] = {
            'status': status,
            'timestamp': last_time.strftime("%Y-%m-%d %H:%M:%S")
        }

    cursor.close()
    conn.close()

    result = []
    for router in routers:
        rid = router['id']
        status_info = latest_status.get(rid, {'status': 'offline', 'timestamp': None})
        result.append({
            'id': rid,
            'name': router['name'],
            'ip_address': router['ip_address'],
            'location': router['location'],
            'status': status_info['status'],
            'last_update': status_info['timestamp'],
        })

    return jsonify({'success': True, 'data': result})
