import mysql.connector

def get_db_connection():
    return mysql.connector.connect(
        host='localhost',        # or your MySQL host
        user='root',        # replace with your MySQL username
        password='',    # replace with your password
        database='winyfi'       # replace with your database name
    )
