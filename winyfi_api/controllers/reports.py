from flask import Blueprint, request, jsonify
from db_config import get_db_connection

reports_bp = Blueprint('reports', __name__)

@reports_bp.route('/reports', methods=['GET'])
def get_reports_by_date():
    date = request.args.get('date')  # format: YYYY-MM-DD

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT 
            r.name AS router,
            r.location,
            l.status,
            DATE_FORMAT(l.timestamp, '%%m/%%d/%%y') AS date
        FROM router_status_log l
        JOIN routers r ON r.id = l.router_id
        WHERE DATE(l.timestamp) = %s AND l.status = 'offline'
        ORDER BY l.timestamp DESC
    """, (date,))
    reports = cursor.fetchall()
    cursor.close()
    conn.close()

    return jsonify(reports)
