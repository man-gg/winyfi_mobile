from flask import Blueprint, request, jsonify
from db_config import get_db_connection
from datetime import datetime, timedelta
from utils.reports_helpers import get_uptime_percentage, get_status_logs

reports_bp = Blueprint('reports', __name__)

def parse_date(date_str):
    # Try both microseconds and seconds ISO format
    try:
        return datetime.strptime(date_str, "%Y-%m-%dT%H:%M:%S.%f")
    except Exception:
        try:
            return datetime.strptime(date_str, "%Y-%m-%dT%H:%M:%S")
        except Exception:
            raise ValueError(f"Invalid date format: {date_str}")

def format_duration_hm(minutes):
    """Format minutes as 'Xh Ym' for easy reading."""
    mins = int(round(minutes))
    hours = mins // 60
    mins = mins % 60
    if hours > 0:
        return f"{hours}h {mins}m"
    return f"{mins}m"

@reports_bp.route('/uptime', methods=['GET'])
def get_uptime_percentage_report():
    router_id = request.args.get('router_id')
    start_date = parse_date(request.args.get('start_date'))
    end_date = parse_date(request.args.get('end_date'))
    uptime_percentage = get_uptime_percentage(router_id, start_date, end_date)
    return jsonify({'success': True, 'uptime_percentage': uptime_percentage})

@reports_bp.route('/logs', methods=['GET'])
def get_status_logs_report():
    router_id = request.args.get('router_id')
    start_date = parse_date(request.args.get('start_date'))
    end_date = parse_date(request.args.get('end_date'))
    # Fetch logs: status, timestamp, and router name
    logs = []
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT r.name as router_name, l.timestamp, l.status
        FROM router_status_log l
        JOIN routers r ON r.id = l.router_id
        WHERE l.router_id = %s AND l.timestamp BETWEEN %s AND %s
        ORDER BY l.timestamp ASC
    """, (router_id, start_date, end_date))
    for row in cursor.fetchall():
        logs.append({
            "router": row["router_name"],
            "timestamp": row["timestamp"].strftime("%Y-%m-%d %H:%M:%S"),
            "status": row["status"]
        })
    cursor.close()
    conn.close()
    return jsonify({'success': True, 'logs': logs})

@reports_bp.route('/offenders', methods=['GET'])
def get_top_offenders():
    start_date = parse_date(request.args.get('start_date'))
    end_date = parse_date(request.args.get('end_date'))

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT id, name FROM routers")
    routers = cursor.fetchall()
    offenders = []
    total_secs = (end_date - start_date).total_seconds()
    for r in routers:
        router_id = r['id']
        # Fetch logs for this router
        cursor2 = conn.cursor(dictionary=True)
        cursor2.execute("""
            SELECT timestamp, status
            FROM router_status_log
            WHERE router_id = %s AND timestamp BETWEEN %s AND %s
            ORDER BY timestamp ASC
        """, (router_id, start_date, end_date))
        logs = cursor2.fetchall()
        cursor2.close()

        # Calculate total downtime for this router
        offline_start = None
        total_offline_seconds = 0
        for entry in logs:
            status = entry['status']
            ts = entry['timestamp']
            if isinstance(ts, str):
                try:
                    ts = datetime.strptime(ts, "%Y-%m-%d %H:%M:%S")
                except Exception:
                    ts = datetime.strptime(ts, "%Y-%m-%dT%H:%M:%S.%f")
            if status == 'offline':
                if offline_start is None:
                    offline_start = ts
            else:
                if offline_start:
                    downtime_sec = (ts - offline_start).total_seconds()
                    total_offline_seconds += downtime_sec
                    offline_start = None
        if offline_start:
            downtime_sec = (end_date - offline_start).total_seconds()
            total_offline_seconds += downtime_sec

        downtime_min = round(total_offline_seconds / 60, 2)
        downtime_pct = (total_offline_seconds / total_secs * 100) if total_secs > 0 else 0.0
        uptime_pct = 100 - downtime_pct

        offenders.append({
            "router": r["name"],
            "router_id": r["id"],
            "downtime_minutes": downtime_min,
            "downtime_hm": format_duration_hm(downtime_min),
            "downtime_pct": round(downtime_pct, 2),
            "uptime_pct": round(uptime_pct, 2)
        })
    offenders.sort(key=lambda x: x["downtime_minutes"], reverse=True)
    cursor.close()
    conn.close()
    return jsonify({'success': True, 'offenders': offenders})

@reports_bp.route('/downtime_detail', methods=['GET'])
def downtime_detail():
    router_id = request.args.get('router_id')
    end = datetime.utcnow()
    start = end - timedelta(days=30)

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT timestamp, status
        FROM router_status_log
        WHERE router_id = %s AND timestamp BETWEEN %s AND %s
        ORDER BY timestamp ASC
    """, (router_id, start, end))
    logs = cursor.fetchall()
    cursor.close()
    conn.close()

    # Calculate downtime periods and total downtime
    downtimes = []
    offline_start = None
    total_offline_seconds = 0

    for entry in logs:
        status = entry['status']
        ts = entry['timestamp']
        # Ensure ts is a datetime object
        if isinstance(ts, str):
            try:
                ts = datetime.strptime(ts, "%Y-%m-%d %H:%M:%S")
            except Exception:
                ts = datetime.strptime(ts, "%Y-%m-%dT%H:%M:%S.%f")
        if status == 'offline':
            if offline_start is None:
                offline_start = ts
        else:
            if offline_start:
                downtime_sec = (ts - offline_start).total_seconds()
                total_offline_seconds += downtime_sec
                downtimes.append({
                    'start': offline_start.strftime("%Y-%m-%d %H:%M:%S"),
                    'end': ts.strftime("%Y-%m-%d %H:%M:%S"),
                    'duration_seconds': int(downtime_sec)
                })
                offline_start = None
    # If still offline at the end
    if offline_start:
        downtime_sec = (end - offline_start).total_seconds()
        total_offline_seconds += downtime_sec
        downtimes.append({
            'start': offline_start.strftime("%Y-%m-%d %H:%M:%S"),
            'end': None,
            'duration_seconds': int(downtime_sec)
        })

    # Total downtime in seconds and minutes
    total_offline_minutes = round(total_offline_seconds / 60, 2)

    return jsonify({
        'success': True,
        'total_downtime_seconds': int(total_offline_seconds),
        'total_downtime_minutes': total_offline_minutes,
        'downtimes': downtimes
    })
