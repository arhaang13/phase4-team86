import mysql.connector

DB_CONFIG = {
    "host": "127.0.0.1",
    "user": "root",
    "password": "",
    "database": "flight_tracking"
}

def get_db_connection():
    return mysql.connector.connect(**DB_CONFIG)

def test_db_connection():
    try:
        conn = get_db_connection()
        conn.close()
        return True
    except:
        return False

def execute_query(query, params=None):
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute(query, params) if params else cursor.execute(query)
        
        try:
            return cursor.fetchall()
        except:
            conn.commit()
            return []
    except Exception as e:
        if conn:
            conn.rollback()
        print(f"Query error: {e}")
        raise
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

def execute_procedure(procedure_name, params=None):
    conn = None
    cursor = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        if params:
            placeholders = ', '.join(['%s'] * len(params))
            cursor.execute(f"CALL {procedure_name}({placeholders})", params)
        else:
            cursor.execute(f"CALL {procedure_name}()")
            
        results = []
        try:
            results = cursor.fetchall()
        except:
            pass
            
        conn.commit()
        return results
    except Exception as e:
        if conn:
            conn.rollback()
        print(f"Procedure error: {e}")
        raise
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()