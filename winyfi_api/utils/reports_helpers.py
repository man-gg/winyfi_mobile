from db_config import get_db_connection
from datetime import datetime

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
    Returns a list of dicts: {timestamp, status}
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

    # Convert timestamp to Python datetime object if needed
    for log in logs:
        if isinstance(log['timestamp'], str):
            try:
                log['timestamp'] = datetime.strptime(log['timestamp'], "%Y-%m-%d %H:%M:%S")
            except Exception:
                log['timestamp'] = datetime.strptime(log['timestamp'], "%Y-%m-%dT%H:%M:%S.%f")

    cursor.close()
    conn.close()
    return logs

def get_router_name(router_id):
    """Get the router name by id."""
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT name FROM routers WHERE id = %s", (router_id,))
    row = cursor.fetchone()
    cursor.close()
    conn.close()
    if row:
        return row['name']
    return None

# (Optionally, you can add more utility functions as needed)
