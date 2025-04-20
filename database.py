import mysql.connector
from mysql.connector import Error

# Hard-coded database configuration
DB_HOST = "127.0.0.1"
DB_USER = "root"
DB_PASSWORD = ""  # Empty string for no password
DB_NAME = "flight_tracking"

def test_db_connection():
    """Tests the database connection and returns True if successful, False otherwise"""
    try:
        connection = get_db_connection()
        if connection:
            connection.close()
            return True
        return False
    except Exception:
        return False

def get_db_connection():
    """Establishes a connection to the MySQL database"""
    try:
        # Connect to MySQL
        connection = mysql.connector.connect(
            host=DB_HOST,
            user=DB_USER,
            password=DB_PASSWORD,
            database=DB_NAME
        )
        
        return connection
    except Error as e:
        print(f"Error connecting to database: {e}")
        raise

def execute_procedure(procedure_name, params=None):
    """Executes a MySQL stored procedure with the given parameters"""
    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        
        # Call the stored procedure
        if params:
            param_placeholders = ', '.join(['%s' for _ in range(len(params))])
            query = f"CALL {procedure_name}({param_placeholders})"
            cursor.execute(query, params)
        else:
            query = f"CALL {procedure_name}()"
            cursor.execute(query)
            
        # Get results if any
        results = []
        try:
            result = cursor.fetchall()
            if result:
                results.extend(result)
        except:
            pass
            
        connection.commit()
        return results
    except Exception as e:
        if connection:
            connection.rollback()
        print(f"Error executing procedure {procedure_name}: {e}")
        raise
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

def execute_query(query, params=None):
    """Executes a MySQL query with the given parameters"""
    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        
        if params:
            cursor.execute(query, params)
        else:
            cursor.execute(query)
        
        try:
            result = cursor.fetchall()
            return result
        except:
            connection.commit()
            return []
    except Exception as e:
        if connection:
            connection.rollback()
        print(f"Error executing query: {e}")
        raise
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()