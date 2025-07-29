import os
from flask import Blueprint, jsonify, url_for, current_app
from db_config import get_db_connection
from datetime import datetime, timedelta

routers_bp = Blueprint('routers', __name__)

# Option 1: If IMAGES_FOLDER is defined in your app.py, import it like this:
# from app import IMAGES_FOLDER

# Option 2: If not, define the image folder here:
IMAGES_FOLDER = r'C:\Users\63967\Desktop\network monitoring\routerLocImg'

@routers_bp.route('/routers', methods=['GET'])
def get_routers():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    # 1) Retrieve basic router info INCLUDING image_path
    cursor.execute("""
        SELECT id, name, ip_address, location, image_path
        FROM routers
    """)
    routers = cursor.fetchall()

    result = []
    for router in routers:
        rid = router['id']

        # 2) Fetch the single most-recent status log for this router
        cursor.execute("""
            SELECT status, timestamp
            FROM router_status_log
            WHERE router_id = %s
            ORDER BY timestamp DESC
            LIMIT 1
        """, (rid,))
        row = cursor.fetchone()

        if row:
            status = row['status']
            ts = row['timestamp']
            last_time = ts if isinstance(ts, datetime) else datetime.strptime(ts, "%Y-%m-%d %H:%M:%S")
        else:
            status = 'offline'
            last_time = None

        # 3) If the last update is older than 1 minute, consider it stale
        error = None
        if last_time and datetime.utcnow() - last_time > timedelta(minutes=1):
            status = 'offline'
            error = 'Refresh failed: Router status is outdated.'

        # 4) Build the image_url if the file exists
        image_path = router.get('image_path')  # can be 'routerLocImg/1.png', 'routerLocImg\\1.png', or just '1.png'
        image_url = None
        if image_path:
            filename = os.path.basename(image_path)  # Always just the filename, e.g. '1.png'
            # Build the full path to check if the file exists
            full_path = os.path.join(IMAGES_FOLDER, filename)
            if os.path.isfile(full_path):
                image_url = url_for('router_image', filename=filename, _external=True)

        result.append({
            'id':          rid,
            'name':        router['name'],
            'ip_address':  router['ip_address'],
            'location':    router['location'],
            'status':      status,
            'last_update': last_time.strftime("%Y-%m-%d %H:%M:%S") if last_time else None,
            'error':       error,
            'image_url':   image_url
        })

    cursor.close()
    conn.close()
    return jsonify({'success': True, 'data': result})


# ——— Existing functions for uptime and logs ———

def get_uptime_percentage(router_id, start_date, end_date):
    """
    Calculate uptime percentage for a given router between two datetimes.
    """
    conn = get_db_connection()
    cursor = conn.cursor()

    total_seconds = (end_date - start_date).total_seconds()

    cursor.execute("""
        SELECT status, timestamp
        FROM router_status_log
        WHERE router_id = %s AND timestamp BETWEEN %s AND %s
        ORDER BY timestamp ASC
    """, (router_id, start_date, end_date))
    rows = cursor.fetchall()

    cursor.close()
    conn.close()

    offline = 0
    prev_ts, prev_status = start_date, 'online'
    for status, ts in rows:
        if prev_status == 'offline':
            offline += (ts - prev_ts).total_seconds()
        prev_status, prev_ts = status, ts
    if prev_status == 'offline':
        offline += (end_date - prev_ts).total_seconds()

    uptime = max(0, total_seconds - offline)
    return (uptime / total_seconds) * 100 if total_seconds else 0


def get_status_logs(router_id, start_date, end_date):
    """
    Fetch raw status logs for a router in a given date range.
    """
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT timestamp, status
        FROM router_status_log
        WHERE router_id = %s AND timestamp BETWEEN %s AND %s
        ORDER BY timestamp ASC
    """, (router_id, start_date, end_date))
    logs = cursor.fetchall()

    cursor.close()
    conn.close()
    return logs

