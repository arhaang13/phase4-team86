import os
import mysql.connector

# make sure to configure these based on local server before running file
DB_HOST = "127.0.0.1"
DB_USER = "root"
DB_PASSWORD = ""
DB_NAME = "flight_tracking"

def execute_sql_file(cur, filepath):
    with open(filepath, 'r', encoding='utf8') as file:
        sql = file.read()
        statements = sql.split(';')
        for statement in statements:
            statement = statement.strip()
            if statement:
                cur.execute(statement)

def setup_database():
    try:
        connection = mysql.connector.connect(
            host=DB_HOST,
            user=DB_USER,
            password=DB_PASSWORD
        )
        cur = connection.cursor()
        print("Creating and using database...")
        cur.execute(f"DROP DATABASE IF EXISTS {DB_NAME}")
        cur.execute(f"CREATE DATABASE {DB_NAME}")
        cur.execute(f"USE {DB_NAME}")

        base_path = os.path.join(os.path.dirname(__file__), "sql")
        print("→ Executing schema.sql...")
        execute_sql_file(cur, os.path.join(base_path, "schema.sql"))

        print("Executing procedures.sql...")
        execute_sql_file(cur, os.path.join(base_path, "procedures.sql"))

        connection.commit()
        cur.close()
        connection.close()
        return True
        
    except mysql.connector.Error as e:
        print(f"Database setup error: {e}")
        return False

if __name__ == "__main__":
    print("=== flight_tracking: database setup ===")
    if setup_database():
        print("Setup complete. Can now run the app.")
    else:
        print("Setup failed.")
