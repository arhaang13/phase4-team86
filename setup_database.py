import os
import mysql.connector

DB_HOST = "127.0.0.1"
DB_USER = "root"
DB_PASSWORD = ""
DB_NAME = "flight_tracking"

def execute_sql_file(cursor, filepath):
    with open(filepath, 'r', encoding='utf8') as file:
        sql = file.read()
        statements = sql.split(';')
        for stmt in statements:
            stmt = stmt.strip()
            if stmt:
                cursor.execute(stmt)

def setup_database():
    try:
        conn = mysql.connector.connect(
            host=DB_HOST,
            user=DB_USER,
            password=DB_PASSWORD
        )
        cursor = conn.cursor()
        print("→ Creating and using database...")
        cursor.execute(f"DROP DATABASE IF EXISTS {DB_NAME}")
        cursor.execute(f"CREATE DATABASE {DB_NAME}")
        cursor.execute(f"USE {DB_NAME}")

        base_path = os.path.join(os.path.dirname(__file__), "sql")
        print("→ Executing schema.sql...")
        execute_sql_file(cursor, os.path.join(base_path, "schema.sql"))

        print("→ Executing procedures.sql...")
        execute_sql_file(cursor, os.path.join(base_path, "procedures.sql"))

        conn.commit()
        cursor.close()
        conn.close()
        return True
    except mysql.connector.Error as e:
        print(f"Database setup error: {e}")
        return False

if __name__ == "__main__":
    print("=== flight_tracking: database setup ===")
    if setup_database():
        print("Setup complete. You can now run your app.")
    else:
        print("Setup failed.")